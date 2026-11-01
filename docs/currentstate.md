# AFTERMIND — Current State

_Last updated: 2026-11-02_

## Milestone
**M0: Project foundation — implemented, verified on an Android emulator only.**
M0 exit criteria still open: install/launch on a **physical** Android device, and agreeing on a baseline device.

## Engine and setup
- Engine: **Godot 4.7.2.stable.official (ed1daf0bf)**, GDScript. Do not change without approval.
- Renderer: Mobile (Vulkan), with automatic fallback to Compatibility (OpenGL ES 3) when Vulkan is unavailable.
- Reference resolution 1920×1080, `canvas_items` stretch, `expand` aspect, landscape (sensor).
- MSAA 4× (3D), soft directional shadows (4096 shadow map).
- Android toolchain (dev machine): Android SDK at `%LOCALAPPDATA%\Android\Sdk`, JDK 21 (Amazon Corretto), Godot 4.7.2 export templates installed, debug keystore configured in Godot editor settings (not in the repo).
- Source-of-truth docs live in `docs/` (`plan.md`, `instructions.md`, `changelog.md`, this file). Note: `instructions.md` says repository root; they were already in `docs/` and were left there.

## Project layout
- `project.godot`, `export_presets.cfg` (Android preset; holds no credentials).
- `scenes/ui/main_menu.tscn`: title screen over a slowly orbiting live view of the battlefield.
- `scenes/skirmish.tscn`: match root with battlefield, camera rig, HUD, pause menu.
- `scenes/world/battlefield.tscn`: environment, sun, and `MapBuilder`.
- `scenes/world/environment.tres`: sky, fog, glow, AgX tonemapping.
- `data/maps/ashfall_basin.tres`: `MapDefinition` data (sites, rocks, ruins).
- `scripts/world/`: `map_definition.gd` (data resource), `map_builder.gd` (spawns the map visuals).
- `scripts/visual/`: `map_props.gd` (procedural placeholder meshes), `spinner.gd`.
- `scripts/camera/rts_camera.gd`: touch/mouse RTS camera.
- `scripts/ui/`: `main_menu.gd`, `hud.gd`, `pause_menu.gd`, `safe_area_margin.gd`.
- `scripts/skirmish.gd`: wires the match scene together.
- `shaders/ground.gdshader`: procedural ground with tactical grid.
- `ui/theme.tres`: global UI theme (rounded dark panels, cyan accents, large touch targets).
- `tests/smoke_test.gd`: headless smoke test.

## Implemented
- Main menu (Start Skirmish, Quit), version label, Android back on the menu quits.
- Skirmish scene showing the map **Ashfall Basin** (120×120, point-symmetric): player and enemy start areas, 6 scrap sites, 2 energy wells, a central AI Core facility, rock formations, ruins, and scattered debris.
- RTS camera: one-finger drag pans (12 px threshold), two-finger pinch zooms and pans, right/middle mouse drag pans, mouse wheel zooms, arrow keys pan. Clamped to the map bounds; pitch changes with zoom.
- HUD: map name chip, pause button (112 px), control hint that fades out.
- Pause menu: Resume, Restart Match, Main Menu. Esc and Android back toggle it; the app going to the background or losing focus auto-pauses.
- Safe-area-aware UI margins.

## Not implemented (by milestone)
- M1: units, selection, move orders, navigation.
- M2: economy, workers, construction. M3: production, combat. M4: enemy AI, victory/defeat. M5: AI Evolution, tutorial, audio. M6: release.
- Map props are **visual placeholders only**: no collision or navigation yet. The Nexus models are decoration, not entities.

## How to run, test, and export
- Open in the editor: `godot --path . -e` (or open `project.godot` in Godot 4.7.2).
- Run: `godot --path .`
- Headless import (parse check): `godot --headless --path . --import`
- Smoke test: `godot --headless --path . --script res://tests/smoke_test.gd` (prints `SMOKE TEST PASSED`, exit 0).
- Android debug APK: `godot --headless --path . --export-debug "Android" build/aftermind-debug.apk` (`build/` is git-ignored).
- Install: `adb install -r build/aftermind-debug.apk`, then launch package `com.aftermind.game`.
- Use `godot_console` instead of `godot` on Windows to see output in the terminal.

## Smoke-test checklist (manual, on device)
1. App launches to the main menu in landscape; the UI clears the notch and safe area.
2. Start Skirmish opens Ashfall Basin centered on the player base.
3. One-finger drag pans; pinch zooms; the camera stops at the map edges.
4. The pause button opens the pause menu without moving the camera.
5. Back toggles pause; Resume, Restart Match, and Main Menu all work.
6. Home → reopen: the match comes back paused, not reset or crashed.
7. Main Menu → Quit closes the app.

## Last verified (2026-11-02)
- Headless import: no errors. Smoke test: PASSED.
- Desktop render (Windows, RTX 5060 Ti, Mobile renderer): menu and skirmish captured and visually checked.
- Android debug export: built and signed (~57 MB, arm64-v8a + x86_64).
- Android emulator (x86_64, 2424×1080, Vulkan via GFXStream): steps 1–6 of the checklist passed. Pinch zoom was **not** tested (adb can't send multi-touch). No physical-device test yet. No performance measurements.

## Known issues and risks
- Directional shadow edges show some stair-stepping at mid zoom; tune after testing on a physical device.
- Auto-pause also triggers on window focus loss on desktop, which is intended but can surprise during desktop testing.
- The package name `com.aftermind.game` is provisional (title not yet cleared for trademark).
- Uses Godot's built-in default font (bundled with the engine). All 3D visuals are generated from engine primitives, so there are no third-party assets.

## Git
- Branch `main`, remote `origin` = https://github.com/ranababu1/aftermind.git. Pushed after each buildable increment.

## Next recommended task
Install the debug APK on a physical Android device, record it as the baseline device, and run the smoke-test checklist (including pinch zoom). Then start M1: add collision for map obstacles, bake a NavigationRegion3D, and add a first selectable unit with tap-to-select and tap-to-move.
