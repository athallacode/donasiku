import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'dart:io';

class AppNotificationService {
  static final AppNotificationService _instance = AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String? pendingPayload;

  static const String channelId = 'donasiku_channel';
  static const String channelName = 'Donasiku Notifications';
  static const String channelDescription = 'Umpan balik instan dan pengingat Donasiku';

  Future<void> initialize() async {
    // Initialize timezones for scheduled notifications
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification clicked: ${details.payload}');
        if (details.payload != null && details.payload!.isNotEmpty) {
          _handleNotificationClick(details.payload!);
        }
      },
    );

    // Check if launched from terminated state
    try {
      final NotificationAppLaunchDetails? launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final NotificationResponse? response = launchDetails.notificationResponse;
        if (response != null && response.payload != null && response.payload!.isNotEmpty) {
          pendingPayload = response.payload;
        }
      }
    } catch (e) {
      debugPrint('Error getting notification launch details: $e');
    }

    // Create high importance channel for Android
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ));
    }
  }

  void _handleNotificationClick(String payload) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final authService = AuthService();
      if (authService.currentUser != null) {
        // Safe navigation if user is logged in
        navigatorKey.currentState?.pushNamed(payload);
      }
    }
  }

  /// Request permissions for Android 13+ and iOS
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }

  /// Show an instant notification
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  /// Schedule a daily reminder (e.g., at 9 AM)
  Future<void> scheduleDailyReminder() async {
    await _notificationsPlugin.zonedSchedule(
      999, // Unique ID for reminder
      'Semangat Berbagi! 🌟',
      'Sudahkah Anda mengecek donasi yang bisa dibantu hari ini?',
      _nextInstanceOfNineAM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Pengingat Harian',
          channelDescription: 'Pesan motivasi harian',
          importance: Importance.low,
        ),
      ),
      payload: '/dashboard',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfNineAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
