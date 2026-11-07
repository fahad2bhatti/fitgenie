// apply_nutrition_speedfix.dart
//
// Nutrition screen ka "add karne ke baad kala flash + spinner + sust load" theek karta hai:
//  * Poori screen ka spinner sirf pehli baar; baad mein purana content dikhta rehta hai
//  * 4 Firestore reads ek saath (parallel), ek ke baad ek nahi
//  * Water +/-: number foran badalta hai, server baad mein update hota hai
//
// Chalane ka tareeqa (project root mein):
//   cp ~/Downloads/apply_nutrition_speedfix.dart .
//   dart apply_nutrition_speedfix.dart
//   flutter run
//
// Backup: ~/fitgenie_backups/calories_screen.dart.speedbak  (aur git)

import 'dart:io';

const _target = 'lib/screens/calories_screen.dart';

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

void main() {
  final file = File(_target);
  if (!file.existsSync()) {
    stderr.writeln(
        '❌ $_target nahi mili. Script ko project root (jahan pubspec.yaml hai) mein rakh kar chalao.');
    exit(1);
  }

  var src = file.readAsStringSync();

  if (src.contains('// speedfix')) {
    stdout.writeln('ℹ️  Speed fix pehle se lagi hui hai, kuch nahi kiya');
    exit(0);
  }

  final home = Platform.environment['HOME'] ?? '.';
  final backupDir = Directory('$home/fitgenie_backups')
    ..createSync(recursive: true);
  File('${backupDir.path}/calories_screen.dart.speedbak')
      .writeAsStringSync(src);
  stdout.writeln(
      '💾 Backup bana: ${backupDir.path}/calories_screen.dart.speedbak');

  var failed = 0;

  // 1) Naya flag
  if (src.contains('bool _hasLoaded')) {
    stdout.writeln('ℹ️  _hasLoaded pehle se hai');
  } else if (src.contains('bool _loading = true;')) {
    src = src.replaceFirst(
      'bool _loading = true;',
      'bool _loading = true;\n  bool _hasLoaded = false;',
    );
    stdout.writeln('✅ _hasLoaded flag add hua');
  } else {
    stdout.writeln('❌ "bool _loading = true;" nahi mila');
    failed++;
  }

  // 2) Methods
  final jobs = <List<String>>[
    ['Future<void> _load()', _loadCode],
    ['Future<void> _quickAddWater()', _addWaterCode],
    ['Future<void> _removeWater()', _removeWaterCode],
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

  file.writeAsStringSync(src);
  stdout.writeln('');
  if (failed == 0) {
    stdout.writeln(
        '🎉 Ho gaya. Ab: dart analyze lib/screens/calories_screen.dart && flutter run');
  } else {
    stdout.writeln(
        '⚠️  $failed hissa nahi laga. Wapas jaane ke liye: git checkout -- $_target');
  }
}

const _loadCode = r'''
Future<void> _load() async {
  // speedfix
  // Poori screen par spinner sirf pehli baar. Baad mein purana content
  // dikhta rehta hai aur peeche se naya data aa jata hai.
  if (!_hasLoaded) {
    setState(() => _loading = true);
  }

  try {
    // Chaaron reads ek saath shuru, ek ke baad ek nahi
    final goalsF = _service.getGoals(_uid);
    final logF = _service.getTodayLog(_uid, date: _selectedDate);
    final entriesF = _service.getMealEntries(_uid, date: _selectedDate);
    final recentF = _service.getRecentFoods(_uid);

    await Future.wait([goalsF, logF, entriesF, recentF]);

    final goals = await goalsF;
    final log = await logF;
    final entries = await entriesF;
    final recent = await recentF;

    if (!mounted) return;

    setState(() {
      caloriesGoal = goals['caloriesGoal'] ?? 2400;
      proteinGoal = goals['proteinGoal'] ?? 180;
      carbsGoal = goals['carbsGoal'] ?? 250;
      fatsGoal = goals['fatsGoal'] ?? 70;
      waterGoal = goals['waterGoal'] ?? 8;

      calories = log['calories'] ?? 0;
      protein = log['protein'] ?? 0;
      carbs = log['carbs'] ?? 0;
      fats = log['fats'] ?? 0;
      water = log['water'] ?? 0;

      _entries = entries;
      _recentFoods = recent;
      _loading = false;
      _hasLoaded = true;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => _loading = false);
    AppSnackbar.showError(
      context,
      AppStrings.get('calories_load_failed', params: {'error': e.toString()}),
    );
  }
}''';

const _addWaterCode = r'''
Future<void> _quickAddWater() async {
  // Number foran badlo, server ko baad mein batao
  setState(() => water++);
  await _service.incrementWater(_uid, date: _selectedDate);
  await _load();
}''';

const _removeWaterCode = r'''
Future<void> _removeWater() async {
  if (water <= 0) return;
  setState(() => water--);
  await _service.decrementWater(_uid, date: _selectedDate);
  await _load();
}''';
