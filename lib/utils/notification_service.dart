import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // [නිවැරදි කිරීම] මෙහි නම settings: විය යුතුමයි
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> showMonthlySummary(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'monthly_summary_channel',
      'Monthly Summary',
      channelDescription: 'Shows monthly cash flow summary',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // [නිවැරදි කිරීම] id, title, body සියල්ල Named Arguments විය යුතුයි
    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}