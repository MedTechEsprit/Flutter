import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/services/notification_service.dart';

enum AlertType { critical, warning, info }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  String selectedFilter = 'All';
  bool _isLoading = true;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);
      final notifications = await _notificationService.getNotifications(
        type: 'patient_alert',
        limit: 100,
      );
      final unreadCount = await _notificationService.getUnreadCount();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _applyFilter(_notifications);
    final criticalCount = _notifications
        .where(
          (item) =>
              (item['severity'] ?? '').toString().toLowerCase() == 'critical',
        )
        .length;
    final warningCount = _notifications
        .where(
          (item) =>
              (item['severity'] ?? '').toString().toLowerCase() == 'warning',
        )
        .length;
    final infoCount = _notifications
        .where(
          (item) => (item['severity'] ?? '').toString().toLowerCase() == 'info',
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: Column(
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
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
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
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_unreadCount unread notifications',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _unreadCount == 0
                          ? null
                          : () async {
                              await _notificationService.markAllAsRead();
                              _loadNotifications();
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFC5252)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Critical alerts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              criticalCount == 0
                                  ? 'No patients in critical alert'
                                  : '$criticalCount patient${criticalCount == 1 ? '' : 's'} need${criticalCount == 1 ? 's' : ''} immediate attention',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _filterTab('All', _notifications.length),
                      _filterTab('Critical', criticalCount),
                      _filterTab('Warning', warningCount),
                      _filterTab('Info', infoCount),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: Color(0xFF22C1C3),
                      ),
                    ),
                  )
                else if (filteredNotifications.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'No notifications for this filter.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...filteredNotifications.map((item) {
                    final type = _mapAlertType(
                      (item['severity'] ?? 'info').toString(),
                    );
                    final isRead = item['isRead'] == true;
                    return _alertCard(
                      id: (item['_id'] ?? '').toString(),
                      name: (item['title'] ?? 'Patient alert').toString(),
                      message: (item['message'] ?? '').toString(),
                      time: _formatRelativeTime(
                        (item['timestamp'] ?? '').toString(),
                      ),
                      type: type,
                      isRead: isRead,
                    );
                  }),
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
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF5B86E5), Color(0xFF74EBD5)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF5B86E5).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> items) {
    if (selectedFilter == 'All') {
      return items;
    }
    if (selectedFilter == 'Critical') {
      return items
          .where(
            (item) =>
                (item['severity'] ?? '').toString().toLowerCase() == 'critical',
          )
          .toList();
    }
    if (selectedFilter == 'Warning') {
      return items
          .where(
            (item) =>
                (item['severity'] ?? '').toString().toLowerCase() == 'warning',
          )
          .toList();
    }
    return items
        .where(
          (item) => (item['severity'] ?? '').toString().toLowerCase() == 'info',
        )
        .toList();
  }

  AlertType _mapAlertType(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AlertType.critical;
      case 'warning':
        return AlertType.warning;
      default:
        return AlertType.info;
    }
  }

  String _formatRelativeTime(String rawTimestamp) {
    if (rawTimestamp.isEmpty) {
      return 'Just now';
    }

    final parsed = DateTime.tryParse(rawTimestamp)?.toLocal();
    if (parsed == null) {
      return 'Recent';
    }

    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} h ago';
    }
    return '${diff.inDays} d ago';
  }

  Widget _alertCard({
    required String id,
    required String name,
    required String message,
    required String time,
    required AlertType type,
    required bool isRead,
  }) {
    Color bgColor, iconColor, borderColor;
    IconData icon;
    switch (type) {
      case AlertType.critical:
        bgColor = const Color(0xFFFFF0F0);
        iconColor = const Color(0xFFFF6B6B);
        borderColor = const Color(0xFFFF6B6B);
        icon = Icons.warning_rounded;
      case AlertType.warning:
        bgColor = const Color(0xFFFFF8E6);
        iconColor = const Color(0xFFFFB347);
        borderColor = const Color(0xFFFFB347);
        icon = Icons.warning_amber;
      case AlertType.info:
        bgColor = const Color(0xFFE8F5FF);
        iconColor = AppColors.lightBlue;
        borderColor = AppColors.lightBlue;
        icon = Icons.info_outline;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.transparent : borderColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.textMuted,
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (!isRead)
                      TextButton.icon(
                        onPressed: () async {
                          await _notificationService.markAsRead(id);
                          _loadNotifications();
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Marquer comme lu'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.softGreen,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
