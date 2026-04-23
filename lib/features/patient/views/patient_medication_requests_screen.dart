import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/models/medication_request_patient_model.dart';
import 'package:diab_care/data/services/medication_request_patient_service.dart';
import 'package:diab_care/data/services/rating_service.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';
import 'package:diab_care/features/patient/views/availability_result_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientMedicationRequestsScreen extends StatefulWidget {
  const PatientMedicationRequestsScreen({super.key});

  @override
  State<PatientMedicationRequestsScreen> createState() =>
      _PatientMedicationRequestsScreenState();
}

class _PatientMedicationRequestsScreenState
    extends State<PatientMedicationRequestsScreen> {
  final _service = MedicationRequestPatientService();
  final _ratingService = RatingService();
  final _tokenService = TokenService();
  bool _loading = true;
  String? _error;
  List<PatientMedicationRequest> _requests = [];
  final Set<String> _ratedKeys = {};
  final Map<String, bool> _ratingSubmitting = {};
  _RequestBucket _selectedBucket = _RequestBucket.inProgress;

  String _ratingKey(String requestId, String pharmacyId) {
    return '$requestId:$pharmacyId';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchMyRequests();
      final parsed = data
          .map((r) => PatientMedicationRequest.fromJson(r))
          .where((r) => r.globalStatus != 'closed')
          .toList();
      if (mounted) {
        setState(() {
          _requests = parsed;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _filteredRequests;
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          'Mes demandes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.softGreen),
            )
          : _error != null
          ? Center(
              child: Text(
                _error ?? 'Erreur',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            )
          : _requests.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aucune demande',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.softGreen,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  Row(
                    children: [
                      _StatusBadge(
                        label: 'En cours',
                        count: _bucketCount(_RequestBucket.inProgress),
                        selected: _selectedBucket == _RequestBucket.inProgress,
                        onTap: () => setState(
                          () => _selectedBucket = _RequestBucket.inProgress,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusBadge(
                        label: 'Traités',
                        count: _bucketCount(_RequestBucket.treated),
                        selected: _selectedBucket == _RequestBucket.treated,
                        onTap: () => setState(
                          () => _selectedBucket = _RequestBucket.treated,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusBadge(
                        label: 'Expirés',
                        count: _bucketCount(_RequestBucket.expired),
                        selected: _selectedBucket == _RequestBucket.expired,
                        onTap: () => setState(
                          () => _selectedBucket = _RequestBucket.expired,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filteredRequests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 56),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _emptyBucketMessage(_selectedBucket),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredRequests.map(
                      (request) => _RequestCard(
                        request: request,
                        isRated: _isRated,
                        isSubmitting: _isSubmittingRating,
                        onRate: (response) => _openRatingSheet(request, response),
                        onOpenMap: () => _openRequestMap(request),
                        onOpenItinerary: (response) =>
                            _openItinerary(request, response),
                        onCancel: request.globalStatus == 'open' &&
                                _selectedBucket == _RequestBucket.inProgress
                            ? () => _cancelRequest(request)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  List<PatientMedicationRequest> get _filteredRequests {
    return _requests.where((request) {
      return _bucketForRequest(request) == _selectedBucket;
    }).toList();
  }

  int _bucketCount(_RequestBucket bucket) {
    return _requests.where((request) => _bucketForRequest(request) == bucket).length;
  }

  _RequestBucket _bucketForRequest(PatientMedicationRequest request) {
    if (_isExpired(request)) {
      return _RequestBucket.expired;
    }

    if (_isTreated(request)) {
      return _RequestBucket.treated;
    }

    return _RequestBucket.inProgress;
  }

  bool _isExpired(PatientMedicationRequest request) {
    return request.globalStatus == 'expired' ||
        request.expiresAt.isBefore(DateTime.now());
  }

  bool _isTreated(PatientMedicationRequest request) {
    return request.globalStatus == 'closed' || request.hasResponse;
  }

  String _emptyBucketMessage(_RequestBucket bucket) {
    switch (bucket) {
      case _RequestBucket.inProgress:
        return 'Aucune demande en cours';
      case _RequestBucket.treated:
        return 'Aucune demande traitée';
      case _RequestBucket.expired:
        return 'Aucune demande expirée';
    }
  }

  bool _isRated(String requestId, String pharmacyId) {
    return _ratedKeys.contains(_ratingKey(requestId, pharmacyId));
  }

  bool _isSubmittingRating(String requestId, String pharmacyId) {
    return _ratingSubmitting[_ratingKey(requestId, pharmacyId)] == true;
  }

  Future<void> _openRequestMap(PatientMedicationRequest request) async {
    final mappable = request.responses
        .where((r) => r.latitude != null && r.longitude != null)
        .toList();

    if (mappable.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune pharmacie localisable pour cette demande.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final patientCoords = await _resolvePatientCoordinates(request);
    if (patientCoords == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position patient indisponible pour afficher la carte.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pharmacies = mappable
        .map(
          (r) => <String, dynamic>{
            'pharmacyId': r.pharmacyId,
            'pharmacyName': r.pharmacyName,
            'pharmacyAddress': r.pharmacyAddress,
            'status': r.status,
            'distanceKm': r.distanceKm,
            'pharmacyCoordinates': r.pharmacyCoordinates,
            'latitude': r.latitude,
            'longitude': r.longitude,
          },
        )
        .toList();

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvailabilityResultScreen(
          medicationName: request.medicationName,
          patientLatitude: patientCoords[0],
          patientLongitude: patientCoords[1],
          pharmacies: pharmacies,
        ),
      ),
    );
  }

  Future<void> _openItinerary(
    PatientMedicationRequest request,
    PatientPharmacyResponse response,
  ) async {
    if (response.latitude == null || response.longitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordonnees indisponibles pour cette pharmacie.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _showNavigationModal(
      pharmacyName: response.pharmacyName,
      latitude: response.latitude!,
      longitude: response.longitude!,
    );
  }

  Future<void> _showNavigationModal({
    required String pharmacyName,
    required double latitude,
    required double longitude,
  }) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Itineraire vers $pharmacyName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ouvrir la navigation dans Google Maps.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.map_rounded,
                    color: AppColors.softGreen,
                  ),
                  title: const Text('Ouvrir Google Maps'),
                  subtitle: const Text('Navigation externe sur le telephone'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _launchGoogleMaps(latitude, longitude);
                  },
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchGoogleMaps(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    final launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir Google Maps.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<double>?> _resolvePatientCoordinates(
    PatientMedicationRequest request,
  ) async {
    if (request.patientLatitude != null && request.patientLongitude != null) {
      return [request.patientLatitude!, request.patientLongitude!];
    }

    final userData = await _tokenService.getUserData();
    if (userData != null) {
      final lat = (userData['latitude'] as num?)?.toDouble();
      final lng = (userData['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return [lat, lng];
      }

      final location = userData['location'];
      if (location is Map<String, dynamic>) {
        final coords = location['coordinates'];
        if (coords is List && coords.length >= 2) {
          final xLng = (coords[0] as num?)?.toDouble();
          final xLat = (coords[1] as num?)?.toDouble();
          if (xLat != null && xLng != null) {
            return [xLat, xLng];
          }
        }
      }
    }

    return null;
  }

  Future<void> _cancelRequest(PatientMedicationRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la demande'),
        content: const Text(
          'Voulez-vous vraiment annuler cette demande ? Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Annuler la demande'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _service.cancelRequest(request.id);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Demande annulee avec succes.'),
          backgroundColor: AppColors.statusGood,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      await _load();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text((result['message'] ?? 'Erreur inconnue').toString()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _openRatingSheet(
    PatientMedicationRequest request,
    PatientPharmacyResponse response,
  ) async {
    final ratingKey = _ratingKey(request.id, response.pharmacyId);

    if (_isSubmittingRating(request.id, response.pharmacyId)) return;

    final commentController = TextEditingController();
    int stars = 5;
    bool medicationAvailable = response.status != 'unavailable';
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              Widget buildStars({
                required int value,
                required ValueChanged<int> onChanged,
              }) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final selected = index < value;
                    return IconButton(
                      onPressed: () => onChanged(index + 1),
                      icon: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: selected ? Colors.amber : Colors.grey.shade400,
                        size: 28,
                      ),
                    );
                  }),
                );
              }

              Future<void> submitRating() async {
                if (submitting) return;
                setSheetState(() => submitting = true);
                setState(() => _ratingSubmitting[ratingKey] = true);

                try {
                  await _ratingService.createRating(
                    pharmacyId: response.pharmacyId,
                    medicationRequestId: request.id,
                    stars: stars,
                    comment: commentController.text,
                    medicationAvailable: medicationAvailable,
                  );

                  if (!mounted) return;
                  setState(() => _ratedKeys.add(ratingKey));
                  Navigator.of(sheetContext).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Merci pour votre avis !'),
                      backgroundColor: AppColors.statusGood,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _ratingSubmitting[ratingKey] = false);
                  }
                  setSheetState(() => submitting = false);
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evaluer la pharmacie',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    response.pharmacyName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: buildStars(
                      value: stars,
                      onChanged: (v) => setSheetState(() => stars = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Medicament disponible',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Switch(
                        value: medicationAvailable,
                        activeColor: AppColors.softGreen,
                        onChanged: (v) =>
                            setSheetState(() => medicationAvailable = v),
                      ),
                    ],
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Laissez un commentaire (optionnel)',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Envoyer'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final PatientMedicationRequest request;
  final bool Function(String requestId, String pharmacyId) isRated;
  final bool Function(String requestId, String pharmacyId) isSubmitting;
  final void Function(PatientPharmacyResponse response) onRate;
  final VoidCallback onOpenMap;
  final void Function(PatientPharmacyResponse response) onOpenItinerary;
  final VoidCallback? onCancel;

  const _RequestCard({
    required this.request,
    required this.isRated,
    required this.isSubmitting,
    required this.onRate,
    required this.onOpenMap,
    required this.onOpenItinerary,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = request.isUrgent;
    final hasMappable = request.responses.any(
      (r) => r.latitude != null && r.longitude != null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.medicationName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (hasMappable)
                IconButton(
                  tooltip: 'Voir la carte',
                  onPressed: onOpenMap,
                  icon: const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: AppColors.softGreen,
                  ),
                ),
              if (urgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Qté: ${request.quantity}  •  ${request.dosage}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _expiryLabel(request.expiresAt),
            style: TextStyle(
              color: request.expiresAt.isAfter(DateTime.now())
                  ? AppColors.textSecondary
                  : Colors.orange.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _globalStatusColor(request.globalStatus).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _globalStatusLabel(request.globalStatus),
                  style: TextStyle(
                    color: _globalStatusColor(request.globalStatus),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (onCancel != null)
                TextButton.icon(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text(
                    'Annuler',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          if ((request.patientNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${request.patientNote}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...request.responses.map(
            (response) => _ResponseRow(
              response,
              showRate:
                  response.status == 'accepted' ||
                  response.status == 'unavailable',
              isRated: isRated(request.id, response.pharmacyId),
              isSubmitting: isSubmitting(request.id, response.pharmacyId),
              onRate: () => onRate(response),
              onOpenItinerary:
                  (response.latitude != null && response.longitude != null)
                      ? () => onOpenItinerary(response)
                      : null,
              onOpenDiscussion: () async {
                final chatVm = context.read<ChatViewModel>();
                final conv = await chatVm.startPharmacistConversation(
                  response.pharmacyId,
                );
                if (conv != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(conversation: conv),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _expiryLabel(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);

    if (diff.inSeconds <= 0) {
      return 'Expiree';
    }

    if (diff.inHours >= 1) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      return 'Expire dans ${hours}h ${minutes}m';
    }

    if (diff.inMinutes >= 1) {
      return 'Expire dans ${diff.inMinutes} min';
    }

    return 'Expire dans moins d\'1 min';
  }
}

class _ResponseRow extends StatelessWidget {
  final PatientPharmacyResponse response;
  final bool showRate;
  final bool isRated;
  final bool isSubmitting;
  final VoidCallback onRate;
  final VoidCallback onOpenDiscussion;
  final VoidCallback? onOpenItinerary;

  const _ResponseRow(
    this.response, {
    required this.showRate,
    required this.isRated,
    required this.isSubmitting,
    required this.onRate,
    required this.onOpenDiscussion,
    required this.onOpenItinerary,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(response.status);
    final statusColor = _statusColor(response.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${response.pharmacyName} • $statusLabel',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showRate)
            TextButton(
              onPressed: isRated || isSubmitting ? null : onRate,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.softGreen,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: Text(
                isRated ? 'Deja note' : 'Evaluer',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          if (response.status == 'accepted' && response.pharmacyId.isNotEmpty)
            IconButton(
              tooltip: 'Discussion',
              onPressed: onOpenDiscussion,
              icon: const Icon(
                Icons.forum_outlined,
                size: 18,
                color: AppColors.softGreen,
              ),
            ),
          if (onOpenItinerary != null)
            IconButton(
              tooltip: 'Itineraire',
              onPressed: onOpenItinerary,
              icon: const Icon(
                Icons.alt_route_rounded,
                size: 18,
                color: AppColors.softGreen,
              ),
            ),
          if (response.indicativePrice != null)
            Text(
              '${response.indicativePrice!.toStringAsFixed(0)} TND',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.softGreen,
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Acceptee';
      case 'declined':
        return 'Refusee';
      case 'unavailable':
        return 'Non disponible';
      case 'expired':
        return 'Expiree';
      case 'ignored':
        return 'Ignoree';
      default:
        return 'En attente';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
      case 'unavailable':
        return Colors.orange;
      case 'expired':
        return Colors.grey;
      case 'ignored':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }
}

String _globalStatusLabel(String status) {
  switch (status) {
    case 'closed':
      return 'Fermee';
    case 'expired':
      return 'Expiree';
    case 'cancelled':
      return 'Annulee';
    default:
      return 'En cours';
  }
}

enum _RequestBucket { inProgress, treated, expired }

class _StatusBadge extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _StatusBadge({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected ? AppColors.softGreen : Colors.white;
    final borderColor = selected ? AppColors.softGreen : Colors.grey.shade300;
    final textColor = selected ? Colors.white : AppColors.textSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: selected ? AppColors.cardShadow : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _globalStatusColor(String status) {
  switch (status) {
    case 'closed':
      return Colors.blueGrey;
    case 'expired':
      return Colors.orange;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.blue;
  }
}
