import 'package:flutter/material.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/appointment_service.dart';
import 'package:diab_care/data/services/patient_request_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'patient_requests_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _tokenService = TokenService();
  final _appointmentService = AppointmentService();
  final _patientRequestService = PatientRequestService(); // NEW

  String _doctorName = '';
  String _doctorSpecialite = '';
  int _totalAppointments = 0;
  int _pendingCount = 0;
  int _confirmedCount = 0;
  int _completedCount = 0;
  int _pendingRequestsCount = 0; // NEW: Patient requests count
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    try {
      final doctorId = await _tokenService.getUserId();
      final token = await _tokenService.getToken();

      if (doctorId == null || token == null) return;

      // Fetch doctor profile
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/medecins/$doctorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _doctorName = '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim();
          _doctorSpecialite = data['specialite'] ?? '';
        });
      }

      // Fetch appointment stats
      try {
        final stats = await _appointmentService.getDoctorStats(doctorId);
        setState(() {
          _totalAppointments = stats.total;
          _pendingCount = stats.pendingCount;
          _confirmedCount = stats.confirmedCount;
          _completedCount = stats.completedCount;
        });
      } catch (_) {}

      // Fetch patient requests count
      try {
        final requests = await _patientRequestService.getPatientRequests(doctorId);
        setState(() {
          _pendingRequestsCount = requests.where((r) => r.isPending).length;
        });
      } catch (_) {}

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading doctor data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient Header with Greeting
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Text(
                        _isLoading ? 'Loading...' : 'Hello Dr. $_doctorName 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _doctorSpecialite.isNotEmpty
                            ? _doctorSpecialite
                            : 'Here\'s how your patients are doing today!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content with padding
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Requests Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB347), Color(0xFFFF9500)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB347).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Patient Requests',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLoading
                                ? 'Loading...'
                                : _pendingRequestsCount == 0
                                    ? 'No pending requests'
                                    : '$_pendingRequestsCount patient${_pendingRequestsCount == 1 ? "" : "s"} waiting for approval',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientRequestsScreen(),
                          ),
                        );
                        // Refresh data after returning from patient requests
                        _loadDoctorData();
                      },
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildColorfulStatCard(
                      '$_pendingCount',
                      'Pending',
                      Icons.hourglass_empty,
                      const Color(0xFFFFB347),
                      const Color(0xFFFF9500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildColorfulStatCard(
                      '$_totalAppointments',
                      'Appointments',
                      Icons.calendar_today_outlined,
                      const Color(0xFF9BC4E2),
                      const Color(0xFF7AB3D6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildColorfulStatCard(
                      '$_confirmedCount',
                      'Confirmed',
                      Icons.check_circle_outline,
                      const Color(0xFF7DDAB9),
                      const Color(0xFF5BC4A8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildColorfulStatCard(
                      '$_completedCount',
                      'Completed',
                      Icons.done_all,
                      const Color(0xFFB794F4),
                      const Color(0xFF9F7AEA),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Population Trends Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Patient Trends',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7DDAB9).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.trending_up, size: 16, color: Color(0xFF7DDAB9)),
                              SizedBox(width: 4),
                              Text(
                                '+12%',
                                style: TextStyle(
                                  color: Color(0xFF7DDAB9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF7DDAB9).withOpacity(0.2),
                            const Color(0xFF7DDAB9).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.show_chart, size: 48, color: Color(0xFF7DDAB9)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTrendItem('In Range', '75%', const Color(0xFF7DDAB9)),
                        _buildTrendItem('Above', '18%', const Color(0xFFFFB347)),
                        _buildTrendItem('Below', '7%', const Color(0xFFFF6B6B)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Critical Alerts Section
              const Text(
                'Critical Alerts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),

              _buildAlertCard(
                'John Doe',
                'High Glucose: 280 mg/dL',
                '10 mins ago',
                const Color(0xFFFF6B6B),
                Icons.warning_rounded,
              ),
              _buildAlertCard(
                'Mary Smith',
                'Missed medication dose',
                '30 mins ago',
                const Color(0xFFFFB347),
                Icons.medication,
              ),
              _buildAlertCard(
                'James Wilson',
                'Appointment in 1 hour',
                '1 hour ago',
                const Color(0xFF9BC4E2),
                Icons.calendar_today,
              ),

              const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorfulStatCard(String value, String label, IconData icon, Color color1, Color color2) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color1.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(String name, String message, String time, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFFA0AEC0),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
