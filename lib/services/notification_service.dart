import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  print("Background Notification: ${message.notification?.title}");
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Ask notification permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(
  firebaseMessagingBackgroundHandler,
);

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

     const AndroidNotificationChannel channel =
    AndroidNotificationChannel(
  'mydrive_channel',
  'MyDrive Notifications',
  description: 'Notifications for MyDrive',
  importance: Importance.high,
);

await _localNotifications
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);

    await _localNotifications.initialize(settings);

   

    // Print FCM Token
    final token = await _messaging.getToken();
    if (token != null) {
  print("FCM Token: $token");

  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    await FirestoreService().updateFcmToken(
      user.uid,
      token,
    );
  }
}

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((message) {
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
  print("Notification opened");
});

_messaging.onTokenRefresh.listen((newToken) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    await FirestoreService().updateFcmToken(
      user.uid,
      newToken,
    );
  }

  print("FCM Token Refreshed: $newToken");
});
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'mydrive_channel',
      'MyDrive Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
    );
  }
}