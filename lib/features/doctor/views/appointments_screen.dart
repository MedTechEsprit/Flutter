import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/appointment_service.dart';
import 'package:diab_care/data/services/patient_service.dart';
import 'package:diab_care/data/models/appointment_model.dart';
import 'dart:convert';
import 'dart:math';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const int _maxAppointmentsPerDay = 15;

  DateTime selectedDate = DateTime.now();
  String selectedView = 'List'; // Changed default to List View

  // API Integration
  final _appointmentService = AppointmentService();
  final _tokenService = TokenService();
  final _patientService = PatientService();
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
        print(
          '🔑 Token preview: ${token.substring(0, min(20, token.length))}...',
        );

        // Try to decode JWT to see what's in it
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            // Decode the payload (second part)
            final payload = parts[1];
            // Add padding if needed
            String normalized = payload
                .replaceAll('-', '+')
                .replaceAll('_', '/');
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
      print(
        '📡 Fetching appointments${_selectedStatusFilter != null ? " with filter: ${_selectedStatusFilter!.name}" : ""}...',
      );

      List<AppointmentModel> appointments;
      if (_selectedStatusFilter != null) {
        appointments = await _appointmentService.getDoctorAppointments(
          _doctorId!,
          status: _selectedStatusFilter,
        );
      } else {
        appointments = await _appointmentService.getDoctorAppointments(
          _doctorId!,
        );
        appointments = appointments
            .where((apt) => apt.status != AppointmentStatus.CANCELLED)
            .toList();
      }

      print('✅ Loaded ${appointments.length} appointments');
      for (var apt in appointments) {
        print(
          '  - Appointment ${apt.id}: ${apt.dateTime} (${apt.status.displayName})',
        );
      }

      // Auto-complete past appointments that are still pending or confirmed
      await _autoCompletePastAppointments(appointments);

      // Load stats separately
      print('📊 Fetching statistics...');
      final stats = await _appointmentService.getDoctorStats(_doctorId!);
      print(
        '✅ Stats loaded: Total ${stats.total}, Pending ${stats.byStatus[AppointmentStatus.PENDING] ?? 0}',
      );

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
  Future<void> _autoCompletePastAppointments(
    List<AppointmentModel> appointments,
  ) async {
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

    if (selectedView == 'Calendar') {
      final filtered = _appointments.where((apt) {
        final matches =
            apt.dateTime.year == selectedDate.year &&
            apt.dateTime.month == selectedDate.month &&
            apt.dateTime.day == selectedDate.day;

        if (matches) {
          print('   ✅ Appointment ${apt.id} matches date filter');
        }

        return matches;
      }).toList();

      print(
        '   Filtered to ${filtered.length} appointments for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
      );

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
      backgroundColor: const Color(0xFFEFF6FF),
      body: Column(
        children: [
          // ═══════════════════════════════════════════
          // GRADIENT HEADER
          // ═══════════════════════════════════════════
          Container(
            padding: const EdgeInsets.only(bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF22C1C3), Color(0xFF5B86E5)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Appointments',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _loadAppointments,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // View Toggle (Modern)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        _buildViewToggle('List', Icons.list_alt_rounded),
                        _buildViewToggle(
                          'Calendar',
                          Icons.calendar_month_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _buildStatusFilterChip('All', null),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(
                          'Pending',
                          AppointmentStatus.PENDING,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(
                          'Confirmed',
                          AppointmentStatus.CONFIRMED,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(
                          'Completed',
                          AppointmentStatus.COMPLETED,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(
                          'Cancelled',
                          AppointmentStatus.CANCELLED,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  if (selectedView == 'Calendar') ...[
                    const SizedBox(height: 24),
                    _buildCalendarSection(),
                  ],
                  const SizedBox(height: 24),
                  _buildAppointmentsList(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF22C1C3), Color(0xFF5B86E5)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B86E5).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddAppointmentDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New appointment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.blueGrey,
                    ),
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
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Colors.blueGrey,
                    ),
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
            ],
          ),
          const SizedBox(height: 20),
          _buildWeekDays(),
          const SizedBox(height: 12),
          _buildCalendarDates(),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  Widget _buildAppointmentsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: Color(0xFF22C1C3)),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 16),
            const Text(
              'Load error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAppointments,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_filteredAppointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 60,
              color: Colors.blueGrey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              selectedView == 'Calendar'
                  ? 'No appointments on this date'
                  : 'No appointments',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedView == 'List' ? 'All appointments' : 'Appointments today',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          ..._filteredAppointments.map(
            (appointment) => _buildAppointmentCardFromModel(appointment),
          ),
        ],
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
          _applyDateFilter();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF5B86E5) : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                view,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF5B86E5) : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 13,
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
      children: days
          .map(
            (day) => SizedBox(
              width: 35,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarDates() {
    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;
    final firstDayOfMonth =
        DateTime(selectedDate.year, selectedDate.month, 1).weekday - 1;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...List.generate(
          firstDayOfMonth,
          (index) => const SizedBox(width: 35, height: 35),
        ),
        ...List.generate(daysInMonth, (index) {
          final day = index + 1;
          final date = DateTime(selectedDate.year, selectedDate.month, day);
          final isSelected =
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          final hasAppointment = _appointments.any(
            (apt) =>
                apt.dateTime.year == date.year &&
                apt.dateTime.month == date.month &&
                apt.dateTime.day == date.day &&
                apt.status != AppointmentStatus.CANCELLED,
          );

          return InkWell(
            onTap: () {
              setState(() {
                selectedDate = date;
              });
              _applyDateFilter();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF22C1C3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF22C1C3).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1E293B),
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (hasAppointment && !isSelected)
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDBB2D),
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
                      Icon(
                        Icons.access_time,
                        color: AppColors.lightBlue,
                        size: 20,
                      ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                        final appointment = _appointments.firstWhere(
                          (a) => a.id == appointmentId,
                        );
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
                              Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: Color(0xFF22C1C3),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Accept',
                                style: TextStyle(
                                  color: Color(0xFF22C1C3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                              Icon(
                                Icons.cancel_rounded,
                                size: 20,
                                color: Color(0xFFFF6B6B),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Decline',
                                style: TextStyle(
                                  color: Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                              Icon(
                                Icons.edit_rounded,
                                size: 20,
                                color: Color(0xFF9BC4E2),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Color(0xFF9BC4E2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                            Icon(
                              Icons.delete_rounded,
                              size: 20,
                              color: Color(0xFFFF6B6B),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                            Icon(
                              Icons.visibility_rounded,
                              size: 20,
                              color: Color(0xFF718096),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'View details',
                              style: TextStyle(color: Color(0xFF718096)),
                            ),
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
      patientName: appointment.patientName ?? 'Patient',
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
        statusColor = const Color(0xFF22C1C3);
        break;
      case 'Pending':
        statusColor = const Color(0xFFFDBB2D);
        break;
      case 'Completed':
        statusColor = const Color(0xFF5B86E5);
        break;
      default:
        statusColor = Colors.blueGrey;
    }

    if (type == 'Online') {
      typeColor = const Color(0xFF5B86E5);
      typeIcon = Icons.videocam_outlined;
    } else {
      typeColor = const Color(0xFF22C1C3);
      typeIcon = Icons.local_hospital_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showAppointmentDetails(appointment.id),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Time Indicator Block
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.8),
                        statusColor.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Patient & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(typeIcon, size: 14, color: typeColor),
                          const SizedBox(width: 6),
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 12,
                              color: typeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions Menu
                PopupMenuButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.blueGrey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                        final apt = _appointments.firstWhere(
                          (a) => a.id == appointmentId,
                        );
                        await _editAppointment(apt);
                        break;
                      case 'delete':
                        await _deleteAppointment(appointmentId);
                        break;
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Color(0xFF5B86E5)),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            color: Colors.blueGrey,
                          ),
                          SizedBox(width: 12),
                          Text('Details'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFFF6B6B),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(color: Color(0xFFFF6B6B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          backgroundColor: Color(0xFF22C1C3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadAppointments(); // Reload to show updated status
    } catch (e) {
      print('❌ Error accepting appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting: ${e.toString()}'),
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
            Text('Decline appointment'),
          ],
        ),
        content: const Text(
          'Are you sure you want to decline this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text('Yes, decline'),
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
            content: Text('Error declining: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editAppointment(AppointmentModel appointment) async {
    _showEditAppointmentDialog(appointment);
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _appointmentService.cancelAppointment(appointmentId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadAppointments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete appointment'),
        content: const Text(
          'Are you sure you want to permanently delete this appointment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, delete permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _appointmentService.deleteAppointment(appointmentId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment deleted permanently'),
            backgroundColor: Colors.red,
          ),
        );
        _loadAppointments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditAppointmentDialog(AppointmentModel appointment) {
    final notesController = TextEditingController(
      text: appointment.notes ?? '',
    );
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit appointment',
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
                const SizedBox(height: 8),
                Text(
                  'Patient: ${appointment.patientName ?? 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Status Selection
                const Text(
                  'Status *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? chipColor
                              : chipColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: chipColor,
                            width: isSelected ? 2 : 1,
                          ),
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
                const Text(
                  'Date and time *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
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
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.softGreen),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.softGreen,
                        ),
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
                const Text(
                  'Appointment type *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(
                          () => selectedType = AppointmentType.ONLINE,
                        ),
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
                              Icon(
                                Icons.videocam,
                                color: selectedType == AppointmentType.ONLINE
                                    ? AppColors.softGreen
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Online',
                                style: TextStyle(
                                  color: selectedType == AppointmentType.ONLINE
                                      ? AppColors.softGreen
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(
                          () => selectedType = AppointmentType.PHYSICAL,
                        ),
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
                              Icon(
                                Icons.local_hospital,
                                color: selectedType == AppointmentType.PHYSICAL
                                    ? AppColors.softGreen
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'In person',
                                style: TextStyle(
                                  color:
                                      selectedType == AppointmentType.PHYSICAL
                                      ? AppColors.softGreen
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Notes
                const Text(
                  'Notes',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Edit notes...',
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.softGreen,
                        width: 2,
                      ),
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
                                notes: notesController.text.isNotEmpty
                                    ? notesController.text
                                    : null,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Appointment updated successfully',
                                  ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Update appointment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
    final appointment = _appointments.firstWhere(
      (apt) => apt.id == appointmentId,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Gradient
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF22C1C3), Color(0xFF5B86E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Appointment details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Details List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildPremiumDetailRow(
                    Icons.person_outline,
                    'Patient',
                    appointment.patientName ?? 'Unknown',
                  ),
                  _buildPremiumDetailRow(
                    Icons.calendar_today_outlined,
                    'Date & Time',
                    appointment.formattedDateTime,
                  ),
                  _buildPremiumDetailRow(
                    Icons.category_outlined,
                    'Type',
                    appointment.type.displayName,
                  ),
                  _buildPremiumDetailRow(
                    Icons.info_outline,
                    'Status',
                    appointment.status.displayName,
                    isStatus: true,
                  ),
                  if (appointment.notes != null &&
                      appointment.notes!.isNotEmpty)
                    _buildPremiumDetailRow(
                      Icons.note_alt_outlined,
                      'Notes',
                      appointment.notes!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isStatus = false,
  }) {
    Color statusColor = const Color(0xFF22C1C3);
    if (isStatus) {
      if (value.contains('Pending')) statusColor = const Color(0xFFFDBB2D);
      if (value.contains('Cancelled')) statusColor = const Color(0xFFFF6B6B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isStatus ? statusColor : const Color(0xFF5B86E5))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isStatus ? statusColor : const Color(0xFF5B86E5),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isStatus ? statusColor : const Color(0xFF1E293B),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _findAppointmentId(String patientName, String time) {
    try {
      return _appointments
          .firstWhere(
            (apt) =>
                (apt.patientName ?? '').contains(patientName.substring(0, 5)) &&
                apt.formattedTime == time,
          )
          .id;
    } catch (e) {
      return null;
    }
  }

  void _showAddAppointmentDialog(BuildContext context) {
    final searchController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(
      const Duration(days: 1, hours: 1),
    );
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Gradient
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF22C1C3), Color(0xFF5B86E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New appointment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Search Field
                      _buildPremiumInputLabel('Select a patient'),
                      const SizedBox(height: 8),

                      // Patient Search Field
                      TextField(
                        controller: searchController,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: selectedPatientId == null
                              ? 'Search by name...'
                              : selectedPatientName,
                          hintStyle: TextStyle(
                            color: selectedPatientId == null
                                ? Colors.grey
                                : const Color(0xFF1E293B),
                          ),
                          prefixIcon: const Icon(
                            Icons.person_search,
                            color: Color(0xFF5B86E5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFB),
                          suffixIcon: selectedPatientId != null
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Color(0xFFFF6B6B),
                                  ),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF5B86E5),
                                    ),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabled: selectedPatientId == null,
                        ),
                        onChanged: (value) async {
                          if (value.length >= 2 && selectedPatientId == null) {
                            setModalState(() => isSearching = true);

                            print('🔍 Searching for patients: $value');

                            try {
                              if (_doctorId == null) {
                                throw Exception('Doctor ID not found');
                              }

                              final patients = await _patientService
                                  .searchPatients(
                                    doctorId: _doctorId!,
                                    query: value,
                                  );

                              print(
                                '✅ Found ${patients.length} linked patients',
                              );

                              setModalState(() {
                                searchResults = List<Map<String, dynamic>>.from(
                                  patients.map(
                                    (p) => {
                                      'id': p.id,
                                      'name': p.fullName.trim().isEmpty
                                          ? 'Unknown'
                                          : p.fullName,
                                      'email': p.email,
                                      'phone': p.telephone,
                                    },
                                  ),
                                );
                                isSearching = false;
                              });
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
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: searchResults.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.withOpacity(0.1),
                            ),
                            itemBuilder: (context, index) {
                              final p = searchResults[index];
                              return ListTile(
                                title: Text(
                                  p['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  p['email'] ?? p['phone'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onTap: () {
                                  setModalState(() {
                                    selectedPatientId = p['id'];
                                    selectedPatientName = p['name'];
                                    searchResults = [];
                                    searchController.text = p['name'];
                                  });
                                },
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Date & Time Picker
                      _buildPremiumInputLabel('Date and time *'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                selectedDateTime,
                              ),
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
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF5B86E5),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} at ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.blueGrey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Appointment Type Selector
                      _buildPremiumInputLabel('Appointment type *'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeChip(
                              'Online',
                              Icons.videocam_outlined,
                              AppointmentType.ONLINE,
                              selectedType,
                              (t) => setModalState(() => selectedType = t),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeChip(
                              'In person',
                              Icons.local_hospital_outlined,
                              AppointmentType.PHYSICAL,
                              selectedType,
                              (t) => setModalState(() => selectedType = t),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Notes
                      _buildPremiumInputLabel('Notes'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Add notes...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Create Button
                      _buildPremiumActionButton(
                        label: 'Create appointment',
                        isLoading: isCreating,
                        onPressed: (selectedPatientId == null || isCreating)
                            ? null
                            : () async {
                                setModalState(() => isCreating = true);
                                try {
                                  final appointment = await _appointmentService
                                      .createAppointment(
                                        patientId: selectedPatientId!,
                                        doctorId: _doctorId!,
                                        dateTime: selectedDateTime,
                                        type: selectedType,
                                        notes:
                                            notesController.text
                                                .trim()
                                                .isNotEmpty
                                            ? notesController.text.trim()
                                            : null,
                                      );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Appointment created with $selectedPatientName!',
                                      ),
                                      backgroundColor: const Color(0xFF22C1C3),
                                    ),
                                  );
                                  _loadAppointments();
                                } catch (e) {
                                  setModalState(() => isCreating = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(
    String label,
    IconData icon,
    AppointmentType type,
    AppointmentType selected,
    Function(AppointmentType) onSelect,
  ) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () => onSelect(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5B86E5).withOpacity(0.1)
              : const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B86E5) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF5B86E5) : Colors.blueGrey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF5B86E5) : Colors.blueGrey,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countAppointmentsOnDate(DateTime date) {
    return _appointments
        .where(
          (apt) =>
              _isSameDay(apt.dateTime, date) &&
              apt.status != AppointmentStatus.CANCELLED,
        )
        .length;
  }

  int _countPatientAppointmentsOnDate(String patientId, DateTime date) {
    return _appointments
        .where(
          (apt) =>
              apt.patientId == patientId &&
              _isSameDay(apt.dateTime, date) &&
              apt.status != AppointmentStatus.CANCELLED,
        )
        .length;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<bool?> _showSameDateWarningDialog(
    DateTime date,
    int dayTotal,
    int patientTotal,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scheduling warning'),
        content: Text(
          'On ${date.day}/${date.month}/${date.year}, you already have $dayTotal appointments.\n'
          '${patientTotal > 0 ? 'This patient already has $patientTotal appointments on that day.\n' : ''}'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, AppointmentStatus? status) {
    final isSelected = _selectedStatusFilter == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = status;
        });
        _loadAppointments();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF5B86E5) : Colors.white,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPremiumActionButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null
            : LinearGradient(
                colors: [
                  color ?? const Color(0xFF22C1C3),
                  color?.withOpacity(0.8) ?? const Color(0xFF5B86E5),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: (color ?? const Color(0xFF5B86E5)).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}
