import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/core/utils/profile_image_utils.dart';
import 'package:diab_care/data/services/patient_request_service.dart';
import 'package:diab_care/features/patient/viewmodels/patient_viewmodel.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';
import 'package:diab_care/features/patient/views/my_doctors_screen.dart';
import 'package:diab_care/features/patient/views/patient_appointments_screen.dart';

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
        final requestType = (r['requestType']?.toString() ?? 'patient_link')
            .toLowerCase();
        if (requestType != 'patient_link') {
          continue;
        }
        // doctorId can be an object (populated) or string
        final docId = r['doctorId'] is Map
            ? r['doctorId']['_id']?.toString()
            : r['doctorId']?.toString();
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PatientViewModel>();
    final doctors = vm.doctors
        .where(
          (d) =>
              d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.specialty.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.doctorBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.doctorGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Médecins',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trouvez et consultez vos médecins',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
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
                              color: Colors.white.withOpacity(0.8),
                            ),
                            hintText: 'Rechercher un médecin...',
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _QuickBtn(
                    icon: Icons.people_outline_rounded,
                    label: 'Mes\nMédecins',
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyDoctorsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _QuickBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Messages',
                    gradient: const LinearGradient(
                      colors: [AppColors.accentBlue, AppColors.primaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    badge: context.watch<ChatViewModel>().doctorUnreadCount,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConversationListScreen(
                          isDoctor: false,
                          doctorOnly: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _QuickBtn(
                    icon: Icons.calendar_today_rounded,
                    label: 'Rendez-\nvous',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF74EBD5), Color(0xFFFDBB2D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientAppointmentsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: doctors.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Aucun médecin trouvé',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
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

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final int badge;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradient,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gradient.colors.first.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gradient.colors.first.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: gradient.colors.first, size: 26),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDBB2D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final dynamic doctor;
  final String? requestStatus;
  final VoidCallback onSendRequest;

  const _DoctorCard({
    required this.doctor,
    this.requestStatus,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    final profileImage = ProfileImageUtils.imageProvider(
      doctor.avatarUrl?.toString(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  image: profileImage != null
                      ? DecorationImage(image: profileImage, fit: BoxFit.cover)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: profileImage == null
                    ? const Icon(Icons.person_outline_rounded, color: Colors.white, size: 32)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (doctor.hospital != null && doctor.hospital!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        doctor.hospital!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: doctor.isAvailable
                            ? AppColors.primaryGreen.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: doctor.isAvailable
                              ? AppColors.primaryGreen.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: doctor.isAvailable ? AppColors.primaryGreen : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doctor.isAvailable ? 'Disponible' : 'Indisponible',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: doctor.isAvailable
                                  ? AppColors.primaryGreen
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(icon: Icons.people_outline_rounded, value: '${doctor.totalPatients}', unit: 'patients', color: AppColors.primaryGreen),
                _StatItem(icon: Icons.star_outline_rounded, value: '${doctor.satisfactionRate}%', unit: '', color: AppColors.softOrange),
                _StatItem(icon: Icons.calendar_today_outlined, value: '${doctor.yearsExperience}', unit: 'ans', color: AppColors.accentBlue),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildRequestButton()),
              const SizedBox(width: 10),
              Expanded(
                child: Builder(
                  builder: (ctx) => Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentBlue, AppColors.primaryBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final chatVM = ctx.read<ChatViewModel>();
                        final conv = await chatVM.startConversation(doctor.id);
                        if (conv != null && ctx.mounted) {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatDetailScreen(conversation: conv),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('Message', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
        ),
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: AppColors.primaryGreen,
          ),
          label: const Text(
            'Accepté',
            style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    } else if (requestStatus == 'pending') {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.statusWarning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.statusWarning.withOpacity(0.3)),
        ),
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(
            Icons.hourglass_top_rounded,
            size: 18,
            color: AppColors.statusWarning,
          ),
          label: const Text(
            'En attente',
            style: TextStyle(color: AppColors.statusWarning, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    } else {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.lightBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
        ),
        child: OutlinedButton.icon(
          onPressed: onSendRequest,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Devenir patient', style: TextStyle(fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.lightBlue,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
