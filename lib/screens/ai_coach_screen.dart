// lib/services/ai_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⚠️ NEW API KEY DALO - purani delete karo!
  static const String _apiKey = 'AIzaSyAj0DQZweojF1LEBlcH30TvukoCxoWrYI0';

  /// First: Check which models are available
  Future<List<String>> getAvailableModels() async {
    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey';
      final response = await http.get(Uri.parse(url));

      debugPrint('📋 Models Response: ${response.statusCode}');
      debugPrint(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List? ?? [];

        List<String> modelNames = [];
        for (var model in models) {
          final name = model['name'] as String?;
          if (name != null && name.contains('gemini')) {
            // Extract just the model name
            final shortName = name.replaceAll('models/', '');
            modelNames.add(shortName);
            debugPrint('✅ Found: $shortName');
          }
        }
        return modelNames;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error listing models: $e');
      return [];
    }
  }

  /// Main chat function
  Future<String> chat({
    required String uid,
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
  }) async {

    debugPrint('🚀 AI Chat Started');

    try {
      // Get available models first
      final availableModels = await getAvailableModels();

      if (availableModels.isEmpty) {
        return '''❌ API Setup Problem!

Please check:
1. Go to console.cloud.google.com
2. Enable "Generative Language API"
3. Create new API key
4. Try again!

Ya phir API quota khatam ho gaya.''';
      }

      // Use first available gemini model
      String modelToUse = availableModels.first;

      // Prefer these models if available
      for (var preferred in ['gemini-pro', 'gemini-1.0-pro', 'gemini-1.5-flash', 'gemini-1.5-pro']) {
        if (availableModels.contains(preferred)) {
          modelToUse = preferred;
          break;
        }
      }

      debugPrint('🎯 Using model: $modelToUse');

      // Get user context
      final userContext = await _getUserContext(uid);

      // Build prompt
      final prompt = '''
Tu FitGenie AI Coach hai - ek professional fitness trainer.

USER DATA:
- Name: ${userContext['profile']['name'] ?? 'Buddy'}
- Calories Goal: ${userContext['goals']['caloriesGoal']} kcal/day  
- Protein Goal: ${userContext['goals']['proteinGoal']}g/day
- Aaj ka Intake: ${userContext['todayNutrition']['calories']} kcal

RULES:
1. Hinglish mein jawab de (Hindi + English)
2. Short practical advice de (2-3 lines)
3. Emojis use kar 💪🔥
4. Friendly aur motivating baat kar

USER KA SAWAAL: $userMessage
''';

      // Call API
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$modelToUse:generateContent?key=$_apiKey';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 500,
          },
        }),
      );

      debugPrint('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final aiResponse = parts[0]['text'] as String;
            debugPrint('✅ Success!');

            await _saveChatHistory(uid, userMessage, aiResponse);
            return aiResponse;
          }
        }
        return 'Response samajh nahi aayi. Dobara try karo! 🙏';

      } else {
        debugPrint('❌ Error: ${response.body}');
        return 'API Error: ${response.statusCode}. Thodi der baad try karo.';
      }

    } catch (e) {
      debugPrint('💥 Exception: $e');
      return 'Network error: $e';
    }
  }

  Future<Map<String, dynamic>> _getUserContext(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      final goalsDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc('main')
          .get();
      final goals = goalsDoc.data() ?? {'caloriesGoal': 2000, 'proteinGoal': 100};

      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final todayLogDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('dailyLogs')
          .doc(dateStr)
          .get();
      final todayLog = todayLogDoc.data() ?? {'calories': 0, 'protein': 0};

      return {
        'profile': userData,
        'goals': goals,
        'todayNutrition': todayLog,
      };
    } catch (e) {
      return {
        'profile': {},
        'goals': {'caloriesGoal': 2000, 'proteinGoal': 100},
        'todayNutrition': {'calories': 0, 'protein': 0},
      };
    }
  }

  Future<void> _saveChatHistory(String uid, String userMsg, String aiResponse) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('aiChats')
          .add({
        'userMessage': userMsg,
        'aiResponse': aiResponse,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  Future<Map<String, dynamic>> generateWorkoutPlan({
    required String uid,
    required String goal,
    required int daysPerWeek,
  }) async {
    final response = await chat(uid: uid, userMessage: '$daysPerWeek-day $goal workout plan batao.');
    return {'rawPlan': response};
  }

  Future<String> getDietSuggestion(String uid) async {
    return await chat(uid: uid, userMessage: 'Aaj kya khana chahiye?');
  }

  Future<String> analyzeWorkoutProgress(String uid) async {
    return await chat(uid: uid, userMessage: 'Mera progress analyze karo.');
  }
}