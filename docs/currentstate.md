# AFTERMIND — Current State

_Last updated: 2026-11-03 — version 0.2.0_

## Milestone
**M1: Movement and selection — implemented and verified on Android emulators.**
Still open from M0/M1: test on a **physical** device (Moto Edge Fusion 70, S25 Ultra), agree on a baseline device, and check that no units get stuck during real play.

## Engine and setup
- Engine: **Godot 4.7.2.stable.official (ed1daf0bf)**, GDScript. Do not change without approval.
- Renderer: Mobile (Vulkan), with automatic fallback to Compatibility (OpenGL ES 3) when Vulkan is unavailable.
- Reference resolution 1920×1080, `canvas_items` stretch, `expand` aspect, landscape (sensor).
- MSAA 4× (3D), soft directional shadows (4096 shadow map).
- Android toolchain (dev machine): Android SDK at `%LOCALAPPDATA%\Android\Sdk`, JDK 21 (Amazon Corretto), Godot 4.7.2 export templates installed, debug keystore configured in Godot editor settings (not in the repo).
- Source-of-truth docs live in `docs/` (`plan.md`, `instructions.md`, `changelog.md`, this file). Note: `instructions.md` says repository root; they were already in `docs/` and were left there.

## Project layout
- `project.godot` (`application/config/version` is the release version), `export_presets.cfg` (presets `Android arm64-v8a` and `Android Universal`; no credentials).
- `.github/workflows/release.yml`: CI release on every push to `main`. `tools/build_release.sh`: shared build script.
- `scenes/ui/main_menu.tscn`: title screen over a slowly orbiting live view of the battlefield.
- `scenes/skirmish.tscn`: match root with battlefield, units, selection and command controllers, camera rig, HUD, pause menu. `starting_units` lists the starting unit definitions.
- `scenes/world/battlefield.tscn`: environment, sun, and `MapBuilder`.
- `scenes/world/environment.tres`: sky, fog, glow, AgX tonemapping.
- `data/maps/ashfall_basin.tres`: `MapDefinition` data (sites, rocks, ruins).
- `data/units/*.tres`: `UnitDefinition` data (id, name, speed, turn speed, radius).
- `scripts/world/`: `map_definition.gd` (data resource), `map_builder.gd` (spawns map visuals, bakes navigation from the ground with obstacles carved by `NavigationObstacle3D`, and adds obstacle physics bodies on layer 2 for tap detection).
- `scripts/units/`: `unit_definition.gd`, `unit.gd` (navigation agent, avoidance, stuck detection).
- `scripts/control/`: `selection_controller.gd` (screen-space picking and the selection set), `command_controller.gd` (move validation, formation, feedback).
- `scripts/visual/`: `mesh_kit.gd` (shared mesh and material helpers), `map_props.gd`, `unit_visuals.gd`, `command_markers.gd`, `spinner.gd`.
- `scripts/camera/rts_camera.gd`: touch/mouse RTS camera.
- `scripts/ui/`: `main_menu.gd`, `hud.gd`, `pause_menu.gd`, `safe_area_margin.gd`.
- `scripts/skirmish.gd`: wires the match scene together.
- `shaders/ground.gdshader`: procedural ground with tactical grid.
- `ui/theme.tres`: global UI theme (rounded dark panels, cyan accents, large touch targets).
- `tests/smoke_test.gd`: headless smoke and scenario tests.

## Implemented
- Main menu (Start Skirmish, Quit), version label, Android back on the menu quits.
- Skirmish scene showing the map **Ashfall Basin** (120×120, point-symmetric): player and enemy start areas, 6 scrap sites, 2 energy wells, a central AI Core facility, rock formations, ruins, and scattered debris.
- RTS camera: one-finger drag pans (12 px threshold), two-finger pinch zooms and pans, right/middle mouse drag pans, mouse wheel zooms, arrow keys pan. Clamped to the map bounds; pitch changes with zoom.
- HUD: map name chip, pause button (112 px), control hint that fades out, selection summary (count and types), Clear and All Units buttons.
- Units: 3 Workers and 5 Rifle units spawn near the player Nexus. Distinct low-poly silhouettes, shown at 1.4× scale for phone readability.
- Selection: tap a unit to select it (72 px finger-friendly pick radius); hold on a unit to add or remove it; All Units; Clear. Cyan selection rings.
- Move orders: tap ground to move. Units path around obstacles on a baked navmesh, spread into a sunflower formation, and avoid each other. A blocked unit abandons its order after 2 s without progress.
- Feedback: cyan pulse at a valid destination; red cross for a tap on a rock or structure, or off walkable ground.
- Pause menu: Resume, Restart Match, Main Menu. Esc and Android back toggle it; the app going to the background or losing focus auto-pauses.
- Safe-area-aware UI margins.

## Not implemented (by milestone)
- Drag-box selection (hold-to-add is the mobile multi-select).
- M2: economy, workers, construction. M3: production, combat. M4: enemy AI, victory/defeat. M5: AI Evolution, tutorial, audio. M6: release.
- Map props and Nexus models are placeholders: they block movement but are not gameplay entities yet (no health, no interaction).

## How to run, test, and export
- Open in the editor: `godot --path . -e` (or open `project.godot` in Godot 4.7.2).
- Run: `godot --path .`
- Headless import (parse check): `godot --headless --path . --import`
- Tests: `godot --headless --fixed-fps 60 --path . --script res://tests/smoke_test.gd` (prints `SMOKE TEST PASSED`, exit 0). `--fixed-fps` keeps the movement scenarios deterministic and fast.
- Android debug APK: `godot --headless --path . --export-debug "Android arm64-v8a" build/aftermind-debug.apk` (`build/` is git-ignored; use `"Android Universal"` for x86_64 emulators).
- Release APKs (same as CI): set `GODOT`, `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`, then run `bash tools/build_release.sh`. Output goes to `release-assets/` (git-ignored).
- Install: `adb install -r <apk>`, then launch package `dev.imrn.aftermind`.

## Release process (internal testing)
- Every push to `main` triggers `.github/workflows/release.yml`. If import, smoke test, and both exports succeed, it publishes GitHub Release `v<config/version>` with `aftermind-arm64-v8a-vX.Y.Z.apk` and `aftermind-universal-vX.Y.Z.apk`.
- **Bump `config/version` in `project.godot` and add a `## vX.Y.Z — date — title` entry to `docs/changelog.md` on every push.** CI fails on an already-released version or a missing changelog entry.
- versionCode = `X*10000 + Y*100 + Z`, so installs upgrade in place.
- Signing: dedicated release keystore kept outside the repo (on the dev machine at `%USERPROFILE%\.aftermind-signing\`). CI reads it from the repo secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`. Losing the keystore means testers must uninstall before the next update.
- The repo is public, so release APKs are publicly downloadable. They are internal test builds, not store distribution.
- Test devices: Motorola Edge Fusion 70, Samsung Galaxy S25 Ultra.
- Use `godot_console` instead of `godot` on Windows to see output in the terminal.

## Smoke-test checklist (manual, on device)
1. App launches to the main menu in landscape; the UI clears the notch and safe area.
2. Start Skirmish opens Ashfall Basin centered on the player base.
3. One-finger drag pans; pinch zooms; the camera stops at the map edges.
4. The pause button opens the pause menu without moving the camera.
5. Back toggles pause; Resume, Restart Match, and Main Menu all work.
6. Home → reopen: the match comes back paused, not reset or crashed.
7. Main Menu → Quit closes the app.
8. Tap a Worker: ring and "1 SELECTED · Worker ×1". Tap ground: cyan pulse, and the unit walks there.
9. All Units, then tap far ground past a ruin: the group routes around it and gathers without overlapping.
10. With units selected, tap a rock or ruin: red cross, and nobody moves.
11. Hold on a unit to add or remove it; Clear empties the selection; HUD buttons never issue world orders.

## Last verified (2026-11-03, v0.2.0)
- Tests PASSED (smoke plus M1 scenarios: spawn on walkable ground, select all, screen pick, move into a rock rejected, tap on a rock top hits the rock, a group crossing the map past a ruin within 30 s, a freed unit leaving the selection, clear).
- Release APKs built locally with `tools/build_release.sh` (versionCode 200).
- Pixel 10 Pro AVD (x86_64, 2856×1280): launch, menu, skirmish, single select, move, All Units (no order leaks from the button), and the group move around the ruin all verified with screenshots. Pinch zoom still untested (adb can't send multi-touch). No physical-device test yet. No performance measurements.

## Earlier verification (2026-11-02, v0.1.0)
- Headless import: no errors. Smoke test: PASSED.
- Desktop render (Windows, RTX 5060 Ti, Mobile renderer): menu and skirmish captured and visually checked.
- Android debug export: built and signed (~57 MB, arm64-v8a + x86_64).
- Android emulator (x86_64, 2424×1080, Vulkan via GFXStream): steps 1–6 of the checklist passed. Pinch zoom was **not** tested (adb can't send multi-touch). No physical-device test yet. No performance measurements.

## Known issues and risks
- Directional shadow edges show some stair-stepping at mid zoom; tune after testing on a physical device.
- Auto-pause also triggers on window focus loss on desktop, which is intended but can surprise during desktop testing.
- Package name `dev.imrn.aftermind`. The title AFTERMIND is still provisional (trademark not yet checked).
- Uses Godot's built-in default font (bundled with the engine). All 3D visuals are generated from engine primitives, so there are no third-party assets.

## Git
- Branch `main`, remote `origin` = https://github.com/ranababu1/aftermind.git. Pushed after each buildable increment.

## Next recommended task
Install v0.2.0 on the Moto Edge Fusion 70 and the S25 Ultra, run checklist steps 1–11 (including pinch zoom), and report anything that feels off with the controls. Then start M2: Scrap and Energy, a resource HUD, worker gathering from scrap sites, and data-driven costs.
