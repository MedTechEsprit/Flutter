import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/core/utils/profile_image_utils.dart';
import 'package:diab_care/data/services/patient_service.dart';
import 'package:diab_care/data/models/patient_model.dart';
import 'package:diab_care/core/widgets/animations.dart';
import 'patient_detail_view_screen.dart';
import 'patient_medical_report_screen.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final _patientService = PatientService();
  final _tokenService = TokenService();
  final _searchController = TextEditingController();

  List<PatientModel> _patients = [];
  StatusCounts? _statusCounts;
  bool _isLoading = true;
  String? _errorMessage;
  String? _doctorId;
  String _searchQuery = '';

  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _doctorId = await _tokenService.getUserId();
      if (_doctorId == null) throw Exception('Doctor ID not found');

      final response = await _patientService.getDoctorPatients(
        doctorId: _doctorId!,
        status: _filterStatus,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _patients = response.data;
        _statusCounts = response.statusCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFEFF6FF,
      ), // Consistent colorful background
      body: Column(
        children: [
          // ═══════════════════════════════════════════
          // GRADIENT HEADER WITH SEARCH
          // ═══════════════════════════════════════════
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF22C1C3), Color(0xFF5B86E5)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'My Patients',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => _loadPatients(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Search Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        _loadPatients();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search for a patient...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════════════════════
                  // KPI CARDS ROW (Refined)
                  // ═══════════════════════════════════════════
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKpiClickableCard(
                        _isLoading ? '--' : '${_statusCounts?.total ?? 0}',
                        'Total',
                        const Color(0xFF5B86E5),
                        _filterStatus == 'all',
                        () {
                          setState(() => _filterStatus = 'all');
                          _loadPatients();
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildKpiClickableCard(
                        _isLoading
                            ? '--'
                            : '${(_statusCounts?.critical ?? 0) + (_statusCounts?.attention ?? 0)}',
                        'Urgent',
                        const Color(0xFFFF6B6B),
                        _filterStatus == 'critical',
                        () {
                          setState(() => _filterStatus = 'critical');
                          _loadPatients();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ═══════════════════════════════════════════
                  // SECTION TITLE: RÉCENTS
                  // ═══════════════════════════════════════════
                  const Text(
                    'Recent',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════
                  // PATIENT CARDS LIST
                  // ═══════════════════════════════════════════
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_patients.isEmpty)
                    const Center(child: Text('No patients found'))
                  else
                    ..._patients.asMap().entries.map((entry) {
                      return FadeInSlide(
                        index: entry.key,
                        child: _buildPatientCard(entry.value),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiClickableCard(
    String value,
    String label,
    Color color,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? Border.all(color: color.withOpacity(0.5), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    final status = patient.displayStatus;
    final name = patient.fullName;
    final lastReading = patient.lastGlucoseReading != null
        ? '${patient.lastGlucoseReading!.toStringAsFixed(0)} mg/dL'
        : 'No data';
    final riskScore = patient.riskScore ?? 'Low';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'critical':
        statusColor = const Color(0xFFFF6B6B);
        break;
      case 'attention':
        statusColor = const Color(0xFFFDBB2D);
        break;
      default:
        statusColor = const Color(0xFF22C1C3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailViewScreen(
                  patientId: patient.id,
                  patientName: name,
                  age: patient.age ?? 0,
                  diabetesType: patient.typeDiabete ?? 'Type Unknown',
                  status: status,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withOpacity(0.8),
                            statusColor.withOpacity(0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${patient.age ?? "--"} yrs',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.monitor_heart_outlined,
                                size: 13,
                                color: statusColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                patient.typeDiabete ?? 'Type 2 Diabetes',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.water_drop,
                        lastReading,
                        'Last Reading',
                        const Color(0xFF5B86E5),
                      ),
                      _buildStatItem(
                        Icons.analytics_outlined,
                        'Risk: $riskScore',
                        'AI Score',
                        _getRiskColor(riskScore),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons (Message & Report)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final chatVM = context.read<ChatViewModel>();
                          final conversation = await chatVM.startConversation(
                            patient.id,
                          );
                          if (conversation != null && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  conversation: conversation,
                                  isDoctor: true,
                                ),
                              ),
                            );
                          }
                        },
                        child: _buildActionButton(
                          'Message',
                          Icons.mail_outline_rounded,
                          const Color(0xFF5B86E5),
                          true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientMedicalReportScreen(
                                patientId: patient.id,
                                patientName: name,
                              ),
                            ),
                          );
                        },
                        child: _buildActionButton(
                          'Report',
                          Icons.description_outlined,
                          const Color(0xFF22C1C3),
                          false,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.blueGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF6B6B);
      case 'medium':
        return const Color(0xFFFDBB2D);
      default:
        return const Color(0xFF22C1C3);
    }
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    bool isBlue,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isBlue
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF0FDF4).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
