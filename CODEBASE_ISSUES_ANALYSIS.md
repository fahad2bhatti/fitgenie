# FitGenie Codebase Issues Analysis

Based on comprehensive code review of the FitGenie Flutter project.

---

## Executive Summary

**Total Issues Found:** 8
- **Critical:** 2
- **High:** 2
- **Medium:** 2
- **Low:** 1
- **Very Low:** 1

---

## Issue Details

### 1. 🔴 CRITICAL - Hive boxes stored without encryption
- **Severity:** High
- **Type:** Security
- **Location:** `lib/core/hive_boxes.dart:14-21`
- **Detail:** `Hive.openBox()` called without encryption key. User health data (weights, goals, workout logs, saved meals, AI chats) stored in plain JSON on disk. This is a significant security risk for health-related data.
- **Fix:** Use `Hive.initEncryption(key)` with a secure encryption key for production builds. The encryption key should be provided via `--dart-define` and never hardcoded.

### 2. 🔴 CRITICAL - `.env` file included as APK asset
- **Severity:** High
- **Type:** Security
- **Location:** `pubspec.yaml:61`
- **Detail:** The `.env` file is listed under `assets:` in `pubspec.yaml`, which means its contents (including `GEMINI_API_KEY`) are bundled inside the APK and publicly extractable. AGENTS.md Security section explicitly warns: "`.env` pubspec assets mein hai, yani uska content APK mein jata hai."
- **Fix:** Remove `.env` from `pubspec.yaml` assets. Use `--dart-define GEMINI_API_KEY=...` for release builds instead of relying on `.env`. The `ai_service.dart` already prefers `--dart-define` over `.env`.

### 3. 🟠 HIGH - AdMob ad units need updating
- **Severity:** Medium
- **Type:** Configuration
- **Location:** `lib/services/ad_manager.dart:17-21`
- **Detail:** Ad IDs are currently set to test IDs (`ca-app-pub-8397637614188934/...`) with a TODO comment: "// TODO: AdMob console se naye units banake yahan paste karo." For production release, these must be replaced with real AdMob console ad unit IDs.
- **Fix:** Replace with real ad unit IDs provided via `--dart-define` or fetched from remote config.

### 4. 🟠 HIGH - No @HiveType annotations despite hive_generator dependency
- **Severity:** Medium
- **Type:** Dead Code / Build Process
- **Location:** Throughout `lib/` (0 matches for `@HiveType`)
- **Detail:** `hive_generator: ^2.0.1` and `build_runner: ^2.4.8` are listed as dev_dependencies in `pubspec.yaml`, but no `@HiveType` annotations were found in the codebase. This means Hive is being used with generic `Box` type (`hive_boxes.dart` uses `Box`), which loses type safety and defeats the purpose of having codegen dependencies.
- **Fix:** Either add `@HiveType` annotations to all Hive model classes and run `dart run build_runner build`, OR remove `hive_generator` and `build_runner` from dev_dependencies if codegen is not needed.

### 5. 🟠 MEDIUM - Google Fit is Android-only, no iOS equivalent
- **Severity:** Medium
- **Type:** Future Bug / Platform
- **Location:** `lib/services/google_fit_service.dart`
- **Detail:** Google Fit service uses `GoogleSignIn` and Fitness API which are fundamentally Android-specific. The app claims to support both English and Roman Urdu (suggesting multi-language support), but Google Fit functionality would silently fail or return 0 for iOS users. No iOS alternative (HealthKit) is implemented.
- **Fix:** Add platform detection and either disable Google Fit for iOS users or implement a HealthKit alternative. Currently `_isConnected` flag will be false on iOS, which gracefully handles this, but user experience could be improved.

### 6. 🟠 MEDIUM - Custom state management without external framework
- **Severity:** Low
- **Type:** Architecture
- **Location:** `lib/core/language_provider.dart`, `lib/main.dart`
- **Detail:** No `provider`, `riverpod`, or `bloc` dependencies are listed in `pubspec.yaml`. State management is handled via `ChangeNotifier` (in `language_provider.dart`) and `setState` throughout the widget tree. This works but is not the "modern Flutter way" that most teams use, and may limit scalability as the app grows.
- **Fix:** Document the current state management pattern intentionally chosen, or consider adopting provider/riverpod/bloc if the team decides to refactor.

### 7. 🟠 LOW - Backup files in lib/screens/
- **Severity:** Very Low
- **Type:** Dead Code
- **Location:** `lib/screens/dashboard_screen.dart.bak`, `dashboard_screen.dart.bak2`
- **Detail:** Two backup files exist (43KB and 50KB respectively) that appear to be older versions of `dashboard_screen.dart`. These serve no purpose in the current codebase and should be removed or added to `.gitignore`.
- **Fix:** Delete the backup files or add them to `.gitignore`.

### 8. 🟢 VERY LOW - .dart_tool and .flutter-plugins-dependencies exist
- **Severity:** Very Low
- **Type:** Standard Flutter Files
- **Location:** `.dart_tool/`, `.flutter-plugins-dependencies`
- **Detail:** Standard Flutter generated configuration files. These are created automatically by `flutter pub get` and should never be manually edited. No action needed.
- **Fix:** None required.

---

## Recommendations Priority Order

### Immediate (Security/Blocking)
1. **Remove `.env` from pubspec.yaml assets** — prevents API key exposure in APK
2. **Add Hive encryption** — protects user health data at rest

### Short-term
3. **Replace AdMob test IDs with real units** — needed for production revenue
4. **Decide on @HiveType strategy** — either add annotations + run codegen, or remove codegen dependencies

### Medium-term
5. **Add iOS Google Fit alternative** — HealthKit integration for iOS users
6. **Document state management decision** — why ChangeNotifier was chosen over framework options

### Low-priority
7. **Remove backup .bak files** — cleanup
8. **No action needed** on `.dart_tool/` — standard generated files

---

## Code Quality Assessment

- **flutter analyze:** No issues found ✅
- **Test coverage:** Only `test/widget_test.dart` exists (as noted in AGENTS.md)
- **Platform support:** English + Roman Urdu ✅
- **Security rules:** `firestore.rules` has proper `users/{uid}` scoping ✅
- **Startup order:** Correct (.env → Firebase → AdMob → Hive → connectivity → SyncService → notifications) ✅
- **Screen flow:** SplashScreen → LanguageGate → AuthGate → ShellScreen ✅

---
*Analysis performed on: 2026-11-06*