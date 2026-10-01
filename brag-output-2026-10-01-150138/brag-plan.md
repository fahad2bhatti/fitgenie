# Brag Plan: FitGenie

## What is this app?
FitGenie is an offline-first Flutter fitness companion that brings AI coaching, guided workouts, nutrition and meal scanning, exercise education, and live activity tracking into one dark, neon-accented mobile app.

## The angle
**Your whole fitness day, coached in one pocket.** Start with a glance at the live dashboard, ask the FitGenie AI Coach what to do next, then move through a real plan and log food without leaving the app. The video should feel like a premium app-store launch film: confident, useful, and specific to FitGenie's Hinglish-first coaching and Pakistani/Asian nutrition context.

The product claim stays grounded in the repository: “Your personal pocket trainer that tracks workouts, nutrition, steps, and gives AI coaching in Hinglish.” Do not invent outcome percentages, streaks, calorie totals, testimonials, or user names.

## Hook (first 2-3 seconds)
Open on FitGenie's actual logo forming over the app's deep navy background, then snap into a fast dashboard glimpse as the line **“Your personal pocket trainer.”** settles on screen. A purple progress ring and neon glass card establish the product immediately; this is more distinctive than a generic fitness montage.

## Key moments (the middle)
- **AI Coach:** Show the real “FitGenie AI Coach” chat surface with the green **“Online • Ready to help”** state and a sanitized prompt such as **“Bhai kal chest ka workout bana de”**. Reveal the quick chips **Workout**, **Diet Plan**, and **Motivate** one by one.
- **Workout system:** Swipe from the Workout hub's **Quick Start / AI powered workout** card into the actual **Workout Plans** card row: **Push Day**, **Pull Day**, and **Full Body Workout**. Briefly feature an exercise card using an existing `assets/exercises/*.gif`, with real labels such as **Flat Bench Press**, **Chest**, **Tempo: 2-1-2**, and **Full Guide**.
- **Nutrition + movement:** Use the real Nutrition screen structure—**Today's Summary**, macro progress, water controls, Breakfast/Lunch/Dinner/Snacks—then cut to the Meal Scanner's camera frame and its post-analysis layout with food name, kcal, protein, carbs, fats, and the **Add to calories** action. A final dashboard beat lands on **Step Counter**, with the ring and live/Google Fit or Pedometer source label visible.

## Outro / punchline
End on the logo and the line **“Train smarter. Eat clearer. Keep moving.”** followed by **“FitGenie — Your AI-powered fitness companion.”** Keep the final claim descriptive, not outcome-based. Use the logo asset rather than redrawing it.

## User flow worth showing
Dashboard glance → open AI Coach and request a workout → move into Workout Plans / Quick Start → scan or log a meal into Nutrition → return to activity tracking. The centerpiece is the working-app sequence, not a collection of abstract feature cards.

## Tone
- Preset: **app-store**
- Creative direction: **polished modern fitness app launch; premium dark UI, energetic but restrained**
- Interpretation: Smooth slides, crisp phone UI crops, short readable feature labels, and restrained interface clicks; let the actual screens and micro-interactions carry the proof.

## Format: landscape — 1920x1080
Use a centered phone-sized UI composition with generous dark negative space so the app remains legible in a launch post. Preserve a safe area around the phone for captions and the final logo.

## Duration: 20 seconds

## Visual identity (from the project)
- Background: `#060B18` (with splash variation `#0A0A0F` → `#0D1117`)
- Card surfaces: `#0E1424` and `#0B1020`
- Primary accent: `#6B6BFF` / light `#8B8BFF`
- Secondary accent: `#39D1C4`
- Warm accent: `#FF7A6A`
- Text: `#FFFFFF`; muted text: `#98A0B3`
- Display font: Inter, via `GoogleFonts.interTextTheme`
- Body font: Inter
- Strongest visual element: deep navy glassmorphism cards with purple progress rings, teal/warm status accents, rounded 16–20px corners, and the animated FitGenie logo
- Brand assets: `assets/images/fitgenie_logo.png`, `assets/icon/app_icon.PNG`, and existing preview captures under `assets/images/preview/`
- Exercise assets: 65 local GIF demos under `assets/exercises/`, grouped by chest, back, legs, shoulders, arms, core, and cardio

## Product and navigation notes for the composition
- Entry flow is splash → language selection → auth/onboarding → `ShellScreen`.
- The authenticated shell has five bottom-nav destinations: **Home**, **Nutrition**, **Workout**, **Progress**, and **Profile**.
- Home exposes Quick Actions for **Workouts**, **Nutrition**, **AI Coach**, **Exercises**, **Challenges**, and **Scan Meal**.
- AI Coach is an in-app route/overlay from Home and uses a dark chat surface, purple psychology avatar, green online indicator, quick-action chips, and a bottom text composer.
- Nutrition is the `CaloriesScreen`, with date navigation, summary/macros, water tracking, meal sections, saved meals, food search, and scanner entry.
- Workout is the `WorkoutScreen`, with AI Quick Start, muscle-group cards, pre-built plans, Full Body, My Library, and recent workouts.
- Avoid showing sensitive or personal data from existing preview screenshots. Replace names, timestamps, live counts, and any account-specific values with neutral demo values or UI placeholders.

## Share copy (draft)
Meet FitGenie: an AI-powered pocket trainer for workouts, Hinglish coaching, Pakistani-food nutrition tracking, meal scanning, and live steps—all in one focused app.

## Audio direction
- Role: warm, rhythmic professional bed with a subtle lift into the logo payoff
- Music: `happy-beats-business-moves-vol-12-by-ende-dot-app.mp3`, steady and clean, suitable for the polished/app-store tone
- Music treatment: start at 0.0s around 0.30–0.35 volume, duck slightly under the hook copy and UI interaction sounds, then let the final logo breathe with a short fade-out after 19.5s
- Music cue guidance: bundled preset read; estimated tempo 109.96 BPM. Strong cue targets: 8.74s for the workout reveal, 13.11s for the nutrition/scanner reveal, 17.47–18.56s for the closing dashboard/logo lift. Beat grid windows are approximately every 0.54–0.56s; use every other beat for readable card/text entrances.
- Audio-reactive treatment: subtle; let the phone glow, progress ring, and purple logo halo breathe slightly with the music RMS/bass. No waveform or equalizer graphics.
- SFX posture: sparse-to-moderate, motion-matched, professional restraint
- Audio-coupled moments: logo assemble, AI prompt send, quick-chip arrivals, workout-plan card slide, scanner result landing, and final logo resolve
- Restraint rule: no loud gym impacts, no voiceover, no synthetic claims, and no sound effect on every text element; the product UI and music should remain clear.

## Storyboard

### Scene 1 — Pocket trainer hook — 0.0–2.5s
Start on the real FitGenie logo asset against `#060B18`, using a soft draw/shine reveal that echoes the existing splash and welcome-intro animation. The logo settles into a compact phone frame, then the dashboard flashes in behind it. Text: **“Your personal pocket trainer.”** Use the actual dark background and purple halo, not a generic gym image.

Sequential/interaction: yes — logo forms, then the dashboard phone locks into place; the headline appears only after the logo settles and holds for the read.
Audio intent: one soft logo shimmer over the first musical phrase, then a clean UI lock-in.
Audio-coupled idea: a restrained `drop`/soft interface accent on the logo settle.
Music: warm, clean opening from vol. 12.
Transition mood: smooth slide → Scene 2

### Scene 2 — Ask FitGenie — 2.5–5.5s
The centered phone expands into the real AI Coach screen. Show the **FitGenie AI Coach** header, green **“Online • Ready to help”**, and a sanitized user message: **“Bhai kal chest ka workout bana de”**. The assistant response begins typing or appears as a concise personalized workout suggestion. Along the bottom, reveal **Workout**, **Diet Plan**, and **Motivate** chips in sequence.

Sequential/interaction: yes — simulate one tap/send, then reveal the three quick chips left to right; keep each chip readable for at least 0.8s.
Audio intent: make the AI feel immediate and helpful, not futuristic or ominous.
Audio-coupled idea: one soft tap for send; low-volume key ticks only if text is visibly typed.
Transition mood: clean wipe → Scene 3

### Scene 3 — Turn advice into training — 5.5–9.0s
Cut to the real Workout hub. Show the **Workout** title, **Choose your training style 💪**, the **Quick Start / AI powered workout** card, then slide the **Workout Plans** row into view with **Push Day**, **Pull Day**, and **Full Body Workout** cards. Land on the plan's real stats language: exercise count, total sets, estimated minutes, and target muscles—no invented values.

Sequential/interaction: yes — plan cards arrive one by one; a visible tap selects **Push Day** or **Full Body Workout** and opens the plan detail.
Audio intent: a slightly brighter rhythmic lift that makes the training choice feel actionable.
Audio-coupled idea: card-slide accents on the first and final plan card only; align the main plan reveal near 8.74s.
Transition mood: energetic horizontal slide → Scene 4

### Scene 4 — Form, not guesswork — 9.0–12.5s
Use the actual exercise-library / muscle-group visual language: purple category chips, dark rounded cards, and one local animated GIF demo. Show **Flat Bench Press** with real metadata such as **Chest**, **Triceps**, **Shoulders**, **Tempo: 2-1-2**, and **Full Guide**. A quick swipe moves to a second exercise card or an exercise detail with **Primary Muscles**, **Equipment**, and **How To**.

Sequential/interaction: yes — one exercise card lands, its metadata chips appear in a readable stagger, then a simulated swipe advances the library.
Audio intent: tactile and precise; emphasize guidance and clarity.
Audio-coupled idea: a soft swipe/card-slide cue; no cue for every metadata chip.
Transition mood: soft crossfade → Scene 5

### Scene 5 — Eat clearer, keep moving — 12.5–17.5s
Split the phone moment into two real UI beats. First, show Nutrition with **Today's Summary**, a macro progress treatment, water tracker, and meal sections **Breakfast**, **Lunch**, **Dinner**, **Snacks**. Then tap **Scan Meal** to reveal the real Meal Scanner frame with **Camera**, **Gallery**, and **Scan Barcode (packaged food)**. Resolve into the analysis-card layout with a food name, quantity, kcal, protein/carbs/fats, and the **Add** action; use fictional demo food values if a live result is needed.

Sequential/interaction: yes — summary → scan action → scanner frame → analysis result; the analysis card must hold long enough to read the macro labels.
Audio intent: a satisfying “under control” turn from food capture to useful nutrition data.
Audio-coupled idea: one camera/tap click, one soft result landing; align the scanner/result reveal near 13.11s.
Transition mood: clean vertical wipe → Scene 6

### Scene 6 — One app, every day — 17.5–20.0s
Return to the dashboard. Let the **Step Counter** ring and source/status label sit beside the daily-goal cards, then pull the phone back to reveal the complete FitGenie frame. Text appears in two holds: **“Train smarter. Eat clearer. Keep moving.”** then **“FitGenie — Your AI-powered fitness companion.”** Finish on `assets/images/fitgenie_logo.png` and the app name.

Sequential/interaction: yes — step ring settles first, tagline second, logo lockup last; keep the final line fully visible through the end.
Audio intent: confident, warm payoff rather than a hard sports-ad hit.
Audio-coupled idea: a gentle success accent on the ring/logo resolve; use the strong cue around 17.47–18.56s and fade music after 19.5s.
Music: warm final lift, then short fade.
Transition mood: soft resolve → end

**Music mood for this video:** upbeat, clean, polished
**Audio summary:** A steady business-beats bed supports a real UI journey from logo to AI coach to workouts to nutrition and steps, with only a few tactile UI accents and a restrained branded finish.
