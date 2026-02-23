import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/appointment_service.dart';
import 'package:diab_care/data/models/appointment_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedView = 'List View'; // Changed default to List View

  // API Integration
  final _appointmentService = AppointmentService();
  final _tokenService = TokenService();
  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> _filteredAppointments = [];
  AppointmentStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;
  String? _doctorId;
  AppointmentStatus? _selectedStatusFilter; // null = "All"

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    print('📋 === LOADING APPOINTMENTS ===');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user data to see what we have
      final userData = await _tokenService.getUserData();
      print('👤 User Data: $userData');

      // Try multiple methods to get doctor ID
      _doctorId = await _tokenService.getUserId();
      final doctorIdAlt = await _tokenService.getDoctorId();

      print('🏥 Doctor ID (getUserId): $_doctorId');
      print('🏥 Doctor ID (getDoctorId): $doctorIdAlt');

      // If getUserId is different from getDoctorId, log it
      if (_doctorId != doctorIdAlt) {
        print('⚠️ WARNING: getUserId and getDoctorId return different values!');
        print('   getUserId: $_doctorId');
        print('   getDoctorId: $doctorIdAlt');
      }

      if (_doctorId == null) {
        print('❌ Doctor ID is null!');
        throw Exception('Doctor ID not found. Please login again.');
      }

      // Check token
      final token = await _tokenService.getToken();
      print('🔑 Token exists: ${token != null}');
      if (token != null) {
        print('🔑 Token preview: ${token.substring(0, min(20, token.length))}...');

        // Try to decode JWT to see what's in it
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            // Decode the payload (second part)
            final payload = parts[1];
            // Add padding if needed
            String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
            while (normalized.length % 4 != 0) {
              normalized += '=';
            }
            final decoded = utf8.decode(base64Decode(normalized));
            final payloadMap = jsonDecode(decoded);
            print('🔓 JWT Payload: $payloadMap');
            print('   sub (subject): ${payloadMap['sub']}');
            print('   role: ${payloadMap['role']}');
            print('   email: ${payloadMap['email']}');
          }
        } catch (e) {
          print('⚠️ Could not decode JWT: $e');
        }
      }

      // Check role
      final role = await _tokenService.getUserRole();
      print('👤 User role: $role');

      // Load appointments with filter if selected
      print('📡 Fetching appointments${_selectedStatusFilter != null ? " with filter: ${_selectedStatusFilter!.name}" : ""}...');

      List<AppointmentModel> appointments;
      if (_selectedStatusFilter != null) {
        appointments = await _appointmentService.getDoctorAppointments(
          _doctorId!,
          status: _selectedStatusFilter,
        );
      } else {
        appointments = await _appointmentService.getDoctorAppointments(_doctorId!);
      }

      print('✅ Loaded ${appointments.length} appointments');
      for (var apt in appointments) {
        print('  - Appointment ${apt.id}: ${apt.dateTime} (${apt.status.displayName})');
      }

      // Auto-complete past appointments that are still pending or confirmed
      await _autoCompletePastAppointments(appointments);

      // Load stats separately
      print('📊 Fetching statistics...');
      final stats = await _appointmentService.getDoctorStats(_doctorId!);
      print('✅ Stats loaded: Total ${stats.total}, Pending ${stats.byStatus[AppointmentStatus.PENDING] ?? 0}');

      setState(() {
        _appointments = appointments;
        _filteredAppointments = appointments;
        _stats = stats;
        _isLoading = false;
      });

      // Apply date filter after setState completes
      _applyDateFilter();

      print('✅ === APPOINTMENTS LOADED SUCCESSFULLY ===');
    } catch (e, stackTrace) {
      print('❌ === ERROR LOADING APPOINTMENTS ===');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Auto-complete past appointments
  Future<void> _autoCompletePastAppointments(List<AppointmentModel> appointments) async {
    final now = DateTime.now();

    for (var appointment in appointments) {
      // Check if appointment is in the past and still Pending or Confirmed
      if (appointment.dateTime.isBefore(now) &&
          (appointment.status == AppointmentStatus.PENDING ||
           appointment.status == AppointmentStatus.CONFIRMED)) {

        try {
          print('⏰ Auto-completing past appointment: ${appointment.id}');
          print('   Date was: ${appointment.dateTime}');
          print('   Old status: ${appointment.status.displayName}');

          await _appointmentService.updateAppointment(
            appointment.id,
            status: AppointmentStatus.COMPLETED,
          );

          print('✅ Appointment auto-completed successfully');
        } catch (e) {
          print('❌ Failed to auto-complete appointment ${appointment.id}: $e');
          // Continue with other appointments even if one fails
        }
      }
    }
  }

  void _applyDateFilter() {
    print('🔍 Applying date filter...');
    print('   View: $selectedView');
    print('   Total appointments: ${_appointments.length}');
    print('   Selected date: $selectedDate');

    if (selectedView == 'Calendar View') {
      final filtered = _appointments.where((apt) {
        final matches = apt.dateTime.year == selectedDate.year &&
            apt.dateTime.month == selectedDate.month &&
            apt.dateTime.day == selectedDate.day;

        if (matches) {
          print('   ✅ Appointment ${apt.id} matches date filter');
        }

        return matches;
      }).toList();

      print('   Filtered to ${filtered.length} appointments for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}');

      setState(() {
        _filteredAppointments = filtered;
      });
    } else {
      print('   No date filter applied (List View)');
      setState(() {
        _filteredAppointments = _appointments;
      });
    }

    print('   Final filtered count: ${_filteredAppointments.length}');
  }

  // ignore: unused_element
  List<AppointmentModel> get _todayAppointments {
    final today = DateTime.now();
    return _appointments.where((apt) {
      return apt.dateTime.year == today.year &&
          apt.dateTime.month == today.month &&
          apt.dateTime.day == today.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Gradient Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7DDAB9),
                      Color(0xFF9BC4E2),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Appointments',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLoading
                                  ? 'Loading...'
                                  : '${_stats?.total ?? _appointments.length} appointments total',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _showAddAppointmentDialog(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFB347), Color(0xFFFF9500)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFB347).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  'New',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // View Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildViewToggle('List View', Icons.list),
                      _buildViewToggle('Calendar View', Icons.calendar_month),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Mini Calendar (only show in Calendar View)
              if (selectedView == 'Calendar View')
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                selectedDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month - 1,
                                  1,
                                );
                              });
                              _applyDateFilter();
                            },
                          ),
                          Text(
                            '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                selectedDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month + 1,
                                  1,
                                );
                              });
                              _applyDateFilter();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildWeekDays(),
                      const SizedBox(height: 8),
                      _buildCalendarDates(),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Filter Tabs
              if (_stats != null)
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildFilterChip('All', _stats!.total, null),
                      _buildFilterChip('Pending', _stats!.byStatus[AppointmentStatus.PENDING] ?? 0, AppointmentStatus.PENDING),
                      _buildFilterChip('Confirmed', _stats!.byStatus[AppointmentStatus.CONFIRMED] ?? 0, AppointmentStatus.CONFIRMED),
                      _buildFilterChip('Completed', _stats!.byStatus[AppointmentStatus.COMPLETED] ?? 0, AppointmentStatus.COMPLETED),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Appointments List or Error/Empty State
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 60, color: Colors.red),
                              const SizedBox(height: 16),
                              const Text(
                                'Error loading appointments',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadAppointments,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredAppointments.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 60, color: AppColors.textLight),
                                  const SizedBox(height: 16),
                                  Text(
                                    selectedView == 'Calendar View'
                                        ? 'No appointments on this date'
                                        : 'No appointments yet',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Create your first appointment',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: _filteredAppointments
                                    .map((appointment) => _buildAppointmentCardFromModel(appointment))
                                    .toList(),
                              ),
                            ),

              const SizedBox(height: 80), // Bottom padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAppointmentDialog(context),
        backgroundColor: AppColors.softGreen,
        icon: const Icon(Icons.add),
        label: const Text('New Appointment'),
      ),
    );
  }

  Widget _buildViewToggle(String view, IconData icon) {
    final isSelected = selectedView == view;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedView = view;
          });
          _applyDateFilter(); // Re-apply filter when view changes
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.softGreen.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.softGreen : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                view,
                style: TextStyle(
                  color: isSelected ? AppColors.softGreen : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDays() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) => SizedBox(
        width: 40,
        child: Text(
          day,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarDates() {
    // Calculate the number of days in the selected month
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    // Calculate the first day of the month (0 = Monday, 6 = Sunday)
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1).weekday - 1;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // Add empty spaces for days before the 1st
        ...List.generate(firstDayOfMonth, (index) => const SizedBox(width: 40, height: 40)),

        // Add actual days
        ...List.generate(daysInMonth, (index) {
          final day = index + 1;
          final isSelected = day == selectedDate.day &&
              selectedDate.month == DateTime.now().month &&
              selectedDate.year == DateTime.now().year;

          // Check if this date has appointments
          final hasAppointment = _appointments.any((apt) =>
              apt.dateTime.year == selectedDate.year &&
              apt.dateTime.month == selectedDate.month &&
              apt.dateTime.day == day);

          return InkWell(
            onTap: () {
              setState(() {
                selectedDate = DateTime(selectedDate.year, selectedDate.month, day);
              });
              _applyDateFilter();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.softGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (hasAppointment && !isSelected)
                    Positioned(
                      bottom: 6,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.softOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFilterChip(String label, int count, AppointmentStatus? status) {
    final isSelected = _selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.softGreen.withOpacity(0.5)
                    : AppColors.softGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatusFilter = status;
          });
          _loadAppointments();
        },
        backgroundColor: AppColors.white,
        selectedColor: AppColors.softGreen.withOpacity(0.2),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAppointmentCard({
    required String patientName,
    required String time,
    required String type,
    required String status,
    required String avatar,
  }) {
    Color statusColor;
    Color typeColor;
    IconData typeIcon;

    switch (status) {
      case 'Confirmed':
        statusColor = AppColors.stable;
        break;
      case 'Pending':
        statusColor = AppColors.attention;
        break;
      case 'Completed':
        statusColor = AppColors.lightBlue;
        break;
      default:
        statusColor = AppColors.textLight;
    }

    if (type == 'Online') {
      typeColor = AppColors.lightBlue;
      typeIcon = Icons.videocam;
    } else {
      typeColor = AppColors.softGreen;
      typeIcon = Icons.local_hospital;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.access_time, color: AppColors.lightBlue, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: typeColor.withOpacity(0.2),
                            child: Text(
                              avatar,
                              style: TextStyle(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(typeIcon, size: 12, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  type,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Actions
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                  onSelected: (value) async {
                    final appointmentId = _findAppointmentId(patientName, time);
                    if (appointmentId == null) return;

                    switch (value) {
                      case 'view':
                        _showAppointmentDetails(appointmentId);
                        break;
                      case 'accept':
                        await _acceptAppointment(appointmentId);
                        break;
                      case 'decline':
                        await _declineAppointment(appointmentId);
                        break;
                      case 'edit':
                        // Find full appointment object for editing
                        final appointment = _appointments.firstWhere((a) => a.id == appointmentId);
                        await _editAppointment(appointment);
                        break;
                      case 'delete':
                        await _deleteAppointment(appointmentId);
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    List<PopupMenuEntry<String>> items = [];

                    // Accept Button (only for Pending)
                    if (status == 'Pending') {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'accept',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF7DDAB9)),
                              SizedBox(width: 12),
                              Text('Accept', style: TextStyle(color: Color(0xFF7DDAB9), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }

                    // Decline Button (only for Pending)
                    if (status == 'Pending') {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'decline',
                          child: Row(
                            children: [
                              Icon(Icons.cancel_rounded, size: 20, color: Color(0xFFFF6B6B)),
                              SizedBox(width: 12),
                              Text('Decline', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }

                    // Edit Button (for all except Completed/Cancelled)
                    if (status != 'Cancelled' && status != 'Completed') {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 20, color: Color(0xFF9BC4E2)),
                              SizedBox(width: 12),
                              Text('Edit', style: TextStyle(color: Color(0xFF9BC4E2), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }

                    // Delete Button (always available)
                    items.add(
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 20, color: Color(0xFFFF6B6B)),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );

                    // Divider
                    items.add(const PopupMenuDivider());

                    // View Details (always available)
                    items.add(
                      const PopupMenuItem<String>(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 20, color: Color(0xFF718096)),
                            SizedBox(width: 12),
                            Text('View Details', style: TextStyle(color: Color(0xFF718096))),
                          ],
                        ),
                      ),
                    );

                    return items;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NEW METHOD: Build appointment card from API model
  Widget _buildAppointmentCardFromModel(AppointmentModel appointment) {
    return _buildAppointmentCardWithActions(
      appointment: appointment,
      patientName: appointment.patientName ?? 'Patient ${appointment.patientId.substring(0, 6)}',
      time: appointment.formattedTime,
      type: appointment.type.displayName,
      status: appointment.status.displayName,
      avatar: (appointment.patientName ?? 'P').substring(0, 1).toUpperCase(),
    );
  }

  Widget _buildAppointmentCardWithActions({
    required AppointmentModel appointment,
    required String patientName,
    required String time,
    required String type,
    required String status,
    required String avatar,
  }) {
    Color statusColor;
    Color typeColor;
    IconData typeIcon;

    switch (status) {
      case 'Confirmed':
        statusColor = AppColors.stable;
        break;
      case 'Pending':
        statusColor = AppColors.attention;
        break;
      case 'Completed':
        statusColor = AppColors.lightBlue;
        break;
      default:
        statusColor = AppColors.textLight;
    }

    if (type == 'Online') {
      typeColor = AppColors.lightBlue;
      typeIcon = Icons.videocam;
    } else {
      typeColor = AppColors.softGreen;
      typeIcon = Icons.local_hospital;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAppointmentDetails(appointment.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Time
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.access_time, color: AppColors.lightBlue, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Patient Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: typeColor.withOpacity(0.2),
                                child: Text(
                                  avatar,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(typeIcon, size: 12, color: typeColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      type,
                                      style: TextStyle(
                                        color: typeColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Actions with API integration
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                      onSelected: (value) async {
                        switch (value) {
                          case 'view':
                            _showAppointmentDetails(appointment.id);
                            break;
                          case 'edit':
                            _showEditAppointmentDialog(appointment);
                            break;
                          case 'confirm':
                            await _confirmAppointment(appointment.id);
                            break;
                          case 'cancel':
                            await _cancelAppointment(appointment.id);
                            break;
                          case 'delete':
                            await _deleteAppointment(appointment.id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 12),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('Edit', style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                    if (appointment.status == AppointmentStatus.PENDING)
                      const PopupMenuItem(
                        value: 'confirm',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 18, color: AppColors.stable),
                            SizedBox(width: 12),
                            Text('Confirm', style: TextStyle(color: AppColors.stable)),
                          ],
                        ),
                      ),
                    if (appointment.status != AppointmentStatus.CANCELLED &&
                        appointment.status != AppointmentStatus.COMPLETED)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, size: 18, color: AppColors.critical),
                            SizedBox(width: 12),
                            Text('Cancel', style: TextStyle(color: AppColors.critical)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ], // Closing itemBuilder list
                ), // Closing PopupMenuButton
              ], // Closing first Row's children
            ), // Closing first Row

            // ACTION BUTTONS for PENDING appointments
            if (status == 'Pending') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Decline Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _declineAppointment(appointment.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B6B),
                        side: const BorderSide(color: Color(0xFFFF6B6B)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_rounded, size: 18),
                      label: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Accept Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptAppointment(appointment.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7DDAB9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ], // Closing Column's children
        ), // Closing Column
      ), // Closing Padding
        ),
      ),
    );
  }

  // API Action Methods
  Future<void> _acceptAppointment(String appointmentId) async {
    try {
      print('✅ Accepting appointment: $appointmentId');
      await _appointmentService.updateAppointment(
        appointmentId,
        status: AppointmentStatus.CONFIRMED,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Appointment accepted successfully'),
            ],
          ),
          backgroundColor: Color(0xFF7DDAB9),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadAppointments(); // Reload to show updated status
    } catch (e) {
      print('❌ Error accepting appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFFF6B6B)),
            SizedBox(width: 12),
            Text('Decline Appointment'),
          ],
        ),
        content: const Text('Are you sure you want to decline this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B6B)),
            child: const Text('Yes, Decline'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('❌ Declining appointment: $appointmentId');
        await _appointmentService.updateAppointment(
          appointmentId,
          status: AppointmentStatus.CANCELLED,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Appointment declined'),
              ],
            ),
            backgroundColor: Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAppointments();
      } catch (e) {
        print('❌ Error declining appointment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining appointment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editAppointment(AppointmentModel appointment) async {
    _showEditAppointmentDialog(appointment);
  }

  Future<void> _confirmAppointment(String appointmentId) async {
    try {
      await _appointmentService.confirmAppointment(appointmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment confirmed'), backgroundColor: Colors.green),
      );
      _loadAppointments(); // Reload to show updated status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _appointmentService.cancelAppointment(appointmentId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled'), backgroundColor: Colors.orange),
        );
        _loadAppointments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to permanently DELETE this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _appointmentService.deleteAppointment(appointmentId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment deleted permanently'), backgroundColor: Colors.red),
        );
        _loadAppointments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditAppointmentDialog(AppointmentModel appointment) {
    final notesController = TextEditingController(text: appointment.notes ?? '');
    AppointmentStatus selectedStatus = appointment.status;
    AppointmentType selectedType = appointment.type;
    DateTime selectedDateTime = appointment.dateTime;
    bool isUpdating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 24, right: 24, top: 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Appointment',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Patient: ${appointment.patientName ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // Status Selection
                const Text('Status *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppointmentStatus.values.map((status) {
                    final isSelected = selectedStatus == status;
                    Color chipColor;
                    switch (status) {
                      case AppointmentStatus.PENDING:
                        chipColor = Colors.orange;
                        break;
                      case AppointmentStatus.CONFIRMED:
                        chipColor = Colors.green;
                        break;
                      case AppointmentStatus.COMPLETED:
                        chipColor = Colors.blue;
                        break;
                      case AppointmentStatus.CANCELLED:
                        chipColor = Colors.red;
                        break;
                    }
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedStatus = status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor : chipColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: chipColor, width: isSelected ? 2 : 1),
                        ),
                        child: Text(
                          status.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : chipColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Date & Time Picker
                const Text('Date & Time *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setModalState(() {
                          selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.softGreen),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.softGreen),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} at ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Appointment Type Selector
                const Text('Appointment Type *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedType = AppointmentType.ONLINE),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selectedType == AppointmentType.ONLINE
                                ? AppColors.softGreen.withAlpha(30)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedType == AppointmentType.ONLINE
                                  ? AppColors.softGreen
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.videocam,
                                  color: selectedType == AppointmentType.ONLINE
                                      ? AppColors.softGreen
                                      : Colors.grey),
                              const SizedBox(height: 4),
                              Text('Online',
                                  style: TextStyle(
                                    color: selectedType == AppointmentType.ONLINE
                                        ? AppColors.softGreen
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedType = AppointmentType.PHYSICAL),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selectedType == AppointmentType.PHYSICAL
                                ? AppColors.softGreen.withAlpha(30)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedType == AppointmentType.PHYSICAL
                                  ? AppColors.softGreen
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.local_hospital,
                                  color: selectedType == AppointmentType.PHYSICAL
                                      ? AppColors.softGreen
                                      : Colors.grey),
                              const SizedBox(height: 4),
                              Text('Physical',
                                  style: TextStyle(
                                    color: selectedType == AppointmentType.PHYSICAL
                                        ? AppColors.softGreen
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Notes
                const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Update notes...',
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.softGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isUpdating
                        ? null
                        : () async {
                            setModalState(() => isUpdating = true);
                            try {
                              await _appointmentService.updateAppointment(
                                appointment.id,
                                status: selectedStatus,
                                dateTime: selectedDateTime,
                                type: selectedType,
                                notes: notesController.text.isNotEmpty ? notesController.text : null,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Appointment updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadAppointments();
                            } catch (e) {
                              setModalState(() => isUpdating = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Update Appointment',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetails(String appointmentId) {
    final appointment = _appointments.firstWhere((apt) => apt.id == appointmentId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appointment Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Patient ID', appointment.patientId),
            _buildDetailRow('Date & Time', appointment.formattedDateTime),
            _buildDetailRow('Type', appointment.type.displayName),
            _buildDetailRow('Status', appointment.status.displayName),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              _buildDetailRow('Notes', appointment.notes!),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _findAppointmentId(String patientName, String time) {
    try {
      return _appointments
          .firstWhere((apt) =>
              (apt.patientName ?? '').contains(patientName.substring(0, 5)) &&
              apt.formattedTime == time)
          .id;
    } catch (e) {
      return null;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showAddAppointmentDialog(BuildContext context) {
    final searchController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1, hours: 1));
    AppointmentType selectedType = AppointmentType.ONLINE;
    bool isCreating = false;

    // For patient selection
    String? selectedPatientId;
    String? selectedPatientName;
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Appointment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Patient Search Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: selectedPatientId == null ? 'Search Patient *' : 'Selected Patient',
                        hintText: selectedPatientId == null ? 'Search by name or email...' : selectedPatientName,
                        prefixIcon: const Icon(Icons.person_search),
                        suffixIcon: selectedPatientId != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setModalState(() {
                                    selectedPatientId = null;
                                    selectedPatientName = null;
                                    searchController.clear();
                                    searchResults.clear();
                                  });
                                },
                              )
                            : isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabled: selectedPatientId == null,
                      ),
                      onChanged: (value) async {
                        if (value.length >= 2 && selectedPatientId == null) {
                          setModalState(() => isSearching = true);

                          print('🔍 Searching for patients: $value');

                          try {
                            // Search patients using the search by name or email API
                            final token = await _tokenService.getToken();
                            print('🔑 Token: ${token?.substring(0, 20)}...');

                            final uri = Uri.parse('http://10.0.2.2:3000/api/patients/search/by-name-or-email?query=$value');
                            print('📡 Request URL: $uri');

                            final response = await http.get(
                              uri,
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Content-Type': 'application/json',
                              },
                            ).timeout(const Duration(seconds: 5));

                            print('📥 Response status: ${response.statusCode}');
                            print('📥 Response body: ${response.body}');

                            if (response.statusCode == 200) {
                              final List<dynamic> patients = jsonDecode(response.body);

                              print('✅ Found ${patients.length} patients');

                              setModalState(() {
                                searchResults = List<Map<String, dynamic>>.from(
                                  patients.map((p) {
                                    final nom = p['nom'] ?? '';
                                    final prenom = p['prenom'] ?? '';
                                    final name = '$prenom $nom'.trim();
                                    final finalName = name.isEmpty ? 'Unknown' : name;

                                    print('  Patient: $finalName (${p['email']})');

                                    return {
                                      'id': p['_id'] ?? p['id'] ?? '',
                                      'name': finalName,
                                      'email': p['email'] ?? 'No email',
                                    };
                                  })
                                );
                                isSearching = false;
                              });
                            } else {
                              print('❌ Error: ${response.statusCode} - ${response.body}');
                              setModalState(() {
                                searchResults = [];
                                isSearching = false;
                              });

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error searching patients: ${response.statusCode}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            print('❌ Search error: $e');
                            setModalState(() {
                              searchResults = [];
                              isSearching = false;
                            });

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else if (value.isEmpty) {
                          setModalState(() {
                            searchResults = [];
                            isSearching = false;
                          });
                        }
                      },
                    ),

                    // Search Results Dropdown
                    if (searchResults.isNotEmpty && selectedPatientId == null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.softGreen.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final patient = searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.softGreen.withOpacity(0.2),
                                child: Text(
                                  patient['name'].toString().substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.softGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                patient['name'],
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                patient['email'],
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                setModalState(() {
                                  selectedPatientId = patient['id'];
                                  selectedPatientName = patient['name'];
                                  searchController.text = patient['name'];
                                  searchResults.clear();
                                });
                              },
                            );
                          },
                        ),
                      ),

                    // Help text
                    if (selectedPatientId == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          'Type at least 2 characters to search',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date & Time Field
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setModalState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date & Time *',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} at ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Appointment Type
                const Text(
                  'Appointment Type *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedType = AppointmentType.ONLINE;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: selectedType == AppointmentType.ONLINE
                                ? AppColors.lightBlue.withOpacity(0.2)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedType == AppointmentType.ONLINE
                                  ? AppColors.lightBlue
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.videocam,
                                color: selectedType == AppointmentType.ONLINE
                                    ? AppColors.lightBlue
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Online',
                                style: TextStyle(
                                  color: selectedType == AppointmentType.ONLINE
                                      ? AppColors.lightBlue
                                      : AppColors.textSecondary,
                                  fontWeight: selectedType == AppointmentType.ONLINE
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setModalState(() {
                            selectedType = AppointmentType.PHYSICAL;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: selectedType == AppointmentType.PHYSICAL
                                ? AppColors.softGreen.withOpacity(0.2)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedType == AppointmentType.PHYSICAL
                                  ? AppColors.softGreen
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.local_hospital,
                                color: selectedType == AppointmentType.PHYSICAL
                                    ? AppColors.softGreen
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Physical',
                                style: TextStyle(
                                  color: selectedType == AppointmentType.PHYSICAL
                                      ? AppColors.softGreen
                                      : AppColors.textSecondary,
                                  fontWeight: selectedType == AppointmentType.PHYSICAL
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Notes Field
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any additional notes...',
                    prefixIcon: const Icon(Icons.note_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCreating
                        ? null
                        : () async {
                            // Validate
                            if (selectedPatientId == null || selectedPatientId!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a patient from the search results'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            setModalState(() => isCreating = true);

                            try {
                              print('🔵 Creating appointment with:');
                              print('  Patient ID: $selectedPatientId');
                              print('  Doctor ID: $_doctorId');
                              print('  DateTime: $selectedDateTime');
                              print('  Type: ${selectedType.name}');

                              final appointment = await _appointmentService.createAppointment(
                                patientId: selectedPatientId!,
                                doctorId: _doctorId!,
                                dateTime: selectedDateTime,
                                type: selectedType,
                                notes: notesController.text.trim().isNotEmpty
                                    ? notesController.text.trim()
                                    : null,
                              );

                              print('✅ Appointment created successfully: ${appointment.id}');

                              if (!context.mounted) return;

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Appointment created with $selectedPatientName!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadAppointments(); // Reload to show new appointment
                            } catch (e) {
                              print('❌ Error creating appointment: $e');

                              if (!context.mounted) return;

                              setModalState(() => isCreating = false);

                              String errorMessage = 'Failed to create appointment';
                              if (e.toString().contains('Serveur inaccessible')) {
                                errorMessage = 'Server is not accessible. Check if backend is running.';
                              } else if (e.toString().contains('Patient not found')) {
                                errorMessage = 'Patient not found. Please select a valid patient.';
                              } else if (e.toString().contains('message')) {
                                // Extract error message from Exception
                                final match = RegExp(r'message[:\s]+(.+)').firstMatch(e.toString());
                                if (match != null) {
                                  errorMessage = match.group(1) ?? errorMessage;
                                }
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softGreen,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Appointment',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
