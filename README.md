# 🏋️ FitGenie — AI Powered Fitness Companion

> **Your personal pocket trainer that tracks workouts, nutrition, steps, and gives AI coaching in Hinglish.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Gemini AI](https://img.shields.io/badge/AI-Gemini%20Pro-8E75B2?style=for-the-badge&logo=google&logoColor=white)
![Offline First](https://img.shields.io/badge/Architecture-Offline%20First-green?style=for-the-badge)
![Android](https://img.shields.io/badge/Platform-Android-blue?style=for-the-badge&logo=android)
![Version](https://img.shields.io/badge/Version-2.0.0-blue?style=for-the-badge)

---

## 📱 App Overview

FitGenie is a comprehensive, offline-first fitness tracking app built with Flutter that combines:

- 🏋️ **Smart Workout System** — Muscle groups, workout plans (Push/Pull/Legs), custom library, animated exercise demos
- 🍛 **Intelligent Nutrition Tracker** — Pakistani/Asian food database, meal-based logging, saved meals, auto macro calculation
- 🤖 **AI Coach** — Gemini-based Hinglish AI for workouts, nutrition advice, and meal scanning
- 👣 **Step Tracking** — Pedometer + optional Google Fit sync
- 📴 **Offline-First** — Local Hive cache + background Firestore sync
- 🌐 **Multi-language UI** — English and Roman Urdu display text (in progress rollout)

---

## ✨ Key Features

### 🏋️ Workout System

**Muscle Groups (with Animated GIFs)**
- 66+ exercises organized by body part: Chest, Back, Legs, Arms, Shoulders, Core, Cardio
- Animated GIF demos for every exercise (cached for offline)
- Detailed guides: step-by-step instructions, pro tips, common mistakes
- Smart filters: equipment type, difficulty level, GIF toggle
- Exercise detail sheet: full form guide with calories/min, tempo, target muscles

**Workout Plans (Pre-built)**
- 💪 Push Day — Chest + Shoulders + Triceps
- 🔙 Pull Day — Back + Biceps + Rear Delts
- 🦵 Leg Day — Quads + Hams + Glutes + Calves
- 💪 Upper Body — Chest + Back + Shoulders + Arms
- 🦵 Lower Body — Legs + Core
- 🔥 Full Body — Complete all-muscles workout
- ❤️ Cardio & Core — Fat burn + core strength
- 💪 Arms Day — Biceps + Triceps blaster

Each plan includes: exercise list with GIFs, sets × reps configuration, rest time recommendations, coach notes per exercise, estimated duration & target muscles, and one-tap start.

**Custom Workout Library (My Library)**
- Create your own workouts — select exercises from any muscle group
- Custom sets/reps configuration per exercise
- Save & reuse — one-tap start saved workouts
- Full CRUD support (edit & delete)
- Firestore synced — available on any device

**Active Workout Session**
- AI-generated workout plan
- Real-time set logging (exercise, weight, reps)
- Live workout timer
- Session saved to Firestore
- Completion summary with stats

---

### 🍎 Nutrition System

**Smart Nutrition Tracking**
- Meal-based logging: Breakfast, Lunch, Dinner, Snacks
- Daily macro summary: Calories, Protein, Carbs, Fats, Water
- Progress bars for each macro goal
- Date navigation: view today, yesterday, or any past date
- Pull-to-refresh real-time data sync

**Food Database Search (Pakistani/Asian Focused)**
- 70+ Pakistani & Asian foods pre-loaded
- Categories: Staples, Legumes, Meat/Protein, Vegetables, Dairy, Fruits, Snacks, Drinks, Combo Meals
- Local food names: Roti, Daal, Qeema, Biryani, Nihari, Haleem, Paratha, etc.
- Alias support: search "anda" → finds "Boiled Egg", "chawal" → finds "Rice"
- Local serving units: 1 roti, 1 katori, 1 plate, 1 glass
- Quantity multiplier: 0.5×, 1×, 1.5×, 2×, 3× → auto macro calculation
- "Estimated" tag for homemade dishes

**Saved Meals**
- Save current meal as a template (e.g., "My Breakfast")
- One-tap add entire saved meal to any day
- Meal-type override support
- Edit & delete templates
- Items breakdown with macros

**Recent Foods**
- Auto-tracked recently used foods
- One-tap re-add to any meal
- Sorted by last used

**Water Tracker**
- Quick add/remove buttons
- Daily glass count
- Progress bar with goal

**Nutrition Goals**
- Custom goals: Calories, Protein, Carbs, Fats, Water
- Saved to Firestore + local cache
- Used in AI coaching context

**AI Meal Scanner**
- Photo-based meal analysis (Gemini Vision)
- Auto calorie & macro estimation
- Meal type selection after scan
- Saved as entry with "scanner" source tag

**Custom Manual Entry (Fallback)**
- Manual food name, quantity, macros input
- Edit existing entries
- Delete entries with recalculation

---

### 🤖 AI Coach (Gemini, Hinglish)

- Hinglish conversation: *"Bhai kal chest ka workout bana de"*
- Goal-aware: uses your goals, weight, and today's intake for better suggestions
- Workout generation: AI generates muscle-group-specific workout plans
- Meal photo analysis: scan food photos for nutritional info
- Food search: text-based food nutritional lookup
- Offline fallback: smart responses when the API is unavailable
- Chat history saved in Firestore
- Accessible from the dashboard and bottom nav as an in-app overlay (not a separate route)

---

### 👣 Steps & Activity Tracking

Dual-source steps:
1. **Pedometer** (device sensor) — live step counting
2. **Google Fit Integration** (optional) — background steps via REST API

Features:
- Smart merge (highest of Firestore, Pedometer, Google Fit)
- Steps, calories burned, distance, active minutes
- Google Fit status card in Profile
- Works without Google Fit (pedometer fallback)

---

### 📊 Dashboard & Analytics

- Daily summary: steps, calories, protein, water
- Step goal progress ring
- Weekly activity bar chart
- Quick log buttons
- Quick action navigation tiles

---

### 📴 Offline-First & Sync

- Hive encrypted local storage
- SyncService + ConnectivityService — auto-sync when back online
- Reads from cache first for fast loading
- Pending sync queue for offline changes

---

### 🔔 Notifications

- Daily reminders: morning workout, water, lunch logging, evening check-in
- `flutter_local_notifications` + `timezone`
- Notification settings screen

---

### 🌐 Multi-Language System (in progress)

- `LanguageProvider` — active language state + persistence
- `AppStrings` — centralized localized string table (English / Roman Urdu)
- First-launch `LanguageSelectionScreen` gate
- Glassmorphism `AppSnackbar` widget standardized across screens
- Data values (gender, fitness level, goal options) stay in English in Firestore — only the display layer is translated

---

### 🎨 UI/UX

- Modern dark theme with neon accents
- Glassmorphism cards (`FGCard`)
- Custom progress bars (`FGLinearProgress`)
- Animated transitions (fade, slide)
- SliverAppBar collapsing headers
- Responsive grid layouts
- GIF toggle for performance
- Pull-to-refresh support

---

## 🛠️ Tech Stack

| Category | Technology | Usage |
|---|---|---|
| Framework | Flutter 3.x | Cross-platform UI (Android-focused) |
| Language | Dart 3.x | App logic |
| Backend | Firebase | Auth, Firestore, Storage |
| Local DB | Hive + Encryption | Offline cache + secure storage |
| AI | Google Gemini (`google_generative_ai` + `http` REST) | AI coach, meal scanner, workout generation |
| Auth | `firebase_auth`, `google_sign_in` | Email/Password + Google login |
| Storage | `firebase_storage` | Profile photos, assets |
| Steps | `pedometer`, `sensors_plus` | Device sensor steps |
| Google Fit | `google_sign_in` + `http` REST API | Background steps & fitness data |
| Images | `cached_network_image`, `image_picker` | Exercise GIF caching, photo picking |
| State | SetState + Streams | Reactive dashboard & services |
| Offline | `hive_flutter`, `connectivity_plus` | Offline-first architecture |
| UI | `google_fonts`, `fl_chart` | Charts, typography |
| Perms | `permission_handler`, `timezone` | Runtime permissions, notifications |
| Security | `flutter_dotenv`, `flutter_secure_storage` | API keys & secrets |

---

## 📁 Project Structure

```text
lib/
├── main.dart                                  # App entry, init sequence, navigation gates
├── firebase_options.dart                      # Generated Firebase platform config
│
├── app/
│   └── fitgenie_theme.dart                    # Global dark theme, colors, extensions
│
├── core/
│   ├── app_strings.dart                       # Centralized localized strings (EN / Roman Urdu)
│   ├── hive_boxes.dart                        # Hive box registration/initialization
│   └── language_provider.dart                 # Active language state + persistence
│
├── data/
│   ├── exercise_data.dart                     # 66+ exercises (GIFs, steps, tips, mistakes)
│   ├── workout_plans_data.dart                # Pre-built plans (Push/Pull/Legs/Full Body etc.)
│   ├── food_item.dart                         # FoodItem model + FoodPortion calculator
│   └── food_database.dart                     # 70+ Pakistani/Asian foods database
│
├── models/
│   └── chat_message.dart                      # AI chat message model
│
├── services/
│   ├── ai_service.dart                        # Gemini AI (chat, workout gen, meal scanner)
│   ├── auth_service.dart                      # Firebase Auth (login/signup/logout)
│   ├── nutrition_service.dart                 # Nutrition (goals, logs, entries, water, saved meals)
│   ├── workout_service.dart                   # Workout session start/end/set logging
│   ├── image_service.dart                     # Profile photo pick/upload/delete
│   ├── notification_service.dart              # Local notification scheduling
│   ├── connectivity_service.dart              # Online/offline listener
│   ├── local_storage_service.dart             # Hive encrypted storage + pending-sync queue
│   ├── sync_service.dart                      # Auto-sync local → Firestore
│   ├── step_counter_service.dart              # Pedometer + Google Fit step logic
│   └── google_fit_service.dart                # Google Fit REST API
│
├── screens/
│   ├── splash_screen.dart                     # App splash / intro
│   ├── language_selection_screen.dart         # First-launch language picker
│   ├── login_screen.dart                      # Auth UI (login)
│   ├── signup_screen.dart                     # Auth UI (signup)
│   ├── onboarding_screen.dart                 # Profile setup + BMR-based goal calculation
│   ├── shell_screen.dart                      # Bottom nav shell (hosts AI Coach overlay)
│   ├── dashboard_screen.dart                  # Main dashboard (steps, goals, weekly)
│   │
│   ├── workout_screen.dart                    # Workout hub + active workout session
│   ├── muscle_group_exercises_screen.dart     # Exercises by body part (with GIFs)
│   ├── workout_plan_screen.dart               # Plan detail (Push/Pull/Legs etc.)
│   ├── my_library_screen.dart                 # Custom workouts (create/edit/start)
│   ├── workout_detail_screen.dart             # Past workout details
│   │
│   ├── calories_screen.dart                   # Nutrition tracker (meals, macros, water)
│   ├── food_search_screen.dart                # Food database search + quantity select
│   ├── saved_meals_screen.dart                # Saved meal templates (view/pick)
│   ├── meal_scanner_screen.dart                # AI meal photo scanner
│   │
│   ├── profile_screen.dart                    # Profile + Google Fit + settings
│   ├── notification_settings_screen.dart      # Notification preferences
│   ├── challenges_screen.dart                 # (Placeholder) challenges UI
│   └── progress_screen.dart                   # (Placeholder) progress tracking
│
├── widgets/
│   ├── fg_card.dart                           # Glassmorphism card widget
│   ├── fg_progress.dart                       # Custom linear progress bars
│   ├── app_snackbar.dart                      # Glassmorphism snackbar
│   ├── language_selector_dialog.dart          # Language switch dialog
│   ├── quick_action_tile.dart / quick_action_button.dart  # Dashboard quick actions
│   ├── offline_indicator.dart                 # No-internet banner wrapper
│   ├── active_set_sheet.dart / set_timer_widgets.dart      # Workout session UI
│   ├── step_counter_card.dart                 # Steps summary card
│   └── retryable_exercise_image.dart          # GIF loader with retry
│
└── assets/
    └── screenshots/                           # App screenshots (optional)
```

> Note: The AI Coach is not a standalone screen file — it's implemented as an in-app overlay (`_AICoachScreen`) inside `shell_screen.dart`, opened from the dashboard and bottom nav.

---

## 🗄️ Firestore Database Structure

```text
users/{userId}
├── name, email, weight, height, goal, fitnessLevel, profilePhoto, profileComplete
│
├── goals/main
│   └── caloriesGoal, proteinGoal, carbsGoal, fatsGoal, waterGoal, updatedAt
│
├── dailyLogs/{yyyy-MM-dd}
│   ├── calories, protein, carbs, fats, water
│   ├── steps, stepsCalories, stepsDistance, stepsActiveMinutes
│   ├── stepsSource, googleFitEnabled, updatedAt
│   │
│   └── entries/{entryId}
│       └── name, quantity, mealType, calories, protein, carbs, fats,
│           source (manual | scanner | database | saved_meal),
│           createdAt, updatedAt, userId, dateKey
│
├── workouts/{workoutId}
│   └── type, status (active | completed), startedAt, endedAt, duration,
│       totalSets, sets: [{exercise, weight, reps, timestamp}], plannedExercises
│
├── customWorkouts/{workoutId}
│   └── name, bodyPart, exercises: [{exerciseId, name, bodyPart, sets, reps, equipment}],
│       createdAt, updatedAt
│
├── recentFoods/{foodKey}
│   └── name, quantity, calories, protein, carbs, fats, lastUsedAt
│
├── savedMeals/{mealId}
│   └── name, mealType, calories, protein, carbs, fats,
│       items: [{foodId, name, quantity, calories, protein, carbs, fats, source}],
│       createdAt, updatedAt
│
├── aiChats/{chatId}
│   └── userMessage, aiResponse, timestamp
│
└── settings/{settingId}
    └── notification preferences, etc.
```

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter 3.3x+ (tested on 3.38.x)
- Dart 3.x
- Android Studio / SDK — API level 33–36
- Firebase project with Firestore + Auth + Storage
- Gemini API key (Google AI Studio)
- Android device (for pedometer + Google Fit)

### 2. Clone & Install
```bash
git clone https://github.com/fahad2bhatti/fitgenie.git
cd fitgenie
flutter pub get
```

### 3. Environment Setup
Create a `.env` file in the project root:
```bash
GEMINI_API_KEY=your_gemini_api_key_here
```

### 4. Firebase Setup
1. Create a project in the Firebase Console
2. Add the Android app with package **`com.fahadapps.fitgenie`**
3. Download `google-services.json` → place in `android/app/`
4. Run `flutterfire configure`

### 5. Google Fit Setup (Optional)
1. Enable the Fitness API in Google Cloud Console
2. Configure the OAuth consent screen
3. Create Android + Web OAuth clients
4. Add the resulting `serverClientId` in `google_fit_service.dart`

### 6. Firestore Security Rules
Firestore Security Rules are not yet checked into this repo — write and deploy rules that scope every collection under `users/{userId}` to that user only (profile, daily logs, meal entries, workouts, custom workouts, recent foods, saved meals, and AI chat history) before shipping to production.

### 7. Run
```bash
flutter run
```

---

## 📦 Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0

  # Auth
  google_sign_in: ^6.2.1

  # AI
  google_generative_ai: ^0.4.0
  http: ^1.1.0
  flutter_dotenv: ^5.1.0

  # Local Storage
  hive_flutter: ^1.1.0
  path_provider: ^2.1.2
  flutter_secure_storage: ^9.2.2

  # UI
  google_fonts: ^6.2.1
  fl_chart: ^0.68.0
  cached_network_image: ^3.3.1

  # Steps & Sensors
  pedometer: ^4.0.1
  sensors_plus: ^4.0.0

  # Connectivity
  connectivity_plus: ^6.0.3

  # Notifications
  flutter_local_notifications: ^18.0.1
  timezone: ^0.10.0

  # Permissions
  permission_handler: ^11.3.1

  # Utils
  intl: ^0.19.0
  image_picker: ^1.0.7
  uuid: ^4.5.2
```

---

## 🏗️ Release Build

**APK (Sideload)**
```bash
flutter build apk --release
```

**AAB (Play Store)**
```bash
flutter build appbundle --release
```

Currently distributed via **Google Play closed testing** under package `com.fahadapps.fitgenie`.

---

## 📸 Screenshots

| Dashboard | Workout Hub | Exercise Library | Nutrition |
|---|---|---|---|
| <img src="assets/screenshots/dashboard.png" width="180" /> | <img src="assets/screenshots/workout.png" width="180" /> | <img src="assets/screenshots/exercises.png" width="180" /> | <img src="assets/screenshots/nutrition.png" width="180" /> |

| Food Search | Saved Meals | Workout Plans | AI Coach |
|---|---|---|---|
| <img src="assets/screenshots/food_search.png" width="180" /> | <img src="assets/screenshots/saved_meals.png" width="180" /> | <img src="assets/screenshots/plans.png" width="180" /> | <img src="assets/screenshots/ai_coach.png" width="180" /> |

---

## 🗺️ Future Roadmap

- [ ] Social Features — friends, leaderboards, challenges
- [ ] AI Natural Language Input — "2 ande aur 2 roti" → auto parse
- [ ] Barcode Scanner — packaged food scanning
- [ ] Advanced Analytics — weekly/monthly nutrition charts
- [ ] Saved Foods Favorites — star frequently used foods
- [ ] Diet Templates — weight loss, muscle gain, maintenance plans
- [ ] Wear OS Integration — watch companion
- [ ] iOS Support — iOS build & testing
- [ ] Restaurant Food Database — common restaurant meals
- [ ] Grocery List Generator — based on saved meals

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit changes:
   ```bash
   git commit -m "Add amazing feature"
   ```
4. Push:
   ```bash
   git push origin feature/amazing-feature
   ```
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the `LICENSE` file for details.

---

## 👤 Author

**Fahad Saeed**
[LinkedIn](https://linkedin.com/in/fahad-saeed-3402a038b) · [GitHub](https://github.com/fahad2bhatti)

---

<p align="center">Built with ❤️ using Flutter, Firebase & Gemini AI</p>
<p align="center">⭐ If you found this useful, please star the repo! ⭐</p>