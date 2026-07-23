# FitGenie Project Summary

FitGenie is a Flutter-based fitness application designed to provide a personalized, AI-driven experience for health tracking, workout management, and nutritional guidance. It leverages Firebase for its backend and Google Gemini AI for its intelligent coaching.

## 🏗️ Core Architecture

### **Navigation Flow**
The app follows a structured startup and navigation pattern:
1.  **Entry (`main.dart`)**: Initializes services (Firebase, Hive, Local Storage, Step Counter).
2.  **Startup Sequence**: `SplashScreen` -> `Language Selection` (Phase 1 logic) -> `AuthGate`.
3.  **AuthGate**: Checks Firebase Auth status. If logged in, it verifies if the profile is complete.
4.  **Onboarding (`onboarding_screen.dart`)**: Collects user data (Gender, Age, Weight, Height) and calculates personalized goals (BMR, TDEE).
5.  **Main Shell (`shell_screen.dart`)**: The primary interface with a `BottomNavigationBar` managing five core screens.

### **Core Modules & Files**

| Screen / Component | File | Responsibility |
| :--- | :--- | :--- |
| **Dashboard** | [dashboard_screen.dart](file:///home/fahad/fitgenie/lib/screens/dashboard_screen.dart) | High-level overview of daily steps, calories burned, and goal progress. |
| **Nutrition** | [calories_screen.dart](file:///home/fahad/fitgenie/lib/screens/calories_screen.dart) | Detailed calorie and macronutrient tracking. |
| **Workout** | [workout_screen.dart](file:///home/fahad/fitgenie/lib/screens/workout_screen.dart) | Built-in exercise library and training plans. |
| **Library** | [my_library_screen.dart](file:///home/fahad/fitgenie/lib/screens/my_library_screen.dart) | Custom workout builder (CRUD) and session execution. |
| **Progress** | [progress_screen.dart](file:///home/fahad/fitgenie/lib/screens/progress_screen.dart) | Weight and activity trends over time. |
| **Profile** | [profile_screen.dart](file:///home/fahad/fitgenie/lib/screens/profile_screen.dart) | User settings, body stats, and Google Fit integration. |
| **AI Coach** | [shell_screen.dart](file:///home/fahad/fitgenie/lib/screens/shell_screen.dart) | Professional chat interface with Gemini-powered coaching. |

---

## ⚡ Key Button Actions & Interactions

### **Dashboard Actions**
- **Add Steps**: Manual entry for steps that syncs with `StepCounterService`.
- **Add Water**: Quick increments (+1, +2, +3 glasses) for hydration tracking.
- **Active Minutes**: Manual entry for activity duration.
- **Quick Action Tiles**: Rapid navigation to Workouts, Nutrition, AI Coach, and Challenges.

### **Workout Library Actions**
- **Create Workout**: Opens `CustomWorkoutBuilderScreen` to select exercises from `ExerciseData`.
- **Edit/Delete**: Full control over saved custom routines.
- **Start Workout**: Launches `CustomWorkoutSessionScreen`, initiating a real-time session.
- **Log Set**: While in a session, users can log weight and reps for each planned exercise.

### **AI Coach Interactions**
- **Quick Chips**: Pre-defined prompts (e.g., "Mera diet plan bana do", "Mujhe motivate karo") for fast interaction.
- **Message Input**: Multiline text input for custom fitness queries.
- **History Management**: Users can clear chat history, which also updates the `aiChats` subcollection in Firestore.

### **Profile & Settings Actions**
- **Connect Google Fit**: Triggers `StepCounterService.connectGoogleFit()`, initiating a Google Sign-in popup for Health Connect.
- **Update Profile**: Modify name, fitness level, and primary goals.
- **Edit Stats**: Update weight and height, which automatically logs a weight entry for progress tracking.

---

## 🛠️ Service Layer & Logic

### **Step Tracking (`StepCounterService`)**
- **Hybrid Source**: Prioritizes **Google Fit (Health Connect)** data but falls back to the device's **Pedometer sensor**.
- **Data Sync**: Automatically saves steps to Firestore's `dailyLogs` collection every 15 seconds (throttled).
- **Persistence**: Loads previously saved steps on initialization to prevent data loss during app restarts.

### **AI Service (`AIService`)**
- **Gemini Flash**: Uses the latest Gemini Flash model for low-latency responses.
- **Context Injection**: Every chat prompt includes the user's name, goal, and today's nutritional progress to provide relevant advice.
- **Meal Analysis**: Includes logic to analyze food photos via Gemini Vision (currently in "Soon" status on UI).

### **Notifications (`NotificationService`)**
- **Scheduled Reminders**: Morning workout (7 AM), Water (every 2 hours), Lunch (2 PM), Motivation (6 PM), and Evening check-in (8 PM).
- **Customizable**: Allows users to set their own hours for specific reminders.

---

## 🔍 Observations: Potential Improvements & Bugs

> [!NOTE]
> These are technical observations based on the current implementation that could be optimized.

1.  **Calorie Calculation Weight**:
    - In [step_counter_service.dart](file:///home/fahad/fitgenie/lib/services/step_counter_service.dart), calorie calculation defaults to **70kg** (`weightKg = 70`).
    - *Improvement*: Should pull the actual user's weight from `ProfileScreen` or Firestore for accuracy.

2.  **Scan Meal Implementation**:
    - The [DashboardScreen](file:///home/fahad/fitgenie/lib/screens/dashboard_screen.dart) labels "Scan Meal" as **SOON**.
    - However, the [AIService](file:///home/fahad/fitgenie/lib/services/ai_service.dart) already has `analyzeMealPhoto` and `searchFood` logic implemented.
    - *Improvement*: The UI is ready to be linked to the existing `AIService` capability.

3.  **API Key Security**:
    - `AIService` falls back to `.env` if `GEMINI_API_KEY` is not found in `--dart-define`.
    - *Warning*: `.env` files are bundled into the APK assets. For production, the key should **only** be provided via `--dart-define` to ensure it isn't easily extracted.

4.  **Body Part Emojis**:
    - `MyLibraryScreen` uses hardcoded switch statements for body part emojis.
    - *Improvement*: This could be moved into `ExerciseData` or a utility class to ensure consistency across the app.
