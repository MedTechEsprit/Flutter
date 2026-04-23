import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diab_care/core/services/notification_navigation_service.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/notification_service.dart';
import 'package:diab_care/features/patient/viewmodels/glucose_viewmodel.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService with WidgetsBindingObserver {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const String _queueKey = 'fcm_sync_queue_v1';
  static const String _lastRegisterSignatureKey = 'fcm_last_register_signature';

  final TokenService _tokenService = TokenService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  bool _isInitialized = false;
  bool _isSyncingQueue = false;
  bool _isSyncingToken = false;
  int _tokenSyncFailureCount = 0;
  DateTime? _nextTokenSyncAllowedAt;
  Timer? _tokenRetryTimer;

  final Set<String> _processedPushKeys = <String>{};

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initLocalNotifications();
    await _requestPermission();
    await _setupMessageHandlers();
    await _setupTokenRefreshListener();

    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;

    await onAuthenticatedSession(force: false);
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
    _tokenRetryTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onAuthenticatedSession(force: false);
    }
  }

  Future<void> onAuthenticatedSession({bool force = true}) async {
    await _drainQueue();
    await _syncCurrentToken(force: force);
  }

  Future<void> onBeforeLogout() async {
    final jwt = await _tokenService.getToken();
    final userId = await _tokenService.getUserId();
    final role = await _tokenService.getUserRole();
    final fcmToken = await _safeGetFcmToken();

    final userType = _mapRoleToUserType(role);
    if (jwt == null || userId == null || userType == null || fcmToken == null) {
      return;
    }

    try {
      await _notificationService.removeDeviceToken(
        fcmToken: fcmToken,
        userType: userType,
        userId: userId,
      );
    } catch (error) {
      final apiError = error is NotificationApiException ? error : null;
      final shouldQueue = apiError == null || apiError.isTemporary;
      if (shouldQueue) {
        await _enqueueOperation(
          _FcmSyncOperation.remove(
            fcmToken: fcmToken,
            userType: userType,
            userId: userId,
          ),
        );
      }
    }

    try {
      await _localNotifications.cancelAll();
    } catch (_) {}

    try {
      await _messaging.deleteToken();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastRegisterSignatureKey);
    _processedPushKeys.clear();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload == null || response.payload!.isEmpty) {
          await NotificationNavigationService.instance.openInbox();
          return;
        }

        try {
          final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
          await NotificationNavigationService.instance.navigateFromNotificationData(
            payload,
          );
        } catch (_) {
          await NotificationNavigationService.instance.openInbox();
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'diabcare_push',
      'DiabCare Notifications',
      description: 'Notifications push DiabCare',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus.name}');
    }
  }

  Future<void> _setupMessageHandlers() async {
    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _processRemoteMessageNavigation(message);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _processRemoteMessageNavigation(initialMessage);
      });
    }
  }

  Future<void> _setupTokenRefreshListener() async {
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      await _syncCurrentToken(force: true, explicitToken: newToken);
    });
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final key = _messageKey(message);
    if (key != null && _processedPushKeys.contains(key)) {
      return;
    }

    if (key != null) {
      _processedPushKeys.add(key);
    }

    final payloadData = _extractPayload(message);
    final title = message.notification?.title ??
        (payloadData['title']?.toString() ?? 'DiabCare');
    final body = message.notification?.body ??
        (payloadData['message']?.toString() ??
            payloadData['body']?.toString() ??
            'Nouvelle notification');

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'diabcare_push',
          'DiabCare Notifications',
          channelDescription: 'Notifications push DiabCare',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payloadData),
    );

    _triggerInAppRefresh(payloadData);

    await onAuthenticatedSession(force: false);
  }

  Future<void> _processRemoteMessageNavigation(RemoteMessage message) async {
    final key = _messageKey(message);
    if (key != null && _processedPushKeys.contains(key)) {
      return;
    }

    if (key != null) {
      _processedPushKeys.add(key);
    }

    final payload = _extractPayload(message);
    _triggerInAppRefresh(payload);
    await NotificationNavigationService.instance.navigateFromNotificationData(
      payload,
    );

    await onAuthenticatedSession(force: false);
  }

  Future<void> _syncCurrentToken({
    required bool force,
    String? explicitToken,
  }) async {
    if (!force && _isInTokenSyncCooldown()) {
      return;
    }

    if (_isSyncingToken) return;
    _isSyncingToken = true;

    try {
      final token = await _tokenService.getToken();
      final userId = await _tokenService.getUserId();
      final role = await _tokenService.getUserRole();
      final userType = _mapRoleToUserType(role);
      final fcmToken = explicitToken ?? await _safeGetFcmToken();

      if (token == null || userId == null || userType == null) {
        return;
      }

      if (fcmToken == null) {
        _registerTokenSyncFailure();
        return;
      }

      final signature = '$fcmToken|$userType|$userId';
      final prefs = await SharedPreferences.getInstance();
      final lastSignature = prefs.getString(_lastRegisterSignatureKey);

      if (!force && signature == lastSignature) {
        return;
      }

      try {
        await _notificationService.registerDeviceToken(
          fcmToken: fcmToken,
          userType: userType,
          userId: userId,
        );
        await prefs.setString(_lastRegisterSignatureKey, signature);
        _resetTokenSyncFailures();
      } catch (error) {
        final apiError = error is NotificationApiException ? error : null;
        final shouldQueue = apiError == null || apiError.isTemporary;
        if (shouldQueue) {
          await _enqueueOperation(
            _FcmSyncOperation.register(
              fcmToken: fcmToken,
              userType: userType,
              userId: userId,
            ),
          );
        }
      }
    } finally {
      _isSyncingToken = false;
    }
  }

  Future<String?> _safeGetFcmToken() async {
    const maxAttempts = 3;
    var delay = const Duration(seconds: 1);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final token = await _messaging
            .getToken()
            .timeout(const Duration(seconds: 8));

        if (token != null && token.isNotEmpty) {
          if (kDebugMode && attempt > 1) {
            debugPrint('FCM token recovered after retry #$attempt');
          }
          return token;
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('FCM token attempt #$attempt failed: $error');
        }

        final canRetry = _isTransientFcmTokenError(error);
        if (!canRetry || attempt == maxAttempts) {
          if (kDebugMode) {
            debugPrint('FCM token unavailable: $error');
          }
          return null;
        }
      }

      await Future.delayed(delay);
      delay = Duration(seconds: delay.inSeconds * 2);
    }

    return null;
  }

  bool _isTransientFcmTokenError(Object error) {
    final text = error.toString();
    return text.contains('SERVICE_NOT_AVAILABLE') ||
        text.contains('INTERNAL_SERVER_ERROR') ||
        text.contains('TimeoutException') ||
        text.contains('SocketException');
  }

  bool _isInTokenSyncCooldown() {
    final next = _nextTokenSyncAllowedAt;
    return next != null && DateTime.now().isBefore(next);
  }

  void _registerTokenSyncFailure() {
    _tokenSyncFailureCount += 1;

    // 30s, 60s, 120s, ... capped at 10 minutes.
    final backoffSeconds =
        (30 * (1 << (_tokenSyncFailureCount - 1))).clamp(30, 600);
    final retryAfter = Duration(seconds: backoffSeconds);
    _nextTokenSyncAllowedAt = DateTime.now().add(retryAfter);

    _tokenRetryTimer?.cancel();
    _tokenRetryTimer = Timer(retryAfter, () {
      onAuthenticatedSession(force: true);
    });

    if (kDebugMode) {
      debugPrint(
        'FCM token sync backoff #$_tokenSyncFailureCount: retry in ${retryAfter.inSeconds}s',
      );
    }
  }

  void _resetTokenSyncFailures() {
    _tokenSyncFailureCount = 0;
    _nextTokenSyncAllowedAt = null;
    _tokenRetryTimer?.cancel();
    _tokenRetryTimer = null;
  }

  Future<void> _drainQueue() async {
    if (_isSyncingQueue) return;
    _isSyncingQueue = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getStringList(_queueKey) ?? <String>[];
      if (serialized.isEmpty) return;

      final remaining = <String>[];
      for (final item in serialized) {
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          final operation = _FcmSyncOperation.fromJson(map);

          if (operation.type == _FcmSyncType.register) {
            await _notificationService.registerDeviceToken(
              fcmToken: operation.fcmToken,
              userType: operation.userType,
              userId: operation.userId,
            );
          } else {
            await _notificationService.removeDeviceToken(
              fcmToken: operation.fcmToken,
              userType: operation.userType,
              userId: operation.userId,
            );
          }
        } catch (error) {
          final apiError = error is NotificationApiException ? error : null;
          final shouldKeep = apiError == null || apiError.isTemporary;
          if (shouldKeep) {
            remaining.add(item);
          }
        }
      }

      await prefs.setStringList(_queueKey, remaining);
    } finally {
      _isSyncingQueue = false;
    }
  }

  Future<void> _enqueueOperation(_FcmSyncOperation operation) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? <String>[];

    final encoded = jsonEncode(operation.toJson());
    final alreadyQueued = queue.any((item) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final queued = _FcmSyncOperation.fromJson(map);
        return queued.type == operation.type &&
            queued.fcmToken == operation.fcmToken &&
            queued.userType == operation.userType &&
            queued.userId == operation.userId;
      } catch (_) {
        return false;
      }
    });

    if (!alreadyQueued) {
      queue.add(encoded);
      await prefs.setStringList(_queueKey, queue);
    }
  }

  String? _mapRoleToUserType(String? role) {
    if (role == null) return null;
    final normalized = role.toLowerCase();
    if (normalized == 'patient') return 'patient';
    if (normalized == 'medecin' || normalized == 'doctor') return 'doctor';
    if (normalized == 'pharmacien' || normalized == 'pharmacy') {
      return 'pharmacy';
    }
    return null;
  }

  Map<String, dynamic> _extractPayload(RemoteMessage message) {
    final data = <String, dynamic>{...message.data};

    final nestedData = data['data'];
    if (nestedData is String && nestedData.isNotEmpty) {
      try {
        final decoded = jsonDecode(nestedData);
        if (decoded is Map<String, dynamic>) {
          data.addAll(decoded);
        }
      } catch (_) {}
    }

    return data;
  }

  String? _messageKey(RemoteMessage message) {
    final messageId = message.messageId?.trim();
    if (messageId != null && messageId.isNotEmpty) {
      return messageId;
    }

    final fallback = message.data['messageId']?.toString().trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return null;
  }

  void _triggerInAppRefresh(Map<String, dynamic> payload) {
    final context = NotificationNavigationService.instance.navigatorKey.currentContext;
    if (context == null) return;

    final triggerType = payload['triggerType']?.toString().toLowerCase() ?? '';
    final hasMeasurementId =
        (payload['measurementId']?.toString().trim().isNotEmpty ?? false);

    final looksLikeGlucoseEvent = hasMeasurementId ||
        triggerType.contains('glucose') ||
        triggerType.contains('measurement') ||
        triggerType.contains('glycemie') ||
        triggerType.contains('glycemia');

    if (looksLikeGlucoseEvent) {
      try {
        context.read<GlucoseViewModel>().loadReadings();
      } catch (_) {}
    }
  }
}

enum _FcmSyncType { register, remove }

class _FcmSyncOperation {
  final _FcmSyncType type;
  final String fcmToken;
  final String userType;
  final String userId;

  const _FcmSyncOperation({
    required this.type,
    required this.fcmToken,
    required this.userType,
    required this.userId,
  });

  factory _FcmSyncOperation.register({
    required String fcmToken,
    required String userType,
    required String userId,
  }) {
    return _FcmSyncOperation(
      type: _FcmSyncType.register,
      fcmToken: fcmToken,
      userType: userType,
      userId: userId,
    );
  }

  factory _FcmSyncOperation.remove({
    required String fcmToken,
    required String userType,
    required String userId,
  }) {
    return _FcmSyncOperation(
      type: _FcmSyncType.remove,
      fcmToken: fcmToken,
      userType: userType,
      userId: userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'fcmToken': fcmToken,
      'userType': userType,
      'userId': userId,
    };
  }

  factory _FcmSyncOperation.fromJson(Map<String, dynamic> json) {
    final typeText = (json['type'] ?? 'register').toString();
    final type = typeText == 'remove'
        ? _FcmSyncType.remove
        : _FcmSyncType.register;

    return _FcmSyncOperation(
      type: type,
      fcmToken: (json['fcmToken'] ?? '').toString(),
      userType: (json['userType'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
    );
  }
}
