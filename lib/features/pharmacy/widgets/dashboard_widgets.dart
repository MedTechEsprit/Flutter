import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/app_text_styles.dart';
// ignore: unused_import
import 'package:diab_care/data/models/pharmacy_models.dart';

// ─── StatCard ──────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String icon;
  final String number;
  final String label;
  final String? badge;
  final Color? numberColor;
  final Color? cardColor;

  const StatCard({super.key, required this.icon, required this.number, required this.label, this.badge, this.numberColor, this.cardColor});

  @override
  Widget build(BuildContext context) {
    final bgColor = cardColor ?? AppColors.mintGreen;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(14)), child: Text(icon, style: const TextStyle(fontSize: 24))),
            if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(12)), child: Text(badge!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.darkGreen))),
          ]),
          const Spacer(),
          Text(number, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: numberColor ?? AppColors.darkGreen, letterSpacing: -0.5, height: 1.0)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary.withOpacity(0.7), height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── StatCardWithChart ─────────────────────────────────────
class StatCardWithChart extends StatelessWidget {
  final String title, value, subtitle;
  final List<double> chartData;
  final Color primaryColor, chartColor;

  const StatCardWithChart({super.key, required this.title, required this.value, required this.subtitle, required this.chartData, required this.primaryColor, required this.chartColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))),
        ]),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
        const SizedBox(height: 16),
        SizedBox(height: 60, child: CustomPaint(size: const Size(double.infinity, 60), painter: ChartPainter(data: chartData, lineColor: chartColor, fillColor: chartColor.withOpacity(0.3)))),
      ]),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor, fillColor;
  ChartPainter({required this.data, required this.lineColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final minV = data.reduce((a, b) => a < b ? a : b);
    final range = maxV - minV;
    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final nv = range == 0 ? 0.5 : (data[i] - minV) / range;
      final y = size.height - (nv * size.height * 0.8) - size.height * 0.1;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final px = (i - 1) * stepX;
        final py = size.height - ((range == 0 ? 0.5 : (data[i - 1] - minV) / range) * size.height * 0.8) - size.height * 0.1;
        path.cubicTo(px + stepX / 2, py, x - stepX / 2, y, x, y);
        fillPath.cubicTo(px + stepX / 2, py, x - stepX / 2, y, x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
    final lx = (data.length - 1) * stepX;
    final lnv = range == 0 ? 0.5 : (data.last - minV) / range;
    final ly = size.height - (lnv * size.height * 0.8) - size.height * 0.1;
    canvas.drawCircle(Offset(lx, ly), 6, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(lx, ly), 4, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── WelcomeBanner ─────────────────────────────────────────
class WelcomeBanner extends StatefulWidget {
  final List<String> messages;
  const WelcomeBanner({super.key, required this.messages});

  @override
  State<WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<WelcomeBanner> {
  int currentIndex = 0;
  bool dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (dismissed || widget.messages.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.mixedGradient, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: Text(_getIcon(), style: const TextStyle(fontSize: 28))),
        const SizedBox(width: 14),
        Expanded(child: Text(widget.messages[currentIndex], style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14))),
        IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22), onPressed: () => setState(() => dismissed = true), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
    );
  }

  String _getIcon() {
    final m = widget.messages[currentIndex];
    if (m.startsWith('🎉')) return '🎉';
    if (m.startsWith('💰')) return '💰';
    if (m.startsWith('🏆')) return '🏆';
    return '✨';
  }
}

// ─── AlertCard ─────────────────────────────────────────────
class AlertCard extends StatelessWidget {
  final Color backgroundColor;
  final String icon, title, subtitle;
  final VoidCallback? onTap;
  final bool showArrow;

  const AlertCard({super.key, required this.backgroundColor, required this.icon, required this.title, required this.subtitle, this.onTap, this.showArrow = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2), width: 1.5)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12)), child: Text(icon, style: const TextStyle(fontSize: 24))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTextStyles.subheader.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(subtitle, style: AppTextStyles.bodySecondary.copyWith(fontSize: 13))])),
          if (showArrow) Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

// ─── BadgeDisplay ──────────────────────────────────────────
class BadgeDisplay extends StatelessWidget {
  final String icon, name;
  final int currentPoints, maxPoints;

  const BadgeDisplay({super.key, required this.icon, required this.name, required this.currentPoints, required this.maxPoints});

  @override
  Widget build(BuildContext context) {
    final progress = currentPoints / maxPoints;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.cardBackground, AppColors.lightBlue]), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2), width: 1.5)),
      child: Column(children: [
        Container(width: 90, height: 90, decoration: BoxDecoration(gradient: AppColors.premiumGradient, shape: BoxShape.circle), child: Center(child: Text(icon, style: const TextStyle(fontSize: 44)))),
        const SizedBox(height: 16),
        Text(name, style: AppTextStyles.badgeName.copyWith(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ClipRRect(borderRadius: BorderRadius.circular(12), child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.border.withOpacity(0.3), valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkGreen), minHeight: 10)),
        const SizedBox(height: 12),
        Text('$currentPoints/$maxPoints pts', style: AppTextStyles.label.copyWith(color: AppColors.darkGreen, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}

// ─── PerformanceCard ───────────────────────────────────────
class PerformanceCard extends StatelessWidget {
  final String label, value, benchmark, badge;
  final int stars;

  const PerformanceCard({super.key, required this.label, required this.value, required this.stars, required this.benchmark, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.cardBackground, AppColors.mintGreen]), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 14),
        Text(value, style: AppTextStyles.statNumber.copyWith(fontSize: 32, color: AppColors.darkGreen, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(children: List.generate(5, (i) => Padding(padding: const EdgeInsets.only(right: 4), child: Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded, size: 20, color: i < stars ? AppColors.accentGold : AppColors.border)))),
        const SizedBox(height: 12),
        Text(benchmark, style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(10)), child: Text(badge, style: AppTextStyles.smallLabel.copyWith(color: AppColors.cardBackground, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

// ─── ActivityEventCard ─────────────────────────────────────
class ActivityEventCard extends StatelessWidget {
  final String icon, description, timestamp;
  final String? value;

  const ActivityEventCard({super.key, required this.icon, required this.description, required this.timestamp, this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: AppColors.mixedGradient, borderRadius: BorderRadius.circular(12)), child: Text(icon, style: const TextStyle(fontSize: 20))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(description, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(timestamp, style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
          if (value != null) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(8)), child: Text(value!, style: TextStyle(color: AppColors.cardBackground, fontWeight: FontWeight.w600, fontSize: 12)))],
        ])),
      ]),
    );
  }
}

// ─── ReviewCard ────────────────────────────────────────────
class ReviewCard extends StatelessWidget {
  final String patientName, comment, timestamp;
  final int rating;

  const ReviewCard({super.key, required this.patientName, required this.rating, required this.comment, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.cardBackground, AppColors.lightBlue]), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primaryBlue.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(gradient: AppColors.mixedGradient, shape: BoxShape.circle), child: Center(child: Text(patientName[0].toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(patientName, style: AppTextStyles.subheader.copyWith(fontWeight: FontWeight.w600)), Text(timestamp, style: AppTextStyles.bodyMuted.copyWith(fontSize: 11))]),
          ]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(gradient: AppColors.premiumGradient, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.star_rounded, size: 16, color: Colors.white), const SizedBox(width: 4), Text('$rating.0', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))])),
        ]),
        const SizedBox(height: 12),
        Text(comment, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5)),
      ]),
    );
  }
}
