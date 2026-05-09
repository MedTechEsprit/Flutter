// Example: How to use AppointmentService in your Flutter screens
// This file shows integration examples - you can adapt these to your existing screens

import 'package:flutter/material.dart';
import '../data/services/appointment_service.dart';
import '../data/models/appointment_model.dart';

// EXAMPLE 1: Create Appointment (from Patient or Doctor screen)
class CreateAppointmentExample extends StatefulWidget {
  final String patientId;
  final String doctorId;

  const CreateAppointmentExample({
    Key? key,
    required this.patientId,
    required this.doctorId,
  }) : super(key: key);

  @override
  State<CreateAppointmentExample> createState() => _CreateAppointmentExampleState();
}

class _CreateAppointmentExampleState extends State<CreateAppointmentExample> {
  final _appointmentService = AppointmentService();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  AppointmentType _selectedType = AppointmentType.PHYSICAL;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createAppointment() async {
    setState(() => _isLoading = true);

    try {
      final appointment = await _appointmentService.createAppointment(
        patientId: widget.patientId,
        doctorId: widget.doctorId,
        dateTime: _selectedDateTime,
        type: _selectedType,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, appointment); // Return the created appointment
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Date & Time Picker
            ListTile(
              title: const Text('Date & Time'),
              subtitle: Text(_selectedDateTime.toString()),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedDateTime = DateTime(
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
            ),

            // Type Selector
            const SizedBox(height: 20),
            SegmentedButton<AppointmentType>(
              segments: const [
                ButtonSegment(value: AppointmentType.PHYSICAL, label: Text('Physical'), icon: Icon(Icons.local_hospital)),
                ButtonSegment(value: AppointmentType.ONLINE, label: Text('Online'), icon: Icon(Icons.videocam)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<AppointmentType> selected) {
                setState(() => _selectedType = selected.first);
              },
            ),

            // Notes
            const SizedBox(height: 20),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const Spacer(),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAppointment,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// EXAMPLE 2: Get and Display Doctor's Appointments
class DoctorAppointmentsExample extends StatefulWidget {
  final String doctorId;

  const DoctorAppointmentsExample({Key? key, required this.doctorId}) : super(key: key);

  @override
  State<DoctorAppointmentsExample> createState() => _DoctorAppointmentsExampleState();
}

class _DoctorAppointmentsExampleState extends State<DoctorAppointmentsExample> {
  final _appointmentService = AppointmentService();
  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  AppointmentStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    try {
      final appointments = await _appointmentService.getDoctorAppointments(
        widget.doctorId,
        status: _filterStatus,
      );

      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? const Center(child: Text('No appointments found'))
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _appointments[index];
                      return _AppointmentCard(
                        appointment: appointment,
                        onTap: () => _showAppointmentDetails(appointment),
                        onStatusChange: (newStatus) => _updateStatus(appointment.id, newStatus),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create appointment screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Appointments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<AppointmentStatus?>(
              value: _filterStatus,
              hint: const Text('Select Status'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<AppointmentStatus?>(
                  value: null,
                  child: Text('All'),
                ),
                ...AppointmentStatus.values.map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                )),
              ],
              onChanged: (value) {
                setState(() => _filterStatus = value);
                Navigator.pop(context);
                _loadAppointments();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${appointment.patientName ?? 'Unknown'}'),
            Text('Date: ${appointment.formattedDateTime}'),
            Text('Type: ${appointment.type.displayName} ${appointment.typeIcon}'),
            Text('Status: ${appointment.status.displayName}'),
            if (appointment.notes != null) Text('Notes: ${appointment.notes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String appointmentId, AppointmentStatus newStatus) async {
    try {
      await _appointmentService.updateAppointment(appointmentId, status: newStatus);
      _loadAppointments(); // Reload list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${newStatus.displayName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// Appointment Card Widget
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  final Function(AppointmentStatus) onStatusChange;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    required this.onStatusChange,
  });

  Color _getStatusColor() {
    switch (appointment.status) {
      case AppointmentStatus.CONFIRMED:
        return Colors.green;
      case AppointmentStatus.PENDING:
        return Colors.orange;
      case AppointmentStatus.COMPLETED:
        return Colors.blue;
      case AppointmentStatus.CANCELLED:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    appointment.typeIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          appointment.formattedDateTime,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (appointment.notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  appointment.notes!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              if (appointment.status == AppointmentStatus.PENDING) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onStatusChange(AppointmentStatus.CONFIRMED),
                        child: const Text('Confirm'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onStatusChange(AppointmentStatus.CANCELLED),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// EXAMPLE 3: Quick integration in existing Doctor Dashboard
/*
In your existing lib/features/doctor/views/doctor_dashboard_screen.dart:

1. Import the service:
import 'package:diab_care/data/services/appointment_service.dart';
import 'package:diab_care/data/models/appointment_model.dart';

2. Add to your state:
final _appointmentService = AppointmentService();
List<AppointmentModel> _upcomingAppointments = [];

3. Load in initState or where appropriate:
void _loadUpcomingAppointments() async {
  try {
    final appointments = await _appointmentService.getDoctorUpcomingAppointments(doctorId);
    setState(() => _upcomingAppointments = appointments);
  } catch (e) {
    print('Error loading appointments: $e');
  }
}

4. Display in your UI:
ListView.builder(
  itemCount: _upcomingAppointments.length,
  itemBuilder: (context, index) {
    final apt = _upcomingAppointments[index];
    return ListTile(
      title: Text(apt.patientName ?? 'Unknown'),
      subtitle: Text(apt.formattedTime),
      trailing: Text(apt.status.displayName),
    );
  },
)
*/

