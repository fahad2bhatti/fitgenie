# FitGenie

Flutter app: Firebase (Auth, Firestore, Storage), Gemini AI, Hive offline cache, AdMob.

## Commands
- Install: `flutter pub get`
- Run: `flutter run`
- Analyze: `flutter analyze` (har change ke baad chalao, errors fix karke hi kaam khatam maano)
- Format: `dart format .`
- Test: `flutter test` (abhi sirf test/widget_test.dart hai)
- Hive codegen (adapters badlein to): `dart run build_runner build --delete-conflicting-outputs`
- Release: `flutter build appbundle --release`

## Conventions
- Generated files (`*.g.dart`, `lib/firebase_options.dart`) kabhi manually edit mat karo.
- Naya package bina puche mat add karo. pubspec badle to `flutter pub get` chalao.
- Agar change 2 se zyada files chhuta hai to pehle plan batao.
- App English aur Roman Urdu support karta hai (`lib/core/language_provider.dart`). Nayi UI text isi ke through jaye.

## Architecture
- Entry: `lib/main.dart`. Startup order: .env, Firebase, AdMob, Hive, connectivity, SyncService, notifications.
- Flow: SplashScreen, LanguageGate, AuthGate, ShellScreen.
- Services `lib/services/` mein: `ai_service.dart` (Gemini), `auth_service.dart` (Firebase + Google Sign-In), `sync_service.dart` (Hive se Firestore sync).
- Offline-first: pehle Hive cache, internet aane par Firestore sync.

## Security (agent ke liye sakht rules)
- `.env`, `*.jks`, `*.keystore`, `key.properties` kabhi padho, print, edit ya copy mat karo. Structure ke liye `.env.example` dekho. Bash se bypass karne ki koshish mat karo.
- Asal keys ya passwords code, docs ya is file mein kabhi mat likho.
- `.env` pubspec assets mein hai, yani uska content APK mein jata hai. Release ke liye `--dart-define GEMINI_API_KEY=...` use hota hai (ai_service.dart dono tareeqe padhta hai).
- Firestore rules root ki `firestore.rules` mein hain. Unhein dheela mat karo, aur har user ka data sirf us user tak rakho.
