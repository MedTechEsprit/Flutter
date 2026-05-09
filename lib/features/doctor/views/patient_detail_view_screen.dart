import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/core/utils/profile_image_utils.dart';
import 'package:diab_care/data/services/patient_request_service.dart';
import 'package:diab_care/features/ai/views/ai_doctor_screen.dart';
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
  State<PatientDetailViewScreen> createState() =>
      _PatientDetailViewScreenState();
}

class _PatientDetailViewScreenState extends State<PatientDetailViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = PatientRequestService();
  final _tokenService = TokenService();

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _glucoseRecords = [];
  bool _isLoading = true;
  bool _hasAccess = true;
  bool _requestingAccess = false;

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
      final doctorId = await _tokenService.getUserId();
      if (doctorId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasAccess = false;
          });
        }
        return;
      }

      final canAccess = await _service.getDoctorAccessStatusForDoctor(
        doctorId: doctorId,
        patientId: widget.patientId,
      );

      if (!canAccess) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasAccess = false;
          });
        }
        return;
      }

      final results = await Future.wait([
        _service.getPatientProfile(widget.patientId),
        _service.getPatientGlucoseRecords(widget.patientId),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _glucoseRecords =
              (results[1] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _isLoading = false;
          _hasAccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasAccess = false;
        });
      }
    }
  }

  Future<void> _sendAccessRequest() async {
    if (_requestingAccess) return;
    setState(() => _requestingAccess = true);
    try {
      final doctorId = await _tokenService.getUserId();
      if (doctorId == null) throw Exception('Doctor not found');

      await _service.requestDoctorAccess(
        doctorId: doctorId,
        patientId: widget.patientId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Request sent to the patient. Waiting for their response.',
          ),
          backgroundColor: AppColors.softGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _requestingAccess = false);
    }
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
    final patientPhoto = ProfileImageUtils.imageProvider(
      _profile?['photoProfil']?.toString(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22C1C3)),
            )
          : !_hasAccess
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 44,
                        color: Color(0xFFFFB347),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Access denied by the patient',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The patient has disabled access to their information. Send a request to get access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _requestingAccess
                              ? null
                              : _sendAccessRequest,
                          icon: _requestingAccess
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _requestingAccess ? 'Sending...' : 'Send request',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.softGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF22C1C3), Color(0xFF5B86E5)],
                      ),
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
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Patient details',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.psychology_rounded,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Consult AI',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AiDoctorScreen(
                                          patientId: widget.patientId,
                                          patientName: widget.patientName,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: patientPhoto,
                                child: patientPhoto == null
                                    ? Text(
                                        widget.patientName.length >= 2
                                            ? widget.patientName
                                                  .substring(0, 2)
                                                  .toUpperCase()
                                            : widget.patientName.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.patientName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              diabType,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                statusText.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF5B86E5),
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: const Color(0xFF5B86E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Glucose'),
                        Tab(text: 'Medical Profile'),
                        Tab(text: 'Info'),
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
      final values = _glucoseRecords
          .map((r) => (r['value'] as num?)?.toDouble() ?? 0)
          .toList();
      avg = values.reduce((a, b) => a + b) / values.length;
      lastVal = values.first;
    }
    final groupeSanguin =
        _profile?['groupeSanguin'] ??
        (_profile?['profilMedical']
            as Map<String, dynamic>?)?['groupeSanguin'] ??
        '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              title: 'Latest glucose',
              value: lastVal > 0 ? '${lastVal.toInt()}' : '-',
              unit: 'mg/dL',
              color: AppColors.softGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              title: 'Average',
              value: avg > 0 ? '${avg.toInt()}' : '-',
              unit: 'mg/dL',
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              title: 'Blood type',
              value: groupeSanguin.toString(),
              unit: '',
              color: const Color(0xFF9B51E0),
            ),
          ),
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
            Text(
              'No glucose readings',
              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
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
        final date =
            DateTime.tryParse(r['measuredAt']?.toString() ?? '') ??
            DateTime.now();
        final period = r['period']?.toString() ?? '';
        final note = r['note']?.toString();
        final mgdl = unit == 'mmol/L' ? value * 18.0182 : value;
        final color = mgdl < 70
            ? const Color(0xFFFFB347)
            : mgdl > 180
            ? const Color(0xFFFF6B6B)
            : const Color(0xFF48BB78);
        final statusLabel = mgdl < 70
            ? 'Low'
            : mgdl <= 180
            ? 'Normal'
            : 'High';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.02)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          value.toStringAsFixed(unit == 'mmol/L' ? 1 : 0),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (note != null && note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          note,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (period.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _periodLabel(period),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.softGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM HH:mm').format(date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
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
      case 'fasting':
        return 'Fasting';
      case 'before_meal':
        return 'Before meal';
      case 'after_meal':
        return 'After meal';
      case 'bedtime':
        return 'Bedtime';
      default:
        return p;
    }
  }

  Widget _buildMedicalProfileTab() {
    final pm = (_profile?['profilMedical'] as Map<String, dynamic>?) ?? {};
    if (pm.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information,
              size: 60,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 8),
            Text(
              'Medical profile not available',
              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final labels = <String, String>{
      'taille': 'Height (cm)',
      'poids': 'Weight (kg)',
      'imc': 'BMI',
      'tensionArterielle': 'Blood pressure',
      'frequenceCardiaque': 'Heart rate',
      'dateDecouverte': 'Diagnosis date',
      'antecedentsFamiliaux': 'Family history',
      'allergies': 'Allergies',
      'maladiesChroniques': 'Chronic conditions',
      'fumeur': 'Smoker',
      'alcool': 'Alcohol',
      'activitePhysique': 'Physical activity',
      'traitementActuel': 'Current treatment',
      'insulinotherapie': 'Insulin therapy',
      'pompeInsuline': 'Insulin pump',
      'glycemieAJeunMoyenne': 'Avg fasting glucose',
      'hba1c': 'HbA1c',
      'objectifGlycemieMin': 'Target min',
      'objectifGlycemieMax': 'Target max',
      'complicationsConnues': 'Known complications',
    };
    final rows = <MapEntry<String, String>>[];
    for (final e in labels.entries) {
      final v = pm[e.key];
      if (v != null && v.toString().isNotEmpty && v.toString() != 'null') {
        String display = v.toString();
        if (v is bool) display = v ? 'Yes' : 'No';
        if (v is List) display = v.join(', ');
        rows.add(MapEntry(e.value, display));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.02)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C1C3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medical_information,
                      color: Color(0xFF22C1C3),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Medical Profile',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...rows.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160,
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.02)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B86E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF5B86E5),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow('Name', '${p['prenom'] ?? ''} ${p['nom'] ?? ''}'),
              _infoRow('Email', p['email']?.toString() ?? '-'),
              _infoRow('Phone', p['telephone']?.toString() ?? '-'),
              _infoRow('Date of birth', _formatDate(p['dateNaissance'])),
              _infoRow('Diabetes type', p['typeDiabete']?.toString() ?? '-'),
              _infoRow(
                'Blood type',
                (p['groupeSanguin'] ?? pm['groupeSanguin'])?.toString() ?? '-',
              ),
              _infoRow('Sex', pm['sexe']?.toString() ?? '-'),
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
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.softGreen,
                  side: const BorderSide(color: AppColors.softGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
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

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: Colors.blueGrey,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
