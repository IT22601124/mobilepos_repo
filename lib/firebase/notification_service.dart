import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin
  _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important NovaPOS notifications.',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    // Ask Android 13+ and iOS notification permission.
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Notification permission: ${settings.authorizationStatus}');

    // Android local notification configuration.
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS local notification configuration.
    const iosSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;

        if (payload != null && payload.isNotEmpty) {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          handleNotificationNavigation(data);
        }
      },
    );

    // Create Android notification channel.
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);

    // Request Android notification permission.
    await androidPlugin?.requestNotificationsPermission();

    // Show notifications received while app is open.
    FirebaseMessaging.onMessage.listen(showForegroundNotification);

    // Handle notification tap while app is in background.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationNavigation(message.data);
    });

    // Handle notification that opened a terminated app.
    final initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      handleNotificationNavigation(initialMessage.data);
    }

    // Get and print the FCM token for testing.
    final token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');

    // Listen when Firebase refreshes the device token.
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      print('New FCM token: $token');

      // Send the new token to your backend here.
    });
  }

  static Future<void> showForegroundNotification(
      RemoteMessage message,
      ) async {
    print('--- Received Message ---');
    print('Message ID: ${message.messageId}');
    print('From: ${message.from}');
    print('Data: ${message.data}');

    final notification = message.notification;
    final title = notification?.title ??
        message.data['title']?.toString() ??
        'NovaPOS';
    final body = notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';

    print('Notification Title: $title');
    print('Notification Body: $body');

    try {
      await _localNotifications.show(
        id: message.messageId?.hashCode ?? message.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
      print('Local notification shown successfully');
    } catch (e, stackTrace) {
      print('Error showing local notification: $e');
      print(stackTrace);
    }
  }

  static void handleNotificationNavigation(
      Map<String, dynamic> data,
      ) {
    print('Notification clicked: $data');

    final screen = data['screen'];

    if (screen == 'orders') {
      // Navigate to orders screen.
    } else if (screen == 'sales') {
      // Navigate to sales screen.
    }
  }
}
