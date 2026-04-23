class PatientModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? photoProfil;
  final int? age;
  final String? sexe;
  final String? typeDiabete;
  final String? status; // stable, attention, critical
  final double? lastGlucoseReading;
  final String? lastReadingDate;
  final String? riskScore; // Low, Medium, High

  PatientModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.photoProfil,
    this.age,
    this.sexe,
    this.typeDiabete,
    this.status,
    this.lastGlucoseReading,
    this.lastReadingDate,
    this.riskScore,
  });

  String get fullName => '$prenom $nom';

  String get displayStatus {
    if (status == null) return 'Stable';
    return status![0].toUpperCase() + status!.substring(1);
  }

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'],
      photoProfil: json['photoProfil'],
      age: json['age'],
      sexe: json['sexe'],
      typeDiabete: json['typeDiabete'],
      status: json['status'],
      lastGlucoseReading: json['lastGlucoseReading']?.toDouble(),
      lastReadingDate: json['lastReadingDate'],
      riskScore: json['riskScore'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'photoProfil': photoProfil,
      'age': age,
      'sexe': sexe,
      'typeDiabete': typeDiabete,
      'status': status,
      'lastGlucoseReading': lastGlucoseReading,
      'lastReadingDate': lastReadingDate,
      'riskScore': riskScore,
    };
  }
}

class PatientListResponse {
  final List<PatientModel> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final StatusCounts statusCounts;

  PatientListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.statusCounts,
  });

  factory PatientListResponse.fromJson(Map<String, dynamic> json) {
    return PatientListResponse(
      data: (json['data'] as List)
          .map((patient) => PatientModel.fromJson(patient))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 0,
      statusCounts: StatusCounts.fromJson(json['statusCounts'] ?? {}),
    );
  }
}

class StatusCounts {
  final int stable;
  final int attention;
  final int critical;

  StatusCounts({
    required this.stable,
    required this.attention,
    required this.critical,
  });

  int get total => stable + attention + critical;

  factory StatusCounts.fromJson(Map<String, dynamic> json) {
    return StatusCounts(
      stable: json['stable'] ?? 0,
      attention: json['attention'] ?? 0,
      critical: json['critical'] ?? 0,
    );
  }
}

