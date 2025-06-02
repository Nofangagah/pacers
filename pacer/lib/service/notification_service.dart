import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> initLocalNotification() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _local.initialize(initSettings);
  }

  static Future<void> showLocal(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pacer_channel',
      'Pacer Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _local.show(
      0,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }

  Future<void> initNotification(int userId) async {
    await _fcm.requestPermission();
    final token = await _fcm.getToken();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (token != null &&  accessToken != null) {
      await http.patch(
        Uri.parse('http://192.168.100.32:3000/api/user/deviceTokenUpdate/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: '{"device_token": "$token"}',
      );
      await prefs.setString('lastDeviceToken', token);
    }

    FirebaseMessaging.onMessage.listen((message) {
      print("🔔 Foreground message: ${message.notification?.title}");
      showLocal(message); // ✅ tampilkan notifikasi saat app dibuka
    });
  }
}
