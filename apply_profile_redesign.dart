// apply_profile_redesign.dart
//
// Profile screen ko dobara banata hai:
//  * Header + body stats ek card mein: bada avatar, naam, level aur goal, neeche
//    weight / height / age bade Barlow numbers mein, peeche halka bara initial
//  * Goals: icon boxes ki jagah saaf rows, bade numbers
//  * Google Fit: chhota card (status dot, aaj ke steps, ek button), technical
//    checks "Details" ke andar chhupe hue
//  * Settings: rangeen icon boxes hata diye; Delete Account wahan se hata diya
//    (neeche pehle se alag hai)
//  * Logout: shaant outlined button; Delete: chhota text link
//  * Photo sheet: icon boxes hata diye
//
// Chalane ka tareeqa (project root mein):
//   cp ~/Downloads/apply_profile_redesign.dart .
//   dart apply_profile_redesign.dart
//   dart analyze lib/screens/profile_screen.dart
//   flutter run
//
// Backup: ~/fitgenie_backups/profile_screen.dart.bak  (aur git)

import 'dart:io';

const _target = 'lib/screens/profile_screen.dart';

int _skipString(String s, int i) {
  final q = s[i];
  i++;
  while (i < s.length) {
    final c = s[i];
    if (c == r'\') {
      i += 2;
      continue;
    }
    if (c == q) return i + 1;
    if (c == r'$' && i + 1 < s.length && s[i + 1] == '{') {
      final end = _skipBlock(s, i + 1);
      if (end == -1) return s.length;
      i = end;
      continue;
    }
    i++;
  }
  return i;
}

int _skipBlock(String s, int open) {
  var depth = 0;
  var i = open;
  while (i < s.length) {
    final c = s[i];
    if (c == '/' && i + 1 < s.length && s[i + 1] == '/') {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
      continue;
    }
    if (c == '/' && i + 1 < s.length && s[i + 1] == '*') {
      final e = s.indexOf('*/', i + 2);
      i = e == -1 ? s.length : e + 2;
      continue;
    }
    if (c == "'" || c == '"') {
      i = _skipString(s, i);
      continue;
    }
    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) return i + 1;
    }
    i++;
  }
  return -1;
}

List<int>? _findMethod(String src, String signature) {
  final start = src.indexOf(signature);
  if (start == -1) return null;
  final p = src.indexOf('(', start);
  if (p == -1) return null;
  var depth = 0;
  var i = p;
  while (i < src.length) {
    final c = src[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) {
        i++;
        break;
      }
    }
    i++;
  }
  final open = src.indexOf('{', i);
  if (open == -1) return null;
  final end = _skipBlock(src, open);
  if (end == -1) return null;
  return [start, end];
}

String _indent(String code) =>
    code.split('\n').map((l) => l.trim().isEmpty ? l : '  $l').join('\n');

String _removeRange(String src, List<int> r) {
  final lineStart = src.lastIndexOf('\n', r[0]) + 1;
  var e = r[1];
  while (e < src.length && (src[e] == '\n' || src[e] == '\r')) {
    e++;
  }
  return '${src.substring(0, lineStart)}\n${src.substring(e)}';
}

void main() {
  final file = File(_target);
  if (!file.existsSync()) {
    stderr.writeln(
        '❌ $_target nahi mili. Script ko project root (jahan pubspec.yaml hai) mein rakh kar chalao.');
    exit(1);
  }

  var src = file.readAsStringSync();

  if (src.contains('// profile-v2')) {
    stdout
        .writeln('ℹ️  Profile redesign pehle se lagi hui hai, kuch nahi kiya');
    exit(0);
  }

  final home = Platform.environment['HOME'] ?? '.';
  final backupDir = Directory('$home/fitgenie_backups')
    ..createSync(recursive: true);
  File('${backupDir.path}/profile_screen.dart.bak').writeAsStringSync(src);
  stdout.writeln('💾 Backup bana: ${backupDir.path}/profile_screen.dart.bak');

  var failed = 0;

  // Pehli build() _ProfileScreenState ki hai (_EditGoalsSheetState ki baad mein)
  final jobs = <List<String>>[
    ['Widget build(BuildContext context)', _buildCode],
    ['Widget _buildProfileHeader()', _headerCode],
    ['Widget _buildGoalsCard()', _goalsCode],
    ['Widget _buildGoogleFitStatusCard()', _fitCardCode],
    ['Widget _buildStatusCheckRow(', _checkRowCode],
    ['Color _getStatusColor(', _statusColorCode],
    ['String _getStatusText(', _statusTextCode],
    ['Widget _buildSettingsCard()', _settingsCode],
    ['Widget _buildLogoutButton()', _logoutCode],
    ['Widget _buildDeleteAccountButton()', _deleteBtnCode],
    ['void _showPhotoOptions()', _photoSheetCode],
  ];

  for (final job in jobs) {
    final r = _findMethod(src, job[0]);
    if (r == null) {
      stdout.writeln('❌ ${job[0]} nahi mila');
      failed++;
      continue;
    }
    src = src.substring(0, r[0]) +
        _indent(job[1]).trimLeft() +
        src.substring(r[1]);
    stdout.writeln('✅ ${job[0]} badal diya');
  }

  // Ab jin methods ki zaroorat nahi
  for (final sig in [
    'Widget _buildBodyStatsCard()',
    'Widget _buildStatItem(',
    'Widget _buildGoalRow(',
    'Widget _buildBadge(',
    'Color _getLevelColor(',
  ]) {
    final r = _findMethod(src, sig);
    if (r != null) {
      src = _removeRange(src, r);
      stdout.writeln('✅ Hata diya: $sig');
    }
  }

  file.writeAsStringSync(src);
  stdout.writeln('');
  if (failed == 0) {
    stdout.writeln(
        '🎉 Ho gaya. Ab: dart analyze lib/screens/profile_screen.dart && flutter run');
  } else {
    stdout.writeln(
        '⚠️  $failed hissa nahi laga. Wapas jaane ke liye: git checkout -- $_target');
  }
}

// ===============================================================
// Naya code
// ===============================================================

const _buildCode = r'''
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
}''';

const _headerCode = r'''
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
                          border:
                              Border.all(color: FitGenieTheme.border, width: 2),
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
                            border:
                                Border.all(color: FitGenieTheme.card, width: 2),
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
                          '$_fitnessLevel · $_goal'.toUpperCase(),
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
}''';

const _goalsCode = r'''
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
                style:
                    const TextStyle(color: FitGenieTheme.muted, fontSize: 12)),
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
        row('Calories', '$_caloriesGoal', 'kcal'),
        const Divider(height: 1),
        row('Protein', '$_proteinGoal', 'g'),
        const Divider(height: 1),
        row('Water', '$_waterGoal', 'glasses'),
      ],
    ),
  );
}''';

const _fitCardCode = r'''
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
            Text('GOOGLE FIT', style: t.labelSmall),
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
            style: const TextStyle(color: FitGenieTheme.warning, fontSize: 12),
          ),
        ],
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            iconColor: FitGenieTheme.muted,
            collapsedIconColor: FitGenieTheme.muted,
            title: const Text(
              'Details',
              style:
                  TextStyle(color: FitGenieTheme.textSecondary, fontSize: 13),
            ),
            children: [
              _buildStatusCheckRow('Health Connect Available',
                  _healthConnectAvailable, Icons.phone_android),
              _buildStatusCheckRow('Activity Permission', _activityPermission,
                  Icons.directions_walk),
              _buildStatusCheckRow(
                  'Google Fit Authorized', _healthAuthorized, Icons.security),
              _buildStatusCheckRow(
                  'Data Syncing', _dataAccessible, Icons.sync),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: isConnected
              ? OutlinedButton(
                  onPressed: _isGoogleFitLoading ? null : _disconnectGoogleFit,
                  child: const Text('Disconnect Google Fit'),
                )
              : ElevatedButton(
                  onPressed: _isGoogleFitLoading ? null : _connectGoogleFit,
                  child: const Text('Connect Google Fit'),
                ),
        ),
      ],
    ),
  );
}''';

const _checkRowCode = r'''
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
}''';

const _statusColorCode = r'''
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
}''';

const _statusTextCode = r'''
String _getStatusText(GoogleFitConnectionStatus status) {
  switch (status) {
    case GoogleFitConnectionStatus.connected:
      return 'Connected & syncing';
    case GoogleFitConnectionStatus.connectedNoData:
      return 'Connected · walk to see data';
    case GoogleFitConnectionStatus.connecting:
      return 'Connecting...';
    case GoogleFitConnectionStatus.notAuthorized:
      return 'Authorization required';
    case GoogleFitConnectionStatus.permissionDenied:
      return 'Permission denied';
    case GoogleFitConnectionStatus.unavailable:
      return 'Health Connect not installed';
    case GoogleFitConnectionStatus.disconnected:
      return 'Not connected';
    case GoogleFitConnectionStatus.error:
      return 'Something went wrong';
  }
}''';

const _settingsCode = r'''
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
}''';

const _logoutCode = r'''
Widget _buildLogoutButton() {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: _showLogoutConfirmation,
      child: Text(AppStrings.get('profile_logout')),
    ),
  );
}''';

const _deleteBtnCode = r'''
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
}''';

const _photoSheetCode = r'''
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
                  style:
                      const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}''';
