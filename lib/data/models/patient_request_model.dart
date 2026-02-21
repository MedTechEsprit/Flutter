// Patient Request Model for Flutter
// Location: lib/data/models/patient_request_model.dart

class PatientRequestModel {
  final String id;
  final PatientInfo patientId;
  final String doctorId;
  final String status; // pending, accepted, declined
  final String requestDate;
  final String? urgentNote;
  final String createdAt;
  final String updatedAt;

  PatientRequestModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.status,
    required this.requestDate,
    this.urgentNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientRequestModel.fromJson(Map<String, dynamic> json) {
    return PatientRequestModel(
      id: json['_id'] as String,
      patientId: PatientInfo.fromJson(json['patientId']),
      doctorId: json['doctorId'] as String,
      status: json['status'] as String,
      requestDate: json['requestDate'] as String,
      urgentNote: json['urgentNote'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'patientId': patientId.toJson(),
      'doctorId': doctorId,
      'status': status,
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
      id: json['_id'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String,
      telephone: json['telephone'] as String?,
      role: json['role'] as String,
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

