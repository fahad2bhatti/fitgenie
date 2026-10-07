// lib/services/chat_quota_service.dart
//
// AI chatbot ka daily message limit. Firestore mein rakha hai taake user app
// data clear karke limit reset na kar sake.
//
// Doc: users/{uid}/usage/chat  ->  { date: 'yyyy-MM-dd', used: int, bonus: int }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatQuotaService {
  ChatQuotaService._();
  static final ChatQuotaService instance = ChatQuotaService._();

  static const int dailyFree = 8; // 5-10 ke beech, apni marzi se change karo
  static const int bonusPerAd = 5;

  DocumentReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('usage')
        .doc('chat');
  }

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  ({int used, int bonus}) _read(Map<String, dynamic>? d) {
    if (d == null || d['date'] != _today) return (used: 0, bonus: 0);
    return (
    used: (d['used'] as num?)?.toInt() ?? 0,
    bonus: (d['bonus'] as num?)?.toInt() ?? 0,
    );
  }

  /// UI ke liye: kitne messages bache hain.
  Future<int> remaining() async {
    final s = await _doc.get();
    final r = _read(s.data());
    return dailyFree + r.bonus - r.used;
  }

  /// Message bhejne se PEHLE call karo. false aaye to rewarded ad offer karo.
  Future<bool> tryConsume() {
    return FirebaseFirestore.instance.runTransaction<bool>((tx) async {
      final s = await tx.get(_doc);
      final r = _read(s.data());
      if (r.used >= dailyFree + r.bonus) return false;
      tx.set(_doc, {
        'date': _today,
        'used': r.used + 1,
        'bonus': r.bonus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  /// Rewarded ad earned hone ke baad call karo.
  Future<void> addBonus() {
    return FirebaseFirestore.instance.runTransaction<void>((tx) async {
      final s = await tx.get(_doc);
      final r = _read(s.data());
      tx.set(_doc, {
        'date': _today,
        'used': r.used,
        'bonus': r.bonus + bonusPerAd,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

// Firestore rules mein add karo:
//
// match /users/{uid}/usage/{docId} {
//   allow read, write: if request.auth != null && request.auth.uid == uid;
// }