// lib/services/ai_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/language_provider.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════
  // 🚀 GROQ PROXY (Cloudflare Worker)
  // Groq key sirf Worker pe rehti hai. App mein koi API key nahi.
  // ═══════════════════════════════════════════
  static const String _proxyUrl =
      'https://fitgenie-ai.fahadsaeed2622.workers.dev';

  static bool get isConfigured =>
      _proxyUrl.isNotEmpty && !_proxyUrl.contains('YOUR-SUBDOMAIN');

  Future<String?> _callProxy({
    required String task, // 'chat' | 'scan'
    required String prompt,
    String? imageBase64,
  }) async {
    if (!isConfigured) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    String token;
    try {
      token = await user.getIdToken() ?? '';
    } catch (e) {
      debugPrint('⚠️ Token error: $e');
      return null;
    }
    if (token.isEmpty) return null;

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await http
            .post(
              Uri.parse(_proxyUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'task': task,
                'prompt': prompt,
                if (imageBase64 != null) 'imageBase64': imageBase64,
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final text = data['text'];
          if (text is String && text.trim().isNotEmpty) {
            debugPrint('✅ Proxy ok (${data['model']})');
            return text.trim();
          }
          return null;
        }

        debugPrint('⚠️ Proxy failed: ${res.statusCode} ${res.body}');
        final retryable = res.statusCode == 429 || res.statusCode >= 500;
        if (!retryable) return null;
      } catch (e) {
        debugPrint('⚠️ Proxy error: $e');
      }
      if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  static String _sanitizeInput(String input) {
    if (input.isEmpty) return '';
    String cleaned = input.trim();
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'(javascript|script|onclick|onerror)', caseSensitive: false),
        '');
    if (cleaned.length > 1000) cleaned = cleaned.substring(0, 1000);
    return cleaned;
  }

  static String _validateResponse(String response) {
    if (response.isEmpty) return 'Koi response nahi aaya, dobara try kar.';
    String cleaned = response.trim();
    cleaned = cleaned.replaceAll(
        RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    return cleaned;
  }

  // ==========================================
  // 📸 MEAL PHOTO SCANNER
  // ==========================================

  Future<MealAnalysis> analyzeMealPhoto(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await analyzeMealFromBytes(bytes);
    } catch (e) {
      debugPrint('❌ Meal analysis error: $e');
      return _getDefaultMealAnalysis();
    }
  }

  Future<MealAnalysis> analyzeMealFromBytes(Uint8List bytes) async {
    debugPrint('📸 Analyzing meal photo... ${bytes.length} bytes');

    if (!isConfigured) return _getDefaultMealAnalysis();

    if (bytes.length > 10 * 1024 * 1024) {
      return MealAnalysis(
        foodName: 'Image Too Large',
        foodNameHindi: 'Photo bahut badi hai',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        quantity: '0',
        isHealthy: false,
        healthTip: 'Photo 10MB se chhoti honi chahiye. Compress karke bhejo.',
      );
    }

    if (bytes.length < 1000) return _getDefaultMealAnalysis();

    final base64Image = base64Encode(bytes);
    final isEnglish = LanguageProvider().isEnglish;
    final tipLanguage = isEnglish
        ? 'Write the healthTip in plain English.'
        : 'Write the healthTip in Roman Urdu / Hinglish (Hindi+English mix, Latin script only, no Hindi script).';

    final prompt = '''
You are a nutrition and fitness assistant.

Analyze the food image and estimate nutrition values only.

The nutrition values are estimates and may not be completely accurate.

Do not diagnose diseases, allergies, deficiencies, or medical conditions.

Do not provide medical advice or treatment.

Always keep healthTip general wellness advice only.

Analyze this food image carefully.
Return ONLY a valid JSON object (no markdown, no code blocks, just pure JSON):
{
  "foodName": "English name",
  "foodNameHindi": "Local/common name (e.g. Roti, Dal, Biryani)",
  "calories": 250, "protein": 10, "carbs": 30, "fat": 8, "fiber": 3,
  "quantity": "1 plate or 1 serving",
  "isHealthy": true,
  "healthTip": "One short tip"
}
$tipLanguage
All numbers should be integers. isHealthy should be boolean.''';

    final proxied = await _callProxy(
        task: 'scan', prompt: prompt, imageBase64: base64Image);
    if (proxied != null) return MealAnalysis.fromJson(proxied);
    return _getDefaultMealAnalysis();
  }

  MealAnalysis _getDefaultMealAnalysis() {
    return MealAnalysis(
      foodName: 'Food Item',
      foodNameHindi: 'Khana',
      calories: 200,
      protein: 8,
      carbs: 25,
      fat: 8,
      fiber: 3,
      quantity: '1 serving',
      isHealthy: true,
      healthTip:
          'Analysis nahi ho payi. Manually enter karo ya clear photo lo.',
    );
  }

  // ==========================================
  // 🤖 MAIN CHAT FUNCTION
  // ==========================================

  Future<String> chat(
      {required String uid, required String userMessage}) async {
    debugPrint('🚀 AI Chat Started');

    final cleanMessage = _sanitizeInput(userMessage);
    if (cleanMessage.isEmpty) return 'Kuch toh likh bhai! 😄';
    if (!isConfigured) return '❌ AI service set nahi hai. Baad mein try kar.';
    if (cleanMessage.length > 500) {
      return 'Bhai message thoda chhota rakh — 500 characters max! ✂️';
    }

    try {
      final userContext = await _getUserContext(uid);

      final prompt = '''
IMPORTANT HEALTH & SAFETY RULES

You are FitGenie, an AI fitness and wellness assistant.

You provide general fitness, exercise, nutrition, and healthy lifestyle information only.

Never provide medical advice, diagnosis, prescriptions, treatment plans, or emergency guidance.

Never recommend medicines or claim to cure diseases.

If a user mentions pain, injury, chest pain, dizziness, pregnancy, diabetes, heart disease, high blood pressure, allergies, or any medical condition, politely advise them to consult a qualified healthcare professional.

Always remind users that your responses are for informational purposes only and are not a substitute for professional medical advice.

Tu "FitGenie" hai ek friendly AI Fitness Coach!

📋 LANGUAGE RULES: Response HINGLISH mein de (Hindi + English MIX)
• English: workout, calories, protein, exercise, sets, reps, diet, goal
• Hindi: karo, hai, hain, tera, mera, acha, bahut, ke liye, mein, se
• Casual & friendly — gym buddy ki tarah baat karo
• DO NOT use pure Hindi script

👤 USER INFO:
• Name: ${userContext['name']} | Goal: ${userContext['goal']}
• Today: ${userContext['todayCalories']}/${userContext['caloriesGoal']} kcal | ${userContext['todayProtein']}/${userContext['proteinGoal']}g protein

✍️ FORMAT: Greeting + 3-5 bullet tips + motivation. Use emojis 💪🔥🎯✅

❓ USER QUESTION: $cleanMessage

Max 150 words:''';

      final result = await _callProxy(task: 'chat', prompt: prompt);
      if (result != null) {
        final formatted = _formatResponse(_validateResponse(result));
        await _saveChatHistory(uid, cleanMessage, formatted);
        return formatted;
      }

      return _getSmartOfflineResponse(cleanMessage, userContext);
    } catch (e, st) {
      debugPrint('💥 AIService Exception: $e');
      if (kDebugMode) debugPrintStack(stackTrace: st);
      return _getSmartOfflineResponse(cleanMessage, {});
    }
  }

  String _formatResponse(String response) {
    return response.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  Future<Map<String, dynamic>> _getUserContext(String uid) async {
    if (uid.isEmpty || uid.length > 128) return _getDefaultContext();

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      Map<String, dynamic> goals = {
        'caloriesGoal': 2000,
        'proteinGoal': 100,
        'waterGoal': 8
      };
      try {
        final goalsDoc = await _firestore
            .collection('users')
            .doc(uid)
            .collection('goals')
            .doc('main')
            .get();
        if (goalsDoc.exists) goals = {...goals, ...?goalsDoc.data()};
      } catch (_) {}

      Map<String, dynamic> todayLog = {'calories': 0, 'protein': 0, 'water': 0};
      try {
        final today = DateTime.now();
        final dateStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final todayLogDoc = await _firestore
            .collection('users')
            .doc(uid)
            .collection('dailyLogs')
            .doc(dateStr)
            .get();
        if (todayLogDoc.exists) {
          todayLog = {...todayLog, ...?todayLogDoc.data()};
        }
      } catch (_) {}

      int todayWorkouts = 0;
      try {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        final q = await _firestore
            .collection('users')
            .doc(uid)
            .collection('workouts')
            .where('startedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('startedAt', isLessThan: Timestamp.fromDate(endOfDay))
            .get();
        todayWorkouts = q.docs.length;
      } catch (_) {}

      return {
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
    } catch (_) {
      return _getDefaultContext();
    }
  }

  Map<String, dynamic> _getDefaultContext() => {
        'name': 'Champ',
        'fitnessLevel': 'Intermediate',
        'goal': 'Stay Fit',
        'weight': 70,
        'height': 170,
        'caloriesGoal': 2000,
        'proteinGoal': 100,
        'waterGoal': 8,
        'todayCalories': 0,
        'todayProtein': 0,
        'todayWater': 0,
        'todayWorkouts': 0,
      };

  String _getSmartOfflineResponse(
      String message, Map<String, dynamic> context) {
    final msg = message.toLowerCase();
    final name = context['name'] ?? 'Champ';

    if (msg.contains('workout') ||
        msg.contains('exercise') ||
        msg.contains('gym')) {
      return '''💪 Hey $name! Workout tips chahiye?\n\n🎯 Quick Tips:\n• Warm-up zaroor karo (5-10 min)\n• Compound exercises pe focus karo\n• Progressive overload important hai\n• Rest days bhi zaroori hain!\n\n🔥 Let's crush it bhai! 💪''';
    }
    if (msg.contains('diet') ||
        msg.contains('food') ||
        msg.contains('calories') ||
        msg.contains('protein')) {
      return '''🍽️ Hey $name! Diet tips:\n\n• Protein har meal mein include karo\n• Processed food avoid karo\n• Vegetables zyada khao\n• Water 3-4 liters daily\n\n🔥 Consistency is key! 🎯''';
    }
    return '''👋 Hey $name!\n\nMain FitGenie hun - tera AI Fitness Coach! 🤖\n\nKya jaanna hai?\n• 💪 Workouts\n• 🍽️ Nutrition\n• 🔥 Motivation\n\nPooch lo! 🚀''';
  }

  Future<void> _saveChatHistory(
      String uid, String userMsg, String aiResponse) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).collection('aiChats').add({
        'userMessage':
            userMsg.substring(0, userMsg.length > 500 ? 500 : userMsg.length),
        'aiResponse': aiResponse.substring(
            0, aiResponse.length > 2000 ? 2000 : aiResponse.length),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<String> generateWorkout(
      {required String uid,
      required String workoutType,
      String level = 'intermediate'}) async {
    final cleanType = _sanitizeInput(workoutType);
    if (cleanType.isEmpty) return _getOfflineWorkout('chest');

    try {
      final userContext = await _getUserContext(uid);
      final prompt = '''IMPORTANT HEALTH & SAFETY RULES

You are FitGenie, an AI fitness and wellness assistant.

You provide general fitness, exercise, nutrition, and healthy lifestyle information only.

Never provide medical advice, diagnosis, prescriptions, treatment plans, or emergency guidance.

Never recommend medicines, supplements for treating diseases, dosages, or claim to cure any medical condition.

If a user mentions pain, injury, chest pain, dizziness, pregnancy, diabetes, heart disease, high blood pressure, mental health concerns, allergies, or any medical condition, politely tell them to consult a qualified healthcare professional.

Always remind users that your responses are for informational and educational purposes only and are not a substitute for professional medical advice, diagnosis, or treatment.

If a request is medical, politely refuse to diagnose and recommend consulting a healthcare professional instead.You are FitGenie's AI Fitness Coach.

Create safe workout plans only.

Do not provide medical advice or rehabilitation programs.

If the workout request involves injuries, pain, surgery recovery, pregnancy, or any medical condition, recommend consulting a qualified healthcare professional before exercising.

All workout plans are for general fitness purposes only. $cleanType workout plan de in Hinglish.
Client: ${userContext['name']}, Level: $level
Format: 🔥 Name | ⚡ Warm-up | 💪 Main (5-6 exercises sets x reps) | 🧘 Cool down | 💡 Tip''';

      final result = await _callProxy(task: 'chat', prompt: prompt);
      if (result != null) return _formatResponse(_validateResponse(result));
      return _getOfflineWorkout(cleanType);
    } catch (e) {
      return _getOfflineWorkout(cleanType);
    }
  }

  String _getOfflineWorkout(String type) {
    final workouts = {
      'chest':
          '🔥 CHEST WORKOUT\n\n⚡ WARM-UP\n• Arm circles - 30 sec\n• Push-up hold - 30 sec\n\n💪 MAIN\n1. Bench Press - 4x10-12\n2. Incline DB Press - 4x12\n3. Cable Flyes - 3x15\n4. Dips - 3x12\n5. Push-ups - 3xFailure\n\n💡 Mind-muscle connection important hai!\n\n🔥 Chest day is BEST day! 💪',
      'back':
          '🔥 BACK WORKOUT\n\n⚡ WARM-UP\n• Band pull-aparts - 15 reps\n• Dead hangs - 30 sec\n\n💪 MAIN\n1. Pull-ups - 4x8-10\n2. Barbell Rows - 4x10\n3. Lat Pulldown - 3x12\n4. DB Rows - 3x12\n5. Face Pulls - 3x15\n\n💡 Squeeze your back at top!\n\n🔥 Strong back = Strong everything! 🎯',
      'legs':
          '🔥 LEG WORKOUT\n\n⚡ WARM-UP\n• Bodyweight squats - 15 reps\n• Leg swings - 10 each\n\n💪 MAIN\n1. Squats - 4x8-10\n2. Romanian Deadlift - 4x10\n3. Leg Press - 3x12\n4. Lunges - 3x12 each\n5. Calf Raises - 4x15\n\n💡 Never skip leg day!\n\n🔥 Leg day = Best day! 🦵💪',
    };
    return workouts[type.toLowerCase()] ?? workouts['chest']!;
  }
}

// ==========================================
// 📊 MEAL ANALYSIS MODEL
// ==========================================
class MealAnalysis {
  final String foodName;
  final String foodNameHindi;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final String quantity;
  final bool isHealthy;
  final String healthTip;

  MealAnalysis({
    required this.foodName,
    required this.foodNameHindi,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.quantity,
    required this.isHealthy,
    required this.healthTip,
  });

  factory MealAnalysis.fromJson(String jsonString) {
    try {
      String cleaned = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .replaceAll('`', '')
          .trim();
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        throw Exception('No valid JSON found');
      }

      final Map<String, dynamic> json =
          jsonDecode(cleaned.substring(start, end + 1));

      return MealAnalysis(
        foodName: (json['foodName']?.toString() ?? 'Food Item').substring(0,
            (json['foodName']?.toString() ?? 'Food Item').length.clamp(0, 100)),
        foodNameHindi: (json['foodNameHindi']?.toString() ?? 'Khana').substring(
            0,
            (json['foodNameHindi']?.toString() ?? 'Khana')
                .length
                .clamp(0, 100)),
        calories: _parseInt(json['calories']).clamp(0, 5000),
        protein: _parseInt(json['protein']).clamp(0, 500),
        carbs: _parseInt(json['carbs']).clamp(0, 1000),
        fat: _parseInt(json['fat']).clamp(0, 500),
        fiber: _parseInt(json['fiber']).clamp(0, 200),
        quantity: (json['quantity']?.toString() ?? '1 serving').substring(0,
            (json['quantity']?.toString() ?? '1 serving').length.clamp(0, 50)),
        isHealthy: json['isHealthy'] == true ||
            json['isHealthy'].toString().toLowerCase() == 'true',
        healthTip: (json['healthTip']?.toString() ?? 'Enjoy your meal!')
            .substring(
                0,
                (json['healthTip']?.toString() ?? 'Enjoy your meal!')
                    .length
                    .clamp(0, 200)),
      );
    } catch (e) {
      debugPrint('❌ JSON parse error: $e');
      return MealAnalysis(
        foodName: 'Food Item',
        foodNameHindi: 'Khana',
        calories: 200,
        protein: 10,
        carbs: 25,
        fat: 8,
        fiber: 3,
        quantity: '1 serving',
        isHealthy: true,
        healthTip: 'Photo se identify nahi ho paya. Clear photo lo.',
      );
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''))
              ?.toInt() ??
          0;
    }
    return 0;
  }

  Map<String, dynamic> toMap() => {
        'foodName': foodName,
        'foodNameHindi': foodNameHindi,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'quantity': quantity,
        'isHealthy': isHealthy,
        'healthTip': healthTip,
      };
}
