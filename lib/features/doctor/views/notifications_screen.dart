import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';

enum AlertType { critical, warning, info }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('2 unread notifications', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Critical Alert Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFC5252)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Critical Alerts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('1 patient requires immediate attention', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Filters
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Row(children: [_filterTab('All', null), _filterTab('Critical', 1), _filterTab('Warning', 2), _filterTab('Info', 1)]),
                ),
                const SizedBox(height: 20),
                _alertCard(name: 'Michael Brown', message: 'Critical glucose level detected:\n220 mg/dL', time: '6h ago', type: AlertType.critical, isRead: false),
                _alertCard(name: 'John Smith', message: 'Elevated glucose readings for 3\nconsecutive days', time: '11h ago', type: AlertType.warning, isRead: false),
                _alertCard(name: 'Emily Davis', message: 'Appointment reminder: Tomorrow\nat 11:00 AM', time: '13h ago', type: AlertType.info, isRead: true),
                _alertCard(name: 'Michael Brown', message: 'Missed medication dose reported', time: '1d ago', type: AlertType.warning, isRead: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String label, int? count) {
    final isSelected = selectedFilter == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? AppColors.softGreen : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textMuted, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                  child: Text('$count', style: TextStyle(color: isSelected ? Colors.white : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _alertCard({required String name, required String message, required String time, required AlertType type, required bool isRead}) {
    Color bgColor, iconColor, borderColor;
    IconData icon;
    switch (type) {
      case AlertType.critical:
        bgColor = const Color(0xFFFFF0F0); iconColor = const Color(0xFFFF6B6B); borderColor = const Color(0xFFFF6B6B); icon = Icons.warning_rounded;
      case AlertType.warning:
        bgColor = const Color(0xFFFFF8E6); iconColor = const Color(0xFFFFB347); borderColor = const Color(0xFFFFB347); icon = Icons.warning_amber;
      case AlertType.info:
        bgColor = const Color(0xFFE8F5FF); iconColor = AppColors.lightBlue; borderColor = AppColors.lightBlue; icon = Icons.info_outline;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isRead ? Colors.transparent : borderColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Text(name, style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.bold, fontSize: 16, color: AppColors.textPrimary))), IconButton(icon: const Icon(Icons.close, size: 18), color: AppColors.textMuted, onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints())]),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
                const SizedBox(height: 8),
                Row(children: [Text(time, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)), const Spacer(), if (!isRead) TextButton.icon(onPressed: () {}, icon: const Icon(Icons.check, size: 16), label: const Text('Mark as read'), style: TextButton.styleFrom(foregroundColor: AppColors.softGreen, padding: EdgeInsets.zero))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
