// lib/screens/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/fitgenie_theme.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final String userId;

  const NotificationSettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  bool _isSaving = false;

  // Notification Settings
  bool _workoutEnabled = true;
  TimeOfDay _workoutTime = const TimeOfDay(hour: 7, minute: 0);

  bool _waterEnabled = true;
  int _waterIntervalHours = 2;

  bool _lunchEnabled = true;
  TimeOfDay _lunchTime = const TimeOfDay(hour: 14, minute: 0);

  bool _motivationEnabled = true;
  TimeOfDay _motivationTime = const TimeOfDay(hour: 18, minute: 0);

  bool _eveningEnabled = true;
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ============ LOAD SETTINGS FROM FIRESTORE ============
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final doc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _workoutEnabled = data['workoutEnabled'] ?? true;
          _workoutTime = _parseTime(data['workoutTime']) ?? const TimeOfDay(hour: 7, minute: 0);

          _waterEnabled = data['waterEnabled'] ?? true;
          _waterIntervalHours = data['waterIntervalHours'] ?? 2;

          _lunchEnabled = data['lunchEnabled'] ?? true;
          _lunchTime = _parseTime(data['lunchTime']) ?? const TimeOfDay(hour: 14, minute: 0);

          _motivationEnabled = data['motivationEnabled'] ?? true;
          _motivationTime = _parseTime(data['motivationTime']) ?? const TimeOfDay(hour: 18, minute: 0);

          _eveningEnabled = data['eveningEnabled'] ?? true;
          _eveningTime = _parseTime(data['eveningTime']) ?? const TimeOfDay(hour: 20, minute: 0);
        });
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }

    setState(() => _isLoading = false);
  }

  // ============ PARSE TIME STRING TO TIMEOFDAY ============
  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  // ============ FORMAT TIMEOFDAY TO STRING ============
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ============ FORMAT TIME FOR DISPLAY ============
  String _formatTimeDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // ============ SAVE SETTINGS TO FIRESTORE ============
  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('settings')
          .doc('notifications')
          .set({
        'workoutEnabled': _workoutEnabled,
        'workoutTime': _formatTime(_workoutTime),
        'waterEnabled': _waterEnabled,
        'waterIntervalHours': _waterIntervalHours,
        'lunchEnabled': _lunchEnabled,
        'lunchTime': _formatTime(_lunchTime),
        'motivationEnabled': _motivationEnabled,
        'motivationTime': _formatTime(_motivationTime),
        'eveningEnabled': _eveningEnabled,
        'eveningTime': _formatTime(_eveningTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reschedule notifications with new settings
      await _notificationService.scheduleCustomNotifications(
        workoutEnabled: _workoutEnabled,
        workoutHour: _workoutTime.hour,
        workoutMinute: _workoutTime.minute,
        waterEnabled: _waterEnabled,
        waterIntervalHours: _waterIntervalHours,
        lunchEnabled: _lunchEnabled,
        lunchHour: _lunchTime.hour,
        lunchMinute: _lunchTime.minute,
        motivationEnabled: _motivationEnabled,
        motivationHour: _motivationTime.hour,
        motivationMinute: _motivationTime.minute,
        eveningEnabled: _eveningEnabled,
        eveningHour: _eveningTime.hour,
        eveningMinute: _eveningTime.minute,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification settings saved!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  // ============ PICK TIME ============
  Future<void> _pickTime(TimeOfDay currentTime, Function(TimeOfDay) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: FitGenieTheme.primary,
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onPicked(picked);
    }
  }

  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: FitGenieTheme.primary),
            onPressed: () async {
              await _notificationService.showInstantNotification(
                title: '🔔 Test Notification',
                body: 'Notifications are working perfectly!',
              );
            },
            tooltip: 'Test Notification',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FitGenieTheme.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customize your reminders',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Workout Reminder
            _buildNotificationCard(
              icon: Icons.fitness_center,
              iconColor: Colors.orange,
              title: 'Workout Reminder',
              subtitle: 'Daily morning workout reminder',
              enabled: _workoutEnabled,
              onToggle: (val) => setState(() => _workoutEnabled = val),
              time: _workoutTime,
              onTimeTap: () => _pickTime(_workoutTime, (t) => setState(() => _workoutTime = t)),
            ),
            const SizedBox(height: 12),

            // Water Reminder
            _buildWaterReminderCard(),
            const SizedBox(height: 12),

            // Lunch Reminder
            _buildNotificationCard(
              icon: Icons.restaurant,
              iconColor: Colors.green,
              title: 'Lunch Reminder',
              subtitle: 'Remind to log lunch calories',
              enabled: _lunchEnabled,
              onToggle: (val) => setState(() => _lunchEnabled = val),
              time: _lunchTime,
              onTimeTap: () => _pickTime(_lunchTime, (t) => setState(() => _lunchTime = t)),
            ),
            const SizedBox(height: 12),

            // Motivation
            _buildNotificationCard(
              icon: Icons.local_fire_department,
              iconColor: Colors.red,
              title: 'Daily Motivation',
              subtitle: 'Get inspired with motivational quotes',
              enabled: _motivationEnabled,
              onToggle: (val) => setState(() => _motivationEnabled = val),
              time: _motivationTime,
              onTimeTap: () => _pickTime(_motivationTime, (t) => setState(() => _motivationTime = t)),
            ),
            const SizedBox(height: 12),

            // Evening Reminder
            _buildNotificationCard(
              icon: Icons.nightlight_round,
              iconColor: Colors.purple,
              title: 'Evening Reminder',
              subtitle: 'Remind to complete daily tracking',
              enabled: _eveningEnabled,
              onToggle: (val) => setState(() => _eveningEnabled = val),
              time: _eveningTime,
              onTimeTap: () => _pickTime(_eveningTime, (t) => setState(() => _eveningTime = t)),
            ),
            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FitGenieTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  '💾 Save Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============ NOTIFICATION CARD WIDGET ============
  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool enabled,
    required Function(bool) onToggle,
    required TimeOfDay time,
    required VoidCallback onTimeTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? FitGenieTheme.primary.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: FitGenieTheme.primary,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onTimeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: FitGenieTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '⏰ Time',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      _formatTimeDisplay(time),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: FitGenieTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ WATER REMINDER CARD ============
  Widget _buildWaterReminderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _waterEnabled ? FitGenieTheme.primary.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.water_drop, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Water Reminders',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Stay hydrated throughout the day',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _waterEnabled,
                onChanged: (val) => setState(() => _waterEnabled = val),
                activeColor: FitGenieTheme.primary,
              ),
            ],
          ),
          if (_waterEnabled) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: FitGenieTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🔄 Remind every',
                    style: TextStyle(color: Colors.grey),
                  ),
                  DropdownButton<int>(
                    value: _waterIntervalHours,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: FitGenieTheme.primary,
                    ),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 hour')),
                      DropdownMenuItem(value: 2, child: Text('2 hours')),
                      DropdownMenuItem(value: 3, child: Text('3 hours')),
                      DropdownMenuItem(value: 4, child: Text('4 hours')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _waterIntervalHours = val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}