import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

late AndroidNotificationChannel notificationChannel;
bool notificationsInitialized = false;
late FlutterLocalNotificationsPlugin localNotifications;

/// User-visible content carried by a push notification.
final class PushNotificationContent {
  const PushNotificationContent({required this.title, required this.body});

  final String title;
  final String body;
}

/// Keeps push payload interpretation in one place for notification rendering
/// and for the in-app message opened from a notification tap.
PushNotificationContent? notificationContentFor(RemoteMessage message) {
  final title =
      message.notification?.title ?? message.data['title']?.toString();
  final body = message.notification?.body ?? message.data['body']?.toString();
  if (title == null ||
      title.trim().isEmpty ||
      body == null ||
      body.trim().isEmpty) {
    return null;
  }
  return PushNotificationContent(title: title.trim(), body: body.trim());
}

void showFlutterNotification(RemoteMessage message) {
  final notification = message.notification;
  final android = notification?.android;
  final link = message.data['link']?.toString() ?? '';

  if (link.isNotEmpty) {
    const categoryId = 'whatsapp_action_category';
    initializeLocalNotifications(categoryId);
    const linkChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones y Alertas',
      description:
          'Notificaciones y alertas sobre sus paquetes e información importante.',
      importance: Importance.high,
    );
    localNotifications.show(
      notification.hashCode,
      message.data['title']?.toString(),
      message.data['body']?.toString(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          linkChannel.id,
          linkChannel.name,
          channelDescription: linkChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_push_icon',
          actions: const [
            AndroidNotificationAction(
              'open_whatsapp',
              'Responder',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: categoryId,
        ),
      ),
      payload: link,
    );
    return;
  }

  if (notification != null && android != null && !kIsWeb) {
    localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannel.id,
          notificationChannel.name,
          channelDescription: notificationChannel.description,
          icon: 'ic_push_icon',
        ),
      ),
    );
  }
}

void initializeLocalNotifications(String categoryId) {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  final category = DarwinNotificationCategory(
    categoryId,
    actions: [
      DarwinNotificationAction.plain(
        'open_whatsapp',
        'Responder',
        options: {DarwinNotificationActionOption.foreground},
      ),
    ],
    options: const {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
  );
  final ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: [category],
  );
  localNotifications.initialize(
    InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: _handleNotificationResponse,
    onDidReceiveBackgroundNotificationResponse: _handleNotificationResponse,
  );
}

@pragma('vm:entry-point')
void _handleNotificationResponse(NotificationResponse details) {
  if (details.actionId == 'open_whatsapp' && details.payload != null) {
    _launchExternal(details.payload!);
  }
}

Future<void> _launchExternal(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
