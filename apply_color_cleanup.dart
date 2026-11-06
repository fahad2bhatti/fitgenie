// apply_color_cleanup.dart
//
// lib/screens aur lib/widgets mein hardcoded rang theme se jodta hai.
//
// Pehle dry-run (kuch likhta nahi, sirf batata hai):
//   dart apply_color_cleanup.dart --dry
// Phir asli:
//   dart apply_color_cleanup.dart
//
// Wapas jaane ke liye (git commit pehle kar lena):
//   git checkout -- lib

import 'dart:io';

const _dirs = ['lib/screens', 'lib/widgets'];

// workout_screen ka redesign alag se hoga, abhi haath nahi lagate.
const _skip = {'workout_screen.dart'};

// In files mein rang category dikhate hain (push/pull/legs...), to purple ko
// primary se alag rakhna zaroori hai.
const _categoryFiles = {'my_library_screen.dart', 'workout_detail_screen.dart'};

const _themeImport = "import '../app/fitgenie_theme.dart';";

// ---------------------------------------------------------------
// 1) Hardcoded greys / navy  ->  theme surfaces
// ---------------------------------------------------------------
final _surfaces = <RegExp, String>{
  RegExp(r'(?:const\s+)?Color\(0xFF1A1A1A\)'): 'FitGenieTheme.card',
  RegExp(r'(?:const\s+)?Color\(0xFF1E1E1E\)'): 'FitGenieTheme.card',
  RegExp(r'(?:const\s+)?Color\(0xFF0D0D0D\)'): 'FitGenieTheme.card2',
  RegExp(r'(?:const\s+)?Color\(0xFF121212\)'): 'FitGenieTheme.card2',
  RegExp(r'(?:const\s+)?Color\(0xFF0A0A0A\)'): 'FitGenieTheme.bg',
  RegExp(r'(?:const\s+)?Color\(0xFF0A0A0F\)'): 'FitGenieTheme.bg',
  RegExp(r'(?:const\s+)?Color\(0xFF0D1117\)'): 'FitGenieTheme.card2',
  RegExp(r'(?:const\s+)?Color\(0xFF0D1530\)'): 'FitGenieTheme.card',
  RegExp(r'(?:const\s+)?Color\(0xFF1A1A2E\)'): 'FitGenieTheme.card',
  RegExp(r'(?:const\s+)?Color\(0xFF16213E\)'): 'FitGenieTheme.card',
};

// ---------------------------------------------------------------
// 2) Material rang  ->  theme ke maani wale rang
// ---------------------------------------------------------------
const _semantic = <String, String>{
  'amber': 'warning',
  'teal': 'teal',
  'pink': 'hot',
  'greenAccent': 'success',
  'redAccent': 'error',
  'orangeAccent': 'warning',
  'blueAccent': 'info',
  'blue': 'primary',
  // 'purple' neeche file ke hisaab se
};

RegExp _colorRe(String k) => RegExp('Colors\\.$k\\b(?!\\.shade|\\[)');

void main(List<String> args) {
  final dry = args.contains('--dry');
  var totalReplacements = 0;
  var filesChanged = 0;

  for (final dir in _dirs) {
    final d = Directory(dir);
    if (!d.existsSync()) {
      stdout.writeln('❌ $dir nahi mila. Project root se chalao.');
      exit(1);
    }
    final files = d
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final f in files) {
      final name = f.path.split('/').last;
      if (_skip.contains(name)) {
        stdout.writeln('⏭️  $name (workout redesign ke liye chhoda)');
        continue;
      }

      var src = f.readAsStringSync();
      var count = 0;

      String rep(String text, RegExp re, String to) {
        final m = re.allMatches(text).length;
        if (m == 0) return text;
        count += m;
        return text.replaceAll(re, to);
      }

      // a) Khaas cases (generic se pehle)
      src = rep(
        src,
        RegExp(r'\[\s*FitGenieTheme\.primary,\s*Colors\.purple\s*\]'),
        '[FitGenieTheme.primary, FitGenieTheme.primaryDark]',
      );
      // Pani = mint, har jagah
      src = rep(
        src,
        RegExp(r'Icons\.water_drop,\s*color:\s*Colors\.blue\b'),
        'Icons.water_drop, color: FitGenieTheme.teal',
      );
      if (name == 'notification_settings_screen.dart') {
        src = rep(
          src,
          RegExp(r'Colors\.blue\.withValues\(alpha:\s*0\.2\)'),
          'FitGenieTheme.teal.withValues(alpha: 0.2)',
        );
      }

      // b) Bottom nav wali container: card2 (theme ke nav se match)
      if (name == 'shell_screen.dart') {
        final lines = src.split('\n');
        for (final idx in [69, 82]) {
          if (idx < lines.length && lines[idx].contains('0xFF1A1A1A')) {
            lines[idx] = lines[idx].replaceAll(
              RegExp(r'(?:const\s+)?Color\(0xFF1A1A1A\)'),
              'FitGenieTheme.card2',
            );
            count++;
          }
        }
        src = lines.join('\n');
      }

      // c) Surfaces
      _surfaces.forEach((re, to) => src = rep(src, re, to));

      // d) Semantic rang
      _semantic.forEach((k, v) {
        src = rep(src, _colorRe(k), 'FitGenieTheme.$v');
      });
      src = rep(
        src,
        _colorRe('purple'),
        _categoryFiles.contains(name) ? 'FitGenieTheme.ai' : 'FitGenieTheme.primary',
      );

      if (count == 0) continue;

      // e) Theme import na ho to add karo
      if (!src.contains('fitgenie_theme.dart')) {
        final m = RegExp(r'^import ', multiLine: true).firstMatch(src);
        src = m != null
            ? '${src.substring(0, m.start)}$_themeImport\n${src.substring(m.start)}'
            : '$_themeImport\n$src';
      }

      stdout.writeln('${dry ? "👀" : "✅"} $name: $count jagah');
      totalReplacements += count;
      filesChanged++;
      if (!dry) f.writeAsStringSync(src);
    }
  }

  stdout.writeln('');
  stdout.writeln(
      '${dry ? "Dry-run: " : ""}$filesChanged files, $totalReplacements replacements');
  if (dry) {
    stdout.writeln('Kuch likha nahi gaya. Asli chalane ke liye --dry hata do.');
  } else {
    stdout.writeln('Ab: dart analyze lib && flutter run');
    stdout.writeln('Wapas jaane ke liye: git checkout -- lib');
  }
}
