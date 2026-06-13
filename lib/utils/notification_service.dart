import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io'; // Android ද කියා පරීක්ෂා කිරීමට අලුතින් එක් කළා

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

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // --- අලුත් කොටස: App එක Open කරද්දීම Notification Permission Pop-up එක පෙන්වීම ---
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Android 13+ නම් අවසර ඉල්ලන Pop-up එක තිරයට ගෙන එයි
      await androidImplementation?.requestNotificationsPermission();
    }
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

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}