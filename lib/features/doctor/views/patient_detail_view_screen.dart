import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/services/patient_request_service.dart';
import 'package:intl/intl.dart';

class PatientDetailViewScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final int? age;
  final String? diabetesType;
  final String? status;

  const PatientDetailViewScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.age,
    this.diabetesType,
    this.status,
  });

  @override
  State<PatientDetailViewScreen> createState() => _PatientDetailViewScreenState();
}

class _PatientDetailViewScreenState extends State<PatientDetailViewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = PatientRequestService();

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _glucoseRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getPatientProfile(widget.patientId),
        _service.getPatientGlucoseRecords(widget.patientId),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _glucoseRecords = (results[1] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAge() {
    if (widget.age != null) return '${widget.age} ans';
    final dob = _profile?['dateNaissance'];
    if (dob == null) return '-';
    final d = DateTime.tryParse(dob.toString());
    if (d == null) return '-';
    final now = DateTime.now();
    int age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
    return '$age ans';
  }

  @override
  Widget build(BuildContext context) {
    final statusText = widget.status ?? 'Stable';
    Color statusColor = statusText.toLowerCase() == 'critical'
        ? const Color(0xFFFF6B6B)
        : statusText.toLowerCase() == 'attention'
            ? const Color(0xFFFFB347)
            : const Color(0xFF48BB78);

    final diabType = widget.diabetesType ?? _profile?['typeDiabete'] ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.softGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppColors.mainGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Expanded(
                                  child: Text('Details du patient', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Text(
                                widget.patientName.length >= 2 ? widget.patientName.substring(0, 2).toUpperCase() : widget.patientName.toUpperCase(),
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.softGreen),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(widget.patientName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('${_getAge()} - $diabType', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                              child: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricsRow(),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.softGreen,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicator: BoxDecoration(color: AppColors.softGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Glycemie'),
                        Tab(text: 'Profil medical'),
                        Tab(text: 'Infos'),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGlucoseTab(),
                        _buildMedicalProfileTab(),
                        _buildInfoTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricsRow() {
    double avg = 0, lastVal = 0;
    if (_glucoseRecords.isNotEmpty) {
      final values = _glucoseRecords.map((r) => (r['value'] as num?)?.toDouble() ?? 0).toList();
      avg = values.reduce((a, b) => a + b) / values.length;
      lastVal = values.first;
    }
    final groupeSanguin = _profile?['groupeSanguin'] ?? (_profile?['profilMedical'] as Map<String, dynamic>?)?['groupeSanguin'] ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _MetricCard(title: 'Derniere glycemie', value: lastVal > 0 ? '${lastVal.toInt()}' : '-', unit: 'mg/dL', color: AppColors.softGreen)),
          const SizedBox(width: 10),
          Expanded(child: _MetricCard(title: 'Moyenne', value: avg > 0 ? '${avg.toInt()}' : '-', unit: 'mg/dL', color: AppColors.lightBlue)),
          const SizedBox(width: 10),
          Expanded(child: _MetricCard(title: 'Groupe sanguin', value: groupeSanguin.toString(), unit: '', color: const Color(0xFF9B51E0))),
        ],
      ),
    );
  }

  Widget _buildGlucoseTab() {
    if (_glucoseRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 60, color: AppColors.textMuted),
            SizedBox(height: 8),
            Text('Aucune mesure de glycemie', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _glucoseRecords.length.clamp(0, 30),
      itemBuilder: (ctx, i) {
        final r = _glucoseRecords[i];
        final value = (r['value'] as num?)?.toDouble() ?? 0;
        final unit = r['unit']?.toString() ?? 'mg/dL';
        final date = DateTime.tryParse(r['measuredAt']?.toString() ?? '') ?? DateTime.now();
        final period = r['period']?.toString() ?? '';
        final note = r['note']?.toString();
        final mgdl = unit == 'mmol/L' ? value * 18.0182 : value;
        final color = mgdl < 70
            ? const Color(0xFFFFB347)
            : mgdl > 180
                ? const Color(0xFFFF6B6B)
                : const Color(0xFF48BB78);
        final statusLabel = mgdl < 70 ? 'Bas' : mgdl <= 180 ? 'Normal' : 'Eleve';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
          ),
          child: Row(
            children: [
              Container(width: 4, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(value.toStringAsFixed(unit == 'mmol/L' ? 1 : 0), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                        const SizedBox(width: 4),
                        Text(unit, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                        ),
                      ],
                    ),
                    if (note != null && note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(note, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (period.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.softGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(_periodLabel(period), style: const TextStyle(fontSize: 10, color: AppColors.softGreen, fontWeight: FontWeight.w500)),
                    ),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd/MM HH:mm').format(date), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _periodLabel(String p) {
    switch (p) {
      case 'fasting': return 'A jeun';
      case 'before_meal': return 'Avant repas';
      case 'after_meal': return 'Apres repas';
      case 'bedtime': return 'Coucher';
      default: return p;
    }
  }

  Widget _buildMedicalProfileTab() {
    final pm = (_profile?['profilMedical'] as Map<String, dynamic>?) ?? {};
    if (pm.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_information, size: 60, color: AppColors.textMuted),
            SizedBox(height: 8),
            Text('Profil medical non renseigne', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
          ],
        ),
      );
    }

    final labels = <String, String>{
      'taille': 'Taille (cm)',
      'poids': 'Poids (kg)',
      'imc': 'IMC',
      'tensionArterielle': 'Tension arterielle',
      'frequenceCardiaque': 'Frequence cardiaque',
      'dateDecouverte': 'Date de decouverte',
      'antecedentsFamiliaux': 'Antecedents familiaux',
      'allergies': 'Allergies',
      'maladiesChroniques': 'Maladies chroniques',
      'fumeur': 'Fumeur',
      'alcool': 'Alcool',
      'activitePhysique': 'Activite physique',
      'traitementActuel': 'Traitement actuel',
      'insulinotherapie': 'Insulinotherapie',
      'pompeInsuline': 'Pompe a insuline',
      'glycemieAJeunMoyenne': 'Glycemie a jeun moy.',
      'hba1c': 'HbA1c',
      'objectifGlycemieMin': 'Objectif min',
      'objectifGlycemieMax': 'Objectif max',
      'complicationsConnues': 'Complications connues',
    };
    final rows = <MapEntry<String, String>>[];
    for (final e in labels.entries) {
      final v = pm[e.key];
      if (v != null && v.toString().isNotEmpty && v.toString() != 'null') {
        String display = v.toString();
        if (v is bool) display = v ? 'Oui' : 'Non';
        if (v is List) display = v.join(', ');
        rows.add(MapEntry(e.value, display));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.medical_information, color: AppColors.softGreen, size: 20),
                  SizedBox(width: 8),
                  Text('Profil medical', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ...rows.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 160, child: Text(e.key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    Expanded(child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    final p = _profile ?? {};
    final pm = (p['profilMedical'] as Map<String, dynamic>?) ?? {};
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: AppColors.softGreen, size: 20),
                  SizedBox(width: 8),
                  Text('Informations personnelles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow('Nom', '${p['prenom'] ?? ''} ${p['nom'] ?? ''}'),
              _infoRow('Email', p['email']?.toString() ?? '-'),
              _infoRow('Telephone', p['telephone']?.toString() ?? '-'),
              _infoRow('Date de naissance', _formatDate(p['dateNaissance'])),
              _infoRow('Type de diabete', p['typeDiabete']?.toString() ?? '-'),
              _infoRow('Groupe sanguin', (p['groupeSanguin'] ?? pm['groupeSanguin'])?.toString() ?? '-'),
              _infoRow('Sexe', pm['sexe']?.toString() ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.call, size: 18),
                label: const Text('Appeler'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.softGreen,
                  side: const BorderSide(color: AppColors.softGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.message, size: 18),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.lightBlue,
                  side: const BorderSide(color: AppColors.lightBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  String _formatDate(dynamic d) {
    if (d == null) return '-';
    final date = DateTime.tryParse(d.toString());
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, height: 1), overflow: TextOverflow.ellipsis)),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 2),
                  child: Text(unit, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}