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
