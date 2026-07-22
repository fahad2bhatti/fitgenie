#!/usr/bin/env python3
"""
FitGenie — Smart retry for broken exercise GIFs

The site (fitnessprogramer.com) keeps the same filename but has moved some
GIFs into different /YYYY/MM/ upload folders. This script takes each broken
filename and tries a range of nearby year/month folders until it finds a
working one.

Run from your Flutter project ROOT (same place as before):
    python3 retry_broken_gifs.py
"""

import os
import time
import requests

OUT_DIR = "assets/exercises"
BASE = "https://fitnessprogramer.com/wp-content/uploads"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
}

# id -> filename only (folder will be brute-forced)
BROKEN = {
    "chest_3": "Decline-Barbell-Bench-Press.gif",
    "chest_8": "Decline-Push-Up.gif",
    "back_1": "Pull-Up.gif",
    "back_6": "T-Bar-Row.gif",
    "back_9": "Chin-Up.gif",
    "back_10": "45-degree-Hyperextension.gif",
    "legs_1": "Barbell-Squat.gif",
    "legs_2": "Leg-Press.gif",
    "legs_4": "Dumbbell-Lunges.gif",
    "legs_7": "Standing-Calf-Raise.gif",
    "legs_8": "Goblet-Squat.gif",
    "legs_9": "Bulgarian-Split-Squat.gif",
    "shoulders_1": "Barbell-Overhead-Press.gif",
    "shoulders_5": "Dumbbell-Rear-Delt-Fly.gif",
    "shoulders_8": "Dumbbell-Shrug.gif",
    "biceps_4": "Barbell-Preacher-Curl.gif",
    "biceps_5": "Incline-Dumbbell-Curl.gif",
    "biceps_7": "Cable-Curl.gif",
    "triceps_2": "Skull-Crusher.gif",
    "triceps_5": "Triceps-Dips.gif",
    "triceps_6": "Diamond-Push-Up.gif",
    "triceps_7": "Rope-Pushdown.gif",
    "core_1": "Front-Plank.gif",
    "core_2": "Crunch.gif",
    "core_5": "Mountain-Climber.gif",
    "core_6": "Dead-Bug.gif",
    "core_8": "Hanging-Leg-Raise.gif",
    "cardio_1": "Run.gif",
    "cardio_2": "Stationary-Bike-Walk.gif",
    "cardio_3": "Jump-Rope.gif",
    "cardio_4": "Burpee.gif",
    "cardio_5": "Jumping-Jack.gif",
    "cardio_6": "High-Knee-Run.gif",
}

# Candidate year/month folders to try, in order of likelihood
CANDIDATE_FOLDERS = []
for year in ("2021", "2022", "2020", "2023"):
    for month in ("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"):
        CANDIDATE_FOLDERS.append(f"{year}/{month}")


def try_download(exercise_id: str, filename: str) -> bool:
    dest = os.path.join(OUT_DIR, f"{exercise_id}.gif")

    for folder in CANDIDATE_FOLDERS:
        url = f"{BASE}/{folder}/{filename}"
        try:
            resp = requests.get(url, headers=HEADERS, timeout=8)
            if resp.status_code == 200 and resp.content[:6] in (b"GIF87a", b"GIF89a"):
                with open(dest, "wb") as f:
                    f.write(resp.content)
                print(f"✅ {exercise_id}  found at {folder}/  ({len(resp.content)//1024} KB)")
                return True
        except requests.RequestException:
            pass

    print(f"❌ {exercise_id}  — no match found in any tried folder (filename: {filename})")
    return False


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    still_failed = []

    print(f"Trying {len(CANDIDATE_FOLDERS)} folder variations per exercise, {len(BROKEN)} exercises...\n")

    for exercise_id, filename in BROKEN.items():
        ok = try_download(exercise_id, filename)
        if not ok:
            still_failed.append((exercise_id, filename))
        time.sleep(0.15)

    print("\n" + "=" * 50)
    print(f"Recovered: {len(BROKEN) - len(still_failed)}/{len(BROKEN)}")
    if still_failed:
        print(f"\n⚠️  {len(still_failed)} truly need manual search (filename changed, not just folder):")
        for fid, fname in still_failed:
            print(f"    {fid}  (was: {fname})")
        print("\n   Google: \"exercise name\" site:fitnessprogramer.com")
        print("   Right-click the GIF → Save As → assets/exercises/<id>.gif")
    else:
        print("🎉 All recovered!")


if __name__ == "__main__":
    main()
