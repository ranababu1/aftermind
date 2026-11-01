# AFTERMIND
## Development Instructions

These instructions govern all implementation work in this repository. Follow them for human-written and AI-assisted changes.

---

## 1. Source-of-Truth Documents

The repository must contain these files at its root:

- `plan.md`: product vision, scope, gameplay, architecture direction, milestones, and constraints. **Treat as immutable during routine implementation. Do not rewrite, shorten, or silently change it.** If a genuine strategic change is needed, ask for approval first and record the decision in `changelog.md`.
- `instructions.md`: this file. Follow it throughout development. Change only when the project owner approves a change to the working rules.
- `changelog.md`: append a dated entry for meaningful code, asset, configuration, architecture, or release changes.
- `currentstate.md`: concise, current description of what exists, how to run/build it, what works, known issues, and the exact next task. Keep it updated so an agent can understand the project without reading every source file.

If a requested implementation conflicts with `plan.md`, stop and explain the conflict before changing scope.

## 2. Required Working Method

For each task:
1. Read `instructions.md`, `currentstate.md`, and the relevant parts of `plan.md`.
2. Inspect repository status and existing code before editing.
3. Identify the smallest coherent change that satisfies the task.
4. Preserve all user changes and existing behavior unless a change is explicitly required.
5. Implement in small, buildable increments.
6. Run the relevant tests and build/export checks.
7. Review the full diff, including new and deleted files.
8. Update `changelog.md` and `currentstate.md` before committing when feasible.
9. Commit and push according to the Git rules below.
10. Report what changed, what was tested, the result, and any remaining limitations.

Do not claim tests, builds, or exports succeeded unless they were actually run and their results inspected.

## 3. Engine and Code Standards

- Use Godot 4.x and GDScript unless the project owner explicitly approves a different stack.
- Pin and document the exact stable Godot version used by the project.
- Follow the project's existing conventions before introducing new ones.
- Prefer clear, typed GDScript where it improves correctness and maintainability.
- Keep scripts focused on one responsibility.
- Separate simulation/gameplay rules from UI and visual effects.
- Avoid premature abstraction, over-engineering, unnecessary frameworks, and global singletons without a clear ownership reason.
- Use data resources/configuration for unit statistics, building costs, production time, damage, and upgrade definitions when practical.
- Use stable identifiers for entities and data definitions where references must survive scene changes.
- Avoid magic numbers scattered through scripts. Centralize tuning values in data/configuration.
- Use signals/events for meaningful state changes and avoid unnecessary per-frame UI polling.
- Handle null references, freed nodes, invalid targets, blocked paths, depleted resources, and interrupted orders.
- Do not introduce a new dependency without explaining why it is needed.
- Do not change the pinned Godot version without approval, and verify an Android export after any approved engine upgrade.

## 4. Gameplay Integrity

- Resource spending must be validated atomically and cannot produce negative balances.
- Invalid build placement must be rejected with visible feedback.
- Unit commands must fail safely when the target or destination is invalid.
- Navigation and combat systems must handle units or structures being destroyed during an order.
- Enemy AI must not receive hidden resources or map vision unless an explicit, documented difficulty rule permits it.
- Difficulty changes must be explicit parameters, not unexplained cheating.
- Victory/defeat state transitions must be idempotent and must not trigger multiple times.
- Restarting a match must clear all relevant match state, queues, timers, selections, and transient effects.
- The game must remain playable offline for the first release unless the project owner approves a scope change.
- Every AI Evolution upgrade must have a clear benefit and an understandable trade-off.

## 5. Mobile UX and Accessibility

- Test interactions on a physical Android device, not only in the editor.
- Use touch targets appropriate for phone screens.
- Ensure camera gestures and UI controls do not unintentionally issue world commands.
- Provide feedback for selection, movement, attack, construction, invalid orders, resource shortages, and important state changes.
- Respect safe areas and common aspect ratios.
- Keep essential text readable and avoid relying on color alone to communicate faction or unit state.
- Pause/resume and Android app backgrounding must not corrupt a match.
- Avoid unnecessary permissions, network dependencies, or account requirements.

## 6. Build, Test, and Export Rules

- Establish and document a baseline Android device and Godot version.
- Run the fastest relevant test after every meaningful change.
- Before a push, ensure the project remains buildable and run the relevant build/export checks.
- For gameplay changes, run relevant regression scenarios such as movement, resource spending, production, combat, and match completion.
- For Android-related changes, verify a debug export when the environment supports it.
- If a required test cannot be run, clearly state why. Never describe an untested build as successful.
- Do not silence warnings or weaken checks merely to make a build pass. Fix the root cause or document an approved exception.
- Keep a repeatable smoke-test checklist in `currentstate.md` or a dedicated test document.
- Never knowingly push a non-building solution.

## 7. Git Branching, Commits, and Push Frequency

### Branch safety
- Work on the intended/current branch unless the project owner authorizes a branch change.
- Inspect `git status` before editing and before staging.
- Preserve uncommitted user changes. Do not overwrite, discard, or reformat unrelated user work.
- Do not use destructive Git commands such as `git reset --hard`, `git clean -fd`, force push, history rewriting, or branch deletion without explicit permission.
- Do not switch branches if doing so would endanger or strand uncommitted changes.

### Mandatory push cadence
Push frequently, following this rule:

**Push after every file change that leaves the solution buildable, or when approximately 50 lines of production code have changed since the previous push, whichever comes first.**

- A newly created or modified file that leaves the solution buildable should be committed and pushed promptly.
- Do not delay a small, buildable change just because it is fewer than 50 lines.
- If a file change temporarily makes the solution non-building, do not push that state. Continue with the smallest necessary fix until the build succeeds, then commit and push.
- The build/compilation requirement takes precedence over the line-count cadence.
- For changes involving multiple tightly coupled files, make the smallest coherent buildable increment and push that increment.
- If the remote is unavailable or push fails, report the failure and retain the local commit. Retry only when safe.

### Commit hygiene
- Use focused commits with clear, descriptive messages.
- Review `git diff` and `git diff --cached` before committing.
- Stage only files relevant to the task.
- Do not add an AI co-author trailer.
- Do not commit secrets, credentials, API keys, signing keys, private certificates, customer data, local databases, build output, `.godot/`, `.import/` generated cache, `.vs/`, `bin/`, `obj/`, temporary files, or machine-specific settings.
- Ensure `.gitignore` covers relevant Godot, IDE, operating-system, and build artifacts without ignoring source assets that must be versioned.
- Verify the push succeeded and confirm the expected branch and remote.
- Do not claim a push succeeded without checking its result.

## 8. Security and Privacy

- Never hard-code secrets, credentials, private tokens, signing passwords, or personal data.
- Do not commit Android keystores, signing files, private certificates, or exported release credentials.
- Keep secrets out of logs, screenshots, crash reports, and documentation.
- Use only permissions required for the feature.
- Do not add analytics, advertising SDKs, tracking, or remote services without explicit approval and a privacy review.
- Validate external input if a future network feature is approved.
- Review dependency licenses and security posture before adding dependencies.
- Use original or appropriately licensed assets only; record asset source and license.
- Never extract or reuse proprietary assets from commercial games.

## 9. Asset and Content Rules

- Keep art direction consistent with the dystopian post-AI setting and the approved visual reference.
- Prefer readable silhouettes and performant materials over expensive effects.
- Track third-party asset name, source, license, attribution, and intended use.
- Do not include unlicensed music, fonts, sound effects, models, textures, logos, or copied maps.
- Use original names and written content. Do not copy another game's faction names, characters, narrative, UI, maps, branding, or distinctive expression.
- Do not add a large volume of placeholder assets without labeling them as placeholders and tracking replacement needs.

## 10. Performance Rules

- Profile before optimizing and record the device, scenario, entity count, and measured result.
- Avoid expensive full-world scans every frame.
- Avoid repeated path recalculation when destinations and navigation state have not changed.
- Use pooling only when profiling supports it.
- Keep particles, shadows, materials, and draw calls appropriate for the target device.
- Test low, typical, and high entity counts.
- Do not claim a target FPS or memory budget is met without physical-device measurements.

## 11. AI-Assisted Coding Rules

- Treat generated code as a proposal that requires review, not as verified output.
- Inspect relevant files and existing architecture before generating replacements.
- Do not replace an entire file when a focused edit is sufficient.
- When a full-file replacement is necessary, ensure the replacement is complete and preserves unrelated functionality.
- Avoid inventing engine APIs. Check the pinned Godot documentation or existing project usage when uncertain.
- Run parser/build checks after edits.
- Explain assumptions when a requirement is ambiguous instead of silently choosing a risky interpretation.
- Do not mark a feature complete until its acceptance criteria are verified.
- Do not create unnecessary documentation, abstraction layers, or files that do not support the current milestone.

## 12. Documentation Maintenance

### `changelog.md`
Append a dated entry for each meaningful change. Include:
- Summary of change.
- Reason.
- Key files or systems affected.
- Tests/build checks performed and results.
- Any known limitation or follow-up.

Do not rewrite historical entries to make them appear more favorable.

### `currentstate.md`
Keep the following sections current:
- Current milestone and status.
- Engine/version and project setup.
- Implemented features.
- Features not implemented.
- How to open, run, test, and export.
- Last verified build/test and environment.
- Known bugs, risks, and limitations.
- Current branch and last commit/push status when known.
- Exact next recommended task.

Never claim a feature exists unless it is present in the repository. Distinguish verified facts from assumptions.

## 13. Definition of Done

A task is done only when:
- Acceptance criteria are met.
- Relevant tests or build checks have been run, or any inability to run them is documented.
- No unrelated user changes have been lost.
- The diff has been reviewed.
- No secrets, generated artifacts, or unlicensed assets have been introduced.
- `changelog.md` and `currentstate.md` are updated when applicable.
- The solution remains buildable.
- The change is committed and pushed according to the Git rules, or the exact blocker is reported.
- The final report accurately states implementation, verification, commit/push status, and remaining issues.

## 14. Required Final Report Format

After each task, report:
1. **Implemented:** what changed.
2. **Files changed:** concise list.
3. **Verification:** exact tests/build/export performed and result.
4. **Git:** branch, commit, and push status, if applicable.
5. **Remaining issues:** known limitations or blockers.
6. **Next step:** one specific action.

Do not report success based solely on code generation or visual inspection.
