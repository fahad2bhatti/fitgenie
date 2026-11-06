// apply_progress_fix.dart
// progress_screen.dart ki "infinite height" crash theek karta hai:
// scroll view ke andar Row mein CrossAxisAlignment.stretch nahi chalta.
//
//   dart apply_progress_fix.dart
//   dart analyze lib/screens/progress_screen.dart
//   flutter run

import 'dart:io';

const _target = 'lib/screens/progress_screen.dart';

void main() {
  final file = File(_target);
  if (!file.existsSync()) {
    stderr.writeln('❌ $_target nahi mili. Project root se chalao.');
    exit(1);
  }

  final src = file.readAsStringSync();
  final re = RegExp(r'^[ \t]*crossAxisAlignment:\s*CrossAxisAlignment\.stretch,\s*\n',
      multiLine: true);

  if (!re.hasMatch(src)) {
    stdout.writeln('ℹ️  Koi stretch nahi mila, shayad pehle se theek hai');
    exit(0);
  }

  final home = Platform.environment['HOME'] ?? '.';
  final backupDir = Directory('$home/fitgenie_backups')..createSync(recursive: true);
  File('${backupDir.path}/progress_screen.dart.bak').writeAsStringSync(src);
  stdout.writeln('💾 Backup bana: ${backupDir.path}/progress_screen.dart.bak');

  final count = re.allMatches(src).length;
  file.writeAsStringSync(src.replaceAll(re, ''));
  stdout.writeln('✅ $count jagah se stretch hata diya');
}
