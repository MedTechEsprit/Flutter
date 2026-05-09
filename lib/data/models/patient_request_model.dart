// Patient Request Model for Flutter
// Location: lib/data/models/patient_request_model.dart

class PatientRequestModel {
  final String id;
  final PatientInfo patientId;
  final String doctorId;
  final String status; // pending, accepted, declined
  final String requestType; // patient_link, access_renewal
  final String requestDate;
  final String? urgentNote;
  final String createdAt;
  final String updatedAt;

  PatientRequestModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.status,
    this.requestType = 'patient_link',
    required this.requestDate,
    this.urgentNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientRequestModel.fromJson(Map<String, dynamic> json) {
    final patientRaw = json['patientId'];
    final patient = patientRaw is Map<String, dynamic>
        ? PatientInfo.fromJson(patientRaw)
        : PatientInfo(
            id: patientRaw?.toString() ?? '',
            nom: '',
            prenom: '',
            email: '',
            role: '',
          );

    return PatientRequestModel(
      id: json['_id']?.toString() ?? '',
      patientId: patient,
      doctorId: json['doctorId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      requestType: json['requestType']?.toString() ?? 'patient_link',
      requestDate: json['requestDate']?.toString() ?? DateTime.now().toIso8601String(),
      urgentNote: json['urgentNote'] as String?,
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'patientId': patientId.toJson(),
      'doctorId': doctorId,
      'status': status,
      'requestType': requestType,
      'requestDate': requestDate,
      'urgentNote': urgentNote,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Helper getters
  DateTime get requestDateTime => DateTime.parse(requestDate);
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
}

class PatientInfo {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String role;

  PatientInfo({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    required this.role,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      id: json['_id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telephone: json['telephone'] as String?,
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role': role,
    };
  }

  String get fullName => '$prenom $nom';
}

