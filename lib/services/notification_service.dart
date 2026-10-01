// lib/services/notification_service.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import '../core/app_strings.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // Motivation quotes live in AppStrings as push_quote_1 .. push_quote_10
  // (English + Roman Urdu). Each day gets a DIFFERENT quote.
  static const int _quoteCount = 10;
  static const int _motivationBaseId = 100; // IDs 100 .. 100+_motivationDays-1
  static const int _motivationDays = 30;    // pre-schedule 30 days ahead

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
      title: AppStrings.get('push_morning_title'),
      body: AppStrings.get('push_morning_body'),
      hour: 7,
      minute: 0,
      channelId: 'workout_reminder',
      channelName: AppStrings.get('push_workout_channel'),
      channelDescription: AppStrings.get('push_workout_channel_desc'),
    );

    // 2. Water Reminders - Every 2 hours (9 AM to 9 PM)
    await _scheduleWaterReminders();

    // 3. Lunch Calorie Log - 2:00 PM
    await _scheduleDailyNotification(
      id: 20,
      title: AppStrings.get('push_lunch_title'),
      body: AppStrings.get('push_lunch_body'),
      hour: 14,
      minute: 0,
      channelId: 'calorie_reminder',
      channelName: AppStrings.get('push_calorie_channel'),
      channelDescription: AppStrings.get('push_calorie_channel_desc'),
    );

    // 4. Daily Motivation - 6:00 PM
    await _scheduleMotivationNotifications(hour: 18, minute: 0);

    // 5. Evening Calorie Reminder - 8:00 PM
    await _scheduleDailyNotification(
      id: 22,
      title: AppStrings.get('push_evening_title'),
      body: AppStrings.get('push_evening_body'),
      hour: 20,
      minute: 0,
      channelId: 'calorie_reminder',
      channelName: AppStrings.get('push_calorie_channel'),
      channelDescription: AppStrings.get('push_calorie_channel_desc'),
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
        title: AppStrings.get('push_water_title'),
        body: AppStrings.get('push_water_body'),
        hour: waterTimes[i],
        minute: 0,
        channelId: 'water_reminder',
        channelName: AppStrings.get('push_water_channel'),
        channelDescription: AppStrings.get('push_water_channel_desc'),
      );
    }
  }

  // ============ SCHEDULE MOTIVATION (NEW QUOTE EVERY DAY) ============
  Future<void> _scheduleMotivationNotifications({
    required int hour,
    required int minute,
  }) async {
    // Random starting point so users don't always begin with quote #1,
    // then walk through all quotes in order (no repeats until all 10 are used).
    final start = Random().nextInt(_quoteCount);

    for (int i = 0; i < _motivationDays; i++) {
      final quoteNo = ((start + i) % _quoteCount) + 1;
      await _scheduleDailyNotification(
        id: _motivationBaseId + i,
        title: AppStrings.get('push_motivation_title'),
        body: AppStrings.get('push_quote_$quoteNo'),
        hour: hour,
        minute: minute,
        channelId: 'motivation',
        channelName: AppStrings.get('push_motivation_channel'),
        channelDescription: AppStrings.get('push_motivation_channel_desc'),
        repeatDaily: false,
        dayOffset: i,
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
    bool repeatDaily = true,
    int dayOffset = 0,
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

      if (repeatDaily) {
        // If time has passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      } else {
        // One-off notification on a specific day (today + dayOffset)
        scheduledDate = scheduledDate.add(Duration(days: dayOffset));
        if (scheduledDate.isBefore(now)) return; // today's slot already passed
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
        matchDateTimeComponents:
        repeatDaily ? DateTimeComponents.time : null, // Repeat daily or one-off
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
        channelName: AppStrings.get('push_instant_channel'),
        channelDescription: AppStrings.get('push_instant_channel_desc'),
      ),
    );
  }

  // ============ SHOW GOAL ACHIEVED NOTIFICATION ============
  Future<void> showGoalAchievedNotification(String goalName) async {
    await showInstantNotification(
      title: AppStrings.get('push_goal_title'),
      body: AppStrings.get('push_goal_body', params: {'goal': goalName}),
    );
  }

  // ============ SHOW WORKOUT COMPLETED NOTIFICATION ============
  Future<void> showWorkoutCompletedNotification() async {
    await showInstantNotification(
      title: AppStrings.get('push_done_title'),
      body: AppStrings.get('push_done_body'),
    );
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
        title: AppStrings.get('push_morning_title'),
        body: AppStrings.get('push_morning_body'),
        hour: workoutHour,
        minute: workoutMinute,
        channelId: 'workout_reminder',
        channelName: AppStrings.get('push_workout_channel'),
        channelDescription: AppStrings.get('push_workout_channel_desc'),
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
        title: AppStrings.get('push_lunch_title'),
        body: AppStrings.get('push_lunch_body'),
        hour: lunchHour,
        minute: lunchMinute,
        channelId: 'calorie_reminder',
        channelName: AppStrings.get('push_calorie_channel'),
        channelDescription: AppStrings.get('push_calorie_channel_desc'),
      );
    }

    // 4. Motivation
    if (motivationEnabled) {
      await _scheduleMotivationNotifications(
        hour: motivationHour,
        minute: motivationMinute,
      );
    }

    // 5. Evening Reminder
    if (eveningEnabled) {
      await _scheduleDailyNotification(
        id: 22,
        title: AppStrings.get('push_evening_title'),
        body: AppStrings.get('push_evening_body'),
        hour: eveningHour,
        minute: eveningMinute,
        channelId: 'calorie_reminder',
        channelName: AppStrings.get('push_calorie_channel'),
        channelDescription: AppStrings.get('push_calorie_channel_desc'),
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
        title: AppStrings.get('push_water_title'),
        body: AppStrings.get('push_water_body'),
        hour: hour,
        minute: 0,
        channelId: 'water_reminder',
        channelName: AppStrings.get('push_water_channel'),
        channelDescription: AppStrings.get('push_water_channel_desc'),
      );
    }
  }
}