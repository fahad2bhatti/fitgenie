// apply_dashboard_patch.dart
//
// Kaise chalana hai (project root mein, jahan pubspec.yaml hai):
//   1) Ye file wahin rakh do
//   2) dart apply_dashboard_patch.dart
//   3) flutter run
//   4) Script delete kar do
//
// Ye lib/screens/dashboard_screen.dart mein 3 methods badalti hai:
//   _buildHeader, _buildStepsCard, _pickMealTypeForScan (sirf rang/style)
// aur ek naya helper _buildStat add karti hai.
// Pehle backup banati hai: lib/screens/dashboard_screen.dart.bak

import 'dart:io';

const _target = 'lib/screens/dashboard_screen.dart';

// ---------------------------------------------------------------
// Brace-matching jo strings, ${} interpolation aur comments samajhti hai
// ---------------------------------------------------------------
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

/// s[open] == '{'. Matching '}' ke baad ka index lautata hai (-1 agar na mile).
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

/// Method ka [start, end) range dhoondta hai.
List<int>? _findMethod(String src, String signature) {
  final start = src.indexOf(signature);
  if (start == -1) return null;
  final open = src.indexOf('{', start);
  if (open == -1) return null;
  final end = _skipBlock(src, open);
  if (end == -1) return null;
  return [start, end];
}

String _indent(String code) => code
    .split('\n')
    .map((l) => l.trim().isEmpty ? l : '  $l')
    .join('\n');

void main() {
  final file = File(_target);
  if (!file.existsSync()) {
    stderr.writeln(
        '❌ $_target nahi mili. Script ko project root (jahan pubspec.yaml hai) mein rakh kar chalao.');
    exit(1);
  }

  var src = file.readAsStringSync();
  File('$_target.bak').writeAsStringSync(src);
  stdout.writeln('💾 Backup bana: $_target.bak');

  var failed = 0;

  // 1) Header
  final h = _findMethod(src, 'Widget _buildHeader(String name)');
  if (h == null) {
    stdout.writeln('❌ _buildHeader nahi mila');
    failed++;
  } else {
    src = src.substring(0, h[0]) +
        _indent(_headerCode).trimLeft() +
        src.substring(h[1]);
    stdout.writeln('✅ _buildHeader badal diya');
  }

  // 2) Steps card (+ _buildStat helper)
  final s = _findMethod(src, 'Widget _buildStepsCard()');
  if (s == null) {
    stdout.writeln('❌ _buildStepsCard nahi mila');
    failed++;
  } else {
    final hasStat = src.contains('Widget _buildStat(');
    final combined = (hasStat ? '' : '$_statCode\n\n') + _stepsCode;
    src = src.substring(0, s[0]) +
        _indent(combined).trimLeft() +
        src.substring(s[1]);
    stdout.writeln(
        '✅ _buildStepsCard badal diya${hasStat ? '' : ' (+ _buildStat add hua)'}');
  }

  // 3) Meal sheet: sirf rang aur chip style
  final m = _findMethod(src, 'Future<String?> _pickMealTypeForScan()');
  if (m == null) {
    stdout.writeln('❌ _pickMealTypeForScan nahi mila (sheet ka style skip)');
    failed++;
  } else {
    var body = src.substring(m[0], m[1]);
    var changed = 0;

    String sub(String text, RegExp re, String to) {
      if (re.hasMatch(text)) {
        changed++;
        return text.replaceFirst(re, to);
      }
      return text;
    }

    body = sub(
      body,
      RegExp(r'backgroundColor:\s*const Color\(0xFF1A1A1A\),'),
      'backgroundColor: FitGenieTheme.card,',
    );
    body = sub(
      body,
      RegExp(r'Radius\.circular\(22\)'),
      'Radius.circular(FitGenieTheme.radiusXL)',
    );
    body = sub(
      body,
      RegExp(r'color:\s*FitGenieTheme\.primary\.withValues\(alpha:\s*0\.15\),\s*'
          r'borderRadius:\s*BorderRadius\.circular\(14\),\s*'
          r'border:\s*Border\.all\(\s*'
          r'color:\s*FitGenieTheme\.primary\.withValues\(alpha:\s*0\.3\),\s*\),'),
      'color: FitGenieTheme.card2,\n'
      '                  borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),\n'
      '                  border: Border.all(color: FitGenieTheme.border),',
    );
    body = sub(
      body,
      RegExp(r'color:\s*FitGenieTheme\.primary,\s*fontWeight:\s*FontWeight\.bold,'),
      'color: FitGenieTheme.text,\n'
      '                  fontWeight: FontWeight.w700,',
    );

    src = src.substring(0, m[0]) + body + src.substring(m[1]);
    stdout.writeln(changed == 4
        ? '✅ Meal sheet ke 4 style edits lag gaye'
        : '⚠️  Meal sheet: 4 mein se $changed edits lage (baqi haath se kar lena)');
  }

  file.writeAsStringSync(src);
  stdout.writeln('');
  if (failed == 0) {
    stdout.writeln('🎉 Ho gaya. Ab `flutter run` karo.');
  } else {
    stdout.writeln(
        '⚠️  $failed hissa nahi laga. Kuch kharab ho to: copy $_target.bak wapas $_target par.');
  }
  stdout.writeln('Check: dart analyze lib/screens/dashboard_screen.dart');
}

// ===============================================================
// Naye methods ka code
// ===============================================================

const _headerCode = r'''
Widget _buildHeader(String name) {
  final hour = DateTime.now().hour;
  final t = Theme.of(context).textTheme;

  String greeting;
  if (hour >= 5 && hour < 12) {
    greeting = AppStrings.get('dashboard_greeting_morning');
  } else if (hour >= 12 && hour < 17) {
    greeting = AppStrings.get('dashboard_greeting_afternoon');
  } else if (hour >= 17 && hour < 21) {
    greeting = AppStrings.get('dashboard_greeting_evening');
  } else {
    greeting = AppStrings.get('dashboard_greeting_night');
  }

  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting.toUpperCase(), style: t.labelSmall),
            const SizedBox(height: 2),
            Text(name, style: t.displaySmall, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      if (_isLoading)
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: FitGenieTheme.primary,
          ),
        )
      else
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: FitGenieTheme.card,
            borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
            border: Border.all(color: FitGenieTheme.border),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: FitGenieTheme.text,
            size: 22,
          ),
        ),
    ],
  );
}''';

const _statCode = r'''
Widget _buildStat(String value, String unit, Color color) {
  final t = Theme.of(context).textTheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: t.headlineSmall?.copyWith(color: color)),
      const SizedBox(height: 2),
      Text(unit.toUpperCase(), style: t.labelSmall),
    ],
  );
}''';

const _stepsCode = r'''
Widget _buildStepsCard() {
  final t = Theme.of(context).textTheme;
  final double progress = _stepsGoal > 0
      ? (_todaySteps / _stepsGoal).clamp(0.0, 1.0).toDouble()
      : 0.0;
  final goalAchieved = progress >= 1.0;
  final int remaining = math.max(0, _stepsGoal - _todaySteps);

  return FGCard(
    padding: const EdgeInsets.fromLTRB(20, 14, 12, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.get('dashboard_step_counter').toUpperCase(),
              style: t.labelSmall,
            ),
            const SizedBox(width: 10),
            _buildStatusDot(),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _getStepStatusText(),
                style: TextStyle(fontSize: 11, color: _getStepStatusColor()),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            if (!_stepCounterHasPermission)
              IconButton(
                icon: const Icon(Icons.warning_amber_rounded,
                    color: FitGenieTheme.warning, size: 22),
                onPressed: _requestStepPermission,
                tooltip: AppStrings.get('dashboard_enable_step_tracking'),
              )
            else
              IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: FitGenieTheme.muted, size: 24),
                onPressed: _showAddStepsDialog,
                tooltip: AppStrings.get('dashboard_add_steps_manually'),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _formatNumber(_todaySteps),
                  style: t.displayLarge?.copyWith(
                    color: goalAchieved
                        ? FitGenieTheme.primary
                        : FitGenieTheme.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ ${_formatNumber(_stepsGoal)}',
                  style: t.titleMedium?.copyWith(color: FitGenieTheme.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: FitGenieTheme.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(FitGenieTheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          goalAchieved
              ? AppStrings.get('dashboard_goal_achieved')
              : AppStrings.get('dashboard_steps_to_go',
                  params: {'count': _formatNumber(remaining)}),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: goalAchieved ? FitGenieTheme.primary : FitGenieTheme.muted,
          ),
        ),
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('${_stepsCalories.round()}', 'kcal', FitGenieTheme.hot),
              _buildStat(_stepsDistance.toStringAsFixed(1), 'km', FitGenieTheme.teal),
              _buildStat('$_stepsActiveMinutes', 'min', FitGenieTheme.text),
            ],
          ),
        ),
      ],
    ),
  );
}''';
