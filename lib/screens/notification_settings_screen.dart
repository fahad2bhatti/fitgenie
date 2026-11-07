// lib/screens/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/fg_card.dart';
import '../core/app_strings.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final String userId;

  const NotificationSettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
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

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _workoutEnabled = data['workoutEnabled'] ?? true;
          _workoutTime = _parseTime(data['workoutTime']) ??
              const TimeOfDay(hour: 7, minute: 0);

          _waterEnabled = data['waterEnabled'] ?? true;
          _waterIntervalHours = data['waterIntervalHours'] ?? 2;

          _lunchEnabled = data['lunchEnabled'] ?? true;
          _lunchTime = _parseTime(data['lunchTime']) ??
              const TimeOfDay(hour: 14, minute: 0);

          _motivationEnabled = data['motivationEnabled'] ?? true;
          _motivationTime = _parseTime(data['motivationTime']) ??
              const TimeOfDay(hour: 18, minute: 0);

          _eveningEnabled = data['eveningEnabled'] ?? true;
          _eveningTime = _parseTime(data['eveningTime']) ??
              const TimeOfDay(hour: 20, minute: 0);
        });
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }

    if (!mounted) return;
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

      if (!mounted) return;
      AppSnackbar.showSuccess(context, AppStrings.get('notifications_saved'));
      // Screen band ho rahi hai, is liye yahan setState nahi.
      Navigator.pop(context);
      return;
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        AppStrings.get('notifications_error', params: {'error': e.toString()}),
      );
    }

    if (mounted) setState(() => _isSaving = false);
  }

  // ============ PICK TIME ============
  Future<void> _pickTime(
      TimeOfDay currentTime, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null && mounted) {
      onPicked(picked);
    }
  }

  // ============ BUILD UI ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('notifications_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () async {
              await _notificationService.showInstantNotification(
                title: AppStrings.get('notifications_test'),
                body: AppStrings.get('notifications_test_body'),
              );
            },
            tooltip: AppStrings.get('notifications_test_tooltip'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(FitGenieTheme.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      AppStrings.get('notifications_sub'),
                      style: const TextStyle(
                        color: FitGenieTheme.muted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _buildTimeReminder(
                    titleKey: 'notifications_workout',
                    subtitleKey: 'notifications_workout_sub',
                    enabled: _workoutEnabled,
                    onToggle: (v) => setState(() => _workoutEnabled = v),
                    time: _workoutTime,
                    onPicked: (t) => setState(() => _workoutTime = t),
                  ),
                  _buildWaterReminder(),
                  _buildTimeReminder(
                    titleKey: 'notifications_lunch',
                    subtitleKey: 'notifications_lunch_sub',
                    enabled: _lunchEnabled,
                    onToggle: (v) => setState(() => _lunchEnabled = v),
                    time: _lunchTime,
                    onPicked: (t) => setState(() => _lunchTime = t),
                  ),
                  _buildTimeReminder(
                    titleKey: 'notifications_motivation',
                    subtitleKey: 'notifications_motivation_sub',
                    enabled: _motivationEnabled,
                    onToggle: (v) => setState(() => _motivationEnabled = v),
                    time: _motivationTime,
                    onPicked: (t) => setState(() => _motivationTime = t),
                  ),
                  _buildTimeReminder(
                    titleKey: 'notifications_evening',
                    subtitleKey: 'notifications_evening_sub',
                    enabled: _eveningEnabled,
                    onToggle: (v) => setState(() => _eveningEnabled = v),
                    time: _eveningTime,
                    onPicked: (t) => setState(() => _eveningTime = t),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: FitGenieTheme.text,
                            ),
                          )
                        : Text(
                            AppStrings.get('notifications_save').toUpperCase(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // ============ TIME REMINDER (workout, lunch, motivation, evening) ============
  Widget _buildTimeReminder({
    required String titleKey,
    required String subtitleKey,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onPicked,
  }) {
    return _ReminderCard(
      title: AppStrings.get(titleKey),
      subtitle: AppStrings.get(subtitleKey),
      enabled: enabled,
      onToggle: onToggle,
      detail: _DetailRow(
        label: AppStrings.get('notifications_time'),
        onTap: () => _pickTime(time, onPicked),
        trailing: Text(
          MaterialLocalizations.of(context).formatTimeOfDay(time),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: FitGenieTheme.primary,
          ),
        ),
      ),
    );
  }

  // ============ WATER REMINDER (interval dropdown) ============
  Widget _buildWaterReminder() {
    return _ReminderCard(
      title: AppStrings.get('notifications_water'),
      subtitle: AppStrings.get('notifications_water_sub'),
      enabled: _waterEnabled,
      onToggle: (v) => setState(() => _waterEnabled = v),
      detail: _DetailRow(
        label: AppStrings.get('notifications_remind_every'),
        trailing: DropdownButton<int>(
          value: _waterIntervalHours,
          dropdownColor: FitGenieTheme.card,
          isDense: true,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: FitGenieTheme.primary,
          ),
          underline: const SizedBox.shrink(),
          items: [1, 2, 3, 4]
              .map(
                (h) => DropdownMenuItem<int>(
                  value: h,
                  child: Text(
                    h == 1
                        ? AppStrings.get('notifications_hour')
                        : AppStrings.get('notifications_hours',
                            params: {'count': '$h'}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _waterIntervalHours = val);
            }
          },
        ),
      ),
    );
  }
}

// ============ REMINDER CARD ============
class _ReminderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Widget detail;

  const _ReminderCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return FGCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: FitGenieTheme.muted,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            detail,
          ],
        ],
      ),
    );
  }
}

// ============ DETAIL ROW (label left, value right) ============
class _DetailRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: FitGenieTheme.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}
