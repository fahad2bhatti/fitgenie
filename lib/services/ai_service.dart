// lib/services/ai_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════
  // 🔒 SECURE API KEY — loaded from .env file
  // ═══════════════════════════════════════════
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty) {
      debugPrint('❌ GEMINI_API_KEY not found in .env file!');
    }
    return key;
  }

  static bool get isConfigured => _apiKey.isNotEmpty && _apiKey.length > 20;

  static const Duration _timeout = Duration(seconds: 30);

  static String _sanitizeInput(String input) {
    if (input.isEmpty) return '';
    String cleaned = input.trim();
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'(javascript|script|onclick|onerror)', caseSensitive: false), '');
    if (cleaned.length > 1000) cleaned = cleaned.substring(0, 1000);
    return cleaned;
  }

  static String _validateResponse(String response) {
    if (response.isEmpty) return 'Koi response nahi aaya, dobara try kar.';
    String cleaned = response.trim();
    cleaned = cleaned.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    return cleaned;
  }

  Future<List<String>> fetchModelNames() async {
    debugPrint('🔍 Fetching available models...');
    if (!isConfigured) return ['models/gemini-1.5-flash-latest'];

    final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode != 200) throw Exception('Models list failed ${response.statusCode}');
      final data = jsonDecode(response.body);
      final List models = (data['models'] as List?) ?? [];
      final names = <String>[];
      for (final m in models) {
        final name = m['name'];
        if (name is String && name.isNotEmpty) names.add(name);
      }
      debugPrint('✅ Found ${names.length} models');
      return names;
    } catch (e) {
      debugPrint('❌ Error fetching models: $e');
      return ['models/gemini-1.5-flash-latest'];
    }
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
        foodName: 'Image Too Large', foodNameHindi: 'Photo bahut badi hai',
        calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0,
        quantity: '0', isHealthy: false,
        healthTip: 'Photo 10MB se chhoti honi chahiye. Compress karke bhejo.',
      );
    }

    if (bytes.length < 1000) return _getDefaultMealAnalysis();

    try {
      final base64Image = base64Encode(bytes);
      final prompt = '''
You are a nutrition expert. Analyze this food image carefully.
Return ONLY a valid JSON object (no markdown, no code blocks, just pure JSON):
{
  "foodName": "English name",
  "foodNameHindi": "Hinglish name like Roti, Dal, Biryani",
  "calories": 250, "protein": 10, "carbs": 30, "fat": 8, "fiber": 3,
  "quantity": "1 plate or 1 serving",
  "isHealthy": true,
  "healthTip": "One short tip in Hinglish"
}
All numbers should be integers. isHealthy should be boolean.''';

      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [
            {'text': prompt},
            {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image}}
          ]}],
          'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 1000},
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
          ],
        }),
      ).timeout(const Duration(seconds: 60));

      debugPrint('📸 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          if (candidates[0]['finishReason'] == 'SAFETY') return _getDefaultMealAnalysis();
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.isNotEmpty) return MealAnalysis.fromJson(text);
          }
        }
      }
      return _getDefaultMealAnalysis();
    } catch (e) {
      debugPrint('❌ Meal analysis exception: $e');
      return _getDefaultMealAnalysis();
    }
  }

  MealAnalysis _getDefaultMealAnalysis() {
    return MealAnalysis(
      foodName: 'Food Item', foodNameHindi: 'Khana',
      calories: 200, protein: 8, carbs: 25, fat: 8, fiber: 3,
      quantity: '1 serving', isHealthy: true,
      healthTip: 'Analysis nahi ho payi. Manually enter karo ya clear photo lo.',
    );
  }

  Future<MealAnalysis> searchFood(String foodName) async {
    final cleanFoodName = _sanitizeInput(foodName);
    if (cleanFoodName.isEmpty) return _getDefaultMealAnalysis();
    if (!isConfigured) return _getOfflineFoodEstimate(cleanFoodName);

    try {
      final prompt = '''
Provide nutritional information for: "$cleanFoodName"
Return ONLY a valid JSON object (no markdown, no extra text):
{
  "foodName": "$cleanFoodName", "foodNameHindi": "Hinglish name",
  "calories": 200, "protein": 10, "carbs": 25, "fat": 8, "fiber": 3,
  "quantity": "1 serving", "isHealthy": true, "healthTip": "short Hinglish tip"
}''';
      final result = await _tryDirectModel(prompt);
      if (result != null) return MealAnalysis.fromJson(_validateResponse(result));
      return _getOfflineFoodEstimate(cleanFoodName);
    } catch (e) {
      return _getOfflineFoodEstimate(cleanFoodName);
    }
  }

  MealAnalysis _getOfflineFoodEstimate(String foodName) {
    final commonFoods = {
      'roti': MealAnalysis(foodName: 'Roti', foodNameHindi: 'Roti / Chapati', calories: 70, protein: 2, carbs: 15, fat: 1, fiber: 2, quantity: '1 roti', isHealthy: true, healthTip: 'Whole wheat roti fiber rich hoti hai!'),
      'rice': MealAnalysis(foodName: 'Rice', foodNameHindi: 'Chawal', calories: 130, protein: 3, carbs: 28, fat: 0, fiber: 1, quantity: '1 cup cooked', isHealthy: true, healthTip: 'Brown rice zyada healthy hai white rice se.'),
      'dal': MealAnalysis(foodName: 'Dal', foodNameHindi: 'Dal / Lentils', calories: 120, protein: 9, carbs: 20, fat: 1, fiber: 8, quantity: '1 bowl', isHealthy: true, healthTip: 'Dal protein ka best vegetarian source hai!'),
      'chicken': MealAnalysis(foodName: 'Chicken Curry', foodNameHindi: 'Chicken Curry', calories: 250, protein: 25, carbs: 5, fat: 15, fiber: 1, quantity: '1 serving', isHealthy: true, healthTip: 'Grilled chicken zyada healthy hai fried se.'),
      'egg': MealAnalysis(foodName: 'Egg', foodNameHindi: 'Anda', calories: 75, protein: 6, carbs: 1, fat: 5, fiber: 0, quantity: '1 egg', isHealthy: true, healthTip: 'Eggs complete protein source hain!'),
      'paneer': MealAnalysis(foodName: 'Paneer', foodNameHindi: 'Paneer', calories: 265, protein: 18, carbs: 3, fat: 20, fiber: 0, quantity: '100g', isHealthy: true, healthTip: 'Paneer protein rich hai but fat bhi high hai.'),
      'samosa': MealAnalysis(foodName: 'Samosa', foodNameHindi: 'Samosa', calories: 250, protein: 4, carbs: 25, fat: 15, fiber: 2, quantity: '1 piece', isHealthy: false, healthTip: 'Samosa tasty hai but fried hai - limit mein khao!'),
      'biryani': MealAnalysis(foodName: 'Biryani', foodNameHindi: 'Biryani', calories: 350, protein: 15, carbs: 45, fat: 12, fiber: 2, quantity: '1 plate', isHealthy: false, healthTip: 'Biryani heavy hai - portion control important!'),
    };

    final lowerName = foodName.toLowerCase();
    for (final key in commonFoods.keys) {
      if (lowerName.contains(key)) return commonFoods[key]!;
    }

    return MealAnalysis(
      foodName: foodName, foodNameHindi: foodName,
      calories: 200, protein: 8, carbs: 25, fat: 8, fiber: 3,
      quantity: '1 serving', isHealthy: true,
      healthTip: 'Estimated values - actual may vary.',
    );
  }

  // ==========================================
  // 🤖 MAIN CHAT FUNCTION
  // ==========================================

  Future<String> chat({required String uid, required String userMessage}) async {
    debugPrint('🚀 AI Chat Started');

    final cleanMessage = _sanitizeInput(userMessage);
    if (cleanMessage.isEmpty) return 'Kuch toh likh bhai! 😄';
    if (!isConfigured) return '❌ API Key set nahi hai! .env file check kar.';
    if (cleanMessage.length > 500) return 'Bhai message thoda chhota rakh — 500 characters max! ✂️';

    try {
      final userContext = await _getUserContext(uid);

      final prompt = '''
Tu "FitGenie" hai — ek friendly AI Fitness Coach! 🏋️

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

      final directResult = await _tryDirectModel(prompt);
      if (directResult != null) {
        final formatted = _formatResponse(_validateResponse(directResult));
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

  Future<String?> _tryDirectModel(String prompt) async {
    try {
      return await _callGeminiAPI('models/gemini-1.5-flash-latest', prompt);
    } catch (e) {
      debugPrint('⚠️ Direct model failed: $e');
      return null;
    }
  }

  Future<String?> _callGeminiAPI(String modelName, String prompt) async {
    if (!isConfigured) return null;

    final url = 'https://generativelanguage.googleapis.com/v1beta/$modelName:generateContent?key=$_apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1500, 'topP': 0.9, 'topK': 40},
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
          ],
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']?['parts']?[0]?['text'];
          if (text is String && text.trim().isNotEmpty) {
            debugPrint('✅ Success with $modelName');
            return text.trim();
          }
        }
      } else {
        debugPrint('❌ $modelName failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ API call error: $e');
    }
    return null;
  }

  String _formatResponse(String response) {
    return response.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  Future<Map<String, dynamic>> _getUserContext(String uid) async {
    if (uid.isEmpty || uid.length > 128) return _getDefaultContext();

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      Map<String, dynamic> goals = {'caloriesGoal': 2000, 'proteinGoal': 100, 'waterGoal': 8};
      try {
        final goalsDoc = await _firestore.collection('users').doc(uid).collection('goals').doc('main').get();
        if (goalsDoc.exists) goals = {...goals, ...?goalsDoc.data()};
      } catch (_) {}

      Map<String, dynamic> todayLog = {'calories': 0, 'protein': 0, 'water': 0};
      try {
        final today = DateTime.now();
        final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final todayLogDoc = await _firestore.collection('users').doc(uid).collection('dailyLogs').doc(dateStr).get();
        if (todayLogDoc.exists) todayLog = {...todayLog, ...?todayLogDoc.data()};
      } catch (_) {}

      int todayWorkouts = 0;
      try {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        final q = await _firestore.collection('users').doc(uid).collection('workouts')
            .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('startedAt', isLessThan: Timestamp.fromDate(endOfDay))
            .get();
        todayWorkouts = q.docs.length;
      } catch (_) {}

      return {
        'name': _sanitizeInput(userData['name']?.toString() ?? 'Champ'),
        'fitnessLevel': _sanitizeInput(userData['fitnessLevel']?.toString() ?? 'Intermediate'),
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
    'name': 'Champ', 'fitnessLevel': 'Intermediate', 'goal': 'Stay Fit',
    'weight': 70, 'height': 170, 'caloriesGoal': 2000, 'proteinGoal': 100,
    'waterGoal': 8, 'todayCalories': 0, 'todayProtein': 0, 'todayWater': 0, 'todayWorkouts': 0,
  };

  String _getSmartOfflineResponse(String message, Map<String, dynamic> context) {
    final msg = message.toLowerCase();
    final name = context['name'] ?? 'Champ';

    if (msg.contains('workout') || msg.contains('exercise') || msg.contains('gym')) {
      return '''💪 Hey $name! Workout tips chahiye?\n\n🎯 Quick Tips:\n• Warm-up zaroor karo (5-10 min)\n• Compound exercises pe focus karo\n• Progressive overload important hai\n• Rest days bhi zaroori hain!\n\n🔥 Let's crush it bhai! 💪''';
    }
    if (msg.contains('diet') || msg.contains('food') || msg.contains('calories') || msg.contains('protein')) {
      return '''🍽️ Hey $name! Diet tips:\n\n• Protein har meal mein include karo\n• Processed food avoid karo\n• Vegetables zyada khao\n• Water 3-4 liters daily\n\n🔥 Consistency is key! 🎯''';
    }
    return '''👋 Hey $name!\n\nMain FitGenie hun - tera AI Fitness Coach! 🤖\n\nKya jaanna hai?\n• 💪 Workouts\n• 🍽️ Nutrition\n• 🔥 Motivation\n\nPooch lo! 🚀''';
  }

  Future<void> _saveChatHistory(String uid, String userMsg, String aiResponse) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).collection('aiChats').add({
        'userMessage': userMsg.substring(0, userMsg.length > 500 ? 500 : userMsg.length),
        'aiResponse': aiResponse.substring(0, aiResponse.length > 2000 ? 2000 : aiResponse.length),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<String> generateWorkout({required String uid, required String workoutType, String level = 'intermediate'}) async {
    final cleanType = _sanitizeInput(workoutType);
    if (cleanType.isEmpty || !isConfigured) return _getOfflineWorkout(cleanType.isEmpty ? 'chest' : cleanType);

    try {
      final userContext = await _getUserContext(uid);
      final prompt = '''Tu ek gym trainer hai. $cleanType workout plan de in Hinglish.
Client: ${userContext['name']}, Level: $level
Format: 🔥 Name | ⚡ Warm-up | 💪 Main (5-6 exercises sets x reps) | 🧘 Cool down | 💡 Tip''';

      final result = await _tryDirectModel(prompt);
      if (result != null) return _formatResponse(_validateResponse(result));
      return _getOfflineWorkout(cleanType);
    } catch (e) {
      return _getOfflineWorkout(cleanType);
    }
  }

  String _getOfflineWorkout(String type) {
    final workouts = {
      'chest': '🔥 CHEST WORKOUT\n\n⚡ WARM-UP\n• Arm circles - 30 sec\n• Push-up hold - 30 sec\n\n💪 MAIN\n1. Bench Press - 4x10-12\n2. Incline DB Press - 4x12\n3. Cable Flyes - 3x15\n4. Dips - 3x12\n5. Push-ups - 3xFailure\n\n💡 Mind-muscle connection important hai!\n\n🔥 Chest day is BEST day! 💪',
      'back': '🔥 BACK WORKOUT\n\n⚡ WARM-UP\n• Band pull-aparts - 15 reps\n• Dead hangs - 30 sec\n\n💪 MAIN\n1. Pull-ups - 4x8-10\n2. Barbell Rows - 4x10\n3. Lat Pulldown - 3x12\n4. DB Rows - 3x12\n5. Face Pulls - 3x15\n\n💡 Squeeze your back at top!\n\n🔥 Strong back = Strong everything! 🎯',
      'legs': '🔥 LEG WORKOUT\n\n⚡ WARM-UP\n• Bodyweight squats - 15 reps\n• Leg swings - 10 each\n\n💪 MAIN\n1. Squats - 4x8-10\n2. Romanian Deadlift - 4x10\n3. Leg Press - 3x12\n4. Lunges - 3x12 each\n5. Calf Raises - 4x15\n\n💡 Never skip leg day!\n\n🔥 Leg day = Best day! 🦵💪',
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
    required this.foodName, required this.foodNameHindi,
    required this.calories, required this.protein, required this.carbs,
    required this.fat, required this.fiber, required this.quantity,
    required this.isHealthy, required this.healthTip,
  });

  factory MealAnalysis.fromJson(String jsonString) {
    try {
      String cleaned = jsonString.replaceAll('```json', '').replaceAll('```', '').replaceAll('`', '').trim();
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) throw Exception('No valid JSON found');

      final Map<String, dynamic> json = jsonDecode(cleaned.substring(start, end + 1));

      return MealAnalysis(
        foodName: (json['foodName']?.toString() ?? 'Food Item').substring(0, (json['foodName']?.toString() ?? 'Food Item').length.clamp(0, 100)),
        foodNameHindi: (json['foodNameHindi']?.toString() ?? 'Khana').substring(0, (json['foodNameHindi']?.toString() ?? 'Khana').length.clamp(0, 100)),
        calories: _parseInt(json['calories']).clamp(0, 5000),
        protein: _parseInt(json['protein']).clamp(0, 500),
        carbs: _parseInt(json['carbs']).clamp(0, 1000),
        fat: _parseInt(json['fat']).clamp(0, 500),
        fiber: _parseInt(json['fiber']).clamp(0, 200),
        quantity: (json['quantity']?.toString() ?? '1 serving').substring(0, (json['quantity']?.toString() ?? '1 serving').length.clamp(0, 50)),
        isHealthy: json['isHealthy'] == true || json['isHealthy'].toString().toLowerCase() == 'true',
        healthTip: (json['healthTip']?.toString() ?? 'Enjoy your meal!').substring(0, (json['healthTip']?.toString() ?? 'Enjoy your meal!').length.clamp(0, 200)),
      );
    } catch (e) {
      debugPrint('❌ JSON parse error: $e');
      return MealAnalysis(
        foodName: 'Food Item', foodNameHindi: 'Khana',
        calories: 200, protein: 10, carbs: 25, fat: 8, fiber: 3,
        quantity: '1 serving', isHealthy: true,
        healthTip: 'Photo se identify nahi ho paya. Clear photo lo.',
      );
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''))?.toInt() ?? 0;
    return 0;
  }

  Map<String, dynamic> toMap() => {
    'foodName': foodName, 'foodNameHindi': foodNameHindi,
    'calories': calories, 'protein': protein, 'carbs': carbs,
    'fat': fat, 'fiber': fiber, 'quantity': quantity,
    'isHealthy': isHealthy, 'healthTip': healthTip,
  };
}