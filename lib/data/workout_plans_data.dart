// lib/data/workout_plans_data.dart

import 'exercise_data.dart';

// ==========================================
// 📋 WORKOUT PLAN MODEL
// ==========================================

class WorkoutPlan {
  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final int color;
  final String difficulty;
  final int estimatedMinutes;
  final String description;
  final List<PlanExercise> exercises;
  final List<String> targetMuscles;
  final String category; // push, pull, legs, upper, lower, full_body, cardio

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.description,
    required this.exercises,
    required this.targetMuscles,
    required this.category,
  });

  int get totalSets {
    int total = 0;
    for (var e in exercises) {
      total += e.sets;
    }
    return total;
  }

  int get totalExercises => exercises.length;

  // Get actual Exercise objects from ExerciseData
  List<Exercise> getExerciseObjects() {
    final allExercises = ExerciseData.getAllExercises();
    List<Exercise> result = [];
    for (var planEx in exercises) {
      try {
        final found = allExercises.firstWhere((e) => e.id == planEx.exerciseId);
        result.add(found);
      } catch (_) {
        // Exercise not found �� skip
      }
    }
    return result;
  }
}

class PlanExercise {
  final String exerciseId; // matches Exercise.id from exercise_data.dart
  final int sets;
  final String reps; // "10" or "60 sec" for planks etc.
  final String? notes;
  final int restSeconds;

  const PlanExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.notes,
    this.restSeconds = 60,
  });
}

// ==========================================
// 🏋️ ALL WORKOUT PLANS
// ==========================================

class WorkoutPlansData {
  // ==========================================
  // 🔴 PUSH DAY (Chest + Shoulders + Triceps)
  // ==========================================
  static const WorkoutPlan pushDay = WorkoutPlan(
    id: 'push_day',
    name: 'Push Day',
    subtitle: 'Chest + Shoulders + Triceps',
    emoji: '🔴',
    color: 0xFFE53935,
    difficulty: 'Intermediate',
    estimatedMinutes: 60,
    description:
    'Complete push workout targeting chest, shoulders aur triceps. Compound movements se start, isolation pe end.',
    category: 'push',
    targetMuscles: ['Chest', 'Front Delts', 'Side Delts', 'Triceps'],
    exercises: [
      PlanExercise(
        exerciseId: 'chest_1', // Flat Bench Press
        sets: 4,
        reps: '10',
        notes: 'Heavy compound — warm up properly',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'chest_2', // Incline Dumbbell Press
        sets: 3,
        reps: '12',
        notes: 'Upper chest focus — 30° angle',
        restSeconds: 75,
      ),
      PlanExercise(
        exerciseId: 'chest_5', // Cable Crossover
        sets: 3,
        reps: '15',
        notes: 'Squeeze at center — constant tension',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'shoulders_1', // Overhead Press
        sets: 4,
        reps: '10',
        notes: 'Strict press — no leg drive',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'shoulders_3', // Lateral Raises
        sets: 3,
        reps: '15',
        notes: 'Light weight — form important',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'triceps_1', // Tricep Pushdowns
        sets: 3,
        reps: '12',
        notes: 'Elbows locked at sides',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'triceps_2', // Skull Crushers
        sets: 3,
        reps: '10',
        notes: 'Behind head for long head stretch',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'triceps_7', // Rope Pushdowns
        sets: 3,
        reps: '15',
        notes: 'Split rope at bottom — finisher',
        restSeconds: 45,
      ),
    ],
  );

  // ==========================================
  // 🔵 PULL DAY (Back + Biceps + Rear Delts)
  // ==========================================
  static const WorkoutPlan pullDay = WorkoutPlan(
    id: 'pull_day',
    name: 'Pull Day',
    subtitle: 'Back + Biceps + Rear Delts',
    emoji: '🔵',
    color: 0xFF1E88E5,
    difficulty: 'Intermediate',
    estimatedMinutes: 55,
    description:
    'Complete pull workout. Back thickness aur width dono ke liye exercises. Biceps aur rear delts bhi covered.',
    category: 'pull',
    targetMuscles: ['Lats', 'Middle Back', 'Rear Delts', 'Biceps', 'Traps'],
    exercises: [
      PlanExercise(
        exerciseId: 'back_1', // Pull-ups
        sets: 4,
        reps: '8',
        notes: 'Strict form — no kipping',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'back_3', // Barbell Rows
        sets: 4,
        reps: '10',
        notes: 'Back flat — belly button tak pull',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'back_2', // Lat Pulldown
        sets: 3,
        reps: '12',
        notes: 'Wide grip — chest tak pull',
        restSeconds: 75,
      ),
      PlanExercise(
        exerciseId: 'back_5', // Seated Cable Row
        sets: 3,
        reps: '12',
        notes: 'Squeeze shoulder blades',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'back_8', // Face Pulls
        sets: 3,
        reps: '15',
        notes: 'External rotate at end — rear delts',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'biceps_1', // Barbell Curls
        sets: 3,
        reps: '12',
        notes: 'Strict curl — no swing',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'biceps_3', // Hammer Curls
        sets: 3,
        reps: '12',
        notes: 'Neutral grip — brachialis target',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'biceps_4', // Preacher Curls
        sets: 3,
        reps: '10',
        notes: 'Strict isolation — finisher',
        restSeconds: 45,
      ),
    ],
  );

  // ==========================================
  // 🟢 LEG DAY (Quads + Hams + Glutes + Calves)
  // ==========================================
  static const WorkoutPlan legDay = WorkoutPlan(
    id: 'leg_day',
    name: 'Leg Day',
    subtitle: 'Quads + Hams + Glutes + Calves',
    emoji: '🟢',
    color: 0xFF43A047,
    difficulty: 'Intermediate',
    estimatedMinutes: 60,
    description:
    'Complete leg workout. Squats se start, isolation pe end. Calves mat bhoolna!',
    category: 'legs',
    targetMuscles: ['Quads', 'Hamstrings', 'Glutes', 'Calves'],
    exercises: [
      PlanExercise(
        exerciseId: 'legs_1', // Barbell Squats
        sets: 4,
        reps: '10',
        notes: 'King of legs — go deep',
        restSeconds: 120,
      ),
      PlanExercise(
        exerciseId: 'legs_2', // Leg Press
        sets: 4,
        reps: '12',
        notes: 'Feet high for glutes, low for quads',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'legs_3', // Romanian Deadlift
        sets: 3,
        reps: '10',
        notes: 'Hip hinge — hamstring stretch feel karo',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'legs_4', // Walking Lunges
        sets: 3,
        reps: '12 each',
        notes: 'Big steps — both knees 90°',
        restSeconds: 75,
      ),
      PlanExercise(
        exerciseId: 'legs_6', // Leg Extensions
        sets: 3,
        reps: '15',
        notes: 'Quad isolation — squeeze top pe',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'legs_5', // Leg Curls
        sets: 3,
        reps: '12',
        notes: 'Hamstring isolation — slow negatives',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'legs_7', // Calf Raises
        sets: 4,
        reps: '20',
        notes: 'Full ROM — pause at top',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'legs_10', // Hip Thrusts
        sets: 3,
        reps: '12',
        notes: 'Glute squeeze — 2 sec hold top pe',
        restSeconds: 75,
      ),
    ],
  );

  // ==========================================
  // 🟡 UPPER BODY (Chest + Back + Shoulders + Arms)
  // ==========================================
  static const WorkoutPlan upperBody = WorkoutPlan(
    id: 'upper_body',
    name: 'Upper Body',
    subtitle: 'Chest + Back + Shoulders + Arms',
    emoji: '🟡',
    color: 0xFFFFA726,
    difficulty: 'Intermediate',
    estimatedMinutes: 65,
    description:
    'Complete upper body — sab upper muscles ek din mein. Push-pull supersets bhi kar sakte ho.',
    category: 'upper',
    targetMuscles: [
      'Chest',
      'Back',
      'Shoulders',
      'Biceps',
      'Triceps'
    ],
    exercises: [
      PlanExercise(
        exerciseId: 'chest_1', // Flat Bench Press
        sets: 4,
        reps: '10',
        notes: 'Chest compound — heavy',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'back_3', // Barbell Rows
        sets: 4,
        reps: '10',
        notes: 'Back compound — superset with bench',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'shoulders_2', // Dumbbell Shoulder Press
        sets: 3,
        reps: '12',
        notes: 'Seated strict press',
        restSeconds: 75,
      ),
      PlanExercise(
        exerciseId: 'back_2', // Lat Pulldown
        sets: 3,
        reps: '12',
        notes: 'Wide grip — lats',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'chest_4', // Dumbbell Flyes
        sets: 3,
        reps: '12',
        notes: 'Chest isolation — stretch',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'shoulders_3', // Lateral Raises
        sets: 3,
        reps: '15',
        notes: 'Side delts — light weight',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'biceps_2', // Dumbbell Curls
        sets: 3,
        reps: '12',
        notes: 'Superset with tricep pushdowns',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'triceps_1', // Tricep Pushdowns
        sets: 3,
        reps: '12',
        notes: 'Superset with curls',
        restSeconds: 45,
      ),
    ],
  );

  // ==========================================
  // 🟣 LOWER BODY (Legs + Core)
  // ==========================================
  static const WorkoutPlan lowerBody = WorkoutPlan(
    id: 'lower_body',
    name: 'Lower Body',
    subtitle: 'Legs + Glutes + Core',
    emoji: '🟣',
    color: 0xFF8E24AA,
    difficulty: 'Intermediate',
    estimatedMinutes: 55,
    description:
    'Lower body complete — legs aur core dono. Functional strength builder.',
    category: 'lower',
    targetMuscles: ['Quads', 'Hamstrings', 'Glutes', 'Core', 'Calves'],
    exercises: [
      PlanExercise(
        exerciseId: 'legs_8', // Goblet Squats
        sets: 3,
        reps: '12',
        notes: 'Warm up — deep squat',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'legs_1', // Barbell Squats
        sets: 4,
        reps: '10',
        notes: 'Main compound lift',
        restSeconds: 120,
      ),
      PlanExercise(
        exerciseId: 'legs_9', // Bulgarian Split Squats
        sets: 3,
        reps: '10 each',
        notes: 'Single leg — balance + strength',
        restSeconds: 75,
      ),
      PlanExercise(
        exerciseId: 'legs_3', // Romanian Deadlift
        sets: 3,
        reps: '10',
        notes: 'Hamstring focus',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'legs_10', // Hip Thrusts
        sets: 3,
        reps: '12',
        notes: 'Glute builder — squeeze hard',
        restSeconds: 75,
      ),
      PlanExercise(
        exerciseId: 'legs_7', // Calf Raises
        sets: 4,
        reps: '20',
        notes: 'High reps — full ROM',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'core_1', // Plank
        sets: 3,
        reps: '60 sec',
        notes: 'Core stability — tight body',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'core_3', // Leg Raises
        sets: 3,
        reps: '15',
        notes: 'Lower abs — controlled',
        restSeconds: 45,
      ),
    ],
  );

  // ==========================================
  // 🏆 FULL BODY WORKOUT
  // ==========================================
  static const WorkoutPlan fullBody = WorkoutPlan(
    id: 'full_body',
    name: 'Full Body',
    subtitle: 'Complete All Muscles Workout',
    emoji: '🏆',
    color: 0xFFFF6F00,
    difficulty: 'Intermediate',
    estimatedMinutes: 70,
    description:
    'Ek workout mein sab muscles cover. Beginners ke liye 3x/week ya busy schedule ke liye perfect.',
    category: 'full_body',
    targetMuscles: [
      'Chest',
      'Back',
      'Legs',
      'Shoulders',
      'Biceps',
      'Triceps',
      'Core'
    ],
    exercises: [
      PlanExercise(
        exerciseId: 'legs_1', // Barbell Squats
        sets: 3,
        reps: '10',
        notes: 'Start with biggest muscle group',
        restSeconds: 120,
      ),
      PlanExercise(
        exerciseId: 'chest_1', // Flat Bench Press
        sets: 3,
        reps: '10',
        notes: 'Main chest movement',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'back_3', // Barbell Rows
        sets: 3,
        reps: '10',
        notes: 'Back thickness',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'shoulders_1', // Overhead Press
        sets: 3,
        reps: '10',
        notes: 'Shoulder strength',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'legs_3', // Romanian Deadlift
        sets: 3,
        reps: '10',
        notes: 'Posterior chain',
        restSeconds: 90,
      ),
      PlanExercise(
        exerciseId: 'back_1', // Pull-ups
        sets: 3,
        reps: '8',
        notes: 'Back width — use bands if needed',
        restSeconds: 75,
      ),
      PlanExercise(
        exerciseId: 'chest_6', // Push-ups
        sets: 3,
        reps: '15',
        notes: 'Bodyweight chest finisher',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'shoulders_3', // Lateral Raises
        sets: 3,
        reps: '12',
        notes: 'Side delts width',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'biceps_1', // Barbell Curls
        sets: 3,
        reps: '12',
        notes: 'Quick bicep work',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'triceps_1', // Tricep Pushdowns
        sets: 3,
        reps: '12',
        notes: 'Quick tricep work',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'core_1', // Plank
        sets: 3,
        reps: '45 sec',
        notes: 'Core finisher',
        restSeconds: 30,
      ),
      PlanExercise(
        exerciseId: 'core_7', // Bicycle Crunches
        sets: 3,
        reps: '20',
        notes: 'Abs + obliques finisher',
        restSeconds: 30,
      ),
    ],
  );

  // ==========================================
  // 🏃 CARDIO + CORE
  // ==========================================
  static const WorkoutPlan cardioCore = WorkoutPlan(
    id: 'cardio_core',
    name: 'Cardio & Core',
    subtitle: 'Fat Burn + Core Strength',
    emoji: '🏃',
    color: 0xFFD81B60,
    difficulty: 'Beginner',
    estimatedMinutes: 40,
    description:
    'Cardio exercises + core work. Fat burning aur core strengthening combo. Rest day ke baad perfect.',
    category: 'cardio',
    targetMuscles: ['Heart', 'Abs', 'Obliques', 'Full Body'],
    exercises: [
      PlanExercise(
        exerciseId: 'cardio_5', // Jumping Jacks
        sets: 3,
        reps: '45 sec',
        notes: 'Warm up — get heart rate up',
        restSeconds: 15,
      ),
      PlanExercise(
        exerciseId: 'cardio_6', // High Knees
        sets: 3,
        reps: '30 sec',
        notes: 'Knees hip level — fast',
        restSeconds: 15,
      ),
      PlanExercise(
        exerciseId: 'cardio_4', // Burpees
        sets: 3,
        reps: '10',
        notes: 'Full burpee — push-up included',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'cardio_5', // Mountain Climbers (using core_5)
        sets: 3,
        reps: '30 sec',
        notes: 'Fast pace — core tight',
        restSeconds: 30,
      ),
      PlanExercise(
        exerciseId: 'core_1', // Plank
        sets: 3,
        reps: '45 sec',
        notes: 'Hold tight — no sagging',
        restSeconds: 30,
      ),
      PlanExercise(
        exerciseId: 'core_4', // Russian Twists
        sets: 3,
        reps: '20',
        notes: 'Obliques — rotate torso',
        restSeconds: 30,
      ),
      PlanExercise(
        exerciseId: 'core_7', // Bicycle Crunches
        sets: 3,
        reps: '20',
        notes: 'Slow & controlled',
        restSeconds: 30,
      ),
      PlanExercise(
        exerciseId: 'core_3', // Leg Raises
        sets: 3,
        reps: '12',
        notes: 'Lower abs — back pressed',
        restSeconds: 30,
      ),
      PlanExercise(
        exerciseId: 'core_6', // Dead Bug
        sets: 3,
        reps: '10 each',
        notes: 'Cool down — core stability',
        restSeconds: 30,
      ),
    ],
  );

  // ==========================================
  // 💪 ARMS DAY (Biceps + Triceps + Forearms)
  // ==========================================
  static const WorkoutPlan armsDay = WorkoutPlan(
    id: 'arms_day',
    name: 'Arms Day',
    subtitle: 'Biceps + Triceps Blaster',
    emoji: '💪',
    color: 0xFFFF9800,
    difficulty: 'Beginner',
    estimatedMinutes: 45,
    description:
    'Complete arm workout. Biceps aur triceps supersets for maximum pump. Gun show ready!',
    category: 'arms',
    targetMuscles: ['Biceps', 'Triceps', 'Forearms'],
    exercises: [
      PlanExercise(
        exerciseId: 'biceps_1', // Barbell Curls
        sets: 4,
        reps: '10',
        notes: 'Superset with Skull Crushers',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'triceps_2', // Skull Crushers
        sets: 4,
        reps: '10',
        notes: 'Superset with Barbell Curls',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'biceps_3', // Hammer Curls
        sets: 3,
        reps: '12',
        notes: 'Superset with Rope Pushdowns',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'triceps_7', // Rope Pushdowns
        sets: 3,
        reps: '12',
        notes: 'Superset with Hammer Curls',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'biceps_5', // Incline Dumbbell Curls
        sets: 3,
        reps: '10',
        notes: 'Long head stretch — slow negatives',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'triceps_3', // Overhead Extension
        sets: 3,
        reps: '12',
        notes: 'Long head stretch — overhead',
        restSeconds: 60,
      ),
      PlanExercise(
        exerciseId: 'biceps_6', // Concentration Curls
        sets: 3,
        reps: '12',
        notes: 'Peak contraction — finisher',
        restSeconds: 45,
      ),
      PlanExercise(
        exerciseId: 'triceps_6', // Diamond Push-ups
        sets: 3,
        reps: '15',
        notes: 'Bodyweight finisher — burn!',
        restSeconds: 45,
      ),
    ],
  );

  // ==========================================
  // 📋 GET ALL PLANS
  // ==========================================
  static List<WorkoutPlan> getAllPlans() {
    return [
      pushDay,
      pullDay,
      legDay,
      upperBody,
      lowerBody,
      fullBody,
      cardioCore,
      armsDay,
    ];
  }

  // Get plan by ID
  static WorkoutPlan? getPlanById(String id) {
    try {
      return getAllPlans().firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get plan by category
  static List<WorkoutPlan> getPlansByCategory(String category) {
    return getAllPlans().where((p) => p.category == category).toList();
  }

  // ==========================================
  // 📅 TODAY'S SUGGESTED PLAN
  // ==========================================
  static WorkoutPlan? getTodaysPlan() {
    switch (DateTime.now().weekday) {
      case 1: // Monday
        return pushDay;
      case 2: // Tuesday
        return pullDay;
      case 3: // Wednesday
        return legDay;
      case 4: // Thursday
        return upperBody;
      case 5: // Friday
        return fullBody;
      case 6: // Saturday
        return cardioCore;
      case 7: // Sunday — Rest Day
        return null;
      default:
        return fullBody;
    }
  }

  // Get today's info
  static Map<String, String> getTodayInfo() {
    switch (DateTime.now().weekday) {
      case 1:
        return {
          'day': 'Monday',
          'type': 'Push Day',
          'emoji': '🔴',
          'tag': 'push'
        };
      case 2:
        return {
          'day': 'Tuesday',
          'type': 'Pull Day',
          'emoji': '🔵',
          'tag': 'pull'
        };
      case 3:
        return {
          'day': 'Wednesday',
          'type': 'Leg Day',
          'emoji': '🟢',
          'tag': 'legs'
        };
      case 4:
        return {
          'day': 'Thursday',
          'type': 'Upper Body',
          'emoji': '🟡',
          'tag': 'upper'
        };
      case 5:
        return {
          'day': 'Friday',
          'type': 'Full Body',
          'emoji': '🏆',
          'tag': 'full_body'
        };
      case 6:
        return {
          'day': 'Saturday',
          'type': 'Cardio & Core',
          'emoji': '🏃',
          'tag': 'cardio'
        };
      case 7:
        return {
          'day': 'Sunday',
          'type': 'Rest Day',
          'emoji': '😴',
          'tag': 'rest'
        };
      default:
        return {
          'day': 'Today',
          'type': 'Full Body',
          'emoji': '🏆',
          'tag': 'full_body'
        };
    }
  }

  // ==========================================
  // 📊 WEEK SCHEDULE
  // ==========================================
  static const List<Map<String, String>> weekSchedule = [
    {'day': 'Mon', 'type': 'Push', 'emoji': '🔴'},
    {'day': 'Tue', 'type': 'Pull', 'emoji': '🔵'},
    {'day': 'Wed', 'type': 'Legs', 'emoji': '🟢'},
    {'day': 'Thu', 'type': 'Upper', 'emoji': '🟡'},
    {'day': 'Fri', 'type': 'Full', 'emoji': '🏆'},
    {'day': 'Sat', 'type': 'Cardio', 'emoji': '🏃'},
    {'day': 'Sun', 'type': 'Rest', 'emoji': '😴'},
  ];
}