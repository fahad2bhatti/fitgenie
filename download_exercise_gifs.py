#!/usr/bin/env python3
"""
FitGenie — Exercise GIF downloader (Option B: local assets)

Run this from your Flutter project ROOT (where pubspec.yaml lives):
    python3 download_exercise_gifs.py

It downloads every exercise GIF and saves it as:
    assets/exercises/<exercise_id>.gif

Requires: pip install requests
"""

import os
import time
import requests

OUT_DIR = "assets/exercises"

# id -> current gifUrl (copied from lib/data/exercise_data.dart)
EXERCISE_GIFS = {
    # Chest
    "chest_1": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Bench-Press.gif",
    "chest_2": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Incline-Dumbbell-Press.gif",
    "chest_3": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Decline-Barbell-Bench-Press.gif",  # BROKEN (confirmed) — check site for current URL
    "chest_4": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Fly.gif",
    "chest_5": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Cable-Crossover.gif",
    "chest_6": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Push-Up.gif",
    "chest_7": "https://fitnessprogramer.com/wp-content/uploads/2021/06/Incline-Push-Up.gif",
    "chest_8": "https://fitnessprogramer.com/wp-content/uploads/2021/06/Decline-Push-Up.gif",  # BROKEN (confirmed)
    "chest_9": "https://fitnessprogramer.com/wp-content/uploads/2021/06/Chest-Dips.gif",
    "chest_10": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Pec-Deck-Fly.gif",

    # Back
    "back_1": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Pull-Up.gif",  # BROKEN (confirmed)
    "back_2": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Lat-Pulldown.gif",
    "back_3": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Bent-Over-Row.gif",
    "back_4": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Row.gif",
    "back_5": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Seated-Cable-Row.gif",
    "back_6": "https://fitnessprogramer.com/wp-content/uploads/2021/02/T-Bar-Row.gif",  # BROKEN (confirmed)
    "back_7": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Deadlift.gif",
    "back_8": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Face-Pull.gif",
    "back_9": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Chin-Up.gif",  # BROKEN (confirmed)
    "back_10": "https://fitnessprogramer.com/wp-content/uploads/2021/02/45-degree-Hyperextension.gif",  # BROKEN (confirmed)

    # Legs
    "legs_1": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Squat.gif",  # BROKEN (confirmed)
    "legs_2": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Leg-Press.gif",  # BROKEN (confirmed)
    "legs_3": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Romanian-Deadlift.gif",
    "legs_4": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Lunges.gif",  # BROKEN (confirmed)
    "legs_5": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Leg-Curl.gif",
    "legs_6": "https://fitnessprogramer.com/wp-content/uploads/2021/02/LEG-EXTENSION.gif",
    "legs_7": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Standing-Calf-Raise.gif",  # BROKEN (confirmed)
    "legs_8": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Goblet-Squat.gif",  # BROKEN (confirmed)
    "legs_9": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Bulgarian-Split-Squat.gif",  # BROKEN (confirmed)
    "legs_10": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Hip-Thrust.gif",

    # Shoulders
    "shoulders_1": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Overhead-Press.gif",  # BROKEN (confirmed)
    "shoulders_2": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Shoulder-Press.gif",
    "shoulders_3": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Lateral-Raise.gif",
    "shoulders_4": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Front-Raise.gif",
    "shoulders_5": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Rear-Delt-Fly.gif",  # BROKEN (confirmed)
    "shoulders_6": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Arnold-Press.gif",
    "shoulders_7": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Upright-Row.gif",
    "shoulders_8": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Shrug.gif",  # BROKEN (confirmed)

    # Biceps
    "biceps_1": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Curl.gif",
    "biceps_2": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Curl.gif",
    "biceps_3": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Hammer-Curl.gif",
    "biceps_4": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Barbell-Preacher-Curl.gif",  # BROKEN (confirmed)
    "biceps_5": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Incline-Dumbbell-Curl.gif",  # BROKEN (confirmed)
    "biceps_6": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Concentration-Curl.gif",
    "biceps_7": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Cable-Curl.gif",  # BROKEN (confirmed)

    # Triceps
    "triceps_1": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Pushdown.gif",
    "triceps_2": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Skull-Crusher.gif",  # BROKEN (confirmed)
    "triceps_3": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Dumbbell-Triceps-Extension.gif",
    "triceps_4": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Close-Grip-Bench-Press.gif",
    "triceps_5": "https://fitnessprogramer.com/wp-content/uploads/2021/06/Triceps-Dips.gif",  # BROKEN (confirmed)
    "triceps_6": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Diamond-Push-Up.gif",  # BROKEN (confirmed)
    "triceps_7": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Rope-Pushdown.gif",  # BROKEN (confirmed)

    # Core (ALL confirmed broken per your report)
    "core_1": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Front-Plank.gif",
    "core_2": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Crunch.gif",
    "core_3": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Lying-Leg-Raise.gif",
    "core_4": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Russian-Twist.gif",
    "core_5": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Mountain-Climber.gif",
    "core_6": "https://fitnessprogramer.com/wp-content/uploads/2021/06/Dead-Bug.gif",
    "core_7": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Bicycle-Crunch.gif",
    "core_8": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Hanging-Leg-Raise.gif",

    # Cardio
    "cardio_1": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Run.gif",
    "cardio_2": "https://fitnessprogramer.com/wp-content/uploads/2022/02/Stationary-Bike-Walk.gif",
    "cardio_3": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Jump-Rope.gif",
    "cardio_4": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Burpee.gif",
    "cardio_5": "https://fitnessprogramer.com/wp-content/uploads/2021/02/Jumping-Jack.gif",
    "cardio_6": "https://fitnessprogramer.com/wp-content/uploads/2021/02/High-Knee-Run.gif",
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
}


def try_download(exercise_id: str, url: str) -> bool:
    dest = os.path.join(OUT_DIR, f"{exercise_id}.gif")
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        if resp.status_code == 200 and resp.content[:6] in (b"GIF87a", b"GIF89a"):
            with open(dest, "wb") as f:
                f.write(resp.content)
            print(f"✅ {exercise_id}  ({len(resp.content)//1024} KB)")
            return True
        else:
            print(f"❌ {exercise_id}  — HTTP {resp.status_code} (dead link)")
            return False
    except requests.RequestException as e:
        print(f"❌ {exercise_id}  — error: {e}")
        return False


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    failed = []

    for i, (exercise_id, url) in enumerate(EXERCISE_GIFS.items(), 1):
        ok = try_download(exercise_id, url)
        if not ok:
            failed.append(exercise_id)
        time.sleep(0.3)  # be polite to the server

    print("\n" + "=" * 50)
    print(f"Done: {len(EXERCISE_GIFS) - len(failed)}/{len(EXERCISE_GIFS)} downloaded")
    if failed:
        print(f"\n⚠️  {len(failed)} still broken — find current URL manually on")
        print("    fitnessprogramer.com and save the GIF as:")
        for fid in failed:
            print(f"    assets/exercises/{fid}.gif")
    else:
        print("🎉 All GIFs downloaded successfully!")


if __name__ == "__main__":
    main()
