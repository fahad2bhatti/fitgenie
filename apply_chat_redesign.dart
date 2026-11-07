// apply_chat_redesign.dart
//
// AI Coach chat ko theek aur naya karta hai:
//
//  BUG (double send): ab send dabate hi lock + text box saaf + user ka message foran screen
//    par; quota check uske baad. Quota na ho to message wapas text box mein aa jata hai.
//  SPEED (ai_service.dart): 4 Firestore reads ek saath + 90 second cache, aur chat history ka
//    save jawab ke rastay mein nahi.
//  DESIGN: gradient/glow/avatars/hourglass hata kar flat bubbles, outlined text chips,
//    chat-input jaisa bar aur seedha send button (dashboard ke "Ask your coach" bar jaisa).
//
// Chalane ka tareeqa (project root mein):
//   git add -A && git commit -m "before chat redesign"
//   cp ~/Downloads/apply_chat_redesign.dart .
//   dart apply_chat_redesign.dart
//   dart format lib/screens/shell_screen.dart lib/services/ai_service.dart
//   dart analyze lib/screens lib/services
//   flutter run
//
// Backup: ~/fitgenie_backups/*.chatbak

import 'dart:io';

const _shellPath = 'lib/screens/shell_screen.dart';
const _aiPath = 'lib/services/ai_service.dart';

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

void _backup(String path, String content) {
  final home = Platform.environment['HOME'] ?? '.';
  final dir = Directory('$home/fitgenie_backups')..createSync(recursive: true);
  File('${dir.path}/${path.split('/').last}.chatbak')
      .writeAsStringSync(content);
}

void main() {
  var failed = 0;

  // ===============================================================
  // 1) shell_screen.dart
  // ===============================================================
  final shellFile = File(_shellPath);
  if (!shellFile.existsSync()) {
    stderr.writeln(
        '❌ $_shellPath nahi mili. Script ko project root (jahan pubspec.yaml hai) mein rakh kar chalao.');
    exit(1);
  }
  var shell = shellFile.readAsStringSync();

  if (shell.contains('// chat-v2')) {
    stdout.writeln('ℹ️  shell_screen.dart pehle se naya hai, skip');
  } else {
    _backup(_shellPath, shell);
    stdout.writeln('💾 Backup: shell_screen.dart.chatbak');

    // a) AI coach state class (poori)
    final cls = _findClass(
        shell, 'class _AICoachScreenState extends State<_AICoachScreen>');
    if (cls == null) {
      stdout.writeln('❌ _AICoachScreenState nahi mili');
      failed++;
    } else {
      shell = shell.substring(0, cls[0]) + _coachStateCode + shell.substring(cls[1]);
      stdout.writeln('✅ _AICoachScreenState badal di (bug fix + naya design)');
    }

    // b) Bottom nav: shell ki pehli build()
    final b = _findMethod(shell, 'Widget build(BuildContext context)');
    if (b == null) {
      stdout.writeln('❌ ShellScreen build() nahi mili');
      failed++;
    } else {
      shell = shell.substring(0, b[0]) +
          _indent(_shellBuildCode).trimLeft() +
          shell.substring(b[1]);
      stdout.writeln('✅ Bottom nav saaf kiya (shadow hata, patli border)');
    }

    // c) AppSnackbar import
    if (!shell.contains('app_snackbar.dart')) {
      const anchor = "import '../widgets/banner_ad_widget.dart';";
      if (shell.contains(anchor)) {
        shell = shell.replaceFirst(
            anchor, "$anchor\nimport '../widgets/app_snackbar.dart';");
        stdout.writeln('✅ app_snackbar import joda');
      } else {
        stdout.writeln(
            '⚠️  banner_ad_widget import nahi mila. Haath se jodo: import \'../widgets/app_snackbar.dart\';');
        failed++;
      }
    }

    shellFile.writeAsStringSync(shell);
  }

  // ===============================================================
  // 2) ai_service.dart (speed)
  // ===============================================================
  final aiFile = File(_aiPath);
  if (!aiFile.existsSync()) {
    stdout.writeln('⚠️  $_aiPath nahi mili, speed fix skip');
    failed++;
  } else {
    var ai = aiFile.readAsStringSync();
    if (ai.contains('// ai-speed-v1')) {
      stdout.writeln('ℹ️  ai_service.dart pehle se tez hai, skip');
    } else {
      _backup(_aiPath, ai);
      stdout.writeln('💾 Backup: ai_service.dart.chatbak');

      final r = _findMethod(
          ai, 'Future<Map<String, dynamic>> _getUserContext(String uid)');
      if (r == null) {
        stdout.writeln('❌ _getUserContext nahi mila');
        failed++;
      } else {
        ai = ai.substring(0, r[0]) +
            _indent(_userContextCode).trimLeft() +
            ai.substring(r[1]);
        stdout.writeln('✅ _getUserContext: 4 reads ek saath + 90s cache');
      }

      final saveRe =
          RegExp(r'await _saveChatHistory\(uid, cleanMessage, formatted\);');
      if (saveRe.hasMatch(ai)) {
        ai = ai.replaceFirst(
            saveRe, 'unawaited(_saveChatHistory(uid, cleanMessage, formatted));');
        stdout.writeln('✅ Chat history save ab jawab ke rastay mein nahi');
      } else {
        stdout.writeln('⚠️  "await _saveChatHistory(...)" nahi mila');
        failed++;
      }

      if (!ai.contains("import 'dart:async';")) {
        ai = "import 'dart:async';\n$ai";
        stdout.writeln('✅ dart:async import joda');
      }

      if (!ai.contains('_aiCtxCache =')) {
        ai =
            '${ai.trimRight()}\n\n// Chat context cache (90 second): har message par Firestore dobara na jaye\nfinal Map<String, Map<String, dynamic>> _aiCtxCache = {};\nfinal Map<String, DateTime> _aiCtxCacheAt = {};\n';
      }

      aiFile.writeAsStringSync(ai);
    }
  }

  stdout.writeln('');
  if (failed == 0) {
    stdout.writeln(
        '🎉 Ho gaya. Ab: dart format lib/screens/shell_screen.dart lib/services/ai_service.dart && dart analyze lib/screens lib/services && flutter run');
  } else {
    stdout.writeln(
        '⚠️  $failed hissa nahi laga. Wapas jaane ke liye: git checkout -- lib/');
  }
}

// ===============================================================
// Naya code: ai_service.dart
// ===============================================================

const _userContextCode = r'''
Future<Map<String, dynamic>> _getUserContext(String uid) async {
  // ai-speed-v1
  if (uid.isEmpty || uid.length > 128) return _getDefaultContext();

  // 90 second ke andar dobara poochho to Firestore dobara nahi jata
  final cached = _aiCtxCache[uid];
  final cachedAt = _aiCtxCacheAt[uid];
  if (cached != null &&
      cachedAt != null &&
      DateTime.now().difference(cachedAt) < const Duration(seconds: 90)) {
    return cached;
  }

  // Ek read fail ho to baqi context phir bhi chale
  Future<T?> safe<T>(Future<T> f) async {
    try {
      return await f;
    } catch (_) {
      return null;
    }
  }

  try {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final userRef = _firestore.collection('users').doc(uid);

    // Chaaron reads ek saath shuru (pehle ek ke baad ek hote the)
    final userF = safe(userRef.get());
    final goalsF = safe(userRef.collection('goals').doc('main').get());
    final logF = safe(userRef.collection('dailyLogs').doc(dateStr).get());
    final workoutsF = safe(
      userRef
          .collection('workouts')
          .where('startedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get(),
    );

    final userDoc = await userF;
    final goalsDoc = await goalsF;
    final logDoc = await logF;
    final workoutsSnap = await workoutsF;

    final userData = userDoc?.data() ?? {};

    Map<String, dynamic> goals = {
      'caloriesGoal': 2000,
      'proteinGoal': 100,
      'waterGoal': 8
    };
    if (goalsDoc != null && goalsDoc.exists) {
      goals = {...goals, ...?goalsDoc.data()};
    }

    Map<String, dynamic> todayLog = {'calories': 0, 'protein': 0, 'water': 0};
    if (logDoc != null && logDoc.exists) {
      todayLog = {...todayLog, ...?logDoc.data()};
    }

    final todayWorkouts = workoutsSnap?.docs.length ?? 0;

    final result = <String, dynamic>{
      'name': _sanitizeInput(userData['name']?.toString() ?? 'Champ'),
      'fitnessLevel': _sanitizeInput(
          userData['fitnessLevel']?.toString() ?? 'Intermediate'),
      'goal': _sanitizeInput(userData['goal']?.toString() ?? 'Stay Fit'),
      'weight': (userData['weight'] as num?)?.toInt() ?? 70,
      'height': (userData['height'] as num?)?.toInt() ?? 170,
      'caloriesGoal': (goals['caloriesGoal'] as num?)?.toInt() ?? 2000,
      'proteinGoal': (goals['proteinGoal'] as num?)?.toInt() ?? 100,
      'waterGoal': (goals['waterGoal'] as num?)?.toInt() ?? 8,
      'todayCalories': (todayLog['calories'] as num?)?.toInt() ?? 0,
      'todayProtein': (todayLog['protein'] as num?)?.toInt() ?? 0,
      'todayWater': (todayLog['water'] as num?)?.toInt() ?? 0,
      'todayWorkouts': todayWorkouts,
    };

    _aiCtxCache[uid] = result;
    _aiCtxCacheAt[uid] = DateTime.now();
    return result;
  } catch (_) {
    return _getDefaultContext();
  }
}''';

// ===============================================================
// Naya code: shell_screen.dart
// ===============================================================

const _shellBuildCode = r'''
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: FitGenieTheme.bg,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(child: _buildCurrentPage()),
          if (_showBanner) const BannerAdWidget(),
        ],
      ),
    ),
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: FitGenieTheme.card2,
        border: Border(top: BorderSide(color: FitGenieTheme.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: FitGenieTheme.card2,
        selectedItemColor: FitGenieTheme.primary,
        unselectedItemColor: FitGenieTheme.muted,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppStrings.get('shell_nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_outlined),
            activeIcon: const Icon(Icons.restaurant),
            label: AppStrings.get('shell_nav_nutrition'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.fitness_center_outlined),
            activeIcon: const Icon(Icons.fitness_center),
            label: AppStrings.get('shell_nav_workout'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.trending_up_outlined),
            activeIcon: const Icon(Icons.trending_up),
            label: AppStrings.get('shell_nav_progress'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: AppStrings.get('shell_nav_profile'),
          ),
        ],
      ),
    ),
  );
}''';

const _coachStateCode = r'''
class _AICoachScreenState extends State<_AICoachScreen>
    with TickerProviderStateMixin {
  // chat-v2
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _addWelcomeMessage();
  }

  /// Loading flag + typing animation ek saath (animation sirf tab chale jab zaroorat ho)
  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _typingAnimationController.repeat();
    } else {
      _typingAnimationController.stop();
    }
  }

  void _addWelcomeMessage() {
    final name = widget.userName.isNotEmpty
        ? widget.userName
        : AppStrings.get('shell_champ_fallback');
    _messages.add(_ChatMessage(
      text: AppStrings.get('chat_welcome', params: {'name': name}),
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  // Firestore error / offline mein user ko block nahi karte
  Future<bool> _consumeQuota() async {
    try {
      return await ChatQuotaService.instance.tryConsume();
    } catch (_) {
      return true;
    }
  }

  Future<void> _offerChatBonus(String text) async {
    if (!mounted) return;
    final watch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('ad_chat_limit_title')),
        content: Text(AppStrings.get('ad_chat_limit_body',
            params: {'count': '${ChatQuotaService.bonusPerAd}'})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.get('chat_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
            child: Text(AppStrings.get('ad_watch')),
          ),
        ],
      ),
    );
    if (watch != true || !mounted) return;

    final result = await AdManager.instance.showRewarded(RewardKind.chat);
    if (!mounted) return;
    if (result == RewardResult.dismissed) {
      AppSnackbar.showInfo(context, AppStrings.get('ad_not_completed'));
      return;
    }
    await ChatQuotaService.instance.addBonus();
    if (mounted) await _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    final userMessage = text.trim();
    // Guard: pehle tap par hi lock lag jata hai, to 2-3 tap par 2-3 message nahi jate
    if (userMessage.isEmpty || _isLoading) return;

    // Foran (kisi await se pehle): text box saaf, user ka message screen par, lock
    final userMsg = _ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _controller.clear();
    setState(() {
      _messages.add(userMsg);
      _setLoading(true);
    });
    _scrollToBottom();

    // Quota check ab baad mein (message pehle hi dikh chuka hai)
    final allowed = await _consumeQuota();
    if (!mounted) return;

    if (!allowed) {
      // Limit khatam: message wapas lo aur text box mein bhi wapas rakho
      setState(() {
        _messages.remove(userMsg);
        _setLoading(false);
      });
      _controller.text = userMessage;
      _controller.selection =
          TextSelection.collapsed(offset: userMessage.length);
      await _offerChatBonus(userMessage);
      return;
    }

    String reply;
    try {
      reply = await _aiService.chat(
        uid: widget.userId,
        userMessage: userMessage,
      );
    } catch (e) {
      reply = AppStrings.get('chat_error');
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _setLoading(false);
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: FitGenieTheme.bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: 16,
                ),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index], isSmallScreen);
                },
              ),
            ),
            _buildQuickActions(),
            _buildInputArea(isSmallScreen),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final t = Theme.of(context).textTheme;
    return AppBar(
      backgroundColor: FitGenieTheme.bg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.get('shell_ai_coach_title'), style: t.headlineSmall),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? FitGenieTheme.warning
                      : FitGenieTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isLoading
                    ? AppStrings.get('chat_thinking')
                    : AppStrings.get('chat_online'),
                style: const TextStyle(
                  fontSize: 11,
                  color: FitGenieTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline,
              color: FitGenieTheme.muted, size: 22),
          tooltip: AppStrings.get('shell_about_ai_coach'),
          onPressed: _showAboutDialog,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline,
              color: FitGenieTheme.muted, size: 22),
          tooltip: AppStrings.get('shell_clear_chat'),
          onPressed: _showClearChatDialog,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: FitGenieTheme.border),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: FitGenieTheme.bg,
        border: Border(top: BorderSide(color: FitGenieTheme.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _buildQuickChip(AppStrings.get('chat_workout'),
              'Aaj ke liye best workout plan batao'),
          _buildQuickChip(
              AppStrings.get('chat_diet'), 'Mera diet plan bana do'),
          _buildQuickChip(
              AppStrings.get('chat_motivate'), 'Mujhe motivate karo!'),
          _buildQuickChip(
              AppStrings.get('chat_weight_loss'), 'Weight loss tips do'),
          _buildQuickChip(
              AppStrings.get('chat_muscle_gain'), 'Muscle kaise banaye?'),
          _buildQuickChip(AppStrings.get('chat_hydration'),
              'Pani kitna peena chahiye?'),
          _buildQuickChip(
              AppStrings.get('chat_recovery'), 'Recovery tips batao'),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String message) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: _isLoading ? null : () => _sendMessage(message),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FitGenieTheme.border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isLoading
                    ? FitGenieTheme.muted
                    : FitGenieTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 16,
        10,
        isSmallScreen ? 12 : 16,
        12,
      ),
      decoration: const BoxDecoration(
        color: FitGenieTheme.bg,
        border: Border(top: BorderSide(color: FitGenieTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: FitGenieTheme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: FitGenieTheme.border),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  color: FitGenieTheme.text,
                  fontSize: 15,
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: AppStrings.get('chat_placeholder'),
                  hintStyle: const TextStyle(
                    color: FitGenieTheme.muted,
                    fontSize: 14,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLoading ? FitGenieTheme.border : FitGenieTheme.primary,
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: FitGenieTheme.muted,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward_rounded,
                      color: FitGenieTheme.onPrimary,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, bool isSmallScreen) {
    final maxWidth =
        MediaQuery.of(context).size.width * (isSmallScreen ? 0.86 : 0.8);
    final isUser = message.isUser;
    final textColor = isUser ? FitGenieTheme.onPrimary : FitGenieTheme.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 14 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isUser ? FitGenieTheme.primary : FitGenieTheme.card,
                  border: isUser
                      ? null
                      : Border.all(color: FitGenieTheme.border),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: _buildFormattedText(
                    message.text, isSmallScreen, textColor),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: FitGenieTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isSmallScreen, Color color) {
    final lines = text.split('\n');
    final List<Widget> widgets = [];
    final fontSize = isSmallScreen ? 13.5 : 14.5;

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (line.contains('**')) {
        widgets.add(_buildRichText(line, fontSize, color));
      } else if (line.contains('━━━')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(height: 1, color: FitGenieTheme.border),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            line,
            style: TextStyle(color: color, fontSize: fontSize, height: 1.5),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(String line, double fontSize, Color color) {
    final regex = RegExp(r'\*\*(.*?)\*\*');
    final matches = regex.allMatches(line);
    final baseStyle = TextStyle(color: color, fontSize: fontSize, height: 1.5);

    if (matches.isEmpty) return Text(line, style: baseStyle);

    final List<TextSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd)));
    }

    return RichText(text: TextSpan(style: baseStyle, children: spans));
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: FitGenieTheme.card,
            border: Border.all(color: FitGenieTheme.border),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypingDot(0),
              const SizedBox(width: 4),
              _buildTypingDot(1),
              const SizedBox(width: 4),
              _buildTypingDot(2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final value = (_typingAnimationController.value + index * 0.2) % 1.0;
        final wave = 0.5 - (value - 0.5).abs();
        final size = 6.0 + (2.0 * wave * 2);
        final opacity = 0.3 + (0.7 * wave * 2);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: FitGenieTheme.textSecondary.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('chat_about_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('chat_about_powered'),
              style: const TextStyle(color: FitGenieTheme.muted),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('chat_about_features'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(AppStrings.get('chat_about_workouts')),
            Text(AppStrings.get('chat_about_nutrition')),
            Text(AppStrings.get('chat_about_motivation')),
            Text(AppStrings.get('chat_about_progress')),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('chat_about_data'),
              style: const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('chat_got_it')),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('chat_clear_title')),
        content: Text(AppStrings.get('chat_clear_sub')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('chat_cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
              HapticFeedback.lightImpact();
            },
            style: FilledButton.styleFrom(
              backgroundColor: FitGenieTheme.error,
              minimumSize: const Size(96, 46),
            ),
            child: Text(AppStrings.get('chat_clear')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }
}''';
