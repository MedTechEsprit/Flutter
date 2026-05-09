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
  final List<double>? patientCoordinates;
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
    this.patientCoordinates,
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
        patientCoordinates: _readPatientCoordinates(json['patientLocation']),
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

  double? get patientLatitude =>
      (patientCoordinates != null && patientCoordinates!.length >= 2)
      ? patientCoordinates![1]
      : null;

  double? get patientLongitude =>
      (patientCoordinates != null && patientCoordinates!.isNotEmpty)
      ? patientCoordinates![0]
      : null;

  static List<double>? _readPatientCoordinates(dynamic patientLocation) {
    if (patientLocation is Map<String, dynamic>) {
      final coords = patientLocation['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lng = (coords[0] as num?)?.toDouble();
        final lat = (coords[1] as num?)?.toDouble();
        if (lng != null && lat != null) {
          return [lng, lat];
        }
      }
    }
    return null;
  }
}

class PatientPharmacyResponse {
  final String pharmacyId;
  final String pharmacyName;
  final String status;
  final String pharmacyAddress;
  final double? distanceKm;
  final List<double>? pharmacyCoordinates;
  final double? indicativePrice;
  final String? pharmacyMessage;
  final DateTime? respondedAt;

  PatientPharmacyResponse({
    required this.pharmacyId,
    required this.pharmacyName,
    required this.status,
    required this.pharmacyAddress,
    this.distanceKm,
    this.pharmacyCoordinates,
    this.indicativePrice,
    this.pharmacyMessage,
    this.respondedAt,
  });

  factory PatientPharmacyResponse.fromJson(Map<String, dynamic> json) {
    final pharmacy = json['pharmacyId'];
    final pharmacyId = pharmacy is Map
        ? pharmacy['_id']?.toString() ?? ''
        : pharmacy?.toString() ?? '';
    final pharmacyName =
        json['pharmacyName']?.toString() ??
        (pharmacy is Map
            ? pharmacy['nomPharmacie']?.toString() ?? 'Pharmacie'
            : 'Pharmacie');
    final pharmacyAddress =
        json['pharmacyAddress']?.toString() ??
        (pharmacy is Map ? pharmacy['adressePharmacie']?.toString() ?? '' : '');

    List<double>? coords;
    final rawCoords = json['pharmacyCoordinates'];
    if (rawCoords is List && rawCoords.length >= 2) {
      final lng = (rawCoords[0] as num?)?.toDouble();
      final lat = (rawCoords[1] as num?)?.toDouble();
      if (lng != null && lat != null) {
        coords = [lng, lat];
      }
    }

    return PatientPharmacyResponse(
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      status: json['status']?.toString() ?? 'pending',
      pharmacyAddress: pharmacyAddress,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      pharmacyCoordinates: coords,
      indicativePrice: (json['indicativePrice'] as num?)?.toDouble(),
      pharmacyMessage: json['pharmacyMessage']?.toString(),
      respondedAt: json['respondedAt'] != null
          ? DateTime.tryParse(json['respondedAt'].toString())
          : null,
    );
  }

  double? get latitude =>
      (pharmacyCoordinates != null && pharmacyCoordinates!.length >= 2)
      ? pharmacyCoordinates![1]
      : null;

  double? get longitude =>
      (pharmacyCoordinates != null && pharmacyCoordinates!.isNotEmpty)
      ? pharmacyCoordinates![0]
      : null;
}
