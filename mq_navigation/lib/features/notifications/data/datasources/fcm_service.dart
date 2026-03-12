import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/notifications/data/datasources/local_notifications_service.dart';
import 'package:mq_navigation/features/notifications/data/datasources/notification_remote_source.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';

enum NotificationPermissionStatus {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  provisional,
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase may already be initialised or native config may be missing.
  }
  AppLogger.info('Handled background notification', message.messageId);
}

class FcmService {
  FcmService({
    required FirebaseMessaging messaging,
    required NotificationRemoteSource remoteSource,
    required LocalNotificationsService localNotificationsService,
  }) : _messaging = messaging,
       _remoteSource = remoteSource,
       _localNotificationsService = localNotificationsService;

  final FirebaseMessaging _messaging;
  final NotificationRemoteSource _remoteSource;
  final LocalNotificationsService _localNotificationsService;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openAppSubscription;
  bool _isInitialised = false;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize({
    required Future<void> Function(String link) onOpenLink,
  }) async {
    if (_isInitialised || !_isSupported) {
      return;
    }

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      final notification = AppNotification.fromRemoteMessage(message);
      await _localNotificationsService.showForegroundNotification(notification);
    });

    _openAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) async {
      final link = message.data['link'] as String?;
      if (link != null && link.isNotEmpty) {
        await onOpenLink(link);
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    final link = initialMessage?.data['link'] as String?;
    if (link != null && link.isNotEmpty) {
      await onOpenLink(link);
    }

    _isInitialised = true;
  }

  Future<NotificationPermissionStatus> getPermissionStatus() async {
    if (!_isSupported) {
      return NotificationPermissionStatus.denied;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final permission = await Permission.notification.status;
      if (permission.isGranted) {
        return NotificationPermissionStatus.granted;
      }
      if (permission.isPermanentlyDenied) {
        return NotificationPermissionStatus.permanentlyDenied;
      }
      if (permission.isDenied || permission.isRestricted) {
        return NotificationPermissionStatus.denied;
      }
    }

    final settings = await _messaging.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized => NotificationPermissionStatus.granted,
      AuthorizationStatus.provisional =>
        NotificationPermissionStatus.provisional,
      AuthorizationStatus.denied => NotificationPermissionStatus.denied,
      AuthorizationStatus.notDetermined => NotificationPermissionStatus.unknown,
    };
  }

  Future<NotificationPermissionStatus> requestPermission() async {
    if (!_isSupported) {
      return NotificationPermissionStatus.denied;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final permission = await Permission.notification.request();
      if (permission.isGranted) {
        return NotificationPermissionStatus.granted;
      }
      if (permission.isPermanentlyDenied) {
        return NotificationPermissionStatus.permanentlyDenied;
      }
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: defaultTargetPlatform == TargetPlatform.iOS,
    );
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized => NotificationPermissionStatus.granted,
      AuthorizationStatus.provisional =>
        NotificationPermissionStatus.provisional,
      AuthorizationStatus.denied => NotificationPermissionStatus.denied,
      AuthorizationStatus.notDetermined => NotificationPermissionStatus.unknown,
    };
  }

  String? _currentUserId;

  Future<void> syncToken(String userId) async {
    if (!_isSupported) {
      return;
    }

    _currentUserId = userId;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _remoteSource.upsertFcmToken(
      userId: userId,
      token: token,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((
      token,
    ) async {
      final currentId = _currentUserId;
      if (token.isEmpty || currentId == null) {
        return;
      }
      try {
        await _remoteSource.upsertFcmToken(
          userId: currentId,
          token: token,
          platform: defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        );
      } catch (error, stackTrace) {
        AppLogger.warning('Failed to refresh FCM token', error, stackTrace);
      }
    });
  }

  Future<void> removeToken(String userId) async {
    if (!_isSupported) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _remoteSource.deleteFcmToken(userId: userId, token: token);
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openAppSubscription?.cancel();
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService(
    messaging: FirebaseMessaging.instance,
    remoteSource: ref.watch(notificationRemoteSourceProvider),
    localNotificationsService: ref.watch(localNotificationsServiceProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});
