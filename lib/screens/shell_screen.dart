// lib/screens/shell_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/fitgenie_theme.dart';
import '../services/ai_service.dart';
import 'dashboard_screen.dart';
import 'calories_screen.dart';
import 'workout_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

// ============ MAIN SHELL SCREEN ============

class ShellScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ShellScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  void _goToWorkout() {
    setState(() => _currentIndex = 2);
  }

  void _openAICoach() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AICoachScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.background,
      body: SafeArea(
        child: _buildCurrentPage(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1A1A1A),
          selectedItemColor: FitGenieTheme.primary,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_outlined),
              activeIcon: Icon(Icons.restaurant),
              label: 'Nutrition',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Workout',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(
          userId: widget.userId,
          userName: widget.userName,
          onTapWorkout: _goToWorkout,
          onTapAICoach: _openAICoach,
        );
      case 1:
        return CaloriesScreen(userId: widget.userId);
      case 2:
        return WorkoutScreen(userId: widget.userId);
      case 3:
        return ProgressScreen(userId: widget.userId);
      case 4:
        return ProfileScreen(userId: widget.userId);
      default:
        return DashboardScreen(
          userId: widget.userId,
          userName: widget.userName,
          onTapWorkout: _goToWorkout,
          onTapAICoach: _openAICoach,
        );
    }
  }
}

// ============ PROFESSIONAL AI COACH SCREEN ============

class _AICoachScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const _AICoachScreen({
    required this.userId,
    required this.userName,
  });

  @override
  State<_AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<_AICoachScreen> with TickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final name = widget.userName.isNotEmpty ? widget.userName : 'Champ';
    _messages.add(_ChatMessage(
      text: '''👋 Hey $name!

🤖 Main hoon **FitGenie** — tera personal AI Fitness Coach!

━━━━━━━━━━━━━━━━━━━━━━━━

🎯 **Main help kar sakta hun:**

💪 **Workouts**
   Muscle-specific exercises & plans

🍽️ **Nutrition**  
   Diet plans & calorie guidance

🔥 **Motivation**
   Daily inspiration & tips

📊 **Progress**
   Track & improve karne mein

━━━━━━━━━━━━━━━━━━━━━━━━

Neeche quick buttons use karo ya type karo!

**Let's get started! 🚀**''',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = text.trim();
    _controller.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(_ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _aiService.chat(
        uid: widget.userId,
        userMessage: userMessage,
      );

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: '''❌ **Oops! Kuch gadbad ho gayi.**

Please dobara try karo ya internet check karo.

💡 Tip: Neeche quick buttons bhi try kar sakte ho!''',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
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

            // Quick Action Chips
            _buildQuickActions(),

            // Input Area
            _buildInputArea(isSmallScreen),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // AI Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FitGenieTheme.primary,
                  FitGenieTheme.primary.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: FitGenieTheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FitGenie AI Coach',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.orange : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLoading ? 'Thinking...' : 'Online • Ready to help',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isLoading ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Info Button
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white70, size: 22),
          tooltip: 'About AI Coach',
          onPressed: _showAboutDialog,
        ),
        // Clear Chat Button
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 22),
          tooltip: 'Clear Chat',
          onPressed: _showClearChatDialog,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _buildQuickChip('💪', 'Workout', 'Aaj ke liye best workout plan batao'),
          _buildQuickChip('🍽️', 'Diet Plan', 'Mera diet plan bana do'),
          _buildQuickChip('🔥', 'Motivate', 'Mujhe motivate karo!'),
          _buildQuickChip('📉', 'Weight Loss', 'Weight loss tips do'),
          _buildQuickChip('💪', 'Muscle Gain', 'Muscle kaise banaye?'),
          _buildQuickChip('💧', 'Hydration', 'Pani kitna peena chahiye?'),
          _buildQuickChip('😴', 'Recovery', 'Recovery tips batao'),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String emoji, String label, String message) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : () => _sendMessage(message),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: FitGenieTheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
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
        12,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: FitGenieTheme.primary.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 14 : 15,
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask me anything about fitness...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                    vertical: isSmallScreen ? 12 : 14,
                  ),
                  isDense: true,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                enabled: !_isLoading,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send Button
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(_controller.text),
            child: Container(
              width: isSmallScreen ? 46 : 52,
              height: isSmallScreen ? 46 : 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [Colors.grey, Colors.grey.shade700]
                      : [FitGenieTheme.primary, FitGenieTheme.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? []
                    : [
                  BoxShadow(
                    color: FitGenieTheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                color: Colors.white,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, bool isSmallScreen) {
    final maxWidth = MediaQuery.of(context).size.width * (isSmallScreen ? 0.85 : 0.78);
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Avatar (left side for AI messages)
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FitGenieTheme.primary,
                    FitGenieTheme.primary.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],

          // Message Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 14 : 16,
                vertical: isSmallScreen ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? FitGenieTheme.primary
                    : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? FitGenieTheme.primary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Text with formatting
                  _buildFormattedText(message.text, isSmallScreen),

                  // Timestamp
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all, size: 12, color: Colors.white70),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // User Avatar (right side for user messages)
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isSmallScreen) {
    // Simple markdown-like formatting
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Handle bold text with **
      if (line.contains('**')) {
        widgets.add(_buildRichText(line, isSmallScreen));
      }
      // Handle headers with ━━━
      else if (line.contains('━━━')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            height: 1,
            color: FitGenieTheme.primary.withOpacity(0.3),
          ),
        ));
      }
      // Regular text
      else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            line,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 13.5 : 14.5,
              height: 1.5,
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(String line, bool isSmallScreen) {
    final regex = RegExp(r'\*\*(.*?)\*\*');
    final matches = regex.allMatches(line);

    if (matches.isEmpty) {
      return Text(
        line,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 13.5 : 14.5,
          height: 1.5,
        ),
      );
    }

    final List<TextSpan> spans = [];
    int lastEnd = 0;

    for (var match in matches) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
      }
      // Add bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 13.5 : 14.5,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FitGenieTheme.primary,
                  FitGenieTheme.primary.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          // Typing Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
                const SizedBox(width: 12),
                Text(
                  'FitGenie is thinking...',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final value = (_typingAnimationController.value + index * 0.2) % 1.0;
        final size = 6.0 + (2.0 * (0.5 - (value - 0.5).abs()) * 2);
        final opacity = 0.3 + (0.7 * (0.5 - (value - 0.5).abs()) * 2);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: FitGenieTheme.primary.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: FitGenieTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology, color: FitGenieTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('FitGenie AI Coach'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Powered by Google Gemini AI',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              '🎯 Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Personalized workout plans'),
            Text('• Diet & nutrition advice'),
            Text('• Motivation & tips'),
            Text('• Progress tracking help'),
            SizedBox(height: 16),
            Text(
              '💡 Your data is used to personalize responses.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear Chat?'),
          ],
        ),
        content: const Text('Saari messages delete ho jayengi. Ye action undo nahi hoga.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
              HapticFeedback.lightImpact();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
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
}

// ============ CHAT MESSAGE MODEL ============

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
