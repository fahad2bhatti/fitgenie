// apply_nutrition_redesign.dart
//
// Nutrition (calories_screen.dart) ko dobara banata hai:
//  * Summary: bara calories number + bar + "X kcal left", neeche Protein/Carbs/Fats
//    teen chhote columns (5 bars ka dher khatam). Goals edit: pencil icon.
//  * Quick actions: 4 rangeen tiles ki jagah bara "Search" button + "Scan" button
//  * Water: tinted +/- boxes ki jagah bara number + segments + gole buttons
//  * Meal sections: emoji hata diye; header mein naam + kcal/protein; neeche 3 pills
//    "+ Search  + Saved  + Custom"  (pehle dono buttons ka label "Saved" tha: bug fix)
//  * Entries: boxes ke andar boxes hata kar saaf rows, kcal bade number mein
//  * Date switcher: card hata kar seedhi row
//
// Chalane ka tareeqa (project root mein):
//   cp ~/Downloads/apply_nutrition_redesign.dart .
//   dart apply_nutrition_redesign.dart
//   dart analyze lib/screens/calories_screen.dart
//   flutter run
//
// Backup: ~/fitgenie_backups/calories_screen.dart.bak  (aur git)

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

List<int>? _findClass(String src, String header) {
  final start = src.indexOf(header);
  if (start == -1) return null;
  final open = src.indexOf('{', start);
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

  if (src.contains('// nutrition-v2')) {
    stdout.writeln('ℹ️  Nutrition redesign pehle se lagi hui hai, kuch nahi kiya');
    exit(0);
  }

  final home = Platform.environment['HOME'] ?? '.';
  final backupDir = Directory('$home/fitgenie_backups')
    ..createSync(recursive: true);
  File('${backupDir.path}/calories_screen.dart.bak').writeAsStringSync(src);
  stdout.writeln('💾 Backup bana: ${backupDir.path}/calories_screen.dart.bak');

  var failed = 0;

  // Pehli build() _CaloriesScreenState ki hai (_MealEntryTile ki baad mein)
  final jobs = <List<String>>[
    ['Widget build(BuildContext context)', _buildCode],
    ['Widget _buildSummaryCard()', _summaryCode],
    ['Widget _buildQuickActions()', _quickActionsCode],
    ['Widget _buildWaterControls()', _waterCode],
    ['Widget _buildMealSection(', _mealSectionCode],
    ['Widget _buildRecentFoods()', _recentCode],
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

  // Purani helper methods jo ab use nahi hotin
  for (final sig in ['Widget _macroProgress(', 'Widget _actionCard(']) {
    final r = _findMethod(src, sig);
    if (r != null) {
      src = _removeRange(src, r);
      stdout.writeln('✅ Hata diya: $sig');
    }
  }

  // Entry tile class (top-level, indent nahi)
  final tile = _findClass(src, 'class _MealEntryTile extends StatelessWidget');
  if (tile == null) {
    stdout.writeln('❌ _MealEntryTile nahi mila');
    failed++;
  } else {
    src = src.substring(0, tile[0]) + _tileCode + src.substring(tile[1]);
    stdout.writeln('✅ _MealEntryTile badal diya');
  }

  // Scan ke baad meal-type sheet ke chips: neutral style
  final m = _findMethod(src, 'Future<String?> _pickMealTypeForScan()');
  if (m != null) {
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
      RegExp(r'color:\s*FitGenieTheme\.primary\.withValues\(alpha:\s*0\.15\),\s*'
          r'borderRadius:\s*BorderRadius\.circular\(14\),\s*'
          r'border:\s*Border\.all\(\s*'
          r'color:\s*FitGenieTheme\.primary\.withValues\(alpha:\s*0\.3\),\s*\),'),
      'color: FitGenieTheme.card2,\n'
      '                      borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),\n'
      '                      border: Border.all(color: FitGenieTheme.border),',
    );
    body = sub(
      body,
      RegExp(r'color:\s*FitGenieTheme\.primary,\s*fontWeight:\s*FontWeight\.bold,'),
      'color: FitGenieTheme.text,\n'
      '                        fontWeight: FontWeight.w700,',
    );
    src = src.substring(0, m[0]) + body + src.substring(m[1]);
    stdout.writeln('✅ Meal sheet chips neutral kiye ($changed/2)');
  }

  // Unused import
  if (!src.contains('FGLinearProgress')) {
    src = src.replaceAll("import '../widgets/fg_progress.dart';\n", '');
    stdout.writeln('✅ fg_progress import hata diya');
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

// ===============================================================
// Naya code
// ===============================================================

const _buildCode = r'''
Widget build(BuildContext context) {
  // nutrition-v2
  final t = Theme.of(context).textTheme;

  return _loading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _load,
          color: FitGenieTheme.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              FitGenieTheme.screenPadding,
              12,
              FitGenieTheme.screenPadding,
              24,
            ),
            children: [
              Text(AppStrings.get('calories_title'), style: t.displaySmall),
              const SizedBox(height: 4),
              Text(
                AppStrings.get('calories_sub'),
                style: const TextStyle(
                    color: FitGenieTheme.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              const MedicalDisclaimerBanner(compact: true),
              const SizedBox(height: 8),

              // Date switcher: seedhi row, card nahi
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeDate(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(_dateLabel(), style: t.titleMedium),
                    ),
                  ),
                  IconButton(
                    onPressed: _isToday ? null : () => _changeDate(1),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _isToday
                          ? FitGenieTheme.border
                          : FitGenieTheme.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _buildSummaryCard(),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 12),
              _buildWaterControls(),
              const SizedBox(height: 12),

              _buildMealSection(
                  'breakfast', AppStrings.get('meal_breakfast'), ''),
              const SizedBox(height: 12),
              _buildMealSection('lunch', AppStrings.get('meal_lunch'), ''),
              const SizedBox(height: 12),
              _buildMealSection('dinner', AppStrings.get('meal_dinner'), ''),
              const SizedBox(height: 12),
              _buildMealSection('snacks', AppStrings.get('meal_snacks'), ''),
              const SizedBox(height: 12),

              _buildRecentFoods(),
            ],
          ),
        );
}''';

const _summaryCode = r'''
Widget _buildSummaryCard() {
  final t = Theme.of(context).textTheme;
  final remaining = caloriesGoal - calories;

  Widget macro(String label, int value, int goal) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: t.labelSmall),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$value', style: t.headlineSmall),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '/ $goal g',
                    style: const TextStyle(
                        color: FitGenieTheme.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _progress(value, goal),
                minHeight: 4,
                backgroundColor: FitGenieTheme.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(FitGenieTheme.primary),
              ),
            ),
          ],
        ),
      );

  return FGCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.get('calories_summary').toUpperCase(),
              style: t.labelSmall,
            ),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: FitGenieTheme.muted),
              onPressed: _openGoalsSheet,
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$calories', style: t.displayLarge),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '/ $caloriesGoal kcal',
                style: t.titleMedium?.copyWith(color: FitGenieTheme.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _progress(calories, caloriesGoal),
            minHeight: 8,
            backgroundColor: FitGenieTheme.border,
            valueColor: const AlwaysStoppedAnimation<Color>(FitGenieTheme.hot),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          remaining >= 0
              ? '$remaining kcal left'
              : '${-remaining} kcal over',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: remaining >= 0 ? FitGenieTheme.muted : FitGenieTheme.warning,
          ),
        ),
        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 14),
        Row(
          children: [
            macro('Protein', protein, proteinGoal),
            const SizedBox(width: 16),
            macro('Carbs', carbs, carbsGoal),
            const SizedBox(width: 16),
            macro('Fats', fats, fatsGoal),
          ],
        ),
      ],
    ),
  );
}''';

const _quickActionsCode = r'''
Widget _buildQuickActions() {
  return Row(
    children: [
      Expanded(
        flex: 3,
        child: Material(
          color: FitGenieTheme.primary,
          borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
          child: InkWell(
            borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
            onTap: _openFoodSearch,
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_rounded,
                      color: FitGenieTheme.onPrimary, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppStrings.get('calories_search'),
                      style: const TextStyle(
                        color: FitGenieTheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 2,
        child: FGCard(
          onTap: _openMealScanner,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.document_scanner_outlined,
                  size: 18, color: FitGenieTheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppStrings.get('calories_scan'),
                  style: const TextStyle(
                    color: FitGenieTheme.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}''';

const _waterCode = r'''
Widget _buildWaterControls() {
  final t = Theme.of(context).textTheme;
  final int segs = waterGoal.clamp(1, 16).toInt();
  final int filled = waterGoal > 0
      ? ((water / waterGoal) * segs).round().clamp(0, segs).toInt()
      : 0;

  Widget circleButton(IconData icon, VoidCallback onTap,
      {bool filledStyle = false}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filledStyle ? FitGenieTheme.teal : Colors.transparent,
          border: Border.all(
            color: filledStyle ? FitGenieTheme.teal : FitGenieTheme.border,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: filledStyle ? Colors.black : FitGenieTheme.text,
        ),
      ),
    );
  }

  return FGCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get('calories_water').toUpperCase(),
                    style: t.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$water', style: t.headlineMedium),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '/ $waterGoal',
                          style: const TextStyle(
                              color: FitGenieTheme.muted, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            circleButton(Icons.remove_rounded, _removeWater),
            const SizedBox(width: 10),
            circleButton(Icons.add_rounded, _quickAddWater, filledStyle: true),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(segs, (i) {
            return Expanded(
              child: Container(
                height: 8,
                margin: EdgeInsets.only(right: i == segs - 1 ? 0 : 4),
                decoration: BoxDecoration(
                  color: i < filled ? FitGenieTheme.teal : FitGenieTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );
}''';

const _mealSectionCode = r'''
Widget _buildMealSection(String mealType, String title, String emoji) {
  final t = Theme.of(context).textTheme;
  final items = _mealEntries(mealType);

  Widget pill(String label, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
              border: Border.all(color: FitGenieTheme.border),
            ),
            child: Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '+ ',
                      style: TextStyle(
                        color: FitGenieTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    TextSpan(
                      text: label,
                      style: const TextStyle(
                        color: FitGenieTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );

  return FGCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: t.headlineSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${_mealCalories(mealType)} kcal · ${_mealProtein(mealType)}g protein',
                    style: const TextStyle(
                        color: FitGenieTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (items.isNotEmpty)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: AppStrings.get('calories_save_template'),
                icon: const Icon(Icons.bookmark_add_outlined,
                    size: 20, color: FitGenieTheme.muted),
                onPressed: () => _saveMealAsTemplate(mealType),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              AppStrings.get('calories_empty'),
              style: const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
            ),
          )
        else
          ...items.map(
            (entry) => _MealEntryTile(
              entry: entry,
              onEdit: () => _openAddFoodSheet(
                initialEntry: entry,
                entryId: entry.id,
              ),
              onDelete: () => _deleteEntry(entry),
            ),
          ),

        const SizedBox(height: 10),
        Row(
          children: [
            pill(AppStrings.get('calories_search'),
                () => _openFoodSearchForMeal(mealType)),
            const SizedBox(width: 8),
            pill(AppStrings.get('calories_saved'),
                () => _openSavedMealsPicker(mealTypeOverride: mealType)),
            const SizedBox(width: 8),
            pill(
              AppStrings.get('calories_custom'),
              () => _openAddFoodSheet(
                initialEntry: MealEntry(
                  name: '',
                  quantity: '',
                  mealType: mealType,
                  calories: 0,
                  protein: 0,
                  carbs: 0,
                  fats: 0,
                  source: 'manual',
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}''';

const _recentCode = r'''
Widget _buildRecentFoods() {
  if (_recentFoods.isEmpty) return const SizedBox.shrink();

  return FGCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('calories_recent').toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentFoods.map((food) {
            return GestureDetector(
              onTap: () {
                _openAddFoodSheet(
                  initialEntry: MealEntry(
                    name: (food['name'] ?? '').toString(),
                    quantity: (food['quantity'] ?? '1 serving').toString(),
                    mealType: 'breakfast',
                    calories: (food['calories'] is num)
                        ? (food['calories'] as num).toInt()
                        : 0,
                    protein: (food['protein'] is num)
                        ? (food['protein'] as num).toInt()
                        : 0,
                    carbs: (food['carbs'] is num)
                        ? (food['carbs'] as num).toInt()
                        : 0,
                    fats: (food['fats'] is num)
                        ? (food['fats'] as num).toInt()
                        : 0,
                    source: 'recent',
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
                  border: Border.all(color: FitGenieTheme.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (food['name'] ?? 'Food').toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${food['calories'] ?? 0} kcal · ${food['protein'] ?? 0}g P',
                      style: const TextStyle(
                          color: FitGenieTheme.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}''';

const _tileCode = r'''
class _MealEntryTile extends StatelessWidget {
  final MealEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MealEntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: FitGenieTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.quantity} · ${entry.protein}g P · ${entry.carbs}g C · ${entry.fats}g F',
                  style: const TextStyle(
                      color: FitGenieTheme.muted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${entry.calories}',
            style: t.headlineSmall?.copyWith(
              fontSize: 20,
              color: FitGenieTheme.hot,
            ),
          ),
          const SizedBox(width: 3),
          const Text(
            'kcal',
            style: TextStyle(color: FitGenieTheme.muted, fontSize: 11),
          ),
          PopupMenuButton<String>(
            color: FitGenieTheme.cardDark,
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'edit', child: Text(AppStrings.get('edit'))),
              PopupMenuItem(
                  value: 'delete', child: Text(AppStrings.get('delete'))),
            ],
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.more_vert,
                  size: 18, color: FitGenieTheme.muted),
            ),
          ),
        ],
      ),
    );
  }
}''';
