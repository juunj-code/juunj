## Technical Debt Register
Last updated: 2026-08-08
Total items: 1 | Estimated total effort: S

| ID | Category | Description | Files | Effort | Impact | Priority | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|-------|--------|
| TD-002 | Test Debt | 적-데이터 GDD AC12 (soft warning when a stat is outside its documented tuning range) is not enforced anywhere -- no balance tooling reads the range yet. Deliberately deferred as YAGNI (see `tests/unit/core/enemy_registry_test.gd` header). | `tools/validate_data.gd` (would host it), `design/gdd/적-데이터.md` | S | Low | Low (no balance tooling exists yet to consume it) | 2026-08-06 | Backlog |

### Resolved
- **TD-001** (Code Quality Debt, resolved 2026-08-08): `unit_hp_changed`/`unit_sp_changed`/`status_effects_changed` were keyed by `unit_id` alone, which two same-`enemy_id` units in one battle could share. Fixed by adding a `unit_index: int` parameter to all three signals (the unit dict's own `index` field); `battle_screen.gd` now keys its label/row dictionaries by `"id#index"` and stores single values instead of arrays (simplification -- the array-of-labels indirection existed only to paper over the id collision). `UI-HUD.md`'s signal contract table updated to match. `turn_battle_test.gd`'s lambda signature updated for the new arity.

### Notes
- Full-codebase scan (2026-08-06): no `TODO`/`FIXME`/`HACK`/`@deprecated` markers, no files over 500 lines, no functions over 50 lines. The `ponytail:` inline-comment convention (see `.claude/skills/../ponytail` guidance) already covers most deliberate corner-cuts at the point they were made -- this register exists for the subset worth tracking/prioritizing across files, not a duplicate of every inline note.
- Two other `ponytail:` comments (`src/core/run_manager.gd`, `src/core/scene_transition_rules.gd`) were found stale during this scan -- they described SceneManager/ProgressManager autoloads and real `.tscn` scene files as not yet existing, but both have existed since 2026-07-31/08-01. Corrected in place (doc-only, no behavior change); not registered here since there was no actual debt, just an outdated comment.
