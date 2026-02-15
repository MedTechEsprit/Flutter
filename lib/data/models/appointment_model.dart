class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final DateTime dateTime;
  final String type; // 'Online', 'Physical'
  final String status; // 'Confirmed', 'Pending', 'Completed', 'Cancelled'
  final String? notes;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.dateTime,
    required this.type,
    required this.status,
    this.notes,
  });
}
