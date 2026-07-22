#!/usr/bin/env python3
"""
FitGenie — Auto-search for the 22 still-missing exercise GIFs

Instead of guessing folders, this uses the site's own WordPress search
(REST API) to find the current page for each exercise, then scrapes that
page's HTML for the actual current GIF URL — even if the filename itself
changed completely.

Run from your Flutter project ROOT (same place as before):
    pip install requests beautifulsoup4
    python3 auto_search_gifs.py
"""

import os
import re
import time
import requests

OUT_DIR = "assets/exercises"
SEARCH_API = "https://fitnessprogramer.com/wp-json/wp/v2/posts"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
}

# id -> search query (exercise name)
STILL_MISSING = {
    "chest_8": "decline push up",
    "back_1": "pull up",
    "back_10": "hyperextension",
    "legs_1": "barbell squat",
    "legs_2": "leg press",
    "legs_4": "dumbbell lunges",
    "legs_8": "goblet squat",
    "legs_9": "bulgarian split squat",
    "shoulders_1": "barbell overhead press",
    "shoulders_5": "dumbbell rear delt fly",
    "biceps_4": "barbell preacher curl",
    "biceps_5": "incline dumbbell curl",
    "biceps_7": "cable curl",
    "triceps_2": "skull crusher",
    "triceps_6": "diamond push up",
    "core_1": "front plank",
    "core_2": "crunch",
    "core_5": "mountain climber",
    "core_8": "hanging leg raise",
    "cardio_2": "stationary bike",
    "cardio_4": "burpee",
    "cardio_5": "jumping jack",
}

GIF_RE = re.compile(r'https://fitnessprogramer\.com/wp-content/uploads/[^\s"\'<>]+\.gif', re.IGNORECASE)


def find_page_url(query: str):
    try:
        resp = requests.get(
            SEARCH_API,
            params={"search": query, "per_page": 3},
            headers=HEADERS,
            timeout=10,
        )
        if resp.status_code == 200:
            results = resp.json()
            if results:
                return results[0].get("link")
    except requests.RequestException:
        pass
    return None


def find_gif_on_page(page_url: str):
    try:
        resp = requests.get(page_url, headers=HEADERS, timeout=10)
        if resp.status_code == 200:
            matches = GIF_RE.findall(resp.text)
            if matches:
                return matches[0]
    except requests.RequestException:
        pass
    return None


def download_gif(exercise_id: str, gif_url: str) -> bool:
    dest = os.path.join(OUT_DIR, f"{exercise_id}.gif")
    try:
        resp = requests.get(gif_url, headers=HEADERS, timeout=15)
        if resp.status_code == 200 and resp.content[:6] in (b"GIF87a", b"GIF89a"):
            with open(dest, "wb") as f:
                f.write(resp.content)
            print(f"✅ {exercise_id}  ← {gif_url}  ({len(resp.content)//1024} KB)")
            return True
    except requests.RequestException:
        pass
    print(f"❌ {exercise_id}  — download failed from {gif_url}")
    return False


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    failed = []

    for exercise_id, query in STILL_MISSING.items():
        page_url = find_page_url(query)
        if not page_url:
            print(f"❌ {exercise_id}  — no search result for '{query}'")
            failed.append(exercise_id)
            time.sleep(0.4)
            continue

        gif_url = find_gif_on_page(page_url)
        if not gif_url:
            print(f"❌ {exercise_id}  — found page ({page_url}) but no GIF on it")
            failed.append(exercise_id)
            time.sleep(0.4)
            continue

        ok = download_gif(exercise_id, gif_url)
        if not ok:
            failed.append(exercise_id)
        time.sleep(0.4)

    print("\n" + "=" * 50)
    print(f"Recovered: {len(STILL_MISSING) - len(failed)}/{len(STILL_MISSING)}")
    if failed:
        print(f"\n⚠️  {len(failed)} still need manual browser search:")
        for fid in failed:
            print(f"    {fid}  (query was: '{STILL_MISSING[fid]}')")
    else:
        print("🎉 All recovered automatically!")


if __name__ == "__main__":
    main()
