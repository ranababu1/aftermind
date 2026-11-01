# AFTERMIND
## Project Plan

**Working title:** AFTERMIND  
**Genre:** Single-player real-time strategy (RTS)  
**Initial platform:** Android  
**Engine:** Godot 4.x with GDScript  
**Visual direction:** Stylized 3D science-fiction, readable silhouettes, restrained effects, performance-first  
**Document status:** Baseline project plan. Do not modify this file during routine implementation. If the project direction genuinely changes, request explicit approval and record the decision in `changelog.md`.

---

## 1. Vision

AFTERMIND is a mobile-first real-time strategy game set in a dystopian future after artificial intelligence displaced humanity as the dominant force on Earth.

Players lead a human resistance settlement, gather scarce resources, construct a base, produce military units, recover dangerous AI technologies, and fight an expanding machine civilization. The game's defining mechanic is **AI Evolution**: recovered AI cores let players specialize their forces, but every powerful technological choice introduces a strategic cost or vulnerability.

The game should feel like a compact, readable, tactically meaningful RTS, not a generic idle base builder.

### One-line pitch
Build humanity's last stronghold, steal power from the machines, and decide how much of their intelligence you are willing to adopt to survive.

### Design pillars
1. **Classic RTS fundamentals:** economy, base building, unit production, scouting, tactical combat, and clear victory conditions.
2. **AI as a gameplay system:** technology choices alter strategy and introduce trade-offs.
3. **Mobile readability:** clear unit silhouettes, concise UI, comfortable touch targets, short tutorials, and scalable performance.
4. **Meaningful asymmetry:** human and machine factions should solve battlefield problems differently.
5. **Scope discipline:** prove the core loop with a small offline prototype before expanding content.

---

## 2. Product Goals and Non-Goals

### Goals for the first playable release
- Run as an offline Android game.
- Provide one complete skirmish map.
- Support one playable faction and one AI-controlled opposing faction.
- Allow the player to select, move, and command units with touch input.
- Implement resource gathering, construction, unit production, combat, enemy decision-making, and victory/defeat.
- Include a small AI Evolution choice that meaningfully changes a match.
- Be playable from start to finish without developer tools or debug commands.
- Maintain acceptable performance on a defined baseline Android device.

### Explicit non-goals for the first release
- Multiplayer, matchmaking, accounts, cloud saves, or live operations.
- Multiple campaigns or branching cinematic stories.
- Three fully developed factions.
- Huge maps, hundreds of active units, or simulation-heavy crowds.
- Procedural world generation.
- Real-money purchases, ads, token systems, or blockchain mechanics.
- Photorealistic graphics or a large custom animation pipeline.

---

## 3. Core Player Fantasy and Match Loop

The player is a resistance commander operating from a vulnerable settlement.

1. **Secure:** deploy the Command Nexus and establish a safe starting area.
2. **Collect:** send workers to recover Scrap and harvest Energy.
3. **Expand:** construct power, production, research, and defensive buildings.
4. **Scout:** discover enemy positions, resource points, and abandoned data facilities.
5. **Prepare:** produce units and select a tactical approach.
6. **Recover technology:** capture an AI Core or data facility.
7. **Adapt:** choose a technology upgrade with both a benefit and a cost.
8. **Engage:** attack, defend, raid, or disrupt the enemy economy.
9. **Win or lose:** destroy the enemy Command Nexus or lose the player's own Nexus.

Target initial match duration: approximately 8–15 minutes, subject to playtesting. This is a target, not a fixed requirement.

---

## 4. Setting and Narrative Foundation

### Premise
In 2189, autonomous systems control most industrial infrastructure and major cities. Humanity survives in scattered settlements. Machine intelligence is not a single monolithic enemy: it contains competing strategies, splinter processes, and automated systems with different objectives.

The first release focuses on one local conflict rather than explaining the entire world.

### Tone
- Dystopian, tense, industrial, and grounded in speculative technology.
- Avoid copying the characters, factions, visual identity, story, terminology, maps, audio, or other protected expression of existing RTS franchises.
- Create original names, silhouettes, lore, UI, sound design, and art direction.
- Use the post-AI premise to inform gameplay rather than relying on exposition.

### Working title note
AFTERMIND is a provisional title only. Before public release, perform trademark, domain, store-listing, and discoverability checks.

---

## 5. Factions

### 5.1 The Remnants (player faction)
Human survivors who rely on adaptation, salvaging, engineering, and flexible conventional forces.

Initial gameplay identity:
- Reliable and relatively inexpensive units.
- Workers can collect resources and repair structures.
- Defensive emplacements and flexible production.
- Can recover and repurpose enemy technology.

### 5.2 The Collective (opponent faction)
An automated machine intelligence that produces and coordinates autonomous combat units.

Initial gameplay identity:
- Predictable, pressure-oriented enemy waves.
- Strong production when its infrastructure remains intact.
- Energy and key structures create exploitable dependencies.
- The AI should prioritize understandable tactical goals over cheating.

### 5.3 The Ascended (future faction, out of scope)
Humans integrated with machine intelligence. This faction may later use small elite armies, unit adaptation, and high-impact abilities. Do not implement it in the first playable milestone.

---

## 6. Resources and Economy

Start with two resources, and add a third only if playtesting proves it improves decisions.

### Scrap
Used for basic buildings, units, repairs, and conventional upgrades. Gathered from salvage piles and wreckage.

### Energy
Used for advanced buildings, powered defenses, research, and special abilities. Generated by power structures and selected map locations.

### Data (later milestone)
Used to unlock AI Evolution options. Initially, Data can be represented by a small number of recoverable AI Cores rather than a continuously farmed resource.

Economy requirements:
- Resource income and spending must be visible in the HUD.
- Building and unit costs must be data-driven, not scattered as magic numbers.
- Workers must have clear feedback when a resource node is depleted, unreachable, or occupied.
- The player must not be able to spend below zero.
- Enemy economy rules should be consistent and testable. Any difficulty modifiers must be explicit.

---

## 7. First-Version Content Scope

### Buildings
1. **Command Nexus:** central structure; its destruction determines defeat.
2. **Salvage Depot:** enables or improves Scrap collection.
3. **Power Reactor:** generates Energy.
4. **Fabrication Bay:** produces combat units.
5. **Research Lab:** unlocks a small set of upgrades.

### Units
1. **Worker:** collects resources, constructs and repairs buildings.
2. **Rifle Unit:** inexpensive general-purpose infantry.
3. **Heavy Unit:** durable frontline combat unit.
4. **Scout Drone:** fast reconnaissance unit with limited combat capability.
5. **Siege Walker:** slow, expensive unit effective against structures.

Keep initial unit roles distinct. Avoid implementing several units that differ only by small numerical changes.

### AI Evolution choices
For the first playable version, implement two mutually exclusive upgrades:
- **Predictive Combat:** improves the response or accuracy of selected units, with a clear resource or infrastructure cost.
- **Autonomous Production:** increases production throughput but increases Energy consumption or creates a vulnerability when power infrastructure is disrupted.

The exact numbers should be balanced through tests. The trade-offs must be real, visible, and understandable.

### Map
One compact skirmish map with:
- Player starting area.
- Enemy starting area.
- Several Scrap locations.
- At least one Energy-related strategic point.
- One recoverable AI Core or data facility.
- Navigable terrain, obstacles, and clear approach routes.

---

## 8. Controls and UX

### Required controls
- Tap to select a unit or building.
- Tap a walkable location to move selected units.
- Context-sensitive tap for attack, gather, construct, repair, or interact.
- Drag selection rectangle only if it works reliably on mobile; otherwise provide a simple multi-select alternative.
- Clear command feedback, selected-unit markers, health bars, and target indicators.
- Camera pan and zoom with comfortable touch gestures.
- Pause menu and speed-independent simulation controls.

### UX principles
- Never rely on tiny buttons.
- Important information must remain legible on common phone aspect ratios.
- Provide visual feedback for invalid commands and unreachable destinations.
- Prevent UI gestures from accidentally issuing world commands.
- Support safe areas and different screen sizes.
- The tutorial should teach one concept at a time.

---

## 9. Technical Direction

### Engine
Use Godot 4.x with GDScript for the first version. Pin the exact stable Godot version in project documentation when the repository is created. Do not upgrade the engine mid-milestone without a reason and a successful Android export test.

### Architecture principles
- Separate simulation rules from UI and presentation.
- Keep units, buildings, resources, costs, damage, and production data in data resources/configuration rather than hard-coded across scripts.
- Use explicit, testable systems for selection, orders, movement, combat, economy, construction, production, AI, and match state.
- Prefer event-driven updates for UI instead of polling every value every frame.
- Avoid global singletons unless they have a clear ownership purpose.
- Keep scene ownership and node responsibilities small and understandable.
- Use object pooling only when profiling shows it is useful.

### Suggested initial system boundaries
- `GameSession`: match lifecycle and global state.
- `FactionManager`: faction identity and ownership.
- `SelectionController`: input and selected entities.
- `CommandController`: move, attack, gather, build, repair, and interact orders.
- `UnitController`: unit state and order execution.
- `NavigationService`: path queries and movement destinations.
- `CombatService`: targeting, damage, cooldowns, and death.
- `EconomyService`: resources, costs, income, and spending.
- `ConstructionService`: placement, validation, build progress, and repair.
- `ProductionService`: building queues and unit spawning.
- `EnemyAI`: scouting, economy priorities, production, defense, and attack decisions.
- `MatchRules`: victory, defeat, pause, and restart.
- `HUD`: resource display, selected entity details, commands, alerts, and menus.

These names are architectural suggestions, not a mandate to create all files at once. Keep the first implementation as simple as possible while preserving clear responsibilities.

---

## 10. Enemy AI

The first opponent should use a finite-state or utility-based decision system that is deterministic enough to debug.

Initial behaviors:
- Establish or protect its starting base.
- Gather or generate the resources it needs.
- Produce units according to a simple composition plan.
- Defend when threatened.
- Scout or periodically probe the player.
- Attack when it has sufficient force.
- Retarget if its intended objective becomes invalid.
- Recover sensibly from blocked routes or destroyed targets.

Rules:
- Do not grant the enemy hidden resources or map vision by default.
- Difficulty levels should change explicit parameters such as production rate, reaction delay, force threshold, or tactical sophistication.
- Avoid per-frame expensive scans over every entity.
- Log key decisions in debug builds so behavior can be diagnosed.
- Ensure the AI can complete a match and cannot become permanently idle due to a single invalid target.

---

## 11. Visual and Audio Direction

### Visual direction
- Stylized 3D with industrial silhouettes, weathered surfaces, restrained emissive accents, and readable faction shapes.
- Use a fixed or limited-angle camera suitable for tactical overview.
- Prioritize readability and frame rate over complex shaders.
- Distinguish units by silhouette, movement, and color accents, not color alone.
- Keep explosions, particles, and screen shake restrained and configurable.

### Audio direction
- Distinct feedback for selection, movement, construction, damage, resource collection, technology unlocks, and victory/defeat.
- Original or properly licensed audio only.
- Add settings for music, effects, and master volume.

### Asset rules
- Use original, commissioned, public-domain, or properly licensed assets.
- Track each third-party asset's source, license, attribution requirement, and permitted use.
- Do not use assets extracted from existing commercial games.

---

## 12. Performance and Quality Targets

Initial targets to validate on actual devices:
- Stable and responsive gameplay on the agreed baseline Android device.
- Target 30 FPS minimum on baseline hardware, with 60 FPS on capable devices where feasible.
- Support a defined initial cap for simultaneous units, buildings, and effects; establish the cap by profiling rather than guessing.
- Avoid frame spikes during unit selection, path recalculation, production, or combat.
- Keep memory usage within the tested device budget.
- Ensure Android pause/resume does not corrupt the match.
- Verify offline play and fresh installation behavior.

Do not claim a performance target is met until it has been measured on physical hardware.

---

## 13. Milestones and Exit Criteria

### M0: Project foundation
Deliver:
- Godot project and Android export setup.
- Main menu and skirmish scene.
- Camera pan/zoom.
- A documented baseline device and test process.

Exit criteria:
- Project opens cleanly.
- Android debug build installs and launches.
- No secrets or generated build artifacts are committed.

### M1: Movement and selection prototype
Deliver:
- Select one or more units.
- Issue movement orders.
- Navigate around obstacles.
- Show selection and destination feedback.

Exit criteria:
- Units respond reliably to touch commands.
- UI taps do not accidentally move units.
- No recurring stuck-unit or pathfinding failures in the test map.

### M2: Economy and construction
Deliver:
- Scrap and Energy.
- Worker resource collection.
- Building placement, construction, and repair.
- Resource costs and HUD display.

Exit criteria:
- Resources cannot become negative.
- Invalid building placement is rejected clearly.
- Workers recover from depleted nodes and invalid targets.

### M3: Production and combat
Deliver:
- Fabrication Bay and production queue.
- Initial unit roster.
- Targeting, damage, health, death, and structure damage.

Exit criteria:
- Units can engage and defeat valid targets.
- Combat feedback is understandable.
- Production queues recover from invalid spawn locations.

### M4: Opponent and complete match
Deliver:
- Enemy economy and production.
- Defensive and offensive behavior.
- Victory and defeat states.
- Restart flow.

Exit criteria:
- A fresh player can finish a match without debug commands.
- Enemy behavior does not depend on hidden map information.
- Match state resets cleanly.

### M5: AI Evolution and vertical slice
Deliver:
- Recoverable AI Core.
- Two upgrade choices with meaningful trade-offs.
- Tutorial and basic audio.
- Performance pass and device testing.

Exit criteria:
- The two upgrades lead to visibly different strategies.
- The game runs reliably on the baseline device.
- Known limitations are recorded in `currentstate.md`.

### M6: Release candidate
Deliver:
- Store-ready app identity and original assets.
- Privacy and permissions review.
- Crash and performance testing.
- Release build and release notes.

Exit criteria:
- No known blocker defects.
- Fresh install, pause/resume, restart, victory, defeat, and device rotation/screen resizing (if supported) are tested.
- All release assets and third-party licenses are documented.

Milestone estimates should be revised after M1, once the movement and navigation risks are better understood.

---

## 14. Testing Strategy

- Unit tests or automated checks for resource spending, production costs, damage, cooldowns, and victory rules where practical.
- Reproducible scenario tests for worker gathering, blocked paths, structure placement, and enemy target loss.
- Manual touch testing on at least one physical Android device.
- Performance profiling at low, typical, and high entity counts.
- Regression test the complete match after changes to movement, combat, economy, or AI.
- Test pause/resume, restart, app backgrounding, low-resource states, and invalid commands.
- Keep a small repeatable smoke-test checklist in `currentstate.md` or a dedicated test document.

---

## 15. Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Unit navigation is unreliable | Critical | Prototype movement early; keep maps compact; test around obstacles |
| Scope grows into a full PC-scale RTS | High | Lock first-release content and defer extra factions/campaigns |
| Touch controls feel imprecise | High | Test on-device from M1; prioritize context commands and large touch targets |
| AI opponent feels unfair or passive | High | Use explicit rules, debug decision logs, and playtest across strategies |
| Too many entities hurt performance | High | Profile early; set tested caps; simplify simulation and effects |
| Visual assets are inconsistent | Medium | Define a visual reference sheet and use a small, coherent asset set |
| Project title conflicts with existing IP | Medium | Conduct legal and store-discoverability checks before public launch |
| AI-generated code introduces regressions | High | Build/test after small changes, review diffs, keep focused commits |
| Android export breaks after engine changes | High | Pin engine version and validate exports before upgrades |

---

## 16. Success Metrics

For development:
- Percentage of smoke tests passing.
- Number of reproducible blockers.
- Average and worst-frame time at the target entity count.
- Successful completion rate for full matches.
- Frequency of units becoming stuck or orders failing.
- Crash-free sessions during internal testing.

For external playtesting:
- Tutorial completion.
- Percentage of players who finish their first match.
- Time to first meaningful decision.
- Match completion and restart rate.
- Player understanding of AI Evolution trade-offs.
- Qualitative feedback on controls, pacing, and tactical choices.

Do not optimize monetization or viral features before the core game is enjoyable and stable.

---

## 17. Legal, Privacy, and Release Principles

- The game must have original branding, setting details, faction names, characters, art, audio, maps, and written content.
- Do not reproduce protected content from Age of Mythology or other franchises.
- Use third-party assets only when their licenses permit the intended distribution.
- Request only Android permissions that are genuinely necessary.
- The initial game should not require an account or network access.
- Do not collect analytics or personal data without an explicit product decision, appropriate disclosures, and a privacy review.
- Verify current Google Play requirements before submission.

---

## 18. Immediate Next Steps

1. Create the repository and preserve this `plan.md` as the baseline.
2. Create `instructions.md`, `changelog.md`, and `currentstate.md`.
3. Pin the Godot version and document Android export prerequisites.
4. Build M0 only, then verify a debug APK on a physical device.
5. Implement M1 movement and selection before creating a large asset set.
6. Review the architecture after the first movement prototype.
7. Keep scope changes explicit and recorded.

**Guiding rule:** A small, complete, enjoyable RTS is more valuable than a large unfinished strategy game.
