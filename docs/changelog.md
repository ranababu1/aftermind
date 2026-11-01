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
