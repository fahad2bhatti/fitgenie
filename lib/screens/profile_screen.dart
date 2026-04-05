// lib/screens/profile_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../services/image_service.dart';
import '../services/step_counter_service.dart';
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
  GoogleFitConnectionStatus _googleFitStatus = GoogleFitConnectionStatus.disconnected;
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
    setState(() => _isLoading = true);

    try {
      _email = _auth.currentUser?.email ?? '';

      final userDoc = await _firestore.collection('users').doc(widget.userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        setState(() {
          _name = (data['name'] as String?) ?? 'User';
          if (data['email'] != null) _email = data['email'] as String;
          _photoBase64 = data['photoBase64'] as String?;
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

    setState(() => _isLoading = false);
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ═══════════════════════════════════════════
  // 🔍 GOOGLE FIT STATUS CHECK
  // ═══════════════════════════════════════════
  Future<void> _checkGoogleFitStatus() async {
    setState(() => _isGoogleFitLoading = true);

    try {
      final status = await _stepService.checkGoogleFitStatus();

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
      setState(() {
        _googleFitError = e.toString();
        _isGoogleFitLoading = false;
      });
    }
  }

  Future<void> _connectGoogleFit() async {
    setState(() => _isGoogleFitLoading = true);

    try {
      final connected = await _stepService.connectGoogleFit();

      if (connected) {
        _showSnackbar('✅ Google Fit connected!', Colors.green);
      } else {
        _showSnackbar('❌ Connection failed. Try again.', Colors.red);
      }

      await _checkGoogleFitStatus();
    } catch (e) {
      _showSnackbar('⚠️ Error: $e', Colors.orange);
      setState(() => _isGoogleFitLoading = false);
    }
  }

  Future<void> _disconnectGoogleFit() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Disconnect Google Fit?'),
        content: const Text(
          'Steps will be tracked using phone sensor only. Background step counting will stop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isGoogleFitLoading = true);

              await _stepService.disconnectGoogleFit();
              _showSnackbar('🔌 Google Fit disconnected', Colors.orange);

              await _checkGoogleFitStatus();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disconnect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============ PHOTO METHODS ============

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile Photo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FitGenieTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: FitGenieTheme.primary),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.purple),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select from photos', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
              if (_photoBase64 != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Delete current photo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final image = await _imageService.pickImage(source: source);
    if (image == null) {
      _showSnackbar('No image selected', Colors.orange);
      return;
    }

    setState(() => _isUploadingPhoto = true);

    final result = await _imageService.uploadProfilePhoto(
      userId: widget.userId,
      imageFile: image,
    );

    setState(() {
      _isUploadingPhoto = false;
      if (result != null) {
        _photoBase64 = result;
        _showSnackbar('Photo updated! 📷', Colors.green);
      } else {
        _showSnackbar('Failed to upload', Colors.red);
      }
    });
  }

  Future<void> _removePhoto() async {
    setState(() => _isUploadingPhoto = true);

    final success = await _imageService.deleteProfilePhoto(widget.userId);

    setState(() {
      _isUploadingPhoto = false;
      if (success) {
        _photoBase64 = null;
        _showSnackbar('Photo removed', Colors.orange);
      }
    });
  }

  // ============ BUILD UI ============

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildBodyStatsCard(),
          const SizedBox(height: 16),
          _buildGoalsCard(),
          const SizedBox(height: 16),
          _buildGoogleFitStatusCard(),
          const SizedBox(height: 16),
          _buildSettingsCard(),
          const SizedBox(height: 16),
          _buildLogoutButton(),
          const SizedBox(height: 20),
          const Text('FitGenie v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============ PROFILE HEADER ============
  Widget _buildProfileHeader() {
    return FGCard(
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: FitGenieTheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: FitGenieTheme.primary, width: 3),
                  ),
                  child: ClipOval(
                    child: _buildAvatarContent(),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FitGenieTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showEditProfileDialog,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 16, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(_email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildBadge(_fitnessLevel, Icons.fitness_center, _getLevelColor(_fitnessLevel)),
              _buildBadge(_goal, Icons.flag, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_isUploadingPhoto) {
      return const Center(
        child: CircularProgressIndicator(color: FitGenieTheme.primary, strokeWidth: 3),
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
      color: FitGenieTheme.primary.withOpacity(0.2),
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

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return FitGenieTheme.primary;
    }
  }

  // ============ BODY STATS ============
  Widget _buildBodyStatsCard() {
    return FGCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.person_outline, color: FitGenieTheme.primary),
                SizedBox(width: 8),
                Text('Body Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onPressed: _showEditBodyStatsDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(Icons.monitor_weight, 'Weight', '${_weight.toStringAsFixed(1)} kg'),
              Container(height: 40, width: 1, color: Colors.white12),
              _buildStatItem(Icons.height, 'Height', '${_height.toStringAsFixed(0)} cm'),
              Container(height: 40, width: 1, color: Colors.white12),
              _buildStatItem(Icons.cake, 'Age', '$_age yrs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: FitGenieTheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // ============ GOALS ============
  Widget _buildGoalsCard() {
    return FGCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.track_changes, color: FitGenieTheme.hot),
                SizedBox(width: 8),
                Text('Daily Goals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onPressed: _showEditGoalsDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGoalRow(Icons.local_fire_department, 'Calories', '$_caloriesGoal kcal', FitGenieTheme.hot),
          const Divider(height: 24, color: Colors.white12),
          _buildGoalRow(Icons.egg_alt, 'Protein', '$_proteinGoal g', FitGenieTheme.teal),
          const Divider(height: 24, color: Colors.white12),
          _buildGoalRow(Icons.water_drop, 'Water', '$_waterGoal glasses', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildGoalRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 🏋️ GOOGLE FIT STATUS CARD — NEW!
  // ═══════════════════════════════════════════
  Widget _buildGoogleFitStatusCard() {
    final bool isConnected = _googleFitStatus == GoogleFitConnectionStatus.connected ||
        _googleFitStatus == GoogleFitConnectionStatus.connectedNoData;

    final Color statusColor = _getStatusColor(_googleFitStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isConnected ? Icons.check_circle : Icons.fitness_center,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Google Fit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getStatusText(_googleFitStatus),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh Button
              IconButton(
                onPressed: _isGoogleFitLoading ? null : _checkGoogleFitStatus,
                icon: _isGoogleFitLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status Checklist
          _buildStatusCheckRow('Health Connect Available', _healthConnectAvailable, Icons.phone_android),
          const SizedBox(height: 8),
          _buildStatusCheckRow('Activity Permission', _activityPermission, Icons.directions_walk),
          const SizedBox(height: 8),
          _buildStatusCheckRow('Google Fit Authorized', _healthAuthorized, Icons.security),
          const SizedBox(height: 8),
          _buildStatusCheckRow('Data Syncing', _dataAccessible, Icons.sync),

          // Steps Display (if connected)
          if (isConnected) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_run, color: Colors.greenAccent, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Steps",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '$_googleFitSteps',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error Message
          if (_googleFitError.isNotEmpty && !isConnected) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _googleFitError,
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Connect / Disconnect Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGoogleFitLoading
                  ? null
                  : (isConnected ? _disconnectGoogleFit : _connectGoogleFit),
              icon: Icon(
                isConnected ? Icons.link_off : Icons.link,
                size: 20,
              ),
              label: Text(
                isConnected ? 'Disconnect Google Fit' : 'Connect Google Fit',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected
                    ? Colors.red.withOpacity(0.8)
                    : Colors.greenAccent,
                foregroundColor: isConnected ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCheckRow(String label, bool isOk, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: (isOk ? Colors.greenAccent : Colors.redAccent).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOk ? Icons.check_circle : Icons.cancel,
            color: isOk ? Colors.greenAccent : Colors.redAccent,
            size: 18,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(GoogleFitConnectionStatus status) {
    switch (status) {
      case GoogleFitConnectionStatus.connected:
        return Colors.greenAccent;
      case GoogleFitConnectionStatus.connectedNoData:
        return Colors.yellowAccent;
      case GoogleFitConnectionStatus.connecting:
        return Colors.blueAccent;
      case GoogleFitConnectionStatus.notAuthorized:
        return Colors.orangeAccent;
      case GoogleFitConnectionStatus.permissionDenied:
        return Colors.redAccent;
      case GoogleFitConnectionStatus.unavailable:
        return Colors.grey;
      case GoogleFitConnectionStatus.disconnected:
        return Colors.white54;
      case GoogleFitConnectionStatus.error:
        return Colors.redAccent;
    }
  }

  String _getStatusText(GoogleFitConnectionStatus status) {
    switch (status) {
      case GoogleFitConnectionStatus.connected:
        return '✅ Connected & Syncing';
      case GoogleFitConnectionStatus.connectedNoData:
        return '🟡 Connected — Walk to see data';
      case GoogleFitConnectionStatus.connecting:
        return '🔄 Connecting...';
      case GoogleFitConnectionStatus.notAuthorized:
        return '🔐 Authorization Required';
      case GoogleFitConnectionStatus.permissionDenied:
        return '❌ Permission Denied';
      case GoogleFitConnectionStatus.unavailable:
        return '📱 Health Connect Not Installed';
      case GoogleFitConnectionStatus.disconnected:
        return '🔌 Not Connected';
      case GoogleFitConnectionStatus.error:
        return '⚠️ Error Occurred';
    }
  }

  // ============ SETTINGS ============
  Widget _buildSettingsCard() {
    return FGCard(
      child: Column(
        children: [
          const Row(children: [
            Icon(Icons.settings, color: Colors.grey),
            SizedBox(width: 8),
            Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 8),

          // Notification Settings
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications, color: Colors.orange, size: 20),
            ),
            title: const Text('Notification Settings'),
            subtitle: const Text('Customize your reminders', style: TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsScreen(userId: widget.userId),
                ),
              );
            },
          ),

          // About
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
            ),
            title: const Text('About'),
            subtitle: const Text('App info & version', style: TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }

  // ============ LOGOUT ============
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showLogoutConfirmation,
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ============ DIALOGS ============

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    String selectedLevel = _fitnessLevel;
    String selectedGoal = _goal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Full Name', Icons.person),
                ),
                const SizedBox(height: 16),
                const Text('Fitness Level', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                _buildDropdown(selectedLevel, ['Beginner', 'Intermediate', 'Advanced'], (val) {
                  if (val != null) setModalState(() => selectedLevel = val);
                }),
                const SizedBox(height: 16),
                const Text('Goal', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                _buildDropdown(selectedGoal, ['Lose Weight', 'Build Muscle', 'Stay Fit', 'Gain Strength'], (val) {
                  if (val != null) setModalState(() => selectedGoal = val);
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateProfile(name: nameController.text, fitnessLevel: selectedLevel, goal: selectedGoal);
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: FitGenieTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showEditBodyStatsDialog() {
    final wc = TextEditingController(text: _weight.toString());
    final hc = TextEditingController(text: _height.toString());
    final ac = TextEditingController(text: _age.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Body Stats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(controller: wc, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Weight (kg)', Icons.monitor_weight)),
            const SizedBox(height: 12),
            TextField(controller: hc, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Height (cm)', Icons.height)),
            const SizedBox(height: 12),
            TextField(controller: ac, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Age', Icons.cake)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _updateBodyStats(
                    weight: double.tryParse(wc.text) ?? _weight,
                    height: double.tryParse(hc.text) ?? _height,
                    age: int.tryParse(ac.text) ?? _age,
                  );
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: FitGenieTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalsDialog() {
    final cc = TextEditingController(text: _caloriesGoal.toString());
    final pc = TextEditingController(text: _proteinGoal.toString());
    final wc = TextEditingController(text: _waterGoal.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(controller: cc, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Calories (kcal)', Icons.local_fire_department)),
            const SizedBox(height: 12),
            TextField(controller: pc, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Protein (g)', Icons.egg_alt)),
            const SizedBox(height: 12),
            TextField(controller: wc, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Water (glasses)', Icons.water_drop)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _updateGoals(
                    calories: int.tryParse(cc.text) ?? _caloriesGoal,
                    protein: int.tryParse(pc.text) ?? _proteinGoal,
                    water: int.tryParse(wc.text) ?? _waterGoal,
                  );
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: FitGenieTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: FitGenieTheme.primary),
      filled: true,
      fillColor: const Color(0xFF0D0D0D),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  // ============ UPDATE FUNCTIONS ============

  Future<void> _updateProfile({required String name, required String fitnessLevel, required String goal}) async {
    try {
      await _firestore.collection('users').doc(widget.userId).set({
        'name': name, 'fitnessLevel': fitnessLevel, 'goal': goal, 'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() {
        _name = name;
        _fitnessLevel = fitnessLevel;
        _goal = goal;
      });
      _showSnackbar('Profile updated! 👍', Colors.green);
    } catch (e) {
      _showSnackbar('Failed', Colors.red);
    }
  }

  Future<void> _updateBodyStats({required double weight, required double height, required int age}) async {
    try {
      await _firestore.collection('users').doc(widget.userId).set({
        'weight': weight, 'height': height, 'age': age, 'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() {
        _weight = weight;
        _height = height;
        _age = age;
      });
      _showSnackbar('Stats updated! 💪', Colors.green);
    } catch (e) {
      _showSnackbar('Failed', Colors.red);
    }
  }

  Future<void> _updateGoals({required int calories, required int protein, required int water}) async {
    try {
      await _firestore.collection('users').doc(widget.userId).collection('goals').doc('main').set({
        'caloriesGoal': calories, 'proteinGoal': protein, 'waterGoal': water,
      }, SetOptions(merge: true));
      setState(() {
        _caloriesGoal = calories;
        _proteinGoal = protein;
        _waterGoal = water;
      });
      _showSnackbar('Goals updated! 🎯', Colors.green);
    } catch (e) {
      _showSnackbar('Failed', Colors.red);
    }
  }

  // ============ LOGOUT CONFIRMATION ============
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(children: [Icon(Icons.fitness_center, color: FitGenieTheme.primary), SizedBox(width: 8), Text('FitGenie')]),
        content: const Text('Version 1.0.0\n\nYour AI Fitness Coach! 💪'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}