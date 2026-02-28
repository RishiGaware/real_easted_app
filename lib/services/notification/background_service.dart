import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:inhabit_realties/services/notification/notificationService.dart';
import 'package:inhabit_realties/models/notification/NotificationModel.dart';
import 'package:inhabit_realties/services/notification/local_notification_service.dart';

class BackgroundNotificationService {
  static final Set<String> _alertedNotificationIds = {};

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // This will execute the background logic when the app is in foreground or background
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'inhabit_realties_channel',
        initialNotificationTitle: 'Inhabit Realties Service',
        initialNotificationContent: 'Running in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    // Re-initialize local notifications inside the background isolate
    await LocalNotificationService.initialize();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
      service.on('stopService').listen((event) {
        service.stopSelf();
      });
    }

    // Bring in your timer for silent fetches here
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // You can also dynamically update the persistent notification here if desired
        }
      }

      await _silentFetchNewNotifications();
    });
  }

  static Future<void> _silentFetchNewNotifications() async {
    try {
      final result = await NotificationService.getUserNotifications(
        page: 1,
        limit: 10,
        unreadOnly: true,
      );

      if (result['statusCode'] == 200) {
        final List<dynamic> notificationsData = result['data'] ?? [];
        final newSilentNotifications = notificationsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        for (var notification in newSilentNotifications) {
          if (!_alertedNotificationIds.contains(notification.id)) {
            _alertedNotificationIds.add(notification.id);

            // Trigger local push notification
            LocalNotificationService.showNotification(
              id: notification.id.hashCode,
              title: notification.title,
              body: notification.message,
              payload: notification.id,
            );
          }
        }
      }
    } catch (e) {
      // Ignored background exceptions
    }
  }
}
