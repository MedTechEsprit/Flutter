class PatientMedicationRequest {
  final String id;
  final String medicationName;
  final String dosage;
  final int quantity;
  final String format;
  final String urgencyLevel;
  final String? patientNote;
  final String globalStatus;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<PatientPharmacyResponse> responses;

  PatientMedicationRequest({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.quantity,
    required this.format,
    required this.urgencyLevel,
    this.patientNote,
    required this.globalStatus,
    required this.createdAt,
    required this.expiresAt,
    required this.responses,
  });

  factory PatientMedicationRequest.fromJson(Map<String, dynamic> json) {
    return PatientMedicationRequest(
      id: json['_id']?.toString() ?? '',
      medicationName: json['medicationName']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      format: json['format']?.toString() ?? '',
      urgencyLevel: json['urgencyLevel']?.toString() ?? 'normal',
      patientNote: json['patientNote']?.toString(),
      globalStatus: json['globalStatus']?.toString() ?? 'open',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.now(),
      responses:
          (json['pharmacyResponses'] as List?)
              ?.map(
                (r) => PatientPharmacyResponse.fromJson(
                  Map<String, dynamic>.from(r as Map),
                ),
              )
              .toList() ??
          [],
    );
  }

  bool get isUrgent =>
      urgencyLevel == 'urgent' || urgencyLevel == 'tres urgent';
  bool get hasResponse => responses.any((r) => r.status != 'pending');
}

class PatientPharmacyResponse {
  final String pharmacyId;
  final String pharmacyName;
  final String status;
  final double? indicativePrice;
  final String? pharmacyMessage;
  final DateTime? respondedAt;

  PatientPharmacyResponse({
    required this.pharmacyId,
    required this.pharmacyName,
    required this.status,
    this.indicativePrice,
    this.pharmacyMessage,
    this.respondedAt,
  });

  factory PatientPharmacyResponse.fromJson(Map<String, dynamic> json) {
    final pharmacy = json['pharmacyId'];
    final pharmacyId = pharmacy is Map
        ? pharmacy['_id']?.toString() ?? ''
        : pharmacy?.toString() ?? '';
    final pharmacyName = pharmacy is Map
        ? pharmacy['nomPharmacie']?.toString() ?? 'Pharmacie'
        : 'Pharmacie';

    return PatientPharmacyResponse(
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      status: json['status']?.toString() ?? 'pending',
      indicativePrice: (json['indicativePrice'] as num?)?.toDouble(),
      pharmacyMessage: json['pharmacyMessage']?.toString(),
      respondedAt: json['respondedAt'] != null
          ? DateTime.tryParse(json['respondedAt'].toString())
          : null,
    );
  }
}
