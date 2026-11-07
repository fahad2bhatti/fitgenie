// lib/screens/profile_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../services/image_service.dart';
import '../services/step_counter_service.dart';
import '../widgets/app_snackbar.dart';
import '../core/app_strings.dart';
import '../widgets/language_selector_dialog.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImageService _imageService = ImageService();
  final StepCounterService _stepService = StepCounterService();

  // User data
  String _name = 'User';
  String _email = '';
  String? _photoBase64;
  String _gender = 'Other';
  int _age = 25;
  double _weight = 70.0;
  double _height = 170.0;
  String _fitnessLevel = 'Intermediate';
  String _goal = 'Build Muscle';

  // Goals
  int _caloriesGoal = 2000;
  int _proteinGoal = 100;
  int _waterGoal = 8;

  // Google Fit Status
  bool _isGoogleFitLoading = false;
  GoogleFitConnectionStatus _googleFitStatus =
      GoogleFitConnectionStatus.disconnected;
  bool _healthConnectAvailable = false;
  bool _activityPermission = false;
  bool _healthAuthorized = false;
  bool _dataAccessible = false;
  int _googleFitSteps = 0;
  String _googleFitError = '';

  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkGoogleFitStatus();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      _email = _auth.currentUser?.email ?? '';

      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();

      if (!mounted) return;

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        setState(() {
          _name = (data['name'] as String?) ?? 'User';
          if (data['email'] != null) _email = data['email'] as String;
          _photoBase64 = data['photoBase64'] as String?;
          _gender = (data['gender'] as String?) ?? 'Other';
          _age = (data['age'] as int?) ?? 25;
          _weight = _toDouble(data['weight']) ?? 70.0;
          _height = _toDouble(data['height']) ?? 170.0;
          _fitnessLevel = (data['fitnessLevel'] as String?) ?? 'Intermediate';
          _goal = (data['goal'] as String?) ?? 'Build Muscle';
        });
      }

      try {
        final goalsDoc = await _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('goals')
            .doc('main')
            .get();

        if (!mounted) return;

        if (goalsDoc.exists && goalsDoc.data() != null) {
          final goals = goalsDoc.data()!;
          setState(() {
            _caloriesGoal = (goals['caloriesGoal'] as int?) ?? 2000;
            _proteinGoal = (goals['proteinGoal'] as int?) ?? 100;
            _waterGoal = (goals['waterGoal'] as int?) ?? 8;
          });
        }
      } catch (e) {
        debugPrint('Goals error: $e');
      }
    } catch (e) {
      debugPrint('Load error: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ???????????????????????????????????????????
  // ? GOOGLE FIT STATUS CHECK
  // ???????????????????????????????????????????
  Future<void> _checkGoogleFitStatus() async {
    if (!mounted) return;
    setState(() => _isGoogleFitLoading = true);

    try {
      final status = await _stepService.checkGoogleFitStatus();

      if (!mounted) return;
      setState(() {
        _googleFitStatus = status.overallStatus;
        _healthConnectAvailable = status.healthConnectAvailable;
        _activityPermission = status.activityPermissionGranted;
        _healthAuthorized = status.healthAuthorized;
        _dataAccessible = status.dataAccessible;
        _googleFitSteps = status.todaySteps;
        _googleFitError = status.errorMessage;
        _isGoogleFitLoading = false;
      });

      debugPrint(status.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _googleFitError = e.toString();
        _isGoogleFitLoading = false;
      });
    }
  }

  Future<void> _connectGoogleFit() async {
    if (!mounted) return;
    setState(() => _isGoogleFitLoading = true);

    try {
      final connected = await _stepService.connectGoogleFit();

      if (!mounted) return;

      if (connected) {
        AppSnackbar.showSuccess(context, AppStrings.get('profile_googlefit_connected'));
      } else {
        AppSnackbar.showError(context, AppStrings.get('profile_connection_failed'));
      }

      await _checkGoogleFitStatus();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showWarning(context, AppStrings.get('profile_generic_error', params: {'error': '$e'}));
      setState(() => _isGoogleFitLoading = false);
    }
  }

  Future<void> _disconnectGoogleFit() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        title: Text(AppStrings.get('profile_gfit_disconnect_title')),
        content: Text(AppStrings.get('profile_gfit_disconnect_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (!mounted) return;
              setState(() => _isGoogleFitLoading = true);

              await _stepService.disconnectGoogleFit();
              if (!mounted) return;
              AppSnackbar.showWarning(
                context,
                AppStrings.get('profile_gfit_disconnected'),
              );

              await _checkGoogleFitStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FitGenieTheme.error,
            ),
            child: Text(
              AppStrings.get('profile_gfit_disconnect_action'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ============ PHOTO METHODS ============

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FitGenieTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FitGenieTheme.radiusXL)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.get('profile_photo').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(AppStrings.get('profile_take')),
                subtitle: Text(
                  AppStrings.get('profile_take_sub'),
                  style:
                      const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
                ),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(AppStrings.get('profile_gallery')),
                subtitle: Text(
                  AppStrings.get('profile_gallery_sub'),
                  style:
                      const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
                ),
              ),
              if (_photoBase64 != null)
                ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: FitGenieTheme.error),
                  title: Text(
                    AppStrings.get('profile_remove'),
                    style: const TextStyle(color: FitGenieTheme.error),
                  ),
                  subtitle: Text(
                    AppStrings.get('profile_remove_sub'),
                    style: const TextStyle(
                        color: FitGenieTheme.muted, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final image = await _imageService.pickImage(source: source);
    if (!mounted) return;
    if (image == null) {
      AppSnackbar.showWarning(context, AppStrings.get('profile_no_image_selected'));
      return;
    }

    setState(() => _isUploadingPhoto = true);

    final result = await _imageService.uploadProfilePhoto(
      userId: widget.userId,
      imageFile: image,
    );

    if (!mounted) return;
    setState(() {
      _isUploadingPhoto = false;
      if (result != null) {
        _photoBase64 = result;
        AppSnackbar.showSuccess(context, AppStrings.get('profile_photo_updated'));
      } else {
        AppSnackbar.showError(context, AppStrings.get('profile_upload_failed'));
      }
    });
  }

  Future<void> _removePhoto() async {
    setState(() => _isUploadingPhoto = true);

    final success = await _imageService.deleteProfilePhoto(widget.userId);

    if (!mounted) return;
    setState(() {
      _isUploadingPhoto = false;
      if (success) {
        _photoBase64 = null;
        AppSnackbar.showWarning(context, AppStrings.get('profile_photo_removed'));
      }
    });
  }

  // ============ BUILD UI ============

  @override
  Widget build(BuildContext context) {
    // profile-v2
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FitGenieTheme.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: 6),
          _buildProfileHeader(),
          const SizedBox(height: 12),
          _buildGoalsCard(),
          const SizedBox(height: 12),
          _buildGoogleFitStatusCard(),
          const SizedBox(height: 12),
          _buildSettingsCard(),
          const SizedBox(height: 20),
          _buildLogoutButton(),
          const SizedBox(height: 4),
          _buildDeleteAccountButton(),
          const SizedBox(height: 16),
          Text(
            AppStrings.get('profile_version'),
            style: const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============ PROFILE HEADER ============
  Widget _buildProfileHeader() {
    final t = Theme.of(context).textTheme;
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'U';

    Widget stat(String value, String unit) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: t.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(unit.toUpperCase(), style: t.labelSmall),
            ],
          ),
        );

    Widget vline() =>
        Container(height: 36, width: 1, color: FitGenieTheme.border);

    return FGCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -6,
            top: -34,
            child: Text(
              initial,
              style: t.displayLarge?.copyWith(
                fontSize: 150,
                color: FitGenieTheme.text.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: FitGenieTheme.border, width: 2),
                          ),
                          child: ClipOval(child: _buildAvatarContent()),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: FitGenieTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: FitGenieTheme.card, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: FitGenieTheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _showEditProfileDialog,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
                            style: t.headlineMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _email,
                            style: const TextStyle(
                                color: FitGenieTheme.muted, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_displayValue(_fitnessLevel)} · ${_displayValue(_goal)}'.toUpperCase(),
                            style: t.labelSmall
                                ?.copyWith(color: FitGenieTheme.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 20, color: FitGenieTheme.muted),
                    onPressed: _showEditProfileDialog,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),
              InkWell(
                onTap: _showEditBodyStatsDialog,
                child: Row(
                  children: [
                    stat(_weight.toStringAsFixed(1), 'kg'),
                    vline(),
                    stat(_height.toStringAsFixed(0), 'cm'),
                    vline(),
                    stat('$_age', 'yrs'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_isUploadingPhoto) {
      return const Center(
        child: CircularProgressIndicator(
          color: FitGenieTheme.primary,
          strokeWidth: 3,
        ),
      );
    }

    if (_photoBase64 != null) {
      try {
        final base64Data = _photoBase64!.split(',').last;
        final bytes = base64Decode(base64Data);

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 110,
          height: 110,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(),
        );
      } catch (e) {
        debugPrint('Image decode error: $e');
        return _buildInitialAvatar();
      }
    }

    return _buildInitialAvatar();
  }

  Widget _buildInitialAvatar() {
    return Container(
      color: FitGenieTheme.primary.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.bold,
            color: FitGenieTheme.primary,
          ),
        ),
      ),
    );
  }

  // ============ BODY STATS ============

  // ============ GOALS ============
  Widget _buildGoalsCard() {
    final t = Theme.of(context).textTheme;

    Widget row(String label, String value, String unit) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: FitGenieTheme.textSecondary, fontSize: 14),
                ),
              ),
              Text(value, style: t.headlineSmall),
              const SizedBox(width: 4),
              Text(unit,
                  style: const TextStyle(
                      color: FitGenieTheme.muted, fontSize: 12)),
            ],
          ),
        );

    return FGCard(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                AppStrings.get('profile_goals').toUpperCase(),
                style: t.labelSmall,
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined,
                    size: 20, color: FitGenieTheme.muted),
                onPressed: _showEditGoalsDialog,
              ),
            ],
          ),
          row(AppStrings.get('calories_field_calories'), '$_caloriesGoal',
            AppStrings.get('label_kcal')),
          const Divider(height: 1),
          row(AppStrings.get('calories_field_protein'), '$_proteinGoal', 'g'),
          const Divider(height: 1),
          row(AppStrings.get('label_water'), '$_waterGoal',
            AppStrings.get('label_glasses')),
        ],
      ),
    );
  }

  // ???????????????????????????????????????????
  // ?? GOOGLE FIT STATUS CARD
  // ???????????????????????????????????????????
  Widget _buildGoogleFitStatusCard() {
    final t = Theme.of(context).textTheme;
    final bool isConnected =
        _googleFitStatus == GoogleFitConnectionStatus.connected ||
            _googleFitStatus == GoogleFitConnectionStatus.connectedNoData;
    final Color statusColor = _getStatusColor(_googleFitStatus);

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppStrings.get('dashboard_google_fit').toUpperCase(),
                  style: t.labelSmall),
              const Spacer(),
              if (_isGoogleFitLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FitGenieTheme.muted,
                  ),
                )
              else
                InkWell(
                  onTap: _checkGoogleFitStatus,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.refresh_rounded,
                        size: 18, color: FitGenieTheme.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusText(_googleFitStatus),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (isConnected) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$_googleFitSteps', style: t.displaySmall),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    AppStrings.get('profile_today_steps'),
                    style: const TextStyle(
                        color: FitGenieTheme.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (_googleFitError.isNotEmpty && !isConnected) ...[
            const SizedBox(height: 10),
            Text(
              _googleFitError,
              style:
                  const TextStyle(color: FitGenieTheme.warning, fontSize: 12),
            ),
          ],
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              iconColor: FitGenieTheme.muted,
              collapsedIconColor: FitGenieTheme.muted,
              title: Text(
                AppStrings.get('profile_details'),
                style:
                    TextStyle(color: FitGenieTheme.textSecondary, fontSize: 13),
              ),
              children: [
                _buildStatusCheckRow(AppStrings.get('profile_gfit_health_connect'),
                    _healthConnectAvailable, Icons.phone_android),
                _buildStatusCheckRow(AppStrings.get('profile_gfit_activity_permission'), _activityPermission,
                    Icons.directions_walk),
                _buildStatusCheckRow(
                    AppStrings.get('profile_gfit_authorized'), _healthAuthorized, Icons.security),
                _buildStatusCheckRow(
                    AppStrings.get('profile_gfit_data_syncing'), _dataAccessible, Icons.sync),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: isConnected
                ? OutlinedButton(
                    onPressed:
                        _isGoogleFitLoading ? null : _disconnectGoogleFit,
                    child: Text(AppStrings.get('profile_disconnect_googlefit')),
                  )
                : ElevatedButton(
                    onPressed: _isGoogleFitLoading ? null : _connectGoogleFit,
                    child: Text(AppStrings.get('profile_connect_googlefit')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCheckRow(String label, bool isOk, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: FitGenieTheme.textSecondary, fontSize: 13),
            ),
          ),
          Icon(
            isOk ? Icons.check_rounded : Icons.close_rounded,
            color: isOk ? FitGenieTheme.success : FitGenieTheme.error,
            size: 18,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(GoogleFitConnectionStatus status) {
    switch (status) {
      case GoogleFitConnectionStatus.connected:
        return FitGenieTheme.success;
      case GoogleFitConnectionStatus.connectedNoData:
        return FitGenieTheme.warning;
      case GoogleFitConnectionStatus.connecting:
        return FitGenieTheme.info;
      case GoogleFitConnectionStatus.notAuthorized:
        return FitGenieTheme.warning;
      case GoogleFitConnectionStatus.permissionDenied:
        return FitGenieTheme.error;
      case GoogleFitConnectionStatus.unavailable:
        return FitGenieTheme.muted;
      case GoogleFitConnectionStatus.disconnected:
        return FitGenieTheme.muted;
      case GoogleFitConnectionStatus.error:
        return FitGenieTheme.error;
    }
  }

  String _getStatusText(GoogleFitConnectionStatus status) {
    switch (status) {
      case GoogleFitConnectionStatus.connected:
        return AppStrings.get('profile_gfit_status_connected');
      case GoogleFitConnectionStatus.connectedNoData:
        return AppStrings.get('profile_gfit_status_connected_no_data');
      case GoogleFitConnectionStatus.connecting:
        return AppStrings.get('profile_gfit_status_connecting');
      case GoogleFitConnectionStatus.notAuthorized:
        return AppStrings.get('profile_gfit_status_not_authorized');
      case GoogleFitConnectionStatus.permissionDenied:
        return AppStrings.get('profile_gfit_status_permission_denied');
      case GoogleFitConnectionStatus.unavailable:
        return AppStrings.get('profile_gfit_status_unavailable');
      case GoogleFitConnectionStatus.disconnected:
        return AppStrings.get('profile_gfit_status_disconnected');
      case GoogleFitConnectionStatus.error:
        return AppStrings.get('profile_gfit_status_error');
    }
  }

  // ============ SETTINGS ============
  Widget _buildSettingsCard() {
    final t = Theme.of(context).textTheme;
    return FGCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.get('profile_settings').toUpperCase(),
                style: t.labelSmall,
              ),
            ),
          ),
          _settingsRow(
            AppStrings.get('profile_notifications'),
            AppStrings.get('profile_customize_reminders'),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationSettingsScreen(userId: widget.userId),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _settingsRow(
            AppStrings.get('profile_language'),
            AppStrings.get('profile_language_sub'),
            () => LanguageSelectorDialog.show(context),
          ),
          const Divider(height: 1),
          _settingsRow(
            AppStrings.get('profile_about'),
            AppStrings.get('profile_app_info'),
            _showAboutDialog,
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: FitGenieTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: FitGenieTheme.muted),
          ],
        ),
      ),
    );
  }

  // ============ LOGOUT BUTTON ============
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _showLogoutConfirmation,
        child: Text(AppStrings.get('profile_logout')),
      ),
    );
  }

  // ============ DELETE ACCOUNT BUTTON ============
  Widget _buildDeleteAccountButton() {
    return TextButton(
      onPressed: _showDeleteAccountDialog,
      child: Text(
        AppStrings.get('profile_delete'),
        style: TextStyle(
          color: FitGenieTheme.error.withValues(alpha: 0.85),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============ DELETE ACCOUNT DIALOG ============
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        title: Row(
          children: [
            const Icon(Icons.warning, color: FitGenieTheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.get('profile_delete_confirm_title'),
                style: const TextStyle(color: FitGenieTheme.error),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          AppStrings.get('profile_delete_account_warning'),
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FitGenieTheme.error,
            ),
            child: Text(
              AppStrings.get('profile_delete_forever'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ============ DELETE ACCOUNT LOGIC ============
  static const List<String> _userSubcollections = [
    'goals',
    'weightLogs',
    'dailyLogs',
    'workouts',
    'customWorkouts',
    'settings',
    'usage',
    'savedMeals',
    'recentFoods',
    'aiChats',
  ];

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    while (true) {
      final snap = await ref.limit(300).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Future<String?> _askPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        title: Text(AppStrings.get('profile_confirm_password')),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(hintText: AppStrings.get('profile_enter_password')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(AppStrings.get('profile_confirm')),
          ),
        ],
      ),
    );
  }

  Future<bool> _reauthenticate(User user) async {
    final providers = user.providerData.map((p) => p.providerId).toList();
    try {
      if (providers.contains('google.com')) {
        await user.reauthenticateWithProvider(GoogleAuthProvider());
        return true;
      }
      if (providers.contains('password') && user.email != null) {
        final pw = await _askPassword();
        if (pw == null || pw.isEmpty) return false;
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: pw,
        );
        await user.reauthenticateWithCredential(cred);
        return true;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Reauth error: ${e.code}');
      if (mounted) {
        AppSnackbar.showError(
          context,
          AppStrings.get('profile_verification_failed'),
        );
      }
      return false;
    }
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Re-authenticate FIRST (before touching any data)
    final verified = await _reauthenticate(user);
    if (!verified || !mounted) return;

    // 2. Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        content: Row(
          children: [
            const CircularProgressIndicator(color: FitGenieTheme.error),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppStrings.get('profile_deleting'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      // dailyLogs/{date}/entries (nested subcollection)
      final logs = await userRef.collection('dailyLogs').get();
      for (final d in logs.docs) {
        await _deleteCollection(d.reference.collection('entries'));
      }

      for (final name in _userSubcollections) {
        await _deleteCollection(userRef.collection(name));
      }

      await userRef.delete();
      await user.delete();

      if (!mounted) return;
      // Closes loading dialog and returns to root (auth gate / login)
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('Delete account error: $e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppSnackbar.showError(
          context,
          AppStrings.get('profile_delete_account_error'),
        );
      }
    }
  }

  // ============ DIALOGS ============

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    String selectedLevel = _fitnessLevel;
    String selectedGoal = _goal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitGenieTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.get('profile_edit'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(AppStrings.get('field_full_name'), Icons.person),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.get('profile_fitness_level'),
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _buildDropdown(
                  selectedLevel,
                  ['Beginner', 'Intermediate', 'Advanced'],
                  (val) {
                    if (val != null) setModalState(() => selectedLevel = val);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.get('profile_goal'),
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _buildDropdown(
                  selectedGoal,
                  ['Lose Weight', 'Build Muscle', 'Stay Fit', 'Gain Strength'],
                  (val) {
                    if (val != null) setModalState(() => selectedGoal = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateProfile(
                        name: nameController.text,
                        fitnessLevel: selectedLevel,
                        goal: selectedGoal,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FitGenieTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      AppStrings.get('save'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      // ✅ FIX: showModalBottomSheet's Future completes the instant
      // Navigator.pop() is called — but the sheet's closing animation
      // (~250ms) is still rendering the TextField at that point.
      // Disposing nameController immediately crashes mid-animation
      // ("TextEditingController used after being disposed"). Delay
      // disposal until after the close transition has actually finished.
      Future.delayed(const Duration(milliseconds: 300), () {
        nameController.dispose();
      });
    });
  }

  // l10n-r1c: values saved in Firestore stay English, only the label shown is translated
  String _displayValue(String raw) {
    const keys = <String, String>{
      'Male': 'gender_male',
      'Female': 'gender_female',
      'Other': 'gender_other',
      'Beginner': 'level_beginner',
      'Intermediate': 'level_intermediate',
      'Advanced': 'level_advanced',
      'Lose Weight': 'goal_lose_weight',
      'Build Muscle': 'goal_build_muscle',
      'Stay Fit': 'goal_stay_fit',
      'Gain Strength': 'goal_gain_strength',
    };
    final key = keys[raw];
    return key == null ? raw : AppStrings.get(key);
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: FitGenieTheme.card2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: FitGenieTheme.card,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(_displayValue(e),
                      style: const TextStyle(color: Colors.white)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showEditBodyStatsDialog() {
    final wc = TextEditingController(text: _weight.toString());
    final hc = TextEditingController(text: _height.toString());
    final ac = TextEditingController(text: _age.toString());
    String selectedGender = _gender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitGenieTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.get('profile_edit_body_stats'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.get('profile_gender'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              _buildDropdown(selectedGender, ['Male', 'Female', 'Other'], (
                val,
              ) {
                if (val != null) setSheetState(() => selectedGender = val);
              }),
              const SizedBox(height: 12),
              TextField(
                controller: wc,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  AppStrings.get('label_weight_kg'),
                  Icons.monitor_weight,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hc,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(AppStrings.get('profile_height_cm'), Icons.height),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ac,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(AppStrings.get('profile_age'), Icons.cake),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateBodyStats(
                      gender: selectedGender,
                      weight: double.tryParse(wc.text) ?? _weight,
                      height: double.tryParse(hc.text) ?? _height,
                      age: int.tryParse(ac.text) ?? _age,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitGenieTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    AppStrings.get('save'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      wc.dispose();
      hc.dispose();
      ac.dispose();
    });
  }

  void _showEditGoalsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitGenieTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditGoalsSheet(
        initialCalories: _caloriesGoal,
        initialProtein: _proteinGoal,
        initialWater: _waterGoal,
        inputDecoration: _inputDecoration,
        onSave: (calories, protein, water) async {
          await _updateGoals(
            calories: calories,
            protein: protein,
            water: water,
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: FitGenieTheme.primary),
      filled: true,
      fillColor: FitGenieTheme.card2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ============ UPDATE FUNCTIONS ============

  Future<void> _updateProfile({
    required String name,
    required String fitnessLevel,
    required String goal,
  }) async {
    try {
      await _firestore.collection('users').doc(widget.userId).set({
        'name': name,
        'fitnessLevel': fitnessLevel,
        'goal': goal,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _name = name;
        _fitnessLevel = fitnessLevel;
        _goal = goal;
      });
      AppSnackbar.showSuccess(context, AppStrings.get('profile_profile_updated'));
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, AppStrings.get('profile_profile_update_failed'));
    }
  }

  Future<void> _updateBodyStats({
    required String gender,
    required double weight,
    required double height,
    required int age,
  }) async {
    try {
      await _firestore.collection('users').doc(widget.userId).set({
        'gender': gender,
        'weight': weight,
        'height': height,
        'age': age,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ? Keep weightLogs in sync so Progress screen shows the latest weight
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('weightLogs')
          .doc(dateStr)
          .set({
        'weight': weight,
        'date': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _gender = gender;
        _weight = weight;
        _height = height;
        _age = age;
      });
      AppSnackbar.showSuccess(context, AppStrings.get('profile_stats_updated'));
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, AppStrings.get('profile_stats_update_failed'));
    }
  }

  Future<void> _updateGoals({
    required int calories,
    required int protein,
    required int water,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('goals')
          .doc('main')
          .set({
        'caloriesGoal': calories,
        'proteinGoal': protein,
        'waterGoal': water,
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _caloriesGoal = calories;
        _proteinGoal = protein;
        _waterGoal = water;
      });
      AppSnackbar.showSuccess(context, AppStrings.get('profile_goals_updated'));
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, AppStrings.get('profile_goals_update_failed'));
    }
  }

  // ============ LOGOUT ============
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        title: Text(AppStrings.get('profile_logout_confirm_title')),
        content: Text(AppStrings.get('profile_logout_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FitGenieTheme.error,
            ),
            child: Text(
              AppStrings.get('profile_logout_confirm_title'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        title: const Row(
          children: [
            Icon(Icons.fitness_center, color: FitGenieTheme.primary),
            SizedBox(width: 8),
            Text('FitGenie'),
          ],
        ),
        content: Text(AppStrings.get('profile_about_version')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('ok')),
          ),
        ],
      ),
    );
  }
}

class _EditGoalsSheet extends StatefulWidget {
  final int initialCalories;
  final int initialProtein;
  final int initialWater;
  final InputDecoration Function(String, IconData) inputDecoration;
  final Future<void> Function(int calories, int protein, int water) onSave;

  const _EditGoalsSheet({
    required this.initialCalories,
    required this.initialProtein,
    required this.initialWater,
    required this.inputDecoration,
    required this.onSave,
  });

  @override
  State<_EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends State<_EditGoalsSheet> {
  late final TextEditingController cc;
  late final TextEditingController pc;
  late final TextEditingController wc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    cc = TextEditingController(text: widget.initialCalories.toString());
    pc = TextEditingController(text: widget.initialProtein.toString());
    wc = TextEditingController(text: widget.initialWater.toString());
  }

  @override
  void dispose() {
    cc.dispose();
    pc.dispose();
    wc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get('profile_edit_goals'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: cc,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: widget.inputDecoration(
              AppStrings.get('profile_calories_kcal'),
              Icons.local_fire_department,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pc,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: widget.inputDecoration(AppStrings.get('profile_protein_g'), Icons.egg_alt),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: wc,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: widget.inputDecoration(
              AppStrings.get('dashboard_water_glasses'),
              Icons.water_drop,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      await widget.onSave(
                        int.tryParse(cc.text) ?? widget.initialCalories,
                        int.tryParse(pc.text) ?? widget.initialProtein,
                        int.tryParse(wc.text) ?? widget.initialWater,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: FitGenieTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      AppStrings.get('save'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
