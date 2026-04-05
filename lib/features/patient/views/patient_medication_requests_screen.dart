import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/models/medication_request_patient_model.dart';
import 'package:diab_care/data/services/medication_request_patient_service.dart';
import 'package:diab_care/data/services/rating_service.dart';

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
  bool _loading = true;
  String? _error;
  List<PatientMedicationRequest> _requests = [];
  final Set<String> _ratedKeys = {};
  final Map<String, bool> _ratingSubmitting = {};

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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _requests.length,
                itemBuilder: (_, i) => _RequestCard(
                  request: _requests[i],
                  isRated: _isRated,
                  isSubmitting: _isSubmittingRating,
                  onRate: (response) => _openRatingSheet(
                    _requests[i],
                    response,
                  ),
                ),
              ),
            ),
    );
  }

  bool _isRated(String requestId, String pharmacyId) {
    return _ratedKeys.contains(_ratingKey(requestId, pharmacyId));
  }

  bool _isSubmittingRating(String requestId, String pharmacyId) {
    return _ratingSubmitting[_ratingKey(requestId, pharmacyId)] == true;
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
                        selected ? Icons.star_rounded : Icons.star_outline_rounded,
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
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
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
                        onChanged: (v) => setSheetState(() => medicationAvailable = v),
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

  const _RequestCard({
    required this.request,
    required this.isRated,
    required this.isSubmitting,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = request.isUrgent;

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
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if ((request.patientNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${request.patientNote}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...request.responses.map(
            (response) => _ResponseRow(
              response,
              showRate:
                  response.status == 'accepted' || response.status == 'unavailable',
              isRated: isRated(request.id, response.pharmacyId),
              isSubmitting: isSubmitting(request.id, response.pharmacyId),
              onRate: () => onRate(response),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseRow extends StatelessWidget {
  final PatientPharmacyResponse response;
  final bool showRate;
  final bool isRated;
  final bool isSubmitting;
  final VoidCallback onRate;

  const _ResponseRow(
    this.response, {
    required this.showRate,
    required this.isRated,
    required this.isSubmitting,
    required this.onRate,
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
                fontSize: 12,
                color: AppColors.textSecondary,
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
