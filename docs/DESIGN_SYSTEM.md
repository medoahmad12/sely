# SELY KIDS — Design System

Modern Kids UI: round shapes, huge touch targets, soft shadows, few words, lots of motion-with-meaning.
Code: `lib/core/theme/` (colors, tokens, theme) and `lib/widgets/`.

## Colors (`AppColors`)
| Role | Color | Hex |
|---|---|---|
| Primary | Sky blue | `#1E9BFF` (dark `#1366D6`) |
| Ink / titles | Navy | `#2B2F8F`, text `#263159` |
| Secondary | Orange | `#FF9F1C` |
| Secondary | Green (success) | `#3FBF4A` |
| Secondary | Pink | `#FF4F8B` |
| Secondary | Purple | `#7B5CF0` |
| Accent | Sunny yellow (stars) | `#FFD43B` |
| Background | Sky gradient | `#6FD0FF → #E6F7FF` (changeable by rewards) |

Rule: one saturated color per card, white surfaces, never more than ~4 hues per screen.
Color is never the only signal: answers also use shape/size/position/sound.

## Typography
System font (Roboto + the device's Arabic font). Titles 26 sp w900, prompts 22 sp w800, letters/digits 70–170 sp w900.
All sizes are multiplied by `context.u` (screen shortest side / 390, clamped 0.8–1.7) so tablets get bigger UI.
To use a custom Arabic font, add it under `fonts:` in `pubspec.yaml` and set `fontFamily` in `AppTheme`.

## Spacing (`AppSpacing`)
4 / 8 / 16 / 24 / 32 dp (× `u`). Screen padding 16, gap between tiles 12–16.

## Border radius (`AppRadius`)
Cards 28, buttons 36, chips 20. Tiles are rounded squares or circles.

## Shadows (`AppShadows`)
`card`: soft 12 px blur, 5 px down. `soft(color)`: colored glow 14 px blur for world tiles.

## Buttons
- `RoundIconButton` 60 dp circle (back, clear).
- `BigActionButton` / `FilledButton` ≥ 64 dp high, pill shape, icon + short label.
- `Pressable` wraps every touch target: scales to 0.93 on press and plays the tap sound.
- Parent area is only reachable through `HoldToUnlock` (hold 3 s).

## Cards
`OptionTile`: white rounded square, 5 px colored border for state (selected orange, correct green, hint yellow), wrong = faded + shake. World tiles: colored gradient card with emoji, label, progress bar.

## Animation principles
1. Motion explains: pop-in on entrance (`PopIn`), shake on a wrong try, star burst on success, pulse for hints.
2. Short: 150–450 ms, ease-out/back; looping animations only for SELY (blink/bob) and hints.
3. Never punish: wrong answers shake gently, SELY says "حاول مرة ثانية", and after two mistakes the right answer pulses.
4. Cheap: `RepaintBoundary` around SELY, no shaders beyond one gradient, no images in animations.
