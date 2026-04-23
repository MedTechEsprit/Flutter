import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';
import 'package:diab_care/features/patient/views/availability_result_screen.dart';
import 'package:diab_care/features/patient/views/patient_medication_requests_screen.dart';
import 'package:diab_care/data/services/medication_request_patient_service.dart';

class FindPharmaciesScreen extends StatefulWidget {
  const FindPharmaciesScreen({super.key});

  @override
  State<FindPharmaciesScreen> createState() => _FindPharmaciesScreenState();
}

class _FindPharmaciesScreenState extends State<FindPharmaciesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  int _pendingResponses = 0;
  bool _loadingBadge = false;
  bool _requestSending = false;
  bool _resolvingLocation = false;
  static const double _searchRadiusKm = 25;
  static const Duration _requestCooldown = Duration(hours: 4);
  final _requestService = MedicationRequestPatientService();
  final _tokenService = TokenService();
  final List<_MedicationRequestInsight> _requestInsights = [];
  Timer? _requestPollingTimer;

  static const List<String> _categoryOrder = [
    'Tous',
    'Insulines',
    'Biguanides',
    'GLP-1 agonistes',
    'SGLT2 inhibiteurs',
    'DPP-4 inhibiteurs',
    'Sulfonylurees',
    'Autres',
  ];

  static const List<_DiabetesMedication> _catalog = [
    _DiabetesMedication(
      name: 'Insuline rapide (Lispro)',
      category: 'Insulines',
      kind: 'Rapide',
      dosageHint: '100 UI/mL',
    ),
    _DiabetesMedication(
      name: 'Insuline rapide (Aspart)',
      category: 'Insulines',
      kind: 'Rapide',
      dosageHint: '100 UI/mL',
    ),
    _DiabetesMedication(
      name: 'Insuline reguliere',
      category: 'Insulines',
      kind: 'Courte action',
      dosageHint: '100 UI/mL',
    ),
    _DiabetesMedication(
      name: 'Insuline NPH',
      category: 'Insulines',
      kind: 'Intermediaire',
      dosageHint: '100 UI/mL',
    ),
    _DiabetesMedication(
      name: 'Insuline glargine',
      category: 'Insulines',
      kind: 'Longue action',
      dosageHint: '100 UI/mL',
    ),
    _DiabetesMedication(
      name: 'Insuline detemir',
      category: 'Insulines',
      kind: 'Longue action',
      dosageHint: '100 UI/mL',
    ),
    _DiabetesMedication(
      name: 'Insuline degludec',
      category: 'Insulines',
      kind: 'Ultra-longue action',
      dosageHint: '100 UI/mL',
    ),
    _DiabetesMedication(
      name: 'Insuline premix 70/30',
      category: 'Insulines',
      kind: 'Premelangee',
      dosageHint: '100 UI/mL',
    ),
    _DiabetesMedication(
      name: 'Metformine',
      category: 'Biguanides',
      kind: '1ere ligne DT2',
      dosageHint: '500-1000 mg',
    ),
    _DiabetesMedication(
      name: 'Semaglutide',
      category: 'GLP-1 agonistes',
      kind: 'Injection orale/SC',
      dosageHint: '0.25-1 mg',
    ),
    _DiabetesMedication(
      name: 'Liraglutide',
      category: 'GLP-1 agonistes',
      kind: 'Injection SC',
      dosageHint: '0.6-1.8 mg',
    ),
    _DiabetesMedication(
      name: 'Dulaglutide',
      category: 'GLP-1 agonistes',
      kind: 'Injection hebdomadaire',
      dosageHint: '0.75-1.5 mg',
    ),
    _DiabetesMedication(
      name: 'Exenatide',
      category: 'GLP-1 agonistes',
      kind: 'Injection',
      dosageHint: '5-10 mcg',
    ),
    _DiabetesMedication(
      name: 'Lixisenatide',
      category: 'GLP-1 agonistes',
      kind: 'Injection',
      dosageHint: '10-20 mcg',
    ),
    _DiabetesMedication(
      name: 'Empagliflozine',
      category: 'SGLT2 inhibiteurs',
      kind: 'Oral',
      dosageHint: '10-25 mg',
    ),
    _DiabetesMedication(
      name: 'Dapagliflozine',
      category: 'SGLT2 inhibiteurs',
      kind: 'Oral',
      dosageHint: '5-10 mg',
    ),
    _DiabetesMedication(
      name: 'Canagliflozine',
      category: 'SGLT2 inhibiteurs',
      kind: 'Oral',
      dosageHint: '100-300 mg',
    ),
    _DiabetesMedication(
      name: 'Ertugliflozine',
      category: 'SGLT2 inhibiteurs',
      kind: 'Oral',
      dosageHint: '5-15 mg',
    ),
    _DiabetesMedication(
      name: 'Sitagliptine',
      category: 'DPP-4 inhibiteurs',
      kind: 'Oral',
      dosageHint: '100 mg',
    ),
    _DiabetesMedication(
      name: 'Vildagliptine',
      category: 'DPP-4 inhibiteurs',
      kind: 'Oral',
      dosageHint: '50 mg',
    ),
    _DiabetesMedication(
      name: 'Linagliptine',
      category: 'DPP-4 inhibiteurs',
      kind: 'Oral',
      dosageHint: '5 mg',
    ),
    _DiabetesMedication(
      name: 'Saxagliptine',
      category: 'DPP-4 inhibiteurs',
      kind: 'Oral',
      dosageHint: '2.5-5 mg',
    ),
    _DiabetesMedication(
      name: 'Alogliptine',
      category: 'DPP-4 inhibiteurs',
      kind: 'Oral',
      dosageHint: '25 mg',
    ),
    _DiabetesMedication(
      name: 'Gliclazide',
      category: 'Sulfonylurees',
      kind: 'Oral',
      dosageHint: '30-120 mg',
    ),
    _DiabetesMedication(
      name: 'Glimepiride',
      category: 'Sulfonylurees',
      kind: 'Oral',
      dosageHint: '1-4 mg',
    ),
    _DiabetesMedication(
      name: 'Glibenclamide',
      category: 'Sulfonylurees',
      kind: 'Oral',
      dosageHint: '2.5-10 mg',
    ),
    _DiabetesMedication(
      name: 'Repaglinide',
      category: 'Autres',
      kind: 'Meglitinide',
      dosageHint: '0.5-2 mg',
    ),
    _DiabetesMedication(
      name: 'Pioglitazone',
      category: 'Autres',
      kind: 'Thiazolidinedione',
      dosageHint: '15-45 mg',
    ),
    _DiabetesMedication(
      name: 'Acarbose',
      category: 'Autres',
      kind: 'Alpha-glucosidase',
      dosageHint: '50-100 mg',
    ),
    _DiabetesMedication(
      name: 'Pramlintide',
      category: 'Autres',
      kind: 'Analogue amylinique',
      dosageHint: '15-60 mcg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _refreshRequests();
    _requestPollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _refreshRequests();
    });
  }

  @override
  void dispose() {
    _requestPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshRequests() async {
    if (_loadingBadge) return;
    _loadingBadge = true;
    try {
      final data = await _requestService.fetchMyRequests();

      int pending = 0;
      final nextInsights = <_MedicationRequestInsight>[];
      for (final request in data) {
        final globalStatus = request['globalStatus']?.toString().toLowerCase();
        if (globalStatus == 'closed') {
          continue;
        }

        final requestId = request['_id']?.toString() ?? '';
        final medicationName = request['medicationName']?.toString() ?? '';
        final createdAt = _parseDate(request['createdAt']) ?? DateTime.now();
        final responses = request['pharmacyResponses'] as List? ?? [];

        DateTime? firstResponseAt;
        bool hasAcceptedResponse = false;

        for (final response in responses) {
          final status = response is Map
              ? (response['status']?.toString().toLowerCase() ?? '')
              : '';
          if (status == 'pending') pending++;
          if (status == 'accepted' || status == 'available') {
            hasAcceptedResponse = true;
          }

          final map = response is Map<String, dynamic>
              ? response
              : <String, dynamic>{};
          final respondedAt =
              _parseDate(map['respondedAt']) ??
              _parseDate(map['updatedAt']) ??
              _parseDate(map['createdAt']);

          if (status.isNotEmpty && status != 'pending' && respondedAt != null) {
            if (firstResponseAt == null ||
                respondedAt.isBefore(firstResponseAt)) {
              firstResponseAt = respondedAt;
            }
          }
        }

        if (requestId.isNotEmpty && medicationName.isNotEmpty) {
          nextInsights.add(
            _MedicationRequestInsight(
              requestId: requestId,
              medicationName: medicationName,
              createdAt: createdAt,
              firstResponseAt: firstResponseAt,
              hasAcceptedResponse: hasAcceptedResponse,
            ),
          );
        }
      }

      nextInsights.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _pendingResponses = pending;
          _requestInsights
            ..clear()
            ..addAll(nextInsights);
        });
      }
    } catch (_) {
      // Ignore badge load failures
    } finally {
      _loadingBadge = false;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  List<_DiabetesMedication> get _filteredMedications {
    return _catalog.where((m) {
      final byCategory =
          _selectedCategory == 'Tous' || m.category == _selectedCategory;
      if (!byCategory) return false;

      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.kind.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openRequestAvailability(_DiabetesMedication medication) async {
    if (_requestSending) return;

    if (mounted) {
      setState(() => _resolvingLocation = true);
    }

    final userPosition = await _resolvePatientPosition();

    if (mounted) {
      setState(() => _resolvingLocation = false);
    }

    if (userPosition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de recuperer votre position. Activez la localisation ou enregistrez une position dans votre profil.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nearby = await _requestService.fetchNearbyPharmacies(
      latitude: userPosition.latitude,
      longitude: userPosition.longitude,
      radiusKm: _searchRadiusKm,
    );

    final pharmacyOptions = nearby.map((p) {
      final distanceRaw = p['distance'];
      final distance = distanceRaw is num ? distanceRaw.toDouble() : null;
      return _PharmacyDistanceOption(
        id: p['_id']?.toString() ?? '',
        name: p['nomPharmacie']?.toString() ?? 'Pharmacie',
        address: p['adressePharmacie']?.toString() ?? '',
        distanceKm: distance,
      );
    }).where((o) => o.id.isNotEmpty).toList();

    pharmacyOptions.sort((a, b) {
      final aDist = a.distanceKm ?? double.infinity;
      final bDist = b.distanceKm ?? double.infinity;
      return aDist.compareTo(bDist);
    });

    if (pharmacyOptions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucune pharmacie trouvee a proximite (rayon 25 km).',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int quantity = 1;
    final selectedPharmacyIds = pharmacyOptions
      .map((o) => o.id)
      .where((id) => id.isNotEmpty)
      .toSet();
    String? formError;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
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
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Demande de disponibilite',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medication.name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Quantite',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              if (quantity > 1) {
                                setModalState(() => quantity--);
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setModalState(() => quantity++);
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pharmacies proches (ordre: plus proche -> plus loin)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Votre demande sera envoyee uniquement aux pharmacies dans un rayon de 15 km autour de votre position.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Builder(
                        builder: (context) {
                          final visibleOptions = pharmacyOptions;

                          if (visibleOptions.isEmpty) {
                            return const Center(
                              child: Text(
                                'Aucune pharmacie dans ce rayon.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: visibleOptions.length,
                            itemBuilder: (context, index) {
                              final option = visibleOptions[index];
                              final subtitle = option.distanceKm != null
                                  ? '${option.address} • ${option.distanceKm!.toStringAsFixed(1)} km'
                                  : option.address;

                              return CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: selectedPharmacyIds.contains(option.id),
                                activeColor: AppColors.softGreen,
                                title: Text(option.name),
                                subtitle: Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      selectedPharmacyIds.add(option.id);
                                    } else {
                                      selectedPharmacyIds.remove(option.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (formError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          formError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedPharmacyIds.isEmpty) {
                            setModalState(() {
                              formError =
                                  'Veuillez choisir au moins une pharmacie.';
                            });
                            return;
                          }
                          Navigator.pop(ctx, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.softGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Valider et envoyer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() => _requestSending = true);
    }

    // Send patient coordinates so backend can enforce proximity filtering.
    final result = await _requestService.createMedicationRequest(
      medicationName: medication.name,
      dosage: medication.dosageHint,
      quantity: quantity,
      format: medication.kind,
      urgencyLevel: 'normal',
      targetPharmacyIds: selectedPharmacyIds.toList(),
      patientLatitude: userPosition.latitude,
      patientLongitude: userPosition.longitude,
      radiusKm: _searchRadiusKm,
    );

    if (mounted) {
      setState(() => _requestSending = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Demande envoyee avec succes.'
              : (result['message']?.toString() ?? 'Echec de l\'envoi.'),
        ),
        backgroundColor: result['success'] == true
            ? AppColors.softGreen
            : Colors.red,
      ),
    );

    if (result['success'] == true) {
      await _refreshRequests();

      final contactedRaw = result['contactedPharmacies'];
      final contacted = contactedRaw is List
          ? contactedRaw.cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AvailabilityResultScreen(
              medicationName: medication.name,
              patientLatitude: userPosition.latitude,
              patientLongitude: userPosition.longitude,
              pharmacies: contacted,
            ),
          ),
        );
      }
    }
  }

  String _formatElapsed(DateTime from, [DateTime? to]) {
    final end = to ?? DateTime.now();
    final d = end.difference(from);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _formatRemaining(Duration value) {
    var remaining = value;
    if (remaining.isNegative) remaining = Duration.zero;
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  Future<_ResolvedCoordinates?> _resolvePatientPosition() async {
    final storedFirst = await _tryGetStoredPosition();
    if (storedFirst != null) {
      return storedFirst;
    }

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return await _tryGetStoredPosition();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return await _tryGetStoredPosition();
      }

      try {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 8));
        return _ResolvedCoordinates(
          latitude: current.latitude,
          longitude: current.longitude,
        );
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return _ResolvedCoordinates(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
          );
        }
        return await _tryGetStoredPosition();
      }
    } catch (_) {
      return await _tryGetStoredPosition();
    }
  }

  Future<_ResolvedCoordinates?> _tryGetStoredPosition() async {
    try {
      final userData = await _tokenService.getUserData();
      if (userData == null) return null;

      final latitude = _readLatitude(userData);
      final longitude = _readLongitude(userData);
      if (latitude != null && longitude != null) {
        return _ResolvedCoordinates(latitude: latitude, longitude: longitude);
      }

      final location = userData['location'];
      if (location is Map<String, dynamic>) {
        final coordinates = location['coordinates'];
        if (coordinates is List && coordinates.length >= 2) {
          final lng = (coordinates[0] as num?)?.toDouble();
          final lat = (coordinates[1] as num?)?.toDouble();
          if (lat != null && lng != null) {
            return _ResolvedCoordinates(latitude: lat, longitude: lng);
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  double? _readLatitude(Map<String, dynamic> userData) {
    final latitude = userData['latitude'];
    if (latitude is num) return latitude.toDouble();
    return null;
  }

  double? _readLongitude(Map<String, dynamic> userData) {
    final longitude = userData['longitude'];
    if (longitude is num) return longitude.toDouble();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final medications = _filteredMedications;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          if (_resolvingLocation)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.greenGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pharmacies',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Catalogue des medicaments lies au diabete',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            filled: false,
                            fillColor: Colors.transparent,
                            icon: Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.75),
                            ),
                            hintText: 'Rechercher un medicament...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundPrimary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: SizedBox(
                        height: 74,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _QuickBtn(
                              icon: Icons.medication_outlined,
                              label: 'Mes Demandes',
                              badge: _pendingResponses,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PatientMedicationRequestsScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _QuickBtn(
                              icon: Icons.chat_bubble_outline,
                              label: 'Messages',
                              badge: context
                                  .watch<ChatViewModel>()
                                  .pharmacyUnreadCount,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ConversationListScreen(
                                    isDoctor: false,
                                    pharmacistOnly: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: _categoryOrder.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final c = _categoryOrder[index];
                          final selected = c == _selectedCategory;
                          return ChoiceChip(
                            label: Text(c),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = c),
                            selectedColor: AppColors.softGreen,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.softGreen
                                  : AppColors.border,
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            sliver: medications.isEmpty
                ? SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: const Center(
                        child: Text(
                          'Aucun medicament trouve',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MedicationCard(
                          medication: medications[index],
                          insight: _requestInsights
                              .where(
                                (r) =>
                                    r.medicationName.toLowerCase() ==
                                    medications[index].name.toLowerCase(),
                              )
                              .cast<_MedicationRequestInsight?>()
                              .firstWhere((e) => e != null, orElse: () => null),
                          onRequest: () =>
                              _openRequestAvailability(medications[index]),
                          requestSending: _requestSending,
                          formatElapsed: _formatElapsed,
                          formatRemaining: _formatRemaining,
                          cooldownDuration: _requestCooldown,
                        ),
                      ),
                      childCount: medications.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedCoordinates {
  final double latitude;
  final double longitude;

  const _ResolvedCoordinates({
    required this.latitude,
    required this.longitude,
  });
}

class _MedicationCard extends StatelessWidget {
  final _DiabetesMedication medication;
  final _MedicationRequestInsight? insight;
  final VoidCallback onRequest;
  final bool requestSending;
  final String Function(DateTime, [DateTime?]) formatElapsed;
  final String Function(Duration) formatRemaining;
  final Duration cooldownDuration;

  const _MedicationCard({
    required this.medication,
    required this.insight,
    required this.onRequest,
    required this.requestSending,
    required this.formatElapsed,
    required this.formatRemaining,
    required this.cooldownDuration,
  });

  @override
  Widget build(BuildContext context) {
    final hasFirstResponse = insight?.firstResponseAt != null;
    final hasAccepted = insight?.hasAcceptedResponse ?? false;
    final now = DateTime.now();
    Duration? remaining;
    bool cooldownActive = false;

    if (insight != null) {
      final elapsed = now.isAfter(insight!.createdAt)
          ? now.difference(insight!.createdAt)
          : Duration.zero;
      remaining = cooldownDuration - elapsed;
      if (remaining.isNegative) remaining = Duration.zero;
      cooldownActive = !hasAccepted && remaining > Duration.zero;
    }

    final int cooldownHours = cooldownDuration.inHours;
    final String statusText;
    if (insight == null) {
      statusText = 'Aucune demande envoyee pour ce medicament.';
    } else if (hasAccepted) {
      statusText = 'Une pharmacie a accepte. Bouton actif.';
    } else if (cooldownActive) {
      final remainingLabel = formatRemaining(remaining!);
      if (hasFirstResponse) {
        statusText =
            'Premiere reponse en ${formatElapsed(insight!.createdAt, insight!.firstResponseAt)}. Bouton inactif (reactivable dans $remainingLabel).';
      } else {
        statusText =
            'En attente de reponse. Bouton inactif (reactivable dans $remainingLabel).';
      }
    } else {
      if (hasFirstResponse) {
        statusText =
            'Premiere reponse en ${formatElapsed(insight!.createdAt, insight!.firstResponseAt)}. Bouton actif.';
      } else {
        statusText =
            'Demande expiree (${cooldownHours}h). Bouton actif.';
      }
    }

    final IconData statusIcon;
    final Color statusColor;
    final Color statusBackground;
    if (insight == null) {
      statusIcon = Icons.info_outline;
      statusColor = AppColors.textSecondary;
      statusBackground = AppColors.border.withOpacity(0.35);
    } else if (hasAccepted) {
      statusIcon = Icons.check_circle_rounded;
      statusColor = AppColors.statusGood;
      statusBackground = AppColors.statusGood.withOpacity(0.08);
    } else if (cooldownActive) {
      statusIcon = Icons.timer_rounded;
      statusColor = AppColors.warmPeach;
      statusBackground = AppColors.warmPeach.withOpacity(0.1);
    } else {
      statusIcon = Icons.timer_off_rounded;
      statusColor = AppColors.textSecondary;
      statusBackground = AppColors.border.withOpacity(0.35);
    }

    final bool buttonDisabled = requestSending || cooldownActive;
    final String buttonLabel = requestSending
        ? 'Sending...'
        : cooldownActive
            ? 'Reactivable dans ${formatRemaining(remaining!)}'
            : 'Request Availability';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.elevatedShadow,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: AppColors.softGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medication.category} • ${medication.kind}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  medication.dosageHint,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.softGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: buttonDisabled ? null : onRequest,
                  icon: requestSending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          cooldownActive
                              ? Icons.lock_outline
                              : Icons.mark_email_read_outlined,
                          size: 16,
                        ),
                  label: Text(buttonLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.softGreen
                        .withOpacity(0.45),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiabetesMedication {
  final String name;
  final String category;
  final String kind;
  final String dosageHint;

  const _DiabetesMedication({
    required this.name,
    required this.category,
    required this.kind,
    required this.dosageHint,
  });
}

class _MedicationRequestInsight {
  final String requestId;
  final String medicationName;
  final DateTime createdAt;
  final DateTime? firstResponseAt;
  final bool hasAcceptedResponse;

  const _MedicationRequestInsight({
    required this.requestId,
    required this.medicationName,
    required this.createdAt,
    required this.firstResponseAt,
    required this.hasAcceptedResponse,
  });
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;
  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.cardShadow,
            border: Border.all(color: AppColors.border.withOpacity(0.8)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.softGreen, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if ((badge ?? 0) > 0)
                Positioned(
                  right: -2,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PharmacyDistanceOption {
  final String id;
  final String name;
  final String address;
  final double? distanceKm;

  const _PharmacyDistanceOption({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
  });
}
