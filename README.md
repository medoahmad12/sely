# SELY KIDS — سيلي كيدز

Interactive, offline learning app for children aged **3–5**: Arabic letters, numbers, simple addition/subtraction, English letters & words, colors, shapes, and five educational games. Built with Flutter (Android-first, iOS-ready structure). No ads, no accounts, no internet permission, no data collection.

> Screenshots: `docs/screenshots/` *(placeholders — add your own after the first run)*
> ![Home](docs/screenshots/home.png) ![Letter](docs/screenshots/letter.png) ![Trace](docs/screenshots/trace.png)

## Features
- **SELY WORLD** home with 7 worlds, greeting from the mascot SELY (drawn in code, original character).
- **Arabic letters** (10 complete demo letters): listen, picture words, letter shapes (start/middle/end), find-the-letter, **real finger tracing**.
- **Numbers 0–10**: tap-to-count, find the number, tracing. **Count** game.
- **Addition / subtraction**: objects first, numbers later; falls back to objects after a mistake.
- **English World**: 10 letter+word lessons with spoken pronunciation and "Which one is Apple?".
- **Colors (9) and shapes (6)**: learn + play.
- **Games** (reusable over letters, numbers, colors, shapes, English): Find it, Match, Memory, Trace, Count.
- **Stars & rewards**: stars from answers/lessons/categories; cosmetic hats and backgrounds unlock by stars earned (never purchases).
- **Adaptive difficulty** (3 levels per skill) and gentle, non-punishing feedback.
- **Parent area** (hold the lock 3 s): child info, progress per subject, play time, last activity, sound/music/language settings, daily limit with a rest screen, reset progress.
- **Offline first**: all content, images (emoji + vector painters) and sounds are local. Progress saved locally.
- **RTL/LTR** with Arabic + English UI strings, responsive for phones and tablets (portrait).

## Requirements
- Flutter 3.27+ (stable), Dart 3.5+
- Android Studio or VS Code with the Flutter plugin, Android SDK, JDK 17

## Run locally
```bash
flutter pub get
flutter run
```
Run checks: `flutter analyze` and `flutter test`.

## Build the APK
```bash
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```
The release build is signed with the *debug* key so it installs anywhere. For Google Play create your own keystore and signing config in `android/app/build.gradle.kts` (never commit the keystore).

## Upload to GitHub and build with GitHub Actions
```bash
git init && git add . && git commit -m "SELY KIDS"
git branch -M main
git remote add origin https://github.com/<you>/sely-kids.git
git push -u origin main
```
Every push runs `.github/workflows/build-apk.yml` (checkout → Java 17 → Flutter → `pub get` → `analyze` → `test` → `build apk --release`).
Open the **Actions** tab → latest run → **Artifacts → sely-kids-apk** to download `app-release.apk`. You can also start it manually with *Run workflow*.

## Project structure
```
lib/
  main.dart, app.dart, app_state.dart, app_scope.dart
  core/        theme (colors, tokens), l10n (UI strings ar/en), utils
  models/      content models, child profile
  services/    content_repository, audio_service, progress_controller, adaptive_service, ai/ (future AI hooks)
  storage/     StorageService (SharedPreferences / in-memory)
  widgets/     SELY mascot, tiles, buttons, effects, parent gate
  features/    splash, setup, home, arabic, math, english, colors_shapes, games, trace, lesson, rewards, parent
assets/
  data/        arabic_letters.json, numbers.json, english.json, colors.json, shapes.json, math.json
  audio/       ar/ en/ ui/ rewards/ music/
  images/      sely_icon.png
tool/          generate_data.py, generate_audio.py
```

## Add content
**New Arabic letter** — add an entry to `assets/data/arabic_letters.json` (or edit `tool/generate_data.py` and run `python3 tool/generate_data.py`):
`id`, `glyph`, `name`, `words` (emoji + word, starting with the letter), `forms` (initial/medial/final with example word), and `trace` (`strokes`: lists of `[x,y]` points in a 0–1 box, `smooth: true` for curves; `dots`: `[x,y]` points to touch). It appears automatically in the Arabic world, games and progress percentages.

**New lesson** — numbers/English/colors/shapes work the same way: add an item to the matching JSON file. For a new *type* of lesson create a `LessonFlowScreen` with a list of `LessonStep`s (see `features/arabic/letter_lesson.dart`).

**New sound** — drop a file named after the key into `assets/audio/<folder>/<key>.mp3|wav|ogg|m4a`. Keys: letter name `ar_letter_<id>`, letter word `ar_word_<id>_<index>`, number `ar_num_<n>`, game items `item_<id>`, prompts `prompt_<id>`, UI phrases `cheer_1..4`, `try_again`, `home_greet`, `lesson_done` (folder `ui`), English `en_letter_<L>`, `en_word_<id>`. Anything missing falls back to the device's local text-to-speech (no paid services). Sound effects live in `assets/audio/ui` and `assets/audio/rewards`, music in `assets/audio/music`; regenerate the synthesized ones with `python3 tool/generate_audio.py`.

**New game** — a game only needs `GameItem`s (`features/games/game_items.dart`). Add a `ContentKind` value + builder to give all existing games a new content pool, or write a new screen that consumes `buildGameItems(kind, …)` and register it in `games_hub.dart`.

**Change colors** — `lib/core/theme/app_colors.dart` (and background gradients in `features/rewards/reward_catalog.dart`).

**Change SELY** — `lib/widgets/sely_mascot.dart` (a `CustomPainter`; accessories for rewards are in `_drawHat`). The launcher icon is `android/app/src/main/res/mipmap-*/ic_launcher.png`; the splash image is `assets/images/sely_icon.png`.

## Design notes / decisions
- Pictures are emoji rendered by the device (no network, no licensing issues). Replace with your own vector art by changing the `visual`/`picture` builders.
- Digits are shown as 0–9. Arabic letters/words use the device's Arabic font; add a custom font in `pubspec.yaml` if you want a specific style.
- Voice: recorded files first, then local TTS. Arabic TTS depends on the device having an Arabic voice installed.
- Daily limit: when reached, a rest screen covers the app until a parent holds the lock for 3 s.
- Extension points for later: multiple children, cloud sync, parent dashboard, premium, AI tutor (`services/ai/`), voice recording, iOS (`flutter create --platforms=ios .`).

## Not included in v1 (intentionally, so nothing fake appears in the UI)
Remaining Arabic letters (content is data-driven: add them to the JSON), the Arabic↔English comparison activity, professional voice recordings, in-app purchases, accounts.
