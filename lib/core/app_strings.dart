// lib/core/app_strings.dart
// All UI Strings — English + Roman Urdu

import 'package:flutter/foundation.dart';
import 'language_provider.dart';

class AppStrings {
  // ──────────────────────────────────────────
  // 📚 All String Maps
  // ──────────────────────────────────────────

  static const Map<String, String> _en = {
    // ==========================================
    // LANGUAGE SELECTION
    // ==========================================
    'language_select_title': 'Select Your Language',
    'language_english': 'English',
    'language_urdu': 'Roman Urdu',

    // ==========================================
    // ONBOARDING
    // ==========================================
    'onboarding_welcome': 'Hi {name} 👋',
    'onboarding_subtitle': "Let's personalize your FitGenie",
    'onboarding_gender': 'What is your gender?',
    'onboarding_gender_sub': 'This helps us calculate your nutrition goals.',
    'onboarding_age': 'How old are you?',
    'onboarding_age_sub': 'Drag the slider to set your age.',
    'onboarding_height': 'Height & Weight',
    'onboarding_height_sub': 'This is the foundation of your daily targets.',
    'onboarding_level': 'What is your fitness level?',
    'onboarding_level_sub': 'Workouts will be matched to your level.',
    'onboarding_goal': 'What is your main goal?',
    'onboarding_goal_sub': 'We will set calorie and macro targets accordingly.',
    'onboarding_next': 'Next',
    'onboarding_start': "Let's Go 🚀",
    'onboarding_back': 'Back',

    // ==========================================
    // LOGIN
    // ==========================================
    'login_error': 'Something went wrong. Please try again.',
    'login_success': 'Welcome back! 🎉',
    'login_welcome': 'Welcome back',
    'login_email_hint': 'Email Address',
    'login_password_hint': 'Password',
    'login_button': 'Sign In',
    'login_google': 'Continue with Google',
    'login_forgot': 'Forgot password?',
    'login_remember': 'Remember me',
    'login_signup': "Don't have an account?",
    'login_signup_free': 'Sign up free',

    // ==========================================
    // AUTH
    // ==========================================
    'auth_verify_email': 'Verify Your Email!',
    'auth_verify_sub': 'We sent a verification link to your email. Please verify and then login.',
    'auth_check_again': 'Check Again',
    'auth_logout': 'Logout',

    // ==========================================
    // CHAT / AI COACH
    // ==========================================
    'chat_welcome': "👋 Hey {name}!\n\n🤖 I'm **FitGenie** — your personal AI Fitness Coach!\n\n━━━━━━━━━━━━━━━━━━━━━━━━\n\n🎯 **I can help you with:**\n\n💪 **Workouts**\n   Muscle-specific exercises & plans\n\n🍽️ **Nutrition**  \n   Diet plans & calorie guidance\n\n🔥 **Motivation**\n   Daily inspiration & tips\n\n📊 **Progress**\n   Track & improve\n\n━━━━━━━━━━━━━━━━━━━━━━━━\n\nUse the quick buttons below or type your question!\n\n**Let's get started! 🚀**",
    'chat_error': '❌ **Oops! Something went wrong.**\n\nPlease try again or check your internet connection.\n\n💡 Tip: You can also try the quick buttons below!',
    'chat_clear_title': 'Clear Chat?',
    'chat_clear_sub': 'All messages will be deleted. This action cannot be undone.',
    'chat_clear': 'Clear',
    'chat_cancel': 'Cancel',
    'chat_about_title': 'FitGenie AI Coach',
    'chat_about_powered': 'Powered by Google Gemini AI',
    'chat_about_features': '🎯 Features:',
    'chat_about_workouts': '• Personalized workout plans',
    'chat_about_nutrition': '• Diet & nutrition advice',
    'chat_about_motivation': '• Motivation & tips',
    'chat_about_progress': '• Progress tracking help',
    'chat_about_data': '💡 Your data is used to personalize responses.',
    'chat_got_it': 'Got it!',
    'chat_online': 'Online • Ready to help',
    'chat_thinking': 'Thinking...',
    'chat_placeholder': 'Ask me anything about fitness...',
    'chat_send': 'Send',
    'chat_typing': 'FitGenie is thinking...',
    'chat_workout': 'Workout',
    'chat_diet': 'Diet Plan',
    'chat_motivate': 'Motivate',
    'chat_weight_loss': 'Weight Loss',
    'chat_muscle_gain': 'Muscle Gain',
    'chat_hydration': 'Hydration',
    'chat_recovery': 'Recovery',

    // ==========================================
    // SNACKBARS
    // ==========================================
    'snackbar_added': 'Added successfully! ✅',
    'snackbar_deleted': 'Deleted successfully! 🗑️',
    'snackbar_saved': 'Saved successfully! 💾',
    'snackbar_error': 'Something went wrong. Please try again.',
    'snackbar_offline': 'You are offline. Changes will sync when online.',

    // ==========================================
    // CALORIES SCREEN
    // ==========================================
    'calories_title': 'Nutrition 🍽️',
    'calories_sub': 'Track meals, macros & water',
    'calories_summary': "Today's Summary",
    'calories_water': 'Water Tracker',
    'calories_search': 'Search Food',
    'calories_saved': 'Saved Meals',
    'calories_scan': 'Scan Meal',
    'calories_goals': 'Goals',
    'calories_empty': 'No items added yet',
    'calories_custom': 'Custom manual entry',
    'calories_recent': 'Recent Foods',
    'calories_load_failed': 'Load failed: {error}',
    'calories_added_success': '{name} added ✅',
    'calories_scanned_success': '{name} scanned & added ✅',
    'calories_meal_empty_error': 'This meal has no items yet',
    'calories_template_saved': '{name} saved to library ✅',
    'calories_food_name_required': 'Food name is required',

    // ==========================================
    // DASHBOARD SCREEN
    // ==========================================
    'dashboard_greeting_morning': 'Good Morning',
    'dashboard_greeting_afternoon': 'Good Afternoon',
    'dashboard_greeting_evening': 'Good Evening',
    'dashboard_greeting_night': 'Good Night',
    'dashboard_quick_actions': 'Quick Actions',
    'dashboard_step_counter': 'Step Counter',
    'dashboard_calories_burned': 'Calories Burned',
    'dashboard_daily_goals': 'Daily Goals',
    'dashboard_weekly_activity': 'Weekly Activity',
    'dashboard_quick_log': 'Quick Log',
    'dashboard_workouts': 'Workouts',
    'dashboard_nutrition': 'Nutrition',
    'dashboard_ai_coach': 'AI Coach',
    'dashboard_progress': 'Progress',
    'dashboard_challenges': 'Challenges',
    'dashboard_scan_meal': 'Scan Meal',
    'dashboard_goal_achieved': 'Goal achieved!',
    'dashboard_steps_to_go': '{count} steps to go',
    'dashboard_protein_intake': 'Protein Intake',
    'dashboard_water_glasses': 'Water (glasses)',
    'dashboard_active_minutes': 'Active Minutes',
    'dashboard_calories_intake': 'Calories Intake',
    'dashboard_steps_added': '{count} steps added! 🎉',
    'dashboard_water_added': '+{count} glass(es) of water added! 💧',
    'dashboard_minutes_added': '{count} active minutes added! ⚡',
    'dashboard_coming_soon': 'Coming Soon',
    'dashboard_scanner_soon': 'Meal Scanner will be a Premium feature — coming soon!',
    'dashboard_add_steps': 'Add Steps',
    'dashboard_add_water': 'Add Water',
    'dashboard_add_active_minutes': 'Add Active Minutes',
    'dashboard_enter_steps': 'Enter steps',
    'dashboard_enter_minutes': 'Enter minutes',
    'dashboard_current_water': 'Current: {current} / {goal} glasses',

    // ==========================================
    // WORKOUT SCREEN
    // ==========================================
    'workout_title': 'Workout',
    'workout_sub': 'Choose your training style 💪',
    'workout_quick': 'Quick Start',
    'workout_muscle': 'Muscle Groups',
    'workout_plans': 'Workout Plans',
    'workout_full': 'Full Body Workout',
    'workout_library': 'My Library',
    'workout_recent': 'Recent Workouts',
    'workout_loading': 'AI is generating your workout... 🤖',
    'workout_start': 'Start Workout',
    'workout_finish': 'Finish Workout',
    'workout_log': 'Log Set',
    'workout_complete': '🎉 Workout Complete!',
    'workout_rest': 'Rest Day 😴',
    'workout_ai_generating': 'AI is generating your workout... 🤖',
    'workout_wait': 'Please wait a moment',
    'workout_started': 'Workout started! 🔥',
    'workout_sets_logged': '{count} sets logged! 💪',
    'workout_select_exercise': 'Select Exercise First',
    'workout_save_sets': 'Save {count} Sets ✓',
    'workout_exit_confirm': 'Exit Workout?',
    'workout_exit_sub': 'Save or discard your progress?',
    'workout_discard': 'Discard',
    'workout_save_exit': 'Save & Exit',
    'workout_ai_plan': 'AI Suggested Plan',
    'workout_no_sets': 'No sets logged yet',
    'workout_tap_to_log': 'Tap + to log a set 💪',
    'workout_details': 'Details →',

    // ==========================================
    // LIBRARY SCREEN
    // ==========================================
    'library_title': 'My Library 📚',
    'library_sub': 'Custom workout library',
    'library_empty': 'No custom workouts yet',
    'library_empty_sub': 'Create your own workout routine.',
    'library_create': 'Create Workout',
    'library_create_first': 'Create First Workout',
    'library_delete_confirm': 'Delete Workout?',
    'library_delete_sub': 'This custom workout will be permanently deleted.',
    'library_delete_success': 'Workout deleted 🗑️',
    'library_edit': 'Edit Workout ✏️',
    'library_start': 'Start',
    'library_save': 'SAVE',
    'library_name_hint': 'Workout name e.g. My Chest Routine',
    'library_search_hint': 'Search exercises...',
    'library_selected': 'Selected Exercises',
    'library_exercise': 'Exercise',
    'library_config': 'Config',
    'library_planned': 'Planned Exercises',
    'library_logged': 'Logged Sets',
    'library_start_workout': 'Start Custom Workout',
    'library_workout_started': 'Custom workout started! 🔥',
    'library_workout_complete': '🎉 Workout Complete!',
    'library_workout_done': 'Custom workout done! 💪',
    'library_save_config': 'Save Config',
    'library_create_workout': 'Create Workout ➕',
    'library_edit_workout': 'Edit Workout ✏️',
    'library_workout_name_hint': 'Workout name e.g. My Chest Routine',
    'library_exit_workout': 'Exit Workout?',
    'library_exit_sub': 'Save or discard your workout progress?',
    'library_discard': 'Discard',
    'library_save_exit': 'Save & Exit',
    'library_finish': 'FINISH',
    'library_log_set': '🏋️ Log Set',
    'library_select_exercise': 'Select Exercise',
    'library_save_sets': 'Save Sets',
    'library_no_sets': 'No sets logged yet',

    // ==========================================
    // SAVED MEALS SCREEN
    // ==========================================
    'saved_title': 'Saved Meals 📚',
    'saved_picker': 'Choose Saved Meal 📚',
    'saved_empty': 'No saved meals yet',
    'saved_empty_sub': 'Save your meals to add them with one tap.',
    'saved_delete_confirm': 'Delete Saved Meal?',
    'saved_delete_sub': '"{name}" will be deleted.',
    'saved_delete_success': 'Saved meal deleted 🗑️',
    'saved_choose': 'Tap to add this meal',

    // ==========================================
    // PROFILE SCREEN
    // ==========================================
    'profile_title': 'Profile',
    'profile_edit': 'Edit Profile',
    'profile_stats': 'Body Stats',
    'profile_goals': 'Daily Goals',
    'profile_settings': 'Settings',
    'profile_notifications': 'Notification Settings',
    'profile_about': 'About',
    'profile_delete': 'Delete Account',
    'profile_logout': 'Logout',
    'profile_photo': 'Profile Photo',
    'profile_take': 'Take Photo',
    'profile_gallery': 'Choose from Gallery',
    'profile_remove': 'Remove Photo',
    'profile_language': 'Language',
    'profile_language_sub': 'Change app language',
    'profile_take_sub': 'Use camera',
    'profile_gallery_sub': 'Select from photos',
    'profile_remove_sub': 'Delete current photo',
    'profile_gfit_disconnect_title': 'Disconnect Google Fit?',
    'profile_gfit_disconnect_body': 'Steps will be tracked using phone sensor only. Background step counting will stop.',
    'profile_gfit_disconnect_action': 'Disconnect',
    'profile_gfit_disconnected': 'Google Fit disconnected',
    'profile_version': 'FitGenie v2.0.0',
    'profile_customize_reminders': 'Customize your reminders',
    'profile_app_info': 'App info & version',
    'profile_delete_sub': 'Permanently delete your account & data',
    'profile_delete_confirm_title': 'Delete Account',
    'profile_delete_forever': 'Delete Forever',
    'profile_deleting': 'Deleting account...',
    'profile_fitness_level': 'Fitness Level',
    'profile_goal': 'Goal',
    'profile_edit_body_stats': 'Edit Body Stats',
    'profile_gender': 'Gender',
    'profile_edit_goals': 'Edit Goals',
    'profile_logout_confirm_title': 'Logout',
    'profile_logout_confirm_body': 'Are you sure you want to logout?',
    'profile_today_steps': "Today's Steps",
    'profile_about_version': 'Version 2.0.7\n\nYour AI Fitness Coach! 💪',

    // ==========================================
    // PROGRESS SCREEN
    // ==========================================
    'progress_title': '📊 Weekly Report',
    'progress_sub': 'Track your fitness journey',
    'progress_workouts': 'Workouts This Week',
    'progress_calories': 'Calories This Week',
    'progress_protein': 'Protein This Week',
    'progress_weight': 'Weight Trend',
    'progress_best': 'Best Day This Week!',
    'progress_insight': 'AI Insights',
    'progress_get': 'Get Insight',
    'progress_loading': 'Loading...',
    'progress_stats': '🏆 All Time Stats',
    'progress_total': 'Total Workouts',
    'progress_streak': 'Current Streak',
    'progress_best_streak': 'Best Streak',
    'progress_weight_logged': 'Weight logged! 💪',
    'progress_log_weight': 'Log Weight',
    'progress_weight_kg': 'Weight (kg)',
    'progress_cancel': 'Cancel',
    'progress_save': 'Save',
    'progress_tap_insight': 'Tap "Get Insight" for AI analysis',
    'progress_tap_log': 'Tap + to log new weight',
    'progress_today': 'TODAY',
    'progress_avg_calories': 'Avg Calories',
    'progress_avg_protein': 'Avg Protein',
    'progress_per_day': 'per day',
    'progress_days': 'days',
    'progress_best_day': 'Best Day This Week!',
    'progress_daily_breakdown': '📋 Daily Breakdown',

    // ==========================================
    // NOTIFICATIONS SCREEN
    // ==========================================
    'notifications_title': 'Notification Settings',
    'notifications_sub': 'Customize your reminders',
    'notifications_saved': '✅ Notification settings saved!',
    'notifications_error': '❌ Error saving settings: {error}',
    'notifications_test': '🔔 Test Notification',
    'notifications_test_body': 'Notifications are working perfectly!',
    'notifications_workout': 'Workout Reminder',
    'notifications_workout_sub': 'Daily morning workout reminder',
    'notifications_water': 'Water Reminders',
    'notifications_water_sub': 'Stay hydrated throughout the day',
    'notifications_lunch': 'Lunch Reminder',
    'notifications_lunch_sub': 'Remind to log lunch calories',
    'notifications_motivation': 'Daily Motivation',
    'notifications_motivation_sub': 'Get inspired with motivational quotes',
    'notifications_evening': 'Evening Reminder',
    'notifications_evening_sub': 'Remind to complete daily tracking',
    'notifications_time': '⏰ Time',
    'notifications_remind_every': '🔄 Remind every',
    'notifications_hour': '1 hour',
    'notifications_hours': '{count} hours',
    'notifications_save': '💾 Save Settings',
    'notifications_test_tooltip': 'Test Notification',

    // ==========================================
    // CHALLENGES SCREEN
    // ==========================================
    'challenges_title': '🎯 Challenges',
    'challenges_daily': 'Daily',
    'challenges_weekly': 'Weekly',
    'challenges_badges': 'Badges',
    'challenges_completed': 'Completed',
    'challenges_all': 'All challenges completed! 🎉',
    'challenges_level': 'Level {level}',
    'challenges_xp': '{xp} XP',
    'challenges_next_level': '{xp} XP to Level {level}',
    'challenges_unlocked': 'Unlocked ({count})',
    'challenges_locked': 'Locked ({count})',
    'challenges_streak': 'Streak',
    'challenges_workouts': 'Workouts',
    'challenges_badges_count': 'Badges',
    'challenges_weekly_info': "This Week's Challenges",
    'challenges_weekly_reset': 'Resets every Monday',

    // ==========================================
    // SPLASH SCREEN
    // ==========================================
    'splash_loading': 'Loading...',
    'splash_initializing': 'Initializing',
    'splash_tagline': 'Your AI Fitness Coach',
    // ==========================================
    // MEAL SCANNER
    // ==========================================
    'scanner_title': '🍽️ Meal Scanner',
    'scanner_hint': 'Take a photo of your meal or select from gallery',
    'scanner_camera': 'Camera',
    'scanner_gallery': 'Gallery',
    'scanner_loading': 'AI is analyzing your meal... 🤖',
    'scanner_error': 'Analysis failed: {error}',
    'scanner_add': "Add to Today's Calories",
    'scanner_health': 'Health Tip',
    'scanner_quantity': 'Quantity',
    'scanner_pick_error': 'Could not pick image: {error}',
    'scanner_barcode_not_found': 'This product was not found in the Open Food Facts database. Try a photo or add manually.',
    'scanner_barcode_error': 'Barcode lookup failed. Try again.',
    'scanner_added': '{food} added! (+{calories} cal)',
    'scanner_barcode_found': 'Product found via barcode',
    'scanner_placeholder': 'Take a photo of your meal, or scan a packet barcode',
    'scanner_scan_barcode': 'Scan Barcode (packaged food)',
    'scanner_protein': 'Protein',
    'scanner_carbs': 'Carbs',
    'scanner_fat': 'Fat',
    'scanner_fiber': 'Fiber',
    'scanner_kcal': 'kcal',
    'scanner_barcode_title': 'Scan Barcode',
    'scanner_barcode_hint': 'Place the packet barcode inside the frame',
    'exercise_library_title': 'Exercise Library',
    'exercise_search_hint': 'Search exercises...',
    'exercise_all': 'All',
    'exercise_no_results': 'No exercises found in this category. Try another category.',
    'exercise_primary_muscles': 'Primary Muscles',
    'exercise_secondary_muscles': 'Secondary Muscles',
    'exercise_equipment': 'Equipment',
    'exercise_how_to': 'How to do it',


    // ==========================================
    // FOOD SEARCH
    // ==========================================
    'food_search_title': 'Search Food 🔎',
    'food_search_hint': 'Search e.g. anda, roti, daal, biryani...',
    'food_search_empty': 'No food found',
    'food_search_empty_sub': 'Try another keyword like anda, roti, daal',
    'food_search_results': '{count} foods found',
    'food_search_estimated': 'Estimated',
    'food_search_calculated': 'Calculated Nutrition',
    'food_search_quantity': 'Quantity',
    'food_search_meal_type': 'Meal Type',
    'food_search_breakfast': '🍳 Breakfast',
    'food_search_lunch': '🍛 Lunch',
    'food_search_dinner': '🍽️ Dinner',
    'food_search_snacks': '🍿 Snacks',
    'food_search_add': 'Add to Meal',
    'food_search_all': 'All',

    // ==========================================
    // WORKOUT DETAIL SCREEN
    // ==========================================
    'workout_detail_title': 'Workout Details 🕐',
    'workout_detail_completed': 'Completed',
    'workout_detail_active': 'Active',
    'workout_detail_sets': 'sets',
    'workout_detail_volume': 'Volume',
    'workout_detail_calories': 'Calories',
    'workout_detail_planned': '📋 Planned Exercises',
    'workout_detail_performed': '💪 Performed Exercises',
    'workout_detail_all_sets': '🧾 All Logged Sets',
    'workout_detail_repeat': 'Repeat Workout',
    'workout_detail_no_sets': 'No set data available',
    'workout_detail_no_logs': 'No set logs found',
    'workout_detail_minutes': 'min',

    // ==========================================
    // WORKOUT PLAN SCREEN
    // ==========================================
    'workout_plan_overview': 'Plan Overview',
    'workout_plan_target': 'Target Muscles',
    'workout_plan_exercises': 'Exercises in this Plan',
    'workout_plan_start': 'Start This Workout',
    'workout_plan_total_sets': 'Total Sets',
    'workout_plan_minutes': 'Minutes',
    'workout_plan_gifs_on': 'GIFs ON',
    'workout_plan_gifs_off': 'GIFs OFF',
    'workout_plan_rest': '{sec}s rest',
    'workout_plan_cal_min': '{cal} cal/min',
    'workout_plan_tap_guide': 'Tap for full form guide →',

    // ==========================================
    // MUSCLE GROUP EXERCISES
    // ==========================================
    'muscle_exercises_title': '{emoji} {name}',
    'muscle_exercises_count': '{count} Exercises',
    'muscle_exercises_sub': 'with animated demos 🎬',
    'muscle_exercises_gifs_on': 'GIFs ON',
    'muscle_exercises_gifs_off': 'GIFs OFF',
    'muscle_exercises_loading': 'Loading...',
    'muscle_exercises_full_guide': 'Full Guide →',
    'muscle_exercises_how_to': '📝 How to Perform',
    'muscle_exercises_tips': '💡 Pro Tips',
    'muscle_exercises_mistakes': '⚠️ Common Mistakes',
    'muscle_exercises_coming_soon': 'Detailed guide coming soon!',
    'muscle_exercises_target': 'Target Muscles',
    'muscle_exercises_equipment': 'Equipment',
    'muscle_exercises_tempo': 'Tempo: {tempo}',
    'muscle_exercises_cal_per_min': '{cal} cal/min',
    'muscle_exercises_difficulty': 'Difficulty',

    // ==========================================
    // MISC LABELS (batch 2 fix)
    // ==========================================
    'calories_save_goals': 'Save Goals',
    'workout_choose_exercise': 'Choose exercise...',
    'label_sets': 'Sets',
    'label_reps': 'Reps',
    'label_reps_time': 'Reps / Time',
    'label_weight_kg': 'Weight (kg)',
    'workout_great_job': 'Great job bhai!',
    'library_sets_logged': 'Sets logged: {count}',
    'library_duration_min': 'Duration: {min} min',
    'progress_goal_calories': 'Goal: {value}',
    'progress_goal_protein': 'Goal: {value}g',
    'dashboard_steps_label': 'steps',
    'dashboard_goal_steps': 'Goal: {value}',
    'dashboard_goal_calories': 'Goal: {value}',
    'dashboard_kcal': 'kcal',
    'login_reset_password': 'Reset Password',
    'login_send': 'Send',

    // ==========================================
    // GENERAL / COMMON
    // ==========================================
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'close': 'Close',
    'done': 'Done',
    'ok': 'OK',
    'loading': 'Loading...',
    'retry': 'Retry',
    'no_data': 'No data available',
    'search': 'Search...',

    // ==========================================
    // ERRORS
    // ==========================================
    'error_network': 'Network error. Please check your connection.',
    'error_auth': 'Authentication failed. Please try again.',
    'error_unknown': 'Something went wrong. Please try again.',
    'error_empty': 'Please fill in all fields.',
    'error_invalid_email': 'Please enter a valid email address.',
    'error_invalid_password': 'Password must be at least 8 characters.',
  };

  static const Map<String, String> _ur = {
    // ==========================================
    // LANGUAGE SELECTION
    // ==========================================
    'language_select_title': 'Apni Zaban Chuno',
    'language_english': 'English',
    'language_urdu': 'Roman Urdu',



    // ==========================================
    // ONBOARDING
    // ==========================================
    'onboarding_welcome': 'Salam {name} 👋',
    'onboarding_subtitle': "Chalo tumhara FitGenie personalize karte hain",
    'onboarding_gender': 'Tumhara gender kya hai?',
    'onboarding_gender_sub': 'Isse hum tumhare calorie aur nutrition goals sahi calculate karte hain.',
    'onboarding_age': 'Tumhari age kitni hai?',
    'onboarding_age_sub': 'Slider ghuma ke apni age set karo.',
    'onboarding_height': 'Height aur weight batao',
    'onboarding_height_sub': 'Yeh tumhare daily targets ki bunyad hai.',
    'onboarding_level': 'Fitness level kya hai?',
    'onboarding_level_sub': 'Isse workouts tumhari level ke hisab se milenge.',
    'onboarding_goal': 'Tumhara main goal kya hai?',
    'onboarding_goal_sub': 'Hum isi ke hisab se calorie aur macro targets set karenge.',
    'onboarding_next': 'Agla',
    'onboarding_start': 'Shuru Karo 🚀',
    'onboarding_back': 'Peeche',

    // ==========================================
    // LOGIN
    // ==========================================
    'login_error': 'Kuch gadbad ho gayi. Dobara try karo.',
    'login_success': 'Wapas khush aamdeed! 🎉',
    'login_welcome': 'Wapas khush aamdeed',
    'login_email_hint': 'Email Address',
    'login_password_hint': 'Password',
    'login_button': 'Sign In karein',
    'login_google': 'Google se continue karo',
    'login_forgot': 'Password bhool gaye?',
    'login_remember': 'Mujhe yaad rakho',
    'login_signup': "Account nahi hai?",
    'login_signup_free': 'Free sign up karo',

    // ==========================================
    // AUTH
    // ==========================================
    'auth_verify_email': 'Email Verify Karo!',
    'auth_verify_sub': 'Email pe verification link bheja hai. Verify karo phir login karo.',
    'auth_check_again': 'Check karo',
    'auth_logout': 'Logout',

    // ==========================================
    // CHAT / AI COACH
    // ==========================================
    'chat_welcome': "👋 Hey {name}!\n\n🤖 Main hoon **FitGenie** — tera personal AI Fitness Coach!\n\n━━━━━━━━━━━━━━━━━━━━━━━━\n\n🎯 **Main help kar sakta hun:**\n\n💪 **Workouts**\n   Muscle-specific exercises & plans\n\n🍽️ **Nutrition**  \n   Diet plans & calorie guidance\n\n🔥 **Motivation**\n   Daily inspiration & tips\n\n📊 **Progress**\n   Track & improve karne mein\n\n━━━━━━━━━━━━━━━━━━━━━━━━\n\nNeeche quick buttons use karo ya type karo!\n\n**Let's get started! 🚀**",
    'chat_error': '❌ **Oops! Kuch gadbad ho gayi.**\n\nDobara try karo ya internet check karo.\n\n💡 Tip: Neeche quick buttons bhi try kar sakte ho!',
    'chat_clear_title': 'Chat Clear Karo?',
    'chat_clear_sub': 'Saari messages delete ho jayengi. Ye action undo nahi hoga.',
    'chat_clear': 'Clear karein',
    'chat_cancel': 'Cancel karein',
    'chat_about_title': 'FitGenie AI Coach',
    'chat_about_powered': 'Google Gemini AI se powered',
    'chat_about_features': '🎯 Features:',
    'chat_about_workouts': '• Personalized workout plans',
    'chat_about_nutrition': '• Diet aur nutrition advice',
    'chat_about_motivation': '• Motivation aur tips',
    'chat_about_progress': '• Progress tracking mein madad',
    'chat_about_data': '💡 Aapka data responses personalize karne ke liye use hota hai.',
    'chat_got_it': 'Samajh gaya!',
    'chat_online': 'Online • Madad ke liye tayyar',
    'chat_thinking': 'Soch raha hai...',
    'chat_placeholder': 'Fitness ke baare mein kuch poocho...',
    'chat_send': 'Send karein',
    'chat_typing': 'FitGenie soch raha hai...',
    'chat_workout': 'Workout',
    'chat_diet': 'Diet Plan',
    'chat_motivate': 'Motivate karein',
    'chat_weight_loss': 'Weight Loss',
    'chat_muscle_gain': 'Muscle Gain',
    'chat_hydration': 'Hydration',
    'chat_recovery': 'Recovery',

    // ==========================================
    // SNACKBARS
    // ==========================================
    'snackbar_added': 'Add ho gaya! ✅',
    'snackbar_deleted': 'Delete ho gaya! 🗑️',
    'snackbar_saved': 'Save ho gaya! 💾',
    'snackbar_error': 'Kuch gadbad ho gayi. Dobara try karo.',
    'snackbar_offline': 'Aap offline hain. Changes online sync ho jayenge.',

    // ==========================================
    // CALORIES SCREEN
    // ==========================================
    'calories_title': 'Nutrition 🍽️',
    'calories_sub': 'Meals, macros aur water track karo',
    'calories_summary': 'Aaj Ka Khulasa',
    'calories_water': 'Water Tracker',
    'calories_search': 'Khana Talash Karein',
    'calories_saved': 'Saved Meals',
    'calories_scan': 'Meal Scan Karein',
    'calories_goals': 'Goals',
    'calories_empty': 'Abhi koi item nahi hai',
    'calories_custom': 'Custom manual entry',
    'calories_recent': 'Recent Foods',
    'calories_load_failed': 'Load nahi hua: {error}',
    'calories_added_success': '{name} add ho gaya ✅',
    'calories_scanned_success': '{name} scan ho kar add ho gaya ✅',
    'calories_meal_empty_error': 'Is meal mein abhi koi item nahi hai',
    'calories_template_saved': '{name} library mein save ho gaya ✅',
    'calories_food_name_required': 'Food ka naam zaroori hai',

    // ==========================================
    // DASHBOARD SCREEN
    // ==========================================
    'dashboard_greeting_morning': 'Subh Bakhair',
    'dashboard_greeting_afternoon': 'Dopehar Bakhair',
    'dashboard_greeting_evening': 'Sham Bakhair',
    'dashboard_greeting_night': 'Shab Bakhair',
    'dashboard_quick_actions': 'Quick Actions',
    'dashboard_step_counter': 'Step Counter',
    'dashboard_calories_burned': 'Calories Burn Hui',
    'dashboard_daily_goals': 'Daily Goals',
    'dashboard_weekly_activity': 'Weekly Activity',
    'dashboard_quick_log': 'Quick Log',
    'dashboard_workouts': 'Workouts',
    'dashboard_nutrition': 'Nutrition',
    'dashboard_ai_coach': 'AI Coach',
    'dashboard_progress': 'Progress',
    'dashboard_challenges': 'Challenges',
    'dashboard_scan_meal': 'Meal Scan Karein',
    'dashboard_goal_achieved': 'Goal achieve ho gaya!',
    'dashboard_steps_to_go': '{count} steps baaki hain',
    'dashboard_protein_intake': 'Protein Intake',
    'dashboard_water_glasses': 'Paani (glasses)',
    'dashboard_active_minutes': 'Active Minutes',
    'dashboard_calories_intake': 'Calories Intake',
    'dashboard_steps_added': '{count} steps add ho gaye! 🎉',
    'dashboard_water_added': '+{count} glass paani add ho gaya! 💧',
    'dashboard_minutes_added': '{count} active minutes add ho gaye! ⚡',
    'dashboard_coming_soon': 'Jald Aa Raha Hai',
    'dashboard_scanner_soon': 'Meal Scanner ek Premium feature banega — jald hi available hoga!',
    'dashboard_add_steps': 'Steps Add Karo',
    'dashboard_add_water': 'Paani Add Karo',
    'dashboard_add_active_minutes': 'Active Minutes Add Karo',
    'dashboard_enter_steps': 'Steps likho',
    'dashboard_enter_minutes': 'Minutes likho',
    'dashboard_current_water': 'Abhi: {current} / {goal} glasses',

    // ==========================================
    // WORKOUT SCREEN
    // ==========================================
    'workout_title': 'Workout',
    'workout_sub': 'Apna training style chuno 💪',
    'workout_quick': 'Quick Start',
    'workout_muscle': 'Muscle Groups',
    'workout_plans': 'Workout Plans',
    'workout_full': 'Full Body Workout',
    'workout_library': 'My Library',
    'workout_recent': 'Recent Workouts',
    'workout_loading': 'AI workout generate kar raha hai... 🤖',
    'workout_start': 'Workout Shuru Karo',
    'workout_finish': 'Workout Khatam Karo',
    'workout_log': 'Set Log Karo',
    'workout_complete': '🎉 Workout Mukammal!',
    'workout_rest': 'Rest Day 😴',
    'workout_ai_generating': 'AI workout generate kar raha hai... 🤖',
    'workout_wait': 'Thoda wait karo',
    'workout_started': 'Workout start ho gaya! 🔥',
    'workout_sets_logged': '{count} sets log ho gaye! 💪',
    'workout_select_exercise': 'Pehle Exercise Chuno',
    'workout_save_sets': '{count} Sets Save Karo ✓',
    'workout_exit_confirm': 'Workout Chhorna Hai?',
    'workout_exit_sub': 'Save ya discard karo progress?',
    'workout_discard': 'Discard Karein',
    'workout_save_exit': 'Save Karke Nikalein',
    'workout_ai_plan': 'AI Ka Tajweez Kiya Plan',
    'workout_no_sets': 'Abhi koi set log nahi hua',
    'workout_tap_to_log': 'Tap + karo set log karne ke liye 💪',
    'workout_details': 'Details →',

    // ==========================================
    // LIBRARY SCREEN
    // ==========================================
    'library_title': 'My Library 📚',
    'library_sub': 'Custom workout library',
    'library_empty': 'Abhi tak koi custom workout nahi',
    'library_empty_sub': 'Apna khud ka workout banao.',
    'library_create': 'Workout Banayein',
    'library_create_first': 'Pehla Workout Banayein',
    'library_delete_confirm': 'Workout Delete Karo?',
    'library_delete_sub': 'Yeh custom workout permanently delete ho jayega.',
    'library_delete_success': 'Workout delete ho gaya 🗑️',
    'library_edit': 'Workout Edit Karein ✏️',
    'library_start': 'Shuru Karein',
    'library_save': 'SAVE KAREIN',
    'library_name_hint': 'Workout ka naam masalan My Chest Routine',
    'library_search_hint': 'Exercises search karo...',
    'library_selected': 'Chuni Gayi Exercises',
    'library_exercise': 'Exercise',
    'library_config': 'Config',
    'library_planned': 'Planned Exercises',
    'library_logged': 'Logged Sets',
    'library_start_workout': 'Custom Workout Shuru Karo',
    'library_workout_started': 'Custom workout start ho gaya! 🔥',
    'library_workout_complete': '🎉 Workout Mukammal!',
    'library_workout_done': 'Custom workout complete! 💪',
    'library_save_config': 'Config Save Karo',
    'library_create_workout': 'Workout Banayein ➕',
    'library_edit_workout': 'Workout Edit Karein ✏️',
    'library_workout_name_hint': 'Workout ka naam masalan My Chest Routine',
    'library_exit_workout': 'Workout Chhorna Hai?',
    'library_exit_sub': 'Save ya discard karo workout progress?',
    'library_discard': 'Discard Karein',
    'library_save_exit': 'Save Karke Nikalein',
    'library_finish': 'FINISH KAREIN',
    'library_log_set': '🏋️ Set Log Karo',
    'library_select_exercise': 'Exercise Chuno',
    'library_save_sets': 'Sets Save Karo',
    'library_no_sets': 'Abhi koi set log nahi hua',

    // ==========================================
    // SAVED MEALS SCREEN
    // ==========================================
    'saved_title': 'Saved Meals 📚',
    'saved_picker': 'Saved Meal Chuno 📚',
    'saved_empty': 'Abhi tak koi meal save nahi hui',
    'saved_empty_sub': 'Apni meals save karo taake 1 tap mein add ho.',
    'saved_delete_confirm': 'Saved Meal Delete Karo?',
    'saved_delete_sub': '"{name}" delete ho jayega.',
    'saved_delete_success': 'Saved meal delete ho gaya 🗑️',
    'saved_choose': 'Tap karo ye meal add karne ke liye',

    // ==========================================
    // PROFILE SCREEN
    // ==========================================
    'profile_title': 'Profile',
    'profile_edit': 'Profile Edit Karein',
    'profile_stats': 'Body Stats',
    'profile_goals': 'Daily Goals',
    'profile_settings': 'Settings',
    'profile_notifications': 'Notification Settings',
    'profile_about': 'About',
    'profile_delete': 'Account Delete Karein',
    'profile_logout': 'Logout',
    'profile_photo': 'Profile Photo',
    'profile_take': 'Photo Khenchein',
    'profile_gallery': 'Gallery Se Chunein',
    'profile_remove': 'Photo Hataein',
    'profile_language': 'Language',
    'profile_language_sub': 'App ki language change karo',
    'profile_take_sub': 'Camera use karein',
    'profile_gallery_sub': 'Photos se chunein',
    'profile_remove_sub': 'Current photo delete karein',
    'profile_gfit_disconnect_title': 'Google Fit Disconnect Karein?',
    'profile_gfit_disconnect_body': 'Steps ab sirf phone sensor se track honge. Background step counting band ho jayegi.',
    'profile_gfit_disconnect_action': 'Disconnect Karein',
    'profile_gfit_disconnected': 'Google Fit disconnect ho gaya',
    'profile_version': 'FitGenie v2.0.0',
    'profile_customize_reminders': 'Apni reminders customize karein',
    'profile_app_info': 'App ki info aur version',
    'profile_delete_sub': 'Apna account aur data hamesha ke liye delete karein',
    'profile_delete_confirm_title': 'Account Delete Karein',
    'profile_delete_forever': 'Hamesha Ke Liye Delete Karein',
    'profile_deleting': 'Account delete ho raha hai...',
    'profile_fitness_level': 'Fitness Level',
    'profile_goal': 'Goal',
    'profile_edit_body_stats': 'Body Stats Edit Karein',
    'profile_gender': 'Gender',
    'profile_edit_goals': 'Goals Edit Karein',
    'profile_logout_confirm_title': 'Logout',
    'profile_logout_confirm_body': 'Kya aap waqai logout karna chahte hain?',
    'profile_today_steps': 'Aaj Ke Steps',
    'profile_about_version': 'Version 2.0.7\n\nAapka AI Fitness Coach! 💪',

    // ==========================================
    // PROGRESS SCREEN
    // ==========================================
    'progress_title': '📊 Weekly Report',
    'progress_sub': 'Apni fitness journey track karo',
    'progress_workouts': 'Is Hafte Ke Workouts',
    'progress_calories': 'Is Hafte Ki Calories',
    'progress_protein': 'Is Hafte Ka Protein',
    'progress_weight': 'Weight Trend',
    'progress_best': 'Is Hafte Ka Behtareen Din!',
    'progress_insight': 'AI Insights',
    'progress_get': 'Insight Lein',
    'progress_loading': 'Load ho raha hai...',
    'progress_stats': '🏆 Tamam Waqt Ke Stats',
    'progress_total': 'Kul Workouts',
    'progress_streak': 'Current Streak',
    'progress_best_streak': 'Behtareen Streak',
    'progress_weight_logged': 'Weight log ho gaya! 💪',
    'progress_log_weight': 'Weight Log Karo',
    'progress_weight_kg': 'Weight (kg)',
    'progress_cancel': 'Cancel karein',
    'progress_save': 'Save karein',
    'progress_tap_insight': '"Get Insight" tap karo AI analysis ke liye',
    'progress_tap_log': 'Tap + karo naya weight log karne ke liye',
    'progress_today': 'AAJ',
    'progress_avg_calories': 'Average Calories',
    'progress_avg_protein': 'Average Protein',
    'progress_per_day': 'fi din',
    'progress_days': 'din',
    'progress_best_day': 'Is Hafte Ka Behtareen Din!',
    'progress_daily_breakdown': '📋 Roz Ka Tafseeli Jaiza',

    // ==========================================
    // NOTIFICATIONS SCREEN
    // ==========================================
    'notifications_title': 'Notification Settings',
    'notifications_sub': 'Apni reminders customize karo',
    'notifications_saved': '✅ Notification settings save ho gaye!',
    'notifications_error': '❌ Settings save mein error: {error}',
    'notifications_test': '🔔 Test Notification',
    'notifications_test_body': 'Notifications bilkul theek kaam kar rahe hain!',
    'notifications_workout': 'Workout Yaad Dahani',
    'notifications_workout_sub': 'Roz subh workout ki yaad dahani',
    'notifications_water': 'Paani Peene Ki Yaad Dahani',
    'notifications_water_sub': 'Din bhar hydrated raho',
    'notifications_lunch': 'Lunch Ki Yaad Dahani',
    'notifications_lunch_sub': 'Lunch calories log karne ki reminder',
    'notifications_motivation': 'Roz Ki Motivation',
    'notifications_motivation_sub': 'Motivational quotes se inspire ho jao',
    'notifications_evening': 'Sham Ki Yaad Dahani',
    'notifications_evening_sub': 'Daily tracking complete karne ki reminder',
    'notifications_time': '⏰ Waqt',
    'notifications_remind_every': '🔄 Har',
    'notifications_hour': '1 ghante baad yaad dahani',
    'notifications_hours': '{count} ghante',
    'notifications_save': '💾 Settings Save Karo',
    'notifications_test_tooltip': 'Test Notification',

    // ==========================================
    // CHALLENGES SCREEN
    // ==========================================
    'challenges_title': '🎯 Challenges',
    'challenges_daily': 'Roz Ke',
    'challenges_weekly': 'Hafte Ke',
    'challenges_badges': 'Badges',
    'challenges_completed': 'Mukammal',
    'challenges_all': 'Sare challenges mukammal! 🎉',
    'challenges_level': 'Level {level}',
    'challenges_xp': '{xp} XP',
    'challenges_next_level': 'Level {level} ke liye {xp} XP',
    'challenges_unlocked': 'Unlock Ho Gaye ({count})',
    'challenges_locked': 'Lock ({count})',
    'challenges_streak': 'Streak',
    'challenges_workouts': 'Workouts',
    'challenges_badges_count': 'Badges',
    'challenges_weekly_info': 'Is Hafte Ke Challenges',
    'challenges_weekly_reset': 'Har Peer Ko Reset Hota Hai',

    // ==========================================
    // SPLASH SCREEN
    // ==========================================
    'splash_loading': 'Load ho raha hai...',
    'splash_initializing': 'Shuru ho raha hai',
    'splash_tagline': 'Aapka AI Fitness Coach',

    // ==========================================
    // MEAL SCANNER
    // ==========================================
    'scanner_title': '🍽️ Meal Scanner',
    'scanner_hint': 'Khana ki photo lo ya select karo',
    'scanner_camera': 'Camera',
    'scanner_gallery': 'Gallery',
    'scanner_loading': 'AI analyze kar raha hai... 🤖',
    'scanner_error': 'Analysis fail ho gayi: {error}',
    'scanner_add': "Today's Calories mein add karo",
    'scanner_health': 'Sehat Ki Tip',
    'scanner_quantity': 'Quantity',



    'scanner_pick_error': 'Image pick nahi ho payi: {error}',
    'scanner_barcode_not_found': 'Ye product Open Food Facts database mein nahi mila. Photo se try karo ya manually add karo.',
    'scanner_barcode_error': 'Barcode lookup fail ho gaya. Dobara try karo.',
    'scanner_added': '{food} add ho gaya! (+{calories} cal)',
    'scanner_barcode_found': 'Barcode se product mil gaya',
    'scanner_placeholder': 'Khana ki photo lo, ya packet barcode scan karo',
    'scanner_scan_barcode': 'Barcode Scan Karo (packaged food)',
    'scanner_protein': 'Protein',
    'scanner_carbs': 'Carbs',
    'scanner_fat': 'Fat',
    'scanner_fiber': 'Fiber',
    'scanner_kcal': 'kcal',
    'scanner_barcode_title': 'Barcode Scan Karo',
    'scanner_barcode_hint': 'Packet ka barcode frame ke andar rakho',
    'exercise_library_title': 'Exercise Library',
    'exercise_search_hint': 'Exercise search karo...',
    'exercise_all': 'All',
    'exercise_no_results': 'Is category mein exercises nahi mile. Koi aur category try karo.',
    'exercise_primary_muscles': 'Primary Muscles',
    'exercise_secondary_muscles': 'Secondary Muscles',
    'exercise_equipment': 'Equipment',
    'exercise_how_to': 'Ye Kaise Karein',

    // ==========================================
    // FOOD SEARCH
    // ==========================================
    'food_search_title': 'Khana Talash Karein 🔎',
    'food_search_hint': 'Search karo e.g. anda, roti, daal, biryani...',
    'food_search_empty': 'Koi food nahi mila',
    'food_search_empty_sub': 'Kuch aur try karo jaise anda, roti, daal',
    'food_search_results': '{count} foods mil gaye',
    'food_search_estimated': 'Andazan',
    'food_search_calculated': 'Calculate Ki Gayi Nutrition',
    'food_search_quantity': 'Quantity',
    'food_search_meal_type': 'Meal Ki Qisam',
    'food_search_breakfast': '🍳 Nashta',
    'food_search_lunch': '🍛 Lunch',
    'food_search_dinner': '🍽️ Dinner',
    'food_search_snacks': '🍿 Snacks',
    'food_search_add': 'Meal mein add karo',
    'food_search_all': 'Sab',

    // ==========================================
    // WORKOUT DETAIL SCREEN
    // ==========================================
    'workout_detail_title': 'Workout Tafseelat 🕐',
    'workout_detail_completed': 'Mukammal',
    'workout_detail_active': 'Active',
    'workout_detail_sets': 'sets',
    'workout_detail_volume': 'Volume',
    'workout_detail_calories': 'Calories',
    'workout_detail_planned': '📋 Planned Exercises',
    'workout_detail_performed': '💪 Ki Gayi Exercises',
    'workout_detail_all_sets': '🧾 Tamam Logged Sets',
    'workout_detail_repeat': 'Workout Dobara Karein',
    'workout_detail_no_sets': 'Koi set data mojood nahi',
    'workout_detail_no_logs': 'Koi set logs nahi mile',
    'workout_detail_minutes': 'min',

    // ==========================================
    // WORKOUT PLAN SCREEN
    // ==========================================
    'workout_plan_overview': 'Plan Ka Jaiza',
    'workout_plan_target': 'Target Muscles',
    'workout_plan_exercises': 'Is Plan Ki Exercises',
    'workout_plan_start': 'Ye Workout Shuru Karein',
    'workout_plan_total_sets': 'Kul Sets',
    'workout_plan_minutes': 'Minutes',
    'workout_plan_gifs_on': 'GIFs ON',
    'workout_plan_gifs_off': 'GIFs OFF',
    'workout_plan_rest': '{sec}s aaram',
    'workout_plan_cal_min': '{cal} cal/min',
    'workout_plan_tap_guide': 'Poori guide ke liye tap karein →',

    // ==========================================
    // MUSCLE GROUP EXERCISES
    // ==========================================
    'muscle_exercises_title': '{emoji} {name}',
    'muscle_exercises_count': '{count} Exercises',
    'muscle_exercises_sub': 'animated demos ke sath 🎬',
    'muscle_exercises_gifs_on': 'GIFs ON',
    'muscle_exercises_gifs_off': 'GIFs OFF',
    'muscle_exercises_loading': 'Load ho raha hai...',
    'muscle_exercises_full_guide': 'Poori Guide →',
    'muscle_exercises_how_to': '📝 Kaise Karein',
    'muscle_exercises_tips': '💡 Pro Tips',
    'muscle_exercises_mistakes': '⚠️ Aam Ghaltiyan',
    'muscle_exercises_coming_soon': 'Tafseeli guide jald aa rahi hai!',
    'muscle_exercises_target': 'Target Muscles',
    'muscle_exercises_equipment': 'Equipment',
    'muscle_exercises_tempo': 'Tempo: {tempo}',
    'muscle_exercises_cal_per_min': '{cal} cal/min',
    'muscle_exercises_difficulty': 'Mushkil Darja',

    // ==========================================
    // MISC LABELS (batch 2 fix)
    // ==========================================
    'calories_save_goals': 'Goals Save Karein',
    'workout_choose_exercise': 'Exercise chunein...',
    'label_sets': 'Sets',
    'label_reps': 'Reps',
    'label_reps_time': 'Reps / Waqt',
    'label_weight_kg': 'Weight (kg)',
    'workout_great_job': 'Shabash bhai!',
    'library_sets_logged': '{count} sets log hui',
    'library_duration_min': 'Waqt: {min} min',
    'progress_goal_calories': 'Goal: {value}',
    'progress_goal_protein': 'Goal: {value}g',
    'dashboard_steps_label': 'steps',
    'dashboard_goal_steps': 'Goal: {value}',
    'dashboard_goal_calories': 'Goal: {value}',
    'dashboard_kcal': 'kcal',
    'login_reset_password': 'Password Reset Karein',
    'login_send': 'Bhejein',

    // ==========================================
    // GENERAL / COMMON
    // ==========================================
    'cancel': 'Cancel karein',
    'save': 'Save karein',
    'delete': 'Delete karein',
    'edit': 'Edit karein',
    'close': 'Band karein',
    'done': 'Ho gaya',
    'ok': 'Theek hai',
    'loading': 'Load ho raha hai...',
    'retry': 'Dobara koshish karein',
    'no_data': 'Koi data mojood nahi',
    'search': 'Talash karein...',

    // ==========================================
    // ERRORS
    // ==========================================
    'error_network': 'Network mein masla hai. Apna connection check karein.',
    'error_auth': 'Authentication fail ho gayi. Dobara koshish karein.',
    'error_unknown': 'Kuch gadbad ho gayi. Dobara try karo.',
    'error_empty': 'Baraye meharbani sare fields bharein.',
    'error_invalid_email': 'Sahi email address darj karein.',
    'error_invalid_password': 'Password kam az kam 8 characters ka hona chahiye.',
  };

  // ──────────────────────────────────────────
  // 📖 Get String by Key
  // ──────────────────────────────────────────

  static String get(String key, {Map<String, String>? params}) {
    final isEnglish = LanguageProvider().isEnglish;
    final map = isEnglish ? _en : _ur;

    String? value = map[key];

    if (value == null) {
      debugPrint('⚠️ Missing string key: $key');
      return key;
    }

    // Replace parameters
    if (params != null) {
      params.forEach((k, v) {
        value = value!.replaceAll('{$k}', v);
      });
    }

    return value!;
  }

  // ──────────────────────────────────────────
  // 📖 Convenience Getters
  // ──────────────────────────────────────────

  static String get onboardingWelcome => get('onboarding_welcome');
  static String get onboardingSubtitle => get('onboarding_subtitle');
  static String get onboardingGender => get('onboarding_gender');
  static String get onboardingGenderSub => get('onboarding_gender_sub');
  static String get onboardingAge => get('onboarding_age');
  static String get onboardingAgeSub => get('onboarding_age_sub');
  static String get onboardingHeight => get('onboarding_height');
  static String get onboardingHeightSub => get('onboarding_height_sub');
  static String get onboardingLevel => get('onboarding_level');
  static String get onboardingLevelSub => get('onboarding_level_sub');
  static String get onboardingGoal => get('onboarding_goal');
  static String get onboardingGoalSub => get('onboarding_goal_sub');
  static String get onboardingNext => get('onboarding_next');
  static String get onboardingStart => get('onboarding_start');
  static String get onboardingBack => get('onboarding_back');
}