# AFTERMIND — Current State

_Last updated: 2026-11-03 — version 0.3.3_

## Milestone
**M3: Production and combat — in progress (v0.3.1: building selection; v0.3.2: production queue; v0.3.3: combat).** M2 (economy and construction) is complete.
- M2 exit criteria, all covered by tests:
  - resources cannot go negative;
  - invalid placement is rejected with a clear reason;
  - workers recover from depleted deposits and invalid targets.
- Still open from M0/M1: test on a **physical** device (Moto Edge Fusion 70, S25 Ultra), agree on a baseline device, and measure performance.

## Engine and setup
- Engine: **Godot 4.7.2.stable.official (ed1daf0bf)**, GDScript. Do not change without approval.
- Renderer: Mobile (Vulkan), with automatic fallback to Compatibility (OpenGL ES 3) when Vulkan is unavailable.
- Reference resolution 1920×1080, `canvas_items` stretch, `expand` aspect, landscape (sensor).
- MSAA 4× (3D), soft directional shadows (4096 shadow map). Navigation cell size 0.5 m (`project.godot` `[navigation]`).
- Android toolchain (dev machine): Android SDK at `%LOCALAPPDATA%\Android\Sdk`, JDK 21 (Amazon Corretto), Godot 4.7.2 export templates, AVDs `Pixel10Pro` and `Pixel_10a`.
- Source-of-truth docs live in `docs/` (`plan.md`, `instructions.md`, `changelog.md`, this file). Note: `instructions.md` says repository root; they were already in `docs/` and were left there.

## Project layout
- `project.godot` (`application/config/version` is the release version), `export_presets.cfg` (presets `Android arm64-v8a` and `Android Universal`; no credentials).
- `.github/workflows/release.yml`: CI release on every push to `main`. `tools/build_release.sh`: shared build script.
- `scenes/ui/main_menu.tscn`: title screen over a slowly orbiting view of the battlefield.
- `scenes/skirmish.tscn`: match root, with:
  - player economy, structures, units;
  - selection, command, construction and placement controllers;
  - camera rig, HUD, pause menu.
  - Data lists: `starting_units`, `buildable`.
- `scenes/world/battlefield.tscn`: environment, sun, `MapBuilder`.
- `data/maps/ashfall_basin.tres`: map layout (sites, rocks, ruins, Scrap per site).
- `data/units/*.tres`: `UnitDefinition` (speed, radius, gathering stats).
- `data/buildings/*.tres`: `BuildingDefinition` (cost, health, build time, footprint, drop-off, Energy rate, Energy Well multiplier).
- `scripts/world/`: `map_definition.gd`, `map_builder.gd`.
  - Visuals; Scrap deposits; Energy Wells.
  - Navigation baked from the `navigation_source` group, with obstacles carved by `NavigationObstacle3D`; background re-bake when buildings change.
  - Obstacle tap bodies on physics layer 2.
- `scripts/economy/`: `economy.gd` (atomic stockpile), `resource_node.gd`, `drop_off.gd`, `energy_well.gd`.
- `scripts/buildings/`:
  - `building_definition.gd`;
  - `production_queue.gd` (unit orders, exit-point recovery);
  - `structure.gd` (construction, health, repair, damage, roles; tap body on layer 3);
  - `construction_service.gd` (placement rules, cost, spawn, re-bake);
  - `placement_controller.gd` (ghost placement mode).
- `scripts/units/`: `unit_definition.gd`, `unit.gd` (movement, avoidance, stuck detection, one job at a time, health, idle engagement, guard posts), `gather_job.gd`, `build_job.gd`, `attack_job.gd`.
- `scripts/combat/combat.gd`: shared targeting rules (alive, faction, range, nearest enemy).
- `scripts/control/`: `selection_controller.gd`, `command_controller.gd` (move, gather, build orders and feedback).
- `scripts/visual/`: `mesh_kit.gd`, `map_props.gd`, `unit_visuals.gd`, `building_visuals.gd`, `command_markers.gd`, `floating_text.gd`, `spinner.gd`.
- `scripts/ui/`: `main_menu.gd`, `hud.gd`, `resource_chip.gd`, `build_panel.gd`, `pause_menu.gd`, `safe_area_margin.gd`.
- `tests/smoke_test.gd`: headless smoke and scenario tests. `tests/capture_buildings.gd`: visual-check screenshot.

## Implemented
- **Menus and flow:**
  - Main menu (Start Skirmish, Quit) and a pause menu (Resume, Restart Match, Main Menu).
  - Android back toggles pause; backgrounding auto-pauses.
  - UI respects the safe area.
- **Map:** Ashfall Basin (120×120, point-symmetric):
  - start areas, 6 Scrap deposits (600 each), 2 Energy Wells, a central AI Core site;
  - rocks, ruins, debris.
- **Camera:** one-finger drag pans, pinch zooms; mouse and arrow keys on desktop; clamped to the map.
- **Units:** 3 Workers and 5 Rifle units.
  - Tap to select, hold to add or remove, All Units, Clear.
  - Tap ground to move: navmesh pathing, avoidance, sunflower formation, stuck detection.
- **Economy:**
  - Scrap and Energy with atomic spending; start at 300 / 100.
  - HUD resource chips (marker plus label) pulse on change and flash red on a shortage.
- **Gathering:** select Workers and tap a Scrap pile. They harvest 10 per trip and deliver to the nearest drop-off (Nexus or Salvage Depot) with a "+10" popup.
  - Piles shrink and vanish; Workers move to the next pile.
  - Busy Workers pass through crowds; units that can't gather wait beside the pile.
  - Clear "No scrap nearby" and "Can't reach" messages.
- **Construction:**
  - Build button (Workers selected) opens a build menu with costs, red when unaffordable.
  - Placement ghost at screen center: pan or tap to move it; green or red with the reason; Build Here or Cancel.
  - Cost is paid at placement; Workers raise the building (scaffold plus percent label) and announce "… ready".
  - Tap a building with Workers selected to build or repair it; repair costs Scrap and stops at "Need scrap".
- **Buildings:**
  - Salvage Depot: drop-off.
  - Power Reactor: 60 Energy/min, or 120 beside an Energy Well.
  - Fabrication Bay: produces Rifle Units through a 5-order queue (paid on queue, full refund on cancel). Finished units wait for a clear exit ("Exit blocked") and leave once one frees up.
  - Research Lab: placeholder role until M5.
  - All can take damage and be destroyed; navigation updates either way.
- **Combat:**
  - Units and buildings have health.
  - Idle armed units engage enemies in sight; tap an enemy with units selected to attack it.
  - Tracers, impact sparks, death bursts; health bars over damaged or selected units and damaged buildings.
  - Four Collective Sentinels guard the AI Core and return to their posts.
- **Building selection:** tap a building for a ring and an info chip (progress or health bar, role). Cancel Build removes a construction site and refunds 75%.

## Not implemented
- Drag-box selection (hold-to-add is the mobile multi-select).
- M3: remaining unit roster (Heavy, Scout Drone, Siege Walker), attack-move, rally points.
- M4: enemy AI, victory and defeat.
- M5: AI Core and Evolution, tutorial, audio.
- M6: release.
- The Command Nexus models are placeholders: the player Nexus accepts deliveries but is not yet a damageable entity.

## How to run, test, and export
- Open in the editor: `godot --path . -e` (Godot 4.7.2). Run: `godot --path .`
- After adding a script with a new `class_name`, run `godot --headless --path . --import` once so the class cache knows it.
- Tests: `godot --headless --fixed-fps 60 --path . --script res://tests/smoke_test.gd` (prints `SMOKE TEST PASSED`, exit 0; about 1–2 minutes). `--fixed-fps` keeps the simulation deterministic. On failure the gathering check prints per-worker diagnostics.
- Building visual check (needs a window): `godot --path . --resolution 1920x1080 --script res://tests/capture_buildings.gd -- <out.png>`.
- Release APKs (same as CI): set `GODOT`, `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`, then run `bash tools/build_release.sh` (outputs to `release-assets/`).
- Emulator: `emulator -avd Pixel10Pro`, then `adb install -r release-assets/aftermind-universal-vX.Y.Z.apk`, then launch `dev.imrn.aftermind`. Godot exports restart the adb server; wait for the device to show `device` again before installing.
- On Windows use `godot_console` to see output in the terminal.

## Release process (internal testing)
- Every push to `main` triggers `.github/workflows/release.yml`. If import, tests, and both exports succeed, it publishes GitHub Release `v<config/version>` with `aftermind-arm64-v8a-vX.Y.Z.apk` and `aftermind-universal-vX.Y.Z.apk`.
- **Bump `config/version` in `project.godot` and add a `## vX.Y.Z — date — title` entry to `docs/changelog.md` on every push.** CI fails on an already-released version or a missing changelog entry.
- versionCode = `X*10000 + Y*100 + Z`, so installs upgrade in place.
- Signing: dedicated release keystore outside the repo (`%USERPROFILE%\.aftermind-signing\`); CI uses the repo secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`. Back the keystore up; losing it forces testers to uninstall.
- The repo is public, so release APKs are publicly downloadable (internal test builds, not store distribution).
- Test devices: Motorola Edge Fusion 70, Samsung Galaxy S25 Ultra.

## Smoke-test checklist (manual, on device)
1. App launches to the main menu in landscape; the UI clears the notch and safe area.
2. Start Skirmish opens Ashfall Basin at the player base; Scrap 300 and Energy 100 are shown.
3. One-finger drag pans; pinch zooms; the camera stops at the map edges.
4. The pause button opens the pause menu without moving the camera; Back toggles it; Resume, Restart Match, and Main Menu work.
5. Home → reopen: the match comes back paused, intact.
6. Tap a Worker: ring and "1 SELECTED · Worker ×1"; tap ground: cyan pulse and it walks there.
7. All Units, then tap far ground past a ruin: the group routes around it and gathers without overlap.
8. With units selected, tap a rock or ruin: red cross, nobody moves.
9. All Units, then tap a Scrap pile: Workers harvest and "+10" pops at the Nexus while Rifle units wait beside the pile; Scrap rises.
10. Select a Worker → Build → Power Reactor:
    - red over the Nexus and at the map edge, each with a reason;
    - green on open ground;
    - beside an Energy Well it says "Energy Well bonus: 120 Energy/min".
11. Build Here: the cost is deducted, the Worker builds it (percent label), "Power Reactor ready" appears, and Energy starts rising.
12. Try to build with too little Scrap: the card says "Need …", the bar says "Not enough resources", and the Scrap chip flashes red on attempts.
13. HUD buttons never issue world orders; Cancel leaves placement mode.
14. With nothing selected, tap a building: ring and info chip. On a construction site, Cancel Build refunds 75% and removes it.
15. Select a finished Fabrication Bay: Rifle Unit (50 Scrap) queues with a progress bar, Cancel Last refunds, and the unit walks out of the bay.
16. All Units, then tap a red Sentinel at the center: a red ring appears, Rifle Units close in and fire tracers, health bars drop, and the Sentinels burst on death. Survivors engage the rest automatically.

## Last verified (2026-11-03, v0.2.5 / v0.3.0)
- Tests PASSED, covering:
  - movement and selection;
  - economy atomicity;
  - gathering with the full army (escorts stay out of the harvest ring);
  - depletion retargeting and job cancel;
  - placement rules, exact costs and navmesh carving;
  - Workers constructing and repairing, and repair stopping without going negative;
  - Reactor Energy, Depot drop-off, and destruction;
  - Energy Well rules and bonus.
- Pixel 10 Pro AVD (release builds, 2856×1280): checklist steps 1, 2, 4, 6–11 and 13 checked across v0.2.0–v0.2.5 with screenshots.
- Not yet: pinch zoom (adb can't send multi-touch), any physical-device run, and performance measurements.

## Known issues and risks
- Shadow edges show some stair-stepping at mid zoom.
- Gathering had an intermittent stall (workers crowding one stand point), fixed by fanning out; 8 of 8 repeat runs passed since. Watch for regressions in CI.
- A unit standing on a spot when a building's navmesh carve lands can end up off-mesh; placement refuses spots with units on them, but a unit could walk in during the async bake.
- Auto-pause triggers on desktop window focus loss (intended).
- The title AFTERMIND is provisional (trademark not yet checked). All visuals are original primitives; the font is Godot's bundled default.

## Git
- Branch `main`, remote `origin` = https://github.com/ranababu1/aftermind.git. Each push is a versioned release.

## Next recommended task
1. Install the latest release on both phones and run checklist steps 1–16 (especially pinch zoom and how placement feels on a real screen).
2. Continue M3 in small releases:
   - ~~building selection with an info panel~~ (done in v0.3.1);
   - ~~Fabrication Bay production queue~~ (done in v0.3.2);
   - ~~unit health, targeting, damage, death, health bars and combat feedback~~ (done in v0.3.3);
   - remaining roster: Heavy, Scout Drone, Siege Walker (Fabrication Bay production);
   - attack-move and a rally point for produced units.
