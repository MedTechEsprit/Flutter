import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';

/// Multi-step medical profile form shown after registration (and editable later).
/// All fields are optional – patient can skip or fill partially.
class MedicalProfileFormScreen extends StatefulWidget {
  /// When true, show "Passer" (skip) button. False when editing from profile.
  final bool isPostRegistration;

  const MedicalProfileFormScreen({super.key, this.isPostRegistration = true});

  @override
  State<MedicalProfileFormScreen> createState() =>
      _MedicalProfileFormScreenState();
}

class _MedicalProfileFormScreenState extends State<MedicalProfileFormScreen> {
  final _tokenService = TokenService();
  int _currentStep = 0;
  bool _isSaving = false;

  // ── Step 1: Informations personnelles ──────────────────────────
  final _tailleController = TextEditingController();
  final _poidsController = TextEditingController();
  String? _groupeSanguin;
  final _contactUrgenceController = TextEditingController();

  // ── Step 2: Diabète ────────────────────────────────────────────
  String? _typeDiabete;
  DateTime? _dateDiagnostic;
  final _glycemieAJeunController = TextEditingController();
  final _hba1cController = TextEditingController();
  String? _frequenceMesure;

  // ── Step 3: Traitement ─────────────────────────────────────────
  bool _prendInsuline = false;
  final _typeInsulineController = TextEditingController();
  final _doseInsulineController = TextEditingController();
  final _frequenceInjectionController = TextEditingController();
  bool _utiliseCapteur = false;
  final List<String> _traitements = [];

  // ── Step 4: Antécédents & Complications ────────────────────────
  bool _antecedentsFamiliaux = false;
  bool _hypertension = false;
  bool _maladiesCardio = false;
  bool _problemesRenaux = false;
  bool _problemesOculaires = false;
  bool _neuropathie = false;
  bool _piedDiabetique = false;
  bool _ulceres = false;
  bool _hypoglycemiesFreq = false;
  bool _hyperglycemiesFreq = false;
  bool _hospitalisationsRecentes = false;

  // ── Step 5: Mode de vie & Allergies ────────────────────────────
  String? _niveauActivite;
  String? _habitudesAlimentaires;
  String? _tabac;
  final _allergiesController = TextEditingController();
  final _maladiesChroniquesController = TextEditingController();

  static const _groupesSanguins = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  static const _typesDiabete = [
    {'label': 'Type 1', 'value': 'TYPE_1'},
    {'label': 'Type 2', 'value': 'TYPE_2'},
    {'label': 'Gestationnel', 'value': 'GESTATIONNEL'},
    {'label': 'Pré-diabète', 'value': 'PRE_DIABETE'},
    {'label': 'Autre', 'value': 'AUTRE'},
  ];
  static const _frequencesMesure = [
    'Plusieurs fois par jour',
    '1 fois par jour',
    'Quelques fois par semaine',
    'Rarement',
  ];
  static const _niveauxActivite = ['Sédentaire', 'Faible', 'Modérée', 'Élevée'];
  static const _habitudes = [
    'Régime équilibré',
    'Riche en sucre',
    'Riche en gras',
    'Régime spécial diabétique',
    'Autre',
  ];
  static const _tabacOptions = ['Non', 'Oui', 'Ancien fumeur'];
  static const _traitementOptions = [
    'Insuline',
    'Antidiabétiques oraux',
    'Régime alimentaire',
    'Activité physique',
    'Autre traitement',
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.isPostRegistration) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    final userId = await _tokenService.getUserId();
    final token = await _tokenService.getToken();
    if (userId == null || token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/patients/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Medical data lives inside profilMedical sub-document
        final med = (data['profilMedical'] as Map<String, dynamic>?) ?? {};
        setState(() {
          _tailleController.text = (med['taille'] ?? '').toString();
          if (_tailleController.text == 'null') _tailleController.clear();
          _poidsController.text = (med['poids'] ?? '').toString();
          if (_poidsController.text == 'null') _poidsController.clear();
          _groupeSanguin = data['groupeSanguin'];
          _contactUrgenceController.text = med['contactUrgence'] ?? '';

          _typeDiabete = data['typeDiabete'];
          if (med['dateDiagnostic'] != null) {
            _dateDiagnostic = DateTime.tryParse(
              med['dateDiagnostic'].toString(),
            );
          }
          _glycemieAJeunController.text = (med['glycemieAJeunMoyenne'] ?? '')
              .toString();
          if (_glycemieAJeunController.text == '0' ||
              _glycemieAJeunController.text == 'null')
            _glycemieAJeunController.clear();
          _hba1cController.text = (med['dernierHba1c'] ?? '').toString();
          if (_hba1cController.text == '0' || _hba1cController.text == 'null')
            _hba1cController.clear();
          _frequenceMesure = med['frequenceMesureGlycemie'];

          _prendInsuline = med['prendInsuline'] == true;
          _typeInsulineController.text = med['typeInsuline'] ?? '';
          _doseInsulineController.text = (med['doseQuotidienneInsuline'] ?? '')
              .toString();
          if (_doseInsulineController.text == '0' ||
              _doseInsulineController.text == 'null')
            _doseInsulineController.clear();
          _frequenceInjectionController.text = (med['frequenceInjection'] ?? '')
              .toString();
          if (_frequenceInjectionController.text == '0' ||
              _frequenceInjectionController.text == 'null')
            _frequenceInjectionController.clear();
          _utiliseCapteur = med['utiliseCapteurGlucose'] == true;
          if (med['traitements'] is List)
            _traitements.addAll(List<String>.from(med['traitements']));

          _antecedentsFamiliaux = med['antecedentsFamiliauxDiabete'] == true;
          _hypertension = med['hypertension'] == true;
          _maladiesCardio = med['maladiesCardiovasculaires'] == true;
          _problemesRenaux = med['problemesRenaux'] == true;
          _problemesOculaires = med['problemesOculaires'] == true;
          _neuropathie = med['neuropathieDiabetique'] == true;
          _piedDiabetique = med['piedDiabetique'] == true;
          _ulceres = med['ulceres'] == true;
          _hypoglycemiesFreq = med['hypoglycemiesFrequentes'] == true;
          _hyperglycemiesFreq = med['hyperglycemiesFrequentes'] == true;
          _hospitalisationsRecentes = med['hospitalisationsRecentes'] == true;

          _niveauActivite = med['niveauActivitePhysique'];
          _habitudesAlimentaires = med['habitudesAlimentaires'];
          _tabac = med['tabac'];
          if (med['allergies'] is List &&
              (med['allergies'] as List).isNotEmpty) {
            _allergiesController.text = (med['allergies'] as List).join(', ');
          }
          if (med['maladiesChroniques'] is List &&
              (med['maladiesChroniques'] as List).isNotEmpty) {
            _maladiesChroniquesController.text =
                (med['maladiesChroniques'] as List).join(', ');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Load medical data: $e');
    }
  }

  @override
  void dispose() {
    _tailleController.dispose();
    _poidsController.dispose();
    _contactUrgenceController.dispose();
    _glycemieAJeunController.dispose();
    _hba1cController.dispose();
    _typeInsulineController.dispose();
    _doseInsulineController.dispose();
    _frequenceInjectionController.dispose();
    _allergiesController.dispose();
    _maladiesChroniquesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final medicalData = <String, dynamic>{};
    final rootPayload = <String, dynamic>{};

    // ── Root-level Patient fields (edit mode only) ───────────────
    if (!widget.isPostRegistration) {
      if (_typeDiabete != null) rootPayload['typeDiabete'] = _typeDiabete;
      if (_groupeSanguin != null) rootPayload['groupeSanguin'] = _groupeSanguin;
    }

    // ── Sub-document: profilMedical ──────────────────────────────
    // Personal
    final taille = double.tryParse(_tailleController.text);
    final poids = double.tryParse(_poidsController.text);
    if (taille != null) medicalData['taille'] = taille;
    if (poids != null) medicalData['poids'] = poids;
    if (_contactUrgenceController.text.isNotEmpty)
      medicalData['contactUrgence'] = _contactUrgenceController.text.trim();

    // Diabetes details
    if (_dateDiagnostic != null)
      medicalData['dateDiagnostic'] = _dateDiagnostic!.toIso8601String();
    final glycemie = double.tryParse(_glycemieAJeunController.text);
    if (glycemie != null) medicalData['glycemieAJeunMoyenne'] = glycemie;
    final hba1c = double.tryParse(_hba1cController.text);
    if (hba1c != null) medicalData['dernierHba1c'] = hba1c;
    if (_frequenceMesure != null)
      medicalData['frequenceMesureGlycemie'] = _frequenceMesure;

    // Treatment
    medicalData['prendInsuline'] = _prendInsuline;
    if (_prendInsuline) {
      if (_typeInsulineController.text.isNotEmpty)
        medicalData['typeInsuline'] = _typeInsulineController.text.trim();
      final dose = double.tryParse(_doseInsulineController.text);
      if (dose != null) medicalData['doseQuotidienneInsuline'] = dose;
      final freq = int.tryParse(_frequenceInjectionController.text);
      if (freq != null) medicalData['frequenceInjection'] = freq;
    }
    medicalData['utiliseCapteurGlucose'] = _utiliseCapteur;
    if (_traitements.isNotEmpty) medicalData['traitements'] = _traitements;

    // Medical history
    medicalData['antecedentsFamiliauxDiabete'] = _antecedentsFamiliaux;
    medicalData['hypertension'] = _hypertension;
    medicalData['maladiesCardiovasculaires'] = _maladiesCardio;
    medicalData['problemesRenaux'] = _problemesRenaux;
    medicalData['problemesOculaires'] = _problemesOculaires;
    medicalData['neuropathieDiabetique'] = _neuropathie;

    // Complications
    medicalData['piedDiabetique'] = _piedDiabetique;
    medicalData['ulceres'] = _ulceres;
    medicalData['hypoglycemiesFrequentes'] = _hypoglycemiesFreq;
    medicalData['hyperglycemiesFrequentes'] = _hyperglycemiesFreq;
    medicalData['hospitalisationsRecentes'] = _hospitalisationsRecentes;

    // Lifestyle
    if (_niveauActivite != null)
      medicalData['niveauActivitePhysique'] = _niveauActivite;
    if (_habitudesAlimentaires != null)
      medicalData['habitudesAlimentaires'] = _habitudesAlimentaires;
    if (_tabac != null) medicalData['tabac'] = _tabac;

    // Allergies
    if (_allergiesController.text.isNotEmpty) {
      medicalData['allergies'] = _allergiesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (_maladiesChroniquesController.text.isNotEmpty) {
      medicalData['maladiesChroniques'] = _maladiesChroniquesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    medicalData['profilMedicalComplete'] = true;

    rootPayload['profilMedical'] = medicalData;
    return rootPayload;
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final userId = await _tokenService.getUserId();
    final token = await _tokenService.getToken();

    if (userId == null || token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur d\'authentification'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    try {
      final payload = _buildPayload();
      debugPrint('📝 Saving medical profile: ${jsonEncode(payload)}');

      final response = await http
          .patch(
            Uri.parse('${AuthService.baseUrl}/api/patients/$userId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📝 Medical profile save: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Update stored user data
        final updatedUser = jsonDecode(response.body) as Map<String, dynamic>;
        await AuthService().updateStoredUserData(updatedUser);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil médical sauvegardé!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.isPostRegistration) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/patient-home',
            (route) => false,
          );
        } else {
          Navigator.pop(context, true);
        }
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err['message']?.toString() ?? 'Erreur lors de la sauvegarde',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Save medical profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  void _skip() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/patient-home',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.doctorGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    if (!widget.isPostRegistration)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: widget.isPostRegistration
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isPostRegistration
                                ? 'Complétez votre profil'
                                : 'Modifier le profil médical',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isPostRegistration
                                ? 'Ces informations aident votre suivi médical'
                                : 'Mettez à jour vos informations',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isPostRegistration)
                      TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Passer',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: List.generate(steps.length, (i) {
                    final isActive = i == _currentStep;
                    final isDone = i < _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isDone
                              ? Colors.white
                              : isActive
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Step title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(
                      steps[_currentStep]['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      steps[_currentStep]['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentStep + 1}/${steps.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: steps[_currentStep]['content'] as Widget,
                        ),
                      ),
                      // Navigation buttons
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (_currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _currentStep--),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.softGreen,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Précédent'),
                                ),
                              ),
                            if (_currentStep > 0) const SizedBox(width: 12),
                            Expanded(
                              flex: _currentStep == 0 ? 1 : 1,
                              child: ElevatedButton(
                                onPressed: _isSaving
                                    ? null
                                    : _currentStep < steps.length - 1
                                    ? () => setState(() => _currentStep++)
                                    : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.softGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _currentStep < steps.length - 1
                                            ? 'Suivant'
                                            : 'Enregistrer',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildSteps() {
    return [
      {
        'title': 'Informations personnelles',
        'icon': Icons.person_outline,
        'content': _buildStep1(),
      },
      {
        'title': 'Informations diabète',
        'icon': Icons.medical_information_outlined,
        'content': _buildStep2(),
      },
      {
        'title': 'Traitement actuel',
        'icon': Icons.medication_outlined,
        'content': _buildStep3(),
      },
      {
        'title': 'Antécédents & Complications',
        'icon': Icons.health_and_safety_outlined,
        'content': _buildStep4(),
      },
      {
        'title': 'Mode de vie & Allergies',
        'icon': Icons.fitness_center_outlined,
        'content': _buildStep5(),
      },
    ];
  }

  // =====================================================================
  // STEP 1: Informations personnelles
  // =====================================================================
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Taille (cm)'),
        _numericField(_tailleController, 'Ex: 175'),
        const SizedBox(height: 16),
        _fieldLabel('Poids (kg)'),
        _numericField(_poidsController, 'Ex: 70'),
        const SizedBox(height: 8),
        if (_tailleController.text.isNotEmpty &&
            _poidsController.text.isNotEmpty) ...[
          Builder(
            builder: (_) {
              final h = double.tryParse(_tailleController.text);
              final w = double.tryParse(_poidsController.text);
              if (h != null && h > 0 && w != null && w > 0) {
                final bmi = w / ((h / 100) * (h / 100));
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calculate,
                        color: AppColors.softGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'IMC calculé: ${bmi.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.softGreen,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
        ],
        if (!widget.isPostRegistration) ...[
          _fieldLabel('Groupe sanguin'),
          _dropdownField<String>(
            value: _groupeSanguin,
            hint: 'Sélectionner',
            items: _groupesSanguins
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _groupeSanguin = v),
          ),
          const SizedBox(height: 16),
        ],
        _fieldLabel('Contact d\'urgence'),
        _textField(
          _contactUrgenceController,
          'Nom et téléphone',
          TextInputType.text,
        ),
      ],
    );
  }

  // =====================================================================
  // STEP 2: Informations diabète
  // =====================================================================
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isPostRegistration) ...[
          _fieldLabel('Type de diabète'),
          _dropdownField<String>(
            value: _typeDiabete,
            hint: 'Sélectionner le type',
            items: _typesDiabete
                .map(
                  (t) => DropdownMenuItem(
                    value: t['value'],
                    child: Text(t['label']!),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _typeDiabete = v),
          ),
          const SizedBox(height: 16),
        ],
        _fieldLabel('Date de diagnostic'),
        _datePickerField(
          value: _dateDiagnostic,
          hint: 'Sélectionner la date',
          onPicked: (d) => setState(() => _dateDiagnostic = d),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Glycémie à jeun moyenne (mg/dL)'),
        _numericField(_glycemieAJeunController, 'Ex: 120'),
        const SizedBox(height: 16),
        _fieldLabel('Dernier HbA1c (%)'),
        _numericField(_hba1cController, 'Ex: 6.5'),
        const SizedBox(height: 4),
        Text(
          'L\'HbA1c évalue l\'équilibre du diabète sur ~3 mois',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Fréquence de mesure glycémie'),
        _dropdownField<String>(
          value: _frequenceMesure,
          hint: 'Sélectionner',
          items: _frequencesMesure
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (v) => setState(() => _frequenceMesure = v),
        ),
      ],
    );
  }

  // =====================================================================
  // STEP 3: Traitement actuel
  // =====================================================================
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Traitements utilisés'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _traitementOptions.map((t) {
            final selected = _traitements.contains(t);
            return FilterChip(
              label: Text(
                t,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: selected,
              onSelected: (v) => setState(
                () => v ? _traitements.add(t) : _traitements.remove(t),
              ),
              selectedColor: AppColors.softGreen,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _switchTile(
          'Prend de l\'insuline',
          _prendInsuline,
          (v) => setState(() => _prendInsuline = v),
        ),
        if (_prendInsuline) ...[
          const SizedBox(height: 12),
          _fieldLabel('Type d\'insuline'),
          _textField(
            _typeInsulineController,
            'Ex: Lantus, NovoRapid...',
            TextInputType.text,
          ),
          const SizedBox(height: 12),
          _fieldLabel('Dose quotidienne (UI)'),
          _numericField(_doseInsulineController, 'Ex: 30'),
          const SizedBox(height: 12),
          _fieldLabel('Fréquence d\'injection / jour'),
          _numericField(_frequenceInjectionController, 'Ex: 3'),
        ],
        const SizedBox(height: 12),
        _switchTile(
          'Utilise un capteur de glucose',
          _utiliseCapteur,
          (v) => setState(() => _utiliseCapteur = v),
        ),
      ],
    );
  }

  // =====================================================================
  // STEP 4: Antécédents & Complications
  // =====================================================================
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Antécédents médicaux'),
        const SizedBox(height: 8),
        _checkTile(
          'Antécédents familiaux de diabète',
          _antecedentsFamiliaux,
          (v) => setState(() => _antecedentsFamiliaux = v!),
        ),
        _checkTile(
          'Hypertension',
          _hypertension,
          (v) => setState(() => _hypertension = v!),
        ),
        _checkTile(
          'Maladies cardiovasculaires',
          _maladiesCardio,
          (v) => setState(() => _maladiesCardio = v!),
        ),
        _checkTile(
          'Problèmes rénaux',
          _problemesRenaux,
          (v) => setState(() => _problemesRenaux = v!),
        ),
        _checkTile(
          'Problèmes oculaires (rétinopathie)',
          _problemesOculaires,
          (v) => setState(() => _problemesOculaires = v!),
        ),
        _checkTile(
          'Neuropathie diabétique',
          _neuropathie,
          (v) => setState(() => _neuropathie = v!),
        ),
        const SizedBox(height: 16),
        _sectionHeader('Complications actuelles'),
        const SizedBox(height: 8),
        _checkTile(
          'Pied diabétique',
          _piedDiabetique,
          (v) => setState(() => _piedDiabetique = v!),
        ),
        _checkTile('Ulcères', _ulceres, (v) => setState(() => _ulceres = v!)),
        _checkTile(
          'Hypoglycémies fréquentes',
          _hypoglycemiesFreq,
          (v) => setState(() => _hypoglycemiesFreq = v!),
        ),
        _checkTile(
          'Hyperglycémies fréquentes',
          _hyperglycemiesFreq,
          (v) => setState(() => _hyperglycemiesFreq = v!),
        ),
        _checkTile(
          'Hospitalisations récentes',
          _hospitalisationsRecentes,
          (v) => setState(() => _hospitalisationsRecentes = v!),
        ),
      ],
    );
  }

  // =====================================================================
  // STEP 5: Mode de vie & Allergies
  // =====================================================================
  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Niveau d\'activité physique'),
        _dropdownField<String>(
          value: _niveauActivite,
          hint: 'Sélectionner',
          items: _niveauxActivite
              .map((n) => DropdownMenuItem(value: n, child: Text(n)))
              .toList(),
          onChanged: (v) => setState(() => _niveauActivite = v),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Habitudes alimentaires'),
        _dropdownField<String>(
          value: _habitudesAlimentaires,
          hint: 'Sélectionner',
          items: _habitudes
              .map((h) => DropdownMenuItem(value: h, child: Text(h)))
              .toList(),
          onChanged: (v) => setState(() => _habitudesAlimentaires = v),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Tabac'),
        _dropdownField<String>(
          value: _tabac,
          hint: 'Sélectionner',
          items: _tabacOptions
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _tabac = v),
        ),
        const SizedBox(height: 20),
        _fieldLabel('Allergies médicamenteuses'),
        _textField(
          _allergiesController,
          'Ex: Pénicilline, Aspirine (séparées par des virgules)',
          TextInputType.text,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Autres maladies chroniques'),
        _textField(
          _maladiesChroniquesController,
          'Ex: Asthme, Thyroïde (séparées par des virgules)',
          TextInputType.text,
        ),
      ],
    );
  }

  // =====================================================================
  // Building blocks
  // =====================================================================
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.softGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.softGreen,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint,
    TextInputType type,
  ) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: _inputDecoration(hint),
    );
  }

  Widget _numericField(TextEditingController ctrl, String hint) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(hint),
      onChanged: (_) => setState(() {}),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.softGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _dropdownField<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(
        hint,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      items: items,
      onChanged: onChanged,
      decoration: _inputDecoration(''),
      isExpanded: true,
    );
  }

  Widget _datePickerField({
    required DateTime? value,
    required String hint,
    required ValueChanged<DateTime> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(2020),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.softGreen,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: _inputDecoration(''),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
              : hint,
          style: TextStyle(
            color: value != null ? AppColors.textPrimary : Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: value
            ? AppColors.softGreen.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppColors.softGreen.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.softGreen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _checkTile(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.softGreen,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
