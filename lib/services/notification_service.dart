// lib/services/notification_service.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // Motivation Quotes
  final List<String> _motivationQuotes = [
    "The only bad workout is the one that didn't happen! 💪",
    "Your body can do it. It's your mind you need to convince! 🧠",
    "Sore today, strong tomorrow! 🔥",
    "Don't stop when you're tired. Stop when you're done! 🏆",
    "Fitness is not about being better than someone else. It's about being better than you used to be! ⭐",
    "The pain you feel today will be the strength you feel tomorrow! 💥",
    "Push yourself because no one else is going to do it for you! 🚀",
    "Success starts with self-discipline! 🎯",
    "Make yourself proud! 👏",
    "Believe in yourself and all that you are! ✨",
  ];

  // ============ INITIALIZE ============
  Future<void> initialize() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  // ============ REQUEST PERMISSIONS ============
  Future<void> _requestPermissions() async {
    // Request notification permission (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Request exact alarm permission (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // ============ ON NOTIFICATION TAPPED ============
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to specific screen if needed
  }

  // ============ NOTIFICATION DETAILS ============
  NotificationDetails _getNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF00E676),
        enableLights: true,
        enableVibration: true,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ============ SCHEDULE ALL DAILY NOTIFICATIONS ============
  Future<void> scheduleAllDailyNotifications() async {
    // Cancel existing notifications first
    await cancelAllNotifications();

    // 1. Morning Workout Reminder - 7:00 AM
    await _scheduleDailyNotification(
      id: 1,
      title: '💪 Morning Workout Time!',
      body: 'Good morning! Time to crush your workout!',
      hour: 7,
      minute: 0,
      channelId: 'workout_reminder',
      channelName: 'Workout Reminders',
      channelDescription: 'Daily workout reminders',
    );

    // 2. Water Reminders - Every 2 hours (9 AM to 9 PM)
    await _scheduleWaterReminders();

    // 3. Lunch Calorie Log - 2:00 PM
    await _scheduleDailyNotification(
      id: 20,
      title: '🍽️ Log Your Lunch!',
      body: "Don't forget to log your lunch calories!",
      hour: 14,
      minute: 0,
      channelId: 'calorie_reminder',
      channelName: 'Calorie Reminders',
      channelDescription: 'Reminders to log your meals',
    );

    // 4. Daily Motivation - 6:00 PM
    await _scheduleDailyNotification(
      id: 21,
      title: '🔥 Daily Motivation',
      body: _getRandomMotivationQuote(),
      hour: 18,
      minute: 0,
      channelId: 'motivation',
      channelName: 'Daily Motivation',
      channelDescription: 'Daily motivational quotes',
    );

    // 5. Evening Calorie Reminder - 8:00 PM
    await _scheduleDailyNotification(
      id: 22,
      title: '🌙 Evening Check-in',
      body: 'Log your dinner & complete today\'s tracking! 📊',
      hour: 20,
      minute: 0,
      channelId: 'calorie_reminder',
      channelName: 'Calorie Reminders',
      channelDescription: 'Reminders to log your meals',
    );

    debugPrint('✅ All notifications scheduled successfully!');
  }

  // ============ SCHEDULE WATER REMINDERS ============
  Future<void> _scheduleWaterReminders() async {
    // Water reminders every 2 hours: 9 AM, 11 AM, 1 PM, 3 PM, 5 PM, 7 PM, 9 PM
    final waterTimes = [9, 11, 13, 15, 17, 19, 21];

    for (int i = 0; i < waterTimes.length; i++) {
      await _scheduleDailyNotification(
        id: 10 + i, // IDs: 10, 11, 12, 13, 14, 15, 16
        title: '💧 Stay Hydrated!',
        body: 'Time to drink a glass of water!',
        hour: waterTimes[i],
        minute: 0,
        channelId: 'water_reminder',
        channelName: 'Water Reminders',
        channelDescription: 'Reminders to drink water',
      );
    }
  }

  // ============ SCHEDULE DAILY NOTIFICATION ============
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        _getNotificationDetails(
          channelId: channelId,
          channelName: channelName,
          channelDescription: channelDescription,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );

      debugPrint('📅 Scheduled: $title at $hour:$minute');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  // ============ SHOW INSTANT NOTIFICATION ============
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      _getNotificationDetails(
        channelId: 'instant',
        channelName: 'Instant Notifications',
        channelDescription: 'Instant notifications',
      ),
    );
  }

  // ============ SHOW GOAL ACHIEVED NOTIFICATION ============
  Future<void> showGoalAchievedNotification(String goalName) async {
    await showInstantNotification(
      title: '🎉 Goal Achieved!',
      body: 'Congratulations! You completed your $goalName goal!',
    );
  }

  // ============ SHOW WORKOUT COMPLETED NOTIFICATION ============
  Future<void> showWorkoutCompletedNotification() async {
    await showInstantNotification(
      title: '💪 Workout Complete!',
      body: 'Great job! You crushed your workout today!',
    );
  }

  // ============ GET RANDOM MOTIVATION QUOTE ============
  String _getRandomMotivationQuote() {
    final random = Random();
    return _motivationQuotes[random.nextInt(_motivationQuotes.length)];
  }

  // ============ CANCEL ALL NOTIFICATIONS ============
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ All notifications cancelled');
  }

  // ============ CANCEL SPECIFIC NOTIFICATION ============
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // ============ CHECK PENDING NOTIFICATIONS ============
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ============ SCHEDULE CUSTOM NOTIFICATIONS ============
  Future<void> scheduleCustomNotifications({
    required bool workoutEnabled,
    required int workoutHour,
    required int workoutMinute,
    required bool waterEnabled,
    required int waterIntervalHours,
    required bool lunchEnabled,
    required int lunchHour,
    required int lunchMinute,
    required bool motivationEnabled,
    required int motivationHour,
    required int motivationMinute,
    required bool eveningEnabled,
    required int eveningHour,
    required int eveningMinute,
  }) async {
    // Cancel all existing notifications first
    await cancelAllNotifications();

    // 1. Workout Reminder
    if (workoutEnabled) {
      await _scheduleDailyNotification(
        id: 1,
        title: '💪 Morning Workout Time!',
        body: 'Good morning! Time to crush your workout!',
        hour: workoutHour,
        minute: workoutMinute,
        channelId: 'workout_reminder',
        channelName: 'Workout Reminders',
        channelDescription: 'Daily workout reminders',
      );
    }

    // 2. Water Reminders
    if (waterEnabled) {
      await _scheduleCustomWaterReminders(waterIntervalHours);
    }

    // 3. Lunch Reminder
    if (lunchEnabled) {
      await _scheduleDailyNotification(
        id: 20,
        title: '🍽️ Log Your Lunch!',
        body: "Don't forget to log your lunch calories!",
        hour: lunchHour,
        minute: lunchMinute,
        channelId: 'calorie_reminder',
        channelName: 'Calorie Reminders',
        channelDescription: 'Reminders to log your meals',
      );
    }

    // 4. Motivation
    if (motivationEnabled) {
      await _scheduleDailyNotification(
        id: 21,
        title: '🔥 Daily Motivation',
        body: _getRandomMotivationQuote(),
        hour: motivationHour,
        minute: motivationMinute,
        channelId: 'motivation',
        channelName: 'Daily Motivation',
        channelDescription: 'Daily motivational quotes',
      );
    }

    // 5. Evening Reminder
    if (eveningEnabled) {
      await _scheduleDailyNotification(
        id: 22,
        title: '🌙 Evening Check-in',
        body: 'Log your dinner & complete today\'s tracking! 📊',
        hour: eveningHour,
        minute: eveningMinute,
        channelId: 'calorie_reminder',
        channelName: 'Calorie Reminders',
        channelDescription: 'Reminders to log your meals',
      );
    }

    debugPrint('✅ Custom notifications scheduled!');
  }

// ============ SCHEDULE CUSTOM WATER REMINDERS ============
  Future<void> _scheduleCustomWaterReminders(int intervalHours) async {
    int id = 10;
    for (int hour = 9; hour <= 21; hour += intervalHours) {
      await _scheduleDailyNotification(
        id: id++,
        title: '💧 Stay Hydrated!',
        body: 'Time to drink a glass of water!',
        hour: hour,
        minute: 0,
        channelId: 'water_reminder',
        channelName: 'Water Reminders',
        channelDescription: 'Reminders to drink water',
      );
    }
  }
}