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

## v0.2.2 — 2026-11-03 — Workers gather Scrap
**Summary:** Workers can now gather. Select Workers and tap a scrap pile (amber ring): they walk over, salvage, carry a crate back to the Command Nexus, and deliver it with a "+10" popup. Then they repeat on their own. Piles shrink as they're drained and vanish when empty, and Workers move on to the nearest other pile. Rifle units sent to a pile wait beside it.

**Added:**
- `ResourceNode`: harvestable deposits (600 Scrap per site, set in map data) that shrink as drained and remove themselves when empty.
- `DropOff`: delivery point (the Command Nexus for now).
- `GatherJob`: the worker loop. It picks the next pile the moment one runs dry, fans workers out around a pile or drop-off so they don't queue for one spot, retries from a new angle when blocked, and gives up after 3 failed trips with a red "Can't reach" or "No scrap nearby" message.
- Units can run one job; any direct move order cancels it (and drops the cargo).
- Unit data: `can_gather`, `carry_capacity` (10), `gather_seconds` (2.0).
- Visuals: cargo crate on a delivering worker's back, amber pulse when ordering a gather, floating "+10" income text.

**Tests/checks:**
- New gathering scenarios pass: workers deliver to the economy; the deposit drains; a drained deposit removes itself and the worker retargets; a move order cancels the job; a gather order with only Rifle units is refused.
- An intermittent first-delivery failure was traced to workers crowding one stand point; fixed by fanning out. 8 of 8 repeat runs passed afterwards.
- Emulator testing found that with **All Units** selected, Rifle units piled onto the scrap and boxed the Workers in (no deliveries after 20 s). Fixed two ways: units that can't gather now wait at a staging point 11 m beside the pile, and Workers on a gather job pass through other units, a common RTS convention, so traffic can't stall the economy. The test now sends the whole army and checks that escorts stay out of the harvesting ring.
- Release build on the Pixel 10 Pro AVD: All Units, tap a scrap pile; Workers harvest and deliver (Scrap 300 → 330 with "+10" popups) while Rifle units wait beside the pile.

**Known limitations:**
- Energy has no source yet (Power Reactor comes with construction).
- No Salvage Depot drop-off yet.

## v0.2.3 — 2026-11-03 — Construction foundations
**Summary:** The groundwork for building a base. The four Remnant structures exist as data with original models, placement rules, costs and construction progress. There is no build menu yet, so this release looks the same in play; the menu and workers building come in the next release.

**Added:**
- `BuildingDefinition` data for four buildings:
  - **Salvage Depot**: 120 Scrap; drop-off point.
  - **Power Reactor**: 150 Scrap; +60 Energy per minute.
  - **Fabrication Bay**: 200 Scrap + 50 Energy.
  - **Research Lab**: 150 Scrap + 100 Energy.
- `Structure`: a construction site that rises as it is built (scaffold plus percent label). Health grows with progress, and on completion the building applies its role (drop-off, Energy). It can take damage, be repaired, and be destroyed.
- `ConstructionService`: validates placement with a clear reason (edge of map, blocked ground, overlapping building, too close to a deposit, units in the way, not enough resources), charges the cost atomically, and re-bakes navigation in the background so units path around new buildings (and through the gap when one is destroyed).
- Navigation now bakes from a source group, so buildings anywhere in the scene can carve it.
- `tests/capture_buildings.gd`: a visual-check script that places all four buildings and saves a screenshot.

**Tests/checks:**
- Construction scenarios pass:
  - placement refused on the Nexus, a rock, the map edge, a scrap pile, and units;
  - an unaffordable placement spends nothing;
  - a valid placement charges the exact cost;
  - no overlap is allowed;
  - the navmesh is carved;
  - construction completes with full health;
  - a finished Reactor generates Energy;
  - a finished Depot accepts deliveries;
  - a destroyed building is removed.
- Visual capture checked.

**Known limitations:** No build menu or worker construction yet (next).

## v0.2.4 — 2026-11-03 — Build menu, placement and worker construction
**Summary:** You can now build your base. Select one or more Workers and tap **Build**: a menu lists the Power Reactor, Salvage Depot, Fabrication Bay and Research Lab with their costs and roles. Pick one and a ghost of it appears in the middle of the screen. Pan the map, or tap a spot, to position it; it turns green where it fits and red where it doesn't, with the reason shown. Tap **Build Here**: the cost is paid, the selected Workers walk over and raise it, and "Power Reactor ready" pops up when it's done. A finished Reactor starts adding Energy straight away. Tap an unfinished or damaged building with Workers selected to send them to build or repair it; repair costs a little Scrap as it goes.

**Added:**
- `PlacementController`: center-of-screen ghost placement (pan, or tap to jump), snapped to a half-metre grid, re-checked as it moves, tinted green or red. Build Here is disabled while the spot is invalid.
- `BuildPanel`: large touch-friendly cards with name, cost (red "Need …" when unaffordable) and a one-line role.
- HUD: a Build button (shown when Workers are selected) and a placement bar (Cancel · status · Build Here).
- `BuildJob`: Workers fan out around the site and construct it (more Workers build faster). They repair damaged buildings for Scrap (half the building's Scrap cost for a full repair), and stop with "Need scrap" when it runs out.
- Structures have a tap target, so tapping a building sends Workers to build or repair it. Units that can't help get the red cross instead.

**Tests/checks:**
- New scenarios pass:
  - placement mode refuses a rock and stays open, then places on open ground and charges the cost;
  - cancel exits placement;
  - Workers finish construction and stop;
  - a healthy building needs no work;
  - repair restores full health for a fair Scrap cost;
  - repair stops cleanly when Scrap runs out, never going negative.
- Release build on the Pixel 10 Pro AVD:
  - select a Worker, Build, Power Reactor;
  - red "Ground is blocked" over the Nexus; red "Too close to the edge" at the west boundary;
  - green on open ground; Build Here;
  - Scrap 300 → 150, the Worker builds it (34%… then complete), and Energy rises 100 → 126.

**Known limitations:**
- Buildings can't be selected for info yet.
- There is no way to cancel a construction site.

## v0.2.5 — 2026-11-03 — Energy Wells
**Summary:** The two glowing green Energy Wells are now worth fighting over. A Power Reactor built beside one produces **120** Energy per minute instead of 60. When you place a Reactor near a well, the placement bar says "Energy Well bonus: 120 Energy/min". When the Reactor finishes, a "+120 Energy/min" popup confirms it. You can't build on the well itself ("Build beside the well, not on it").

**Added:**
- `EnergyWell`: a map point with a 10 m bonus radius and a protected pad.
- `energy_well_multiplier` in building data (2.0 for the Power Reactor).
- Structures record their Energy rate on completion.
- Placement shows the bonus; completion popup shows the rate.

**Tests/checks:**
- New scenarios pass: building on a well is refused; there is room beside a well; the bonus rate applies near a well and the base rate away from it; a finished Reactor beside a well produces double.
- Release build installs and launches into a skirmish on the Pixel 10 Pro AVD with no errors. The well-bonus text itself was checked by test, not on screen.

**Known limitations:** The Energy Wells are not yet contested, since there is no enemy (M4).
