import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/data/models/pharmacy_models.dart';

class RequestCard extends StatelessWidget {
  final MedicationRequest request;
  final VoidCallback? onAccept, onDecline, onIgnore;

  const RequestCard({super.key, required this.request, this.onAccept, this.onDecline, this.onIgnore});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(),
        Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildBody(),
          if (request.patientNote != null) ...[const SizedBox(height: 14), _buildPatientNote()],
          if (request.status == RequestStatus.pending) ...[const SizedBox(height: 16), _buildActions()],
          if (request.status == RequestStatus.accepted) ...[const SizedBox(height: 14), _buildAcceptedInfo()],
          if (request.status == RequestStatus.declined) ...[const SizedBox(height: 14), _buildDeclinedInfo()],
          if (request.status == RequestStatus.expired) ...[const SizedBox(height: 14), _buildExpiredInfo()],
        ])),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Row(children: [
        _buildStatusBadge(),
        if (request.isUrgent) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(10)), child: const Text('⚡ URGENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)))],
        const Spacer(),
        Text(_getTimeAgo(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
      ]),
    );
  }

  Widget _buildStatusBadge() {
    String text; IconData icon; Color bgColor, textColor;
    switch (request.status) {
      case RequestStatus.pending: text = 'En Attente'; icon = Icons.access_time_rounded; bgColor = AppColors.mintGreen; textColor = AppColors.darkGreen;
      case RequestStatus.accepted: text = 'Accepté'; icon = Icons.check_circle_rounded; bgColor = AppColors.primaryGreen; textColor = Colors.white;
      case RequestStatus.declined: text = 'Refusé'; icon = Icons.cancel_rounded; bgColor = AppColors.textMuted; textColor = Colors.white;
      case RequestStatus.expired: text = 'Expiré'; icon = Icons.schedule_rounded; bgColor = AppColors.secondaryBlue; textColor = AppColors.textPrimary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: textColor), const SizedBox(width: 5), Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor))]),
    );
  }

  Widget _buildBody() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.secondaryBlue, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_rounded, size: 18, color: AppColors.darkGreen)), const SizedBox(width: 10), Text('Patient #${request.patientId}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textSecondary))]),
      const SizedBox(height: 12),
      Text(request.medicationName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 10),
      Row(children: [const Icon(Icons.medication_rounded, size: 16, color: AppColors.primaryGreen), const SizedBox(width: 6), Text('Qté: ${request.quantity}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)), const SizedBox(width: 16), const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primaryBlue), const SizedBox(width: 6), Expanded(child: Text(request.dosage, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis))]),
    ]);
  }

  Widget _buildPatientNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primaryBlue), const SizedBox(width: 10), Expanded(child: Text('"${request.patientNote}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: AppColors.textSecondary)))]),
    );
  }

  Widget _buildActions() {
    return Column(children: [
      SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: onAccept, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_rounded, size: 20), SizedBox(width: 8), Text('Disponible', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]))),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: SizedBox(height: 44, child: OutlinedButton(onPressed: onDecline, style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Non disponible', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))))),
        const SizedBox(width: 10),
        Expanded(child: SizedBox(height: 44, child: OutlinedButton(onPressed: onIgnore, style: OutlinedButton.styleFrom(foregroundColor: AppColors.textMuted, side: BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Ignorer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))))),
      ]),
    ]);
  }

  Widget _buildAcceptedInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.mintGreen, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (request.price != null) Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.payments_rounded, size: 18, color: AppColors.darkGreen)), const SizedBox(width: 10), Text('Prix: ${request.price!.toStringAsFixed(2)} TND', style: AppTextStyles.label.copyWith(color: AppColors.darkGreen, fontWeight: FontWeight.w600))]),
        if (request.pickupDeadline != null) ...[const SizedBox(height: 12), Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.schedule_rounded, size: 18, color: AppColors.accentBlue)), const SizedBox(width: 10), Text('À retirer avant: ${_formatDeadline()}', style: AppTextStyles.bodySecondary.copyWith(color: AppColors.darkGreen, fontWeight: FontWeight.w500))])],
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(gradient: request.isPickedUp ? AppColors.mixedGradient : AppColors.blueGradient, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(request.isPickedUp ? Icons.check_circle_rounded : Icons.pending_actions_rounded, size: 18, color: Colors.white), const SizedBox(width: 8), Text(request.isPickedUp ? '✓ Récupéré' : 'En attente de retrait', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))])),
      ]),
    );
  }

  Widget _buildDeclinedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.statusErrorBg, AppColors.cardBackground]), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.errorRed.withOpacity(0.3), width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (request.declineReason != null) ...[Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.info_rounded, size: 18, color: AppColors.errorRed)), const SizedBox(width: 10), Expanded(child: Text('Raison: ${request.declineReason}', style: AppTextStyles.bodySecondary.copyWith(color: AppColors.errorRed, fontWeight: FontWeight.w500)))]), const SizedBox(height: 12)],
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.errorRed.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.block_rounded, size: 16, color: AppColors.errorRed), SizedBox(width: 8), Text('Demande clôturée', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.w600, fontSize: 13))])),
      ]),
    );
  }

  Widget _buildExpiredInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.statusPendingBg, AppColors.cardBackground]), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.warningOrange.withOpacity(0.3), width: 1.5)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.hourglass_empty_rounded, size: 22, color: AppColors.warningOrange)),
        const SizedBox(width: 12),
        Expanded(child: Text('Aucune réponse donnée dans les 2h', style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.w500))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA07A)]), borderRadius: BorderRadius.circular(10)), child: const Text('⚠️ -2 pts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
      ]),
    );
  }

  String _getTimeAgo() {
    final diff = DateTime.now().difference(request.timestamp);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  String _formatDeadline() {
    if (request.pickupDeadline == null) return '';
    final d = request.pickupDeadline!;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    if (d.day == DateTime.now().day) return 'Aujourd\'hui à $h:$m';
    return '${d.day}/${d.month} à $h:$m';
  }
}
