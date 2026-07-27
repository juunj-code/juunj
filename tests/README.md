# Test Infrastructure

**Engine**: Godot 4.7.1
**Test Framework**: GUT (Gut Unit Testing) v9.7.1 — `addons/gut/`
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-07-27

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  performance/    # Performance/profiling tests
  playtest/       # Manual playtest logs
  smoke/          # Critical path test list for /smoke-check gate
  evidence/       # Screenshot logs and manual test sign-off records
```

## Running Tests

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gexit
```

Config (test dirs, naming convention) lives in `.gutconfig.json` at the repo root.

If GUT reports missing class_names on a fresh clone, run once:
```bash
godot --headless --path . --import
```

## Test Naming

- **Files**: `[system]_[feature]_test.gd` (matches `.gutconfig.json`'s `suffix: "_test.gd"`, not GUT's own default `test_` prefix)
- **Functions**: `test_[scenario]_[expected]`
- **Example**: `tests/unit/combat/combat_formula_test.gd` → `test_skill_damage_epsilon_guard_prevents_float_underflow()`
- Test classes `extends GutTest`.

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `tests/evidence/` |
| UI | Manual walkthrough OR interaction test | `tests/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging.

## Why GUT, not GdUnit4

Several generic skill/agent templates in this repo (`coding-standards.md`,
`test-setup`, `smoke-check`, `test-helpers`) default to GdUnit4 for Godot.
This project's actual decision — recorded in `technical-preferences.md` and
baked into ADR-0001/0003/0005's mock-injection test patterns — is **GUT**.
Follow GUT here; the GdUnit4 references elsewhere are stale generic
boilerplate that was never updated after `/setup-engine` picked GUT.
