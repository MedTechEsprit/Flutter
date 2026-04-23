import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/utils/profile_image_utils.dart';
import 'package:diab_care/data/services/patient_request_service.dart';

class PatientDoctorProfileScreen extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic> doctor;

  const PatientDoctorProfileScreen({
    super.key,
    required this.patientId,
    required this.doctor,
  });

  @override
  State<PatientDoctorProfileScreen> createState() =>
      _PatientDoctorProfileScreenState();
}

class _PatientDoctorProfileScreenState
    extends State<PatientDoctorProfileScreen> {
  final _service = PatientRequestService();
  bool _isLoading = true;
  bool _accessEnabled = true;

  String get _doctorId => widget.doctor['_id']?.toString() ?? '';
  String get _doctorName =>
      'Dr. ${widget.doctor['prenom'] ?? ''} ${widget.doctor['nom'] ?? ''}'
          .trim();

  @override
  void initState() {
    super.initState();
    _loadAccessStatus();
  }

  Future<void> _loadAccessStatus() async {
    try {
      final enabled = await _service.getDoctorAccessStatusForPatient(
        patientId: widget.patientId,
        doctorId: _doctorId,
      );
      if (mounted) {
        setState(() {
          _accessEnabled = enabled;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAccess(bool enabled) async {
    final previous = _accessEnabled;
    setState(() => _accessEnabled = enabled);

    try {
      final updated = await _service.setDoctorAccessByPatient(
        patientId: widget.patientId,
        doctorId: _doctorId,
        enabled: enabled,
      );

      if (!mounted) return;
      setState(() => _accessEnabled = updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated
                ? 'Autorisation activée. Ce médecin peut consulter vos informations à tout moment.'
                : 'Autorisation désactivée. Le médecin devra vous envoyer une demande pour consulter vos données.',
          ),
          backgroundColor: updated
              ? AppColors.softGreen
              : const Color(0xFFFFB347),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _accessEnabled = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final specialite = widget.doctor['specialite']?.toString() ?? '';
    final email = widget.doctor['email']?.toString() ?? '-';
    final phone = widget.doctor['telephone']?.toString() ?? '-';
    final clinique = widget.doctor['clinique']?.toString() ?? '-';
    final profileImage = ProfileImageUtils.imageProvider(
      widget.doctor['photoProfil']?.toString(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text(
          'Profil Médecin',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.softGreen),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.softGreen,
                                  AppColors.softGreen.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: profileImage != null
                                  ? Image(
                                      image: profileImage,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Text(
                                        _doctorName.length > 4
                                            ? _doctorName
                                                  .substring(4, 5)
                                                  .toUpperCase()
                                            : 'D',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _doctorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                if (specialite.isNotEmpty)
                                  Text(
                                    specialite,
                                    style: const TextStyle(
                                      color: AppColors.softGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _infoRow(Icons.email_outlined, email),
                      const SizedBox(height: 8),
                      _infoRow(Icons.phone_outlined, phone),
                      const SizedBox(height: 8),
                      _infoRow(Icons.business_outlined, clinique),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Autorisation d\'accès',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Si activée, ce médecin peut consulter vos informations médicales à tout moment.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _accessEnabled
                              ? 'Accès autorisé'
                              : 'Accès non autorisé',
                        ),
                        subtitle: Text(
                          _accessEnabled
                              ? 'Le médecin peut consulter votre historique.'
                              : 'Le médecin devra envoyer une demande.',
                        ),
                        value: _accessEnabled,
                        onChanged: _toggleAccess,
                        activeColor: AppColors.softGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
