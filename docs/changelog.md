# Changelog

## 2026-11-02 — M0 project foundation
**Summary:** Created the Godot 4.7.2 project with main menu, skirmish scene, RTS camera, pause flow, UI theme, Android export preset, and a headless smoke test. Built a stylized low-poly map, Ashfall Basin, from engine primitives.

**Reason:** M0 in `plan.md` §13 (project foundation, main menu, skirmish scene, camera pan/zoom, Android export).

**Key files/systems:** `project.godot`, `export_presets.cfg`, `scenes/`, `scripts/camera/rts_camera.gd`, `scripts/world/map_definition.gd`, `scripts/world/map_builder.gd`, `scripts/visual/map_props.gd`, `shaders/ground.gdshader`, `ui/theme.tres`, `data/maps/ashfall_basin.tres`, `tests/smoke_test.gd`.

**Visual direction:** dusk palette, AgX tonemapping, glow on restrained emissive accents (cyan for the Remnants, red for the Collective, violet for the AI Core, green for energy), faceted low-poly props, a subtle two-level tactical grid that fades with distance, and a single-draw-call debris field.

**Tests/checks:**
- Headless import: no errors.
- Smoke test: PASSED.
- Desktop render capture: checked visually.
- Android debug APK: exported and signed.
- Android emulator (x86_64, Vulkan): launch, menu, skirmish, drag-pan, pause button, back toggle, and background/resume auto-pause all verified with screenshots.

**Known limitations:**
- Not yet tested on a physical device; pinch zoom untested.
- No performance measurements.
- Map props have no collision or navigation yet (planned for M1).
- Some shadow aliasing at mid zoom.

## v0.1.0 — 2026-11-02 — First internal test build
**Summary:** First versioned internal release: the M0 foundation (main menu, the Ashfall Basin skirmish map, touch camera with drag-pan and pinch zoom, pause menu with Android back and background auto-pause), plus an automated release pipeline.

**Added:**
- `.github/workflows/release.yml`: every push to `main` imports the project, runs the smoke test, exports release-signed APKs, and publishes GitHub Release `v<version>` with notes from this changelog. It fails if the version was already released.
- `tools/build_release.sh`: one build script for CI and local use. It stamps versionCode (`X.Y.Z` → `X*10000+Y*100+Z`) and versionName from `project.godot`.
- Two export presets: `Android arm64-v8a` (most modern phones) and `Android Universal` (armeabi-v7a, arm64-v8a, x86, x86_64).

**Changed:** Android package name is now `dev.imrn.aftermind` (previously the provisional `com.aftermind.game`). Builds are signed with a dedicated release key instead of the debug key.

**Tests/checks:**
- Local run of `tools/build_release.sh`: smoke test passed and both APKs exported (arm64-v8a 26 MB, universal 105 MB).
- `aapt`: `dev.imrn.aftermind`, versionCode 100, versionName 0.1.0.
- `apksigner`: signed with the release certificate.
- Not yet installed on a physical device; the release-signed build was not run on the emulator (no emulator was available).

**Known limitations:** Same as the M0 entry. If an earlier debug build is installed, uninstall it first (different package and signature).

## v0.2.0 — 2026-11-03 — Units, selection and movement (M1)
**Summary:** The first playable units. You start with 3 Workers and 5 Rifle units near your Command Nexus. Tap a unit to select it, hold on a unit to add it to (or remove it from) the selection, tap **All Units** to select everything, and tap the ground to move. Units path around rocks, ruins and structures, spread into a loose group at the destination, and avoid bumping into each other.

**Added:**
- Unit data resources (`data/units/worker.tres`, `rifle.tres`) and `Unit` (`scripts/units/unit.gd`): navigation-agent movement with local avoidance and stuck detection, so a blocked unit gives up its order instead of pushing forever.
- `SelectionController`: finger-friendly screen-space picking (72 px radius), plus select only, toggle, select all and clear. Freed units leave the selection safely.
- `CommandController`: validates move targets. A tap on a rock or structure is rejected with a red cross; a valid move shows a cyan pulse and spreads units in a sunflower formation.
- Camera now reports taps and long presses (one finger, no drag); drags still pan and pinch still zooms.
- HUD: selection summary (count and unit types), Clear and All Units buttons, updated control hint.
- Original low-poly unit models: amber Workers with a hard hat, tank and salvage claw; armored Rifle units with a visor and rifle.
- Navigation mesh baked at map load, with obstacles carved out by `NavigationObstacle3D` so rock tops never become walkable.
- Scenario tests: units spawn on walkable ground, select all, screen picking, a rejected move into a rock, a group crossing the map past a ruin, a freed unit leaving the selection, and clear.

**Changed:**
- `MeshKit` holds the shared mesh and material helpers used by map props, units and markers.
- Tests run with `--fixed-fps 60` for deterministic simulation.
- CI actions updated (checkout v7, setup-java v6, cache v6), clearing the Node 20 deprecation warnings.

**Tests/checks:**
- Smoke and scenario tests pass locally.
- `tools/build_release.sh` builds both release APKs (versionCode 200).
- On-device results are in `docs/currentstate.md`.

**Known limitations:**
- No drag-box selection (hold-to-add is the multi-select method on mobile).
- Units have no combat, health or gathering yet (M2/M3).
- Units at the back of a group can stop up to about 2 m outside their exact formation slot when crowded.

## v0.2.1 — 2026-11-03 — Scrap and Energy stockpile
**Summary:** The match now tracks two resources, Scrap and Energy, shown at the top of the screen. You start with 300 Scrap and 100 Energy. Nothing spends or earns them yet; worker gathering and building costs come next.

**Added:**
- `Economy` (`scripts/economy/economy.gd`): one faction's stockpile. Spending is atomic (a multi-resource cost is paid in full or not at all), balances can never go negative, and negative costs or income are rejected.
- HUD resource bar: one chip per resource with a colored marker and a text label, so it never relies on color alone. The amount pulses on change and flashes red when a purchase can't be afforded.

**Tests/checks:**
- Economy unit tests pass: exact deduction, refused overspend, atomic multi-resource refusal, negative cost and income rejected.
- All earlier scenarios still pass.
- HUD layout checked in a desktop render.

**Known limitations:** No income or costs are wired up yet.
