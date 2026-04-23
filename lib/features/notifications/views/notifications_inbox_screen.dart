import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/notification_navigation_service.dart';
import 'package:diab_care/data/services/notification_service.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() => _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  final NotificationService _service = NotificationService();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _notifications = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isMarkAllLoading = false;
  bool _hasMore = true;
  int _page = 1;
  int _unreadCount = 0;
  String? _error;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final unread = await _service.getUnreadCount();
      final pageItems = await _service.getMyNotifications(
        page: _page,
        limit: _pageSize,
      );

      final sorted = _sortLatestFirst(pageItems);

      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(sorted);
        _unreadCount = unread;
        _hasMore = pageItems.length >= _pageSize;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _page + 1;
      final items = await _service.getMyNotifications(
        page: nextPage,
        limit: _pageSize,
      );

      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _notifications.addAll(_sortLatestFirst(items));
        _hasMore = items.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkAllLoading || _unreadCount == 0) return;

    setState(() => _isMarkAllLoading = true);
    try {
      await _service.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _unreadCount = 0;
        for (final item in _notifications) {
          item['isRead'] = true;
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isMarkAllLoading = false);
    }
  }

  Future<void> _openNotification(Map<String, dynamic> item) async {
    final id = (item['_id'] ?? item['id'] ?? '').toString();
    final alreadyRead = item['isRead'] == true;

    if (id.isNotEmpty && !alreadyRead) {
      try {
        await _service.markAsRead(id);
        setState(() {
          item['isRead'] = true;
          if (_unreadCount > 0) {
            _unreadCount -= 1;
          }
        });
      } catch (_) {}
    }

    final data = _extractNavigationData(item);
    await NotificationNavigationService.instance.navigateFromNotificationData(data);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      _loadMore();
    }
  }

  List<Map<String, dynamic>> _sortLatestFirst(List<Map<String, dynamic>> source) {
    final copy = List<Map<String, dynamic>>.from(source);
    copy.sort((a, b) {
      final left = _parseDate(a);
      final right = _parseDate(b);
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
    return copy;
  }

  DateTime? _parseDate(Map<String, dynamic> item) {
    final raw = (item['createdAt'] ?? item['timestamp'] ?? item['date'] ?? '').toString();
    return DateTime.tryParse(raw);
  }

  Map<String, dynamic> _extractNavigationData(Map<String, dynamic> notification) {
    final merged = <String, dynamic>{...notification};

    final nested = notification['data'];
    if (nested is Map<String, dynamic>) {
      merged.addAll(nested);
    } else if (nested is String && nested.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(nested);
        if (decoded is Map<String, dynamic>) {
          merged.addAll(decoded);
        }
      } catch (_) {}
    }

    return merged;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _unreadCount > 0
                      ? AppColors.softGreen.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$_unreadCount non lues',
                  style: TextStyle(
                    color: _unreadCount > 0 ? AppColors.softGreen : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: (_unreadCount == 0 || _isMarkAllLoading) ? null : _markAllAsRead,
            child: _isMarkAllLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tout lire'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitial,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadInitial,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 150),
          Center(
            child: Column(
              children: [
                Icon(Icons.notifications_none_rounded, size: 54, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('Aucune notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text('Vous êtes à jour.', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _notifications[index];
        final title = (item['title'] ?? 'Notification').toString();
        final body = (item['message'] ?? item['body'] ?? '').toString();
        final isRead = item['isRead'] == true;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openNotification(item),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRead ? AppColors.border : AppColors.softGreen.withOpacity(0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRead ? Colors.grey.shade300 : AppColors.softGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _relativeTime(_parseDate(item)),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _relativeTime(DateTime? time) {
    if (time == null) return 'Récente';
    final diff = DateTime.now().difference(time.toLocal());
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}
