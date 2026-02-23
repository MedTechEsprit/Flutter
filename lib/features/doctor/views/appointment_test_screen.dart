// Test screen for Appointment APIs
// Location: lib/features/doctor/views/appointment_test_screen.dart
// Use this to test all appointment endpoints

import 'package:flutter/material.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/appointment_service.dart';
import 'package:diab_care/data/models/appointment_model.dart';

class AppointmentTestScreen extends StatefulWidget {
  const AppointmentTestScreen({super.key});

  @override
  State<AppointmentTestScreen> createState() => _AppointmentTestScreenState();
}

class _AppointmentTestScreenState extends State<AppointmentTestScreen> {
  final _appointmentService = AppointmentService();
  final _tokenService = TokenService();

  String _testOutput = 'Test output will appear here...\n';
  bool _isLoading = false;

  void _log(String message) {
    setState(() {
      _testOutput += '${DateTime.now().toIso8601String()}: $message\n';
    });
  }

  void _clearLog() {
    setState(() {
      _testOutput = '';
    });
  }

  // TEST 1: Get doctor's appointments
  Future<void> _testGetDoctorAppointments() async {
    setState(() => _isLoading = true);
    try {
      _log('TEST 1: Getting doctor appointments...');

      final doctorId = await _tokenService.getUserId();
      if (doctorId == null) {
        _log('❌ ERROR: No doctor ID found. Login first!');
        setState(() => _isLoading = false);
        return;
      }

      _log('Doctor ID: $doctorId');
      final appointments = await _appointmentService.getDoctorAppointments(doctorId);
      _log('✅ SUCCESS: Found ${appointments.length} appointments');

      for (var apt in appointments) {
        _log('  - ${apt.id}: ${apt.patientName} on ${apt.formattedDateTime}');
      }
    } catch (e) {
      _log('❌ ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TEST 2: Get doctor's upcoming appointments
  Future<void> _testGetDoctorUpcomingAppointments() async {
    setState(() => _isLoading = true);
    try {
      _log('TEST 2: Getting doctor upcoming appointments...');

      final doctorId = await _tokenService.getUserId();
      if (doctorId == null) {
        _log('❌ ERROR: No doctor ID found');
        setState(() => _isLoading = false);
        return;
      }

      final appointments = await _appointmentService.getDoctorUpcomingAppointments(doctorId);
      _log('✅ SUCCESS: Found ${appointments.length} upcoming appointments');

      for (var apt in appointments) {
        _log('  - Status: ${apt.status.displayName}, Type: ${apt.type.displayName}');
      }
    } catch (e) {
      _log('❌ ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TEST 3: Get doctor statistics
  Future<void> _testGetDoctorStats() async {
    setState(() => _isLoading = true);
    try {
      _log('TEST 3: Getting doctor statistics...');

      final doctorId = await _tokenService.getUserId();
      if (doctorId == null) {
        _log('❌ ERROR: No doctor ID found');
        setState(() => _isLoading = false);
        return;
      }

      final stats = await _appointmentService.getDoctorStats(doctorId);
      _log('✅ SUCCESS: Got statistics');
      _log('  Total: ${stats.total}');
      _log('  By Status: ${stats.byStatus}');
      _log('  By Type: ${stats.byType}');
    } catch (e) {
      _log('❌ ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TEST 4: Create appointment (requires patientId and doctorId)
  Future<void> _testCreateAppointment() async {
    setState(() => _isLoading = true);
    try {
      _log('TEST 4: Creating appointment...');

      final doctorId = await _tokenService.getUserId();
      if (doctorId == null) {
        _log('❌ ERROR: No doctor ID found');
        setState(() => _isLoading = false);
        return;
      }

      // For testing, create with same ID or use a known patient ID
      final patientId = 'test-patient-id'; // CHANGE THIS to a real patient ID

      final appointment = await _appointmentService.createAppointment(
        patientId: patientId,
        doctorId: doctorId,
        dateTime: DateTime.now().add(const Duration(days: 1)),
        type: AppointmentType.ONLINE,
        notes: 'Test appointment from Flutter',
      );

      _log('✅ SUCCESS: Created appointment');
      _log('  ID: ${appointment.id}');
      _log('  Status: ${appointment.status.displayName}');
    } catch (e) {
      _log('❌ ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TEST 5: Get single appointment
  Future<void> _testGetSingleAppointment() async {
    setState(() => _isLoading = true);
    try {
      _log('TEST 5: Getting single appointment...');

      // First get a list to get an ID
      final doctorId = await _tokenService.getUserId();
      if (doctorId == null) {
        _log('❌ ERROR: No doctor ID found');
        setState(() => _isLoading = false);
        return;
      }

      final appointments = await _appointmentService.getDoctorAppointments(doctorId);
      if (appointments.isEmpty) {
        _log('❌ No appointments found to test');
        setState(() => _isLoading = false);
        return;
      }

      final appointmentId = appointments.first.id;
      final appointment = await _appointmentService.getAppointmentById(appointmentId);

      _log('✅ SUCCESS: Got appointment $appointmentId');
      _log('  Patient: ${appointment.patientName}');
      _log('  Status: ${appointment.status.displayName}');
    } catch (e) {
      _log('❌ ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TEST 6: Update appointment status
  Future<void> _testUpdateAppointment() async {
    setState(() => _isLoading = true);
    try {
      _log('TEST 6: Updating appointment status...');

      final doctorId = await _tokenService.getUserId();
      if (doctorId == null) {
        _log('❌ ERROR: No doctor ID found');
        setState(() => _isLoading = false);
        return;
      }

      // Get pending appointments
      final appointments = await _appointmentService.getDoctorAppointments(
        doctorId,
        status: AppointmentStatus.PENDING,
      );

      if (appointments.isEmpty) {
        _log('❌ No pending appointments to update');
        setState(() => _isLoading = false);
        return;
      }

      final appointmentId = appointments.first.id;
      final updated = await _appointmentService.updateAppointment(
        appointmentId,
        status: AppointmentStatus.CONFIRMED,
      );

      _log('✅ SUCCESS: Updated appointment');
      _log('  Status: ${updated.status.displayName}');
    } catch (e) {
      _log('❌ ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TEST 7: Confirm appointment (helper method)
  Future<void> _testConfirmAppointment() async {
    setState(() => _isLoading = true);
    try {
      _log('TEST 7: Confirming appointment...');

      final doctorId = await _tokenService.getUserId();
      if (doctorId == null) {
        _log('❌ ERROR: No doctor ID found');
        setState(() => _isLoading = false);
        return;
      }

      final appointments = await _appointmentService.getDoctorAppointments(
        doctorId,
        status: AppointmentStatus.PENDING,
      );

      if (appointments.isEmpty) {
        _log('❌ No pending appointments to confirm');
        setState(() => _isLoading = false);
        return;
      }

      final confirmed = await _appointmentService.confirmAppointment(appointments.first.id);
      _log('✅ SUCCESS: Confirmed appointment');
      _log('  Status: ${confirmed.status.displayName}');
    } catch (e) {
      _log('❌ ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TEST 8: Cancel appointment
  Future<void> _testCancelAppointment() async {
    setState(() => _isLoading = true);
    try {
      _log('TEST 8: Cancelling appointment...');

      final doctorId = await _tokenService.getUserId();
      if (doctorId == null) {
        _log('❌ ERROR: No doctor ID found');
        setState(() => _isLoading = false);
        return;
      }

      final appointments = await _appointmentService.getDoctorAppointments(doctorId);
      if (appointments.isEmpty) {
        _log('❌ No appointments to cancel');
        setState(() => _isLoading = false);
        return;
      }

      final cancelled = await _appointmentService.cancelAppointment(appointments.first.id);
      _log('✅ SUCCESS: Cancelled appointment');
      _log('  Status: ${cancelled.status.displayName}');
    } catch (e) {
      _log('❌ ERROR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment API Tests'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Test buttons
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 8,
                children: [
                  _TestButton(
                    label: '1️⃣ Get Doctor Appointments',
                    onPressed: _testGetDoctorAppointments,
                    isLoading: _isLoading,
                  ),
                  _TestButton(
                    label: '2️⃣ Get Upcoming Appointments',
                    onPressed: _testGetDoctorUpcomingAppointments,
                    isLoading: _isLoading,
                  ),
                  _TestButton(
                    label: '3️⃣ Get Doctor Statistics',
                    onPressed: _testGetDoctorStats,
                    isLoading: _isLoading,
                  ),
                  _TestButton(
                    label: '4️⃣ Create Appointment',
                    onPressed: _testCreateAppointment,
                    isLoading: _isLoading,
                  ),
                  _TestButton(
                    label: '5️⃣ Get Single Appointment',
                    onPressed: _testGetSingleAppointment,
                    isLoading: _isLoading,
                  ),
                  _TestButton(
                    label: '6️⃣ Update Appointment',
                    onPressed: _testUpdateAppointment,
                    isLoading: _isLoading,
                  ),
                  _TestButton(
                    label: '7️⃣ Confirm Appointment',
                    onPressed: _testConfirmAppointment,
                    isLoading: _isLoading,
                  ),
                  _TestButton(
                    label: '8️⃣ Cancel Appointment',
                    onPressed: _testCancelAppointment,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _clearLog,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Log'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Output log
          Container(
            height: 200,
            color: Colors.grey[900],
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Text(
                _testOutput,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Courier',
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _TestButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

