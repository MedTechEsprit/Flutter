import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/patient_request_service.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';

class FindDoctorsScreen extends StatefulWidget {
  const FindDoctorsScreen({super.key});

  @override
  State<FindDoctorsScreen> createState() => _FindDoctorsScreenState();
}

class _FindDoctorsScreenState extends State<FindDoctorsScreen> {
  String _searchQuery = '';
  final _requestService = PatientRequestService();
  final _tokenService = TokenService();
  String? _patientId;
  // Map doctorId → status ('pending', 'accepted', 'declined', or null)
  Map<String, String> _requestStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadRequestStatuses();
  }

  Future<void> _loadRequestStatuses() async {
    _patientId = await _tokenService.getUserId();
    if (_patientId == null) return;
    try {
      final requests = await _requestService.getMyRequests(_patientId!);
      final map = <String, String>{};
      for (final r in requests) {
        // doctorId can be an object (populated) or string
        final docId = r['doctorId'] is Map ? r['doctorId']['_id']?.toString() : r['doctorId']?.toString();
        if (docId != null) {
          map[docId] = r['status'] ?? 'pending';
        }
      }
      if (mounted) setState(() => _requestStatuses = map);
    } catch (_) {}
  }

  Future<void> _sendRequest(String doctorId) async {
    if (_patientId == null) return;
    try {
      await _requestService.createPatientRequest(
        patientId: _patientId!,
        doctorId: doctorId,
      );
      setState(() => _requestStatuses[doctorId] = 'pending');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Demande envoyée avec succès !'),
            backgroundColor: AppColors.statusGood,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PatientViewModel>();
    final doctors = vm.doctors.where((d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase()) || d.specialty.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.mainGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Médecins', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Trouvez et consultez vos médecins', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            icon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                            hintText: 'Rechercher un médecin...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
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
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: doctors.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: Text('Aucun médecin trouvé', style: TextStyle(color: AppColors.textMuted))))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DoctorCard(
                          doctor: doctors[index],
                          requestStatus: _requestStatuses[doctors[index].id],
                          onSendRequest: () => _sendRequest(doctors[index].id),
                        ),
                      ),
                      childCount: doctors.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final dynamic doctor;
  final String? requestStatus;
  final VoidCallback onSendRequest;

  const _DoctorCard({required this.doctor, this.requestStatus, required this.onSendRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.lightBlue.withOpacity(0.15),
                child: Text(
                  doctor.name.split(' ').length > 1 ? '${doctor.name.split(' ')[0][0]}${doctor.name.split(' ')[1][0]}' : doctor.name[0],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.lightBlue),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(doctor.specialty, style: const TextStyle(fontSize: 13, color: AppColors.softGreen)),
                    Text(doctor.hospital ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: doctor.isAvailable ? AppColors.statusGood.withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  doctor.isAvailable ? 'Disponible' : 'Indisponible',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: doctor.isAvailable ? AppColors.statusGood : AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _InfoChip(icon: Icons.people, label: '${doctor.totalPatients} patients'),
              const SizedBox(width: 10),
              _InfoChip(icon: Icons.star, label: '${doctor.satisfactionRate}%'),
              const SizedBox(width: 10),
              _InfoChip(icon: Icons.work_history, label: '${doctor.yearsExperience} ans'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildRequestButton(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Builder(
                  builder: (ctx) => ElevatedButton.icon(
                    onPressed: () async {
                      final chatVM = ctx.read<ChatViewModel>();
                      final conv = await chatVM.startConversation(doctor.id);
                      if (conv != null && ctx.mounted) {
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(conversation: conv),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildRequestButton() {
    if (requestStatus == 'accepted') {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 16, color: AppColors.statusGood),
        label: const Text('Accepté', style: TextStyle(color: AppColors.statusGood)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.statusGood),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (requestStatus == 'pending') {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_top, size: 16, color: AppColors.statusWarning),
        label: const Text('En attente', style: TextStyle(color: AppColors.statusWarning)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.statusWarning),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onSendRequest,
        icon: const Icon(Icons.person_add, size: 16),
        label: const Text('Devenir patient'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightBlue,
          side: const BorderSide(color: AppColors.lightBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
