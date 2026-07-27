# ADR-0005: RNG Injection Pattern Standardization

## Status

Accepted

## Date

2026-07-26

## Last Verified

2026-07-27 (Accepted after `/architecture-review` — see `docs/architecture/architecture-review-2026-07-27.md`, no unresolved verification items for this ADR)

## Decision Makers

technical-director (architecture session)

## Summary

Standardizes one dependency-injection pattern for random number generation across the 3 systems that need it (random dungeon generation, equipment drops, hidden companion assignment), instead of 3 independent implementations, and fixes ownership of the actual `RandomNumberGenerator` instance at `RunManager.start_run()`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — `RandomNumberGenerator` as an injectable instance (vs. global `randi()`/`randf()`) has been stable GDScript/Godot API since 3.x; no post-cutoff behavior involved |
| **References Consulted** | `design/gdd/랜덤-던전.md`, `design/gdd/장비.md`, `design/gdd/히든-트리거.md`, `.claude/docs/coding-standards.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Implementation of `#2 랜덤 던전`'s `generate_floor()`, `#4 장비`'s `roll_drop()`, `#9 히든 트리거`'s companion pool shuffle, and their unit tests (all 3 require deterministic RNG per `.claude/docs/coding-standards.md`'s "no random seeds" testing rule) |
| **Blocks** | Any story implementing floor generation, equipment drop rolls, or hidden companion assignment — these cannot be TDD'd without a fixed injection contract |
| **Ordering Note** | Independent of ADR-0002 and ADR-0006 — no sequencing constraint |

## Context

### Problem Statement

Three unrelated Feature-layer systems each independently need non-deterministic-in-production, deterministic-in-test randomness:

1. `#2 랜덤 던전` — Fisher-Yates shuffle over non-boss rooms, and **with-replacement** sampling for enemy composition per combat room (`design/gdd/랜덤-던전.md` lines 93-99).
2. `#4 장비` — `DROP_CHANCE = 0.5` roll after clearing a combat room, plus a uniform pick over the 6-item equipment pool (`design/gdd/장비.md` lines 100-105).
3. `#9 히든 트리거` — a **without-replacement** shuffle of the 3-id hidden companion pool at run start, consumed one id at a time as hidden rooms are generated (`design/gdd/히든-트리거.md` lines 31-34).

All three GDDs already write their pseudocode as if an `RandomNumberGenerator` were being passed in (`generate_floor(floor_index, rng: RandomNumberGenerator)`, `rng.randf() < DROP_CHANCE`, "런 시작 시(rng 주입받아) 셔플"), which is good instinct but was never formalized as a single contract — each GDD arrived at this independently, and nothing states who actually constructs and owns the `RandomNumberGenerator` instance at runtime, or how the with-replacement/without-replacement distinction is guaranteed not to get confused between the three call sites.

`.claude/docs/coding-standards.md` makes this a hard requirement, not a style preference: "Determinism: Tests must produce the same result every run — no random seeds, no time-dependent assertions" and "Dependency Injection over singletons for testability." Godot's global `randi()`/`randf()` cannot be seeded per-test-case in isolation (they share global engine state), so relying on them anywhere in these 3 systems would violate the testability requirement directly.

### Current State

No code exists yet. This is a greenfield decision to prevent 3 independent, possibly-inconsistent RNG injection implementations from being written ad hoc as each system is implemented.

### Constraints

- Must support both with-replacement sampling (enemy composition — duplicates allowed, only 3 species in MVP) and without-replacement sampling (hidden companion assignment — each of 3 ids used exactly once per run).
- Must allow GUT unit tests to force deterministic outcomes without touching global engine RNG state.
- Must not require each system to hold its own private seeded RNG instance with no coordination (that would make "same run, same overall seed" reproducibility impossible, and would multiply the ownership question by 3).

### Requirements

- One injection signature pattern used identically by all 3 systems.
- One documented owner for the runtime `RandomNumberGenerator` instance.
- An explicit, tested distinction between with-replacement and without-replacement sampling that traces to the documented bug in `design/gdd/랜덤-던전.md`.

## Decision

Each system's generation/roll function accepts a `RandomNumberGenerator` instance as an explicit parameter. `RunManager` creates and owns exactly one seeded `RandomNumberGenerator` instance per run, at `start_run()` time, and passes it down to whichever system needs it for that call. No system holds its own private RNG instance, and no system calls Godot's global `randi()`/`randf()`/`Array.pick_random()`.

### Architecture

```
RunManager.start_run(party_config)
  │
  ├─ _run_rng := RandomNumberGenerator.new()
  │     _run_rng.randomize()   # production: real entropy
  │     (test harness overrides via _run_rng.seed = FIXED_SEED)
  │
  ├─ RandomDungeon.generate_floor(floor_index, _run_rng)   # #2 — reads _run_rng at
  │                                                          #      floor-generation time (once per floor,
  │                                                          #      not once per run, since all 3 floors are
  │                                                          #      generated up front per 랜덤-던전.md Core Rule 3)
  │
  ├─ HiddenTrigger.shuffle_companion_pool(_run_rng)          # #9 — called once at run start,
  │                                                          #      consumed via get_next_companion_id()
  │                                                          #      as hidden rooms are generated
  │
  └─ (later, per combat room clear)
        Equipment.roll_drop(_run_rng)                        # #4 — called per combat-room-clear event,
                                                               #      reuses the same run-scoped instance
```

`_run_rng` is a single instance threaded through the entire run — not re-created per call. This preserves "one seed determines the entire run" reproducibility, which matters for bug repro (a QA tester can hand over one seed and reproduce an entire run's dungeon layout, drops, and hidden assignments) even though no GDD currently requires seed-sharing across systems as a player-facing feature; it costs nothing to preserve and forecloses nothing.

### Key Interfaces

```gdscript
# #2 랜덤 던전
static func generate_floor(floor_index: int, rng: RandomNumberGenerator) -> Array[RoomData]

# #4 장비
static func roll_drop(rng: RandomNumberGenerator) -> EquipmentData  # null if DROP_CHANCE roll misses

# #9 히든 트리거
func shuffle_companion_pool(rng: RandomNumberGenerator) -> void     # instance method — HiddenTrigger
                                                                     # is an Autoload holding the shuffled
                                                                     # pool as internal state, consumed via:
func get_next_companion_id() -> String                              # no rng param — pool already shuffled
```

### Implementation Guidelines

- **Who owns the instance**: `RunManager` creates exactly one `RandomNumberGenerator` in `start_run()` and holds it as a private field (e.g. `_run_rng`) for the run's lifetime. It is not exposed as a public property — systems that need it receive it as an explicit call parameter at the moment they need it (e.g. `RandomDungeon.generate_floor(floor_index, RunManager._run_rng)` — or, to avoid `RunManager` becoming a de facto RNG service locator, `RunManager` passes `_run_rng` directly into the calls it already makes during `start_run()` and `end_run()`/floor-advance flows, per `design/gdd/런-상태-관리.md`'s existing call graph). This was chosen over "each system takes an optional `rng` param defaulting to a shared instance" because a defaulted-shared-instance pattern still needs the shared instance to live *somewhere*, and hiding that behind a default argument obscures the single owner instead of naming it — an explicit required parameter is simpler to audit and exactly as short to call.
- **Tests inject their own instance**: GUT tests construct a `RandomNumberGenerator`, set `.seed` to a fixed constant, and pass it directly to the function under test — no dependency on `RunManager` at all for unit-level tests of `generate_floor()`/`roll_drop()`/`shuffle_companion_pool()`. This satisfies `.claude/docs/coding-standards.md`'s "Unit tests do not call external APIs... use dependency injection" and "Independence" rules directly.
- **With-replacement vs. without-replacement — the pattern must support both, not just one**: This is the cautionary case this ADR must get right, per `design/gdd/랜덤-던전.md`'s own documented bug (lines 93-99): an earlier draft used `random.sample()`-style pseudocode (non-replacement) for enemy composition, which silently made every 2nd/3rd-floor combat room contain all 3 enemy species with no duplicates possible (pool size == draw count == 3), defeating "랜덤 조합." It was fixed to explicit indexed sampling:
  ```gdscript
  # #2 — WITH replacement (duplicates allowed — only 3 enemy species in MVP)
  enemies.append(normal_enemy_pool[rng.randi() % normal_enemy_pool.size()])
  ```
  Meanwhile `#9`'s hidden companion assignment needs the opposite guarantee — each of the 3 hidden ids assigned **exactly once** per run, never repeated:
  ```gdscript
  # #9 — WITHOUT replacement (Fisher-Yates shuffle consumed in order, never re-drawn)
  func shuffle_companion_pool(rng: RandomNumberGenerator) -> void:
      _pool = ["hidden_mage_02", "hidden_archer_03", "hidden_healer_04"]
      # Fisher-Yates in place
      for i in range(_pool.size() - 1, 0, -1):
          var j := rng.randi_range(0, i)
          var tmp = _pool[i]; _pool[i] = _pool[j]; _pool[j] = tmp
      _next_index = 0

  func get_next_companion_id() -> String:
      var id = _pool[_next_index]
      _next_index += 1
      return id
  ```
  The injection pattern (parameter, not global call) is identical in both cases — the with/without-replacement distinction lives entirely in *how the caller uses the injected `rng`* (indexed modulo draw vs. Fisher-Yates-then-consume), not in the injection contract itself. Implementers must not assume "inject an RNG" alone prevents this class of bug — the call-site algorithm choice is still the implementer's responsibility, and this ADR names both patterns explicitly so neither is invented ad hoc a second time.
- `#4`'s `roll_drop()` is a third, simpler case (single `randf()` threshold check + single indexed pick over a fixed 6-item pool) — no replacement concern since it's a single draw, but it must use the same injected-`rng` contract as the other two rather than `Array.pick_random()` (which uses Godot's global RNG per `design/gdd/장비.md` line 104's own note: "`Array.pick_random()`은 전역 RNG라 대신 명시적 인덱싱 사용").

## Alternatives Considered

### Alternative 1: Each system holds its own private seeded RNG instance

- **Description**: `RandomDungeon`, `Equipment`, and `HiddenTrigger` each construct and own their own `RandomNumberGenerator`, seeded independently (e.g. from `Time.get_unix_time_from_system()` or `randomize()`).
- **Pros**: No coordination needed between systems; each is independently testable in isolation.
- **Cons**: No single seed reproduces an entire run — a bug report seed for dungeon layout wouldn't also reproduce drop rolls or hidden assignment, splitting reproducibility 3 ways for no benefit. Also multiplies "who seeds this in production" into 3 separate answers instead of 1.
- **Estimated Effort**: Similar to chosen approach per-system, but higher in aggregate (3 ownership decisions instead of 1).
- **Rejection Reason**: No player-facing or QA requirement demands per-system independent seeding, and run-wide reproducibility is strictly more useful with no extra implementation cost — threading one instance through is not harder than constructing 3.

### Alternative 2: Godot global `randi()`/`randf()` with a test-only override hook

- **Description**: Use Godot's global RNG functions directly in production code, and add a conditional test-mode branch that swaps in deterministic values.
- **Pros**: Slightly less boilerplate at call sites (no parameter to thread through).
- **Cons**: Directly violates `.claude/docs/coding-standards.md`'s explicit DI-over-singletons requirement; global RNG state is shared across the whole engine process, so parallel/isolated test runs can leak state between tests; conditional test-mode branches inside production code are exactly the kind of untestable coupling the coding standard is written to prevent.
- **Estimated Effort**: Lower short-term, but every future test needs a new special-case branch — cost compounds.
- **Rejection Reason**: Directly contradicts an explicit, non-negotiable project coding standard. Rejected without further consideration.

## Consequences

### Positive

- One documented pattern for all 3 systems means a future 4th randomness need (if any) has an obvious precedent to follow instead of inventing a new approach.
- Tests for `generate_floor()`, `roll_drop()`, and `shuffle_companion_pool()` can all use the identical "construct RNG, set `.seed`, pass in" boilerplate — no per-system test setup divergence.
- A single per-run seed (owned by `RunManager`) makes an entire run's procedural content (dungeon layout + drops + hidden assignment) reproducible from one seed value, useful for bug reports and manual QA.

### Negative

- Every call site that needs randomness must explicitly receive and thread through a parameter — slightly more verbose than a bare global call, though this is the intended cost of testability.
- `RunManager` gains one more piece of run-scoped state (`_run_rng`) to manage correctly across `start_run()`/`reset()` — must be cleared/reassigned on `reset()` (per `design/gdd/런-상태-관리.md`'s `reset()` field list) even though the GDD's current field list does not yet mention it; this ADR requires `reset()` to be extended to include `_run_rng = null` (or re-created fresh at the next `start_run()`) to avoid a stale seeded RNG leaking into the next run.

### Neutral

- The choice of "required parameter" over "optional parameter with shared-instance default" is a style decision with equivalent runtime behavior — either would satisfy the testing requirement equally well.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A future implementer uses `rng.randi() % pool.size()` (with-replacement) where without-replacement was actually needed, or vice versa, reintroducing the class of bug this ADR documents | Medium | Medium — silently wrong game behavior (e.g. duplicate hidden companion assignment or artificially reduced enemy variety), not a crash | This ADR names both patterns explicitly with code; unit tests for `#2`/`#9` must assert the replacement/non-replacement property directly (e.g. "3 draws from a 3-item pool with replacement can repeat" vs. "3 draws from a 3-item pool without replacement are a permutation") |
| `RunManager._run_rng` is not reset between runs, causing seed-derived content to correlate across consecutive runs in a subtly detectable way | Low | Low — mostly a QA/fairness-perception issue, not a crash | `reset()` must explicitly clear or reassign `_run_rng`; add to `design/gdd/런-상태-관리.md`'s `reset()` field list in a future GDD revision |
| A system bypasses the injected `rng` and calls Godot's global RNG directly out of habit | Low | Medium — breaks test determinism silently, may not be caught until a flaky test appears | Code review checklist item: grep for `randi()`/`randf()`/`pick_random()` without a preceding `rng.` prefix in `#2`/`#4`/`#9`'s source files during code review |

## Performance Implications

N/A — no implementation exists yet.

## Migration Plan

N/A — no implementation exists yet. This is a greenfield contract for `#2`/`#4`/`#9`, not a migration.

## Validation Criteria

- [ ] `generate_floor()`, `roll_drop()`, and `shuffle_companion_pool()` all accept `RandomNumberGenerator` as an explicit parameter — no global `randi()`/`randf()`/`pick_random()` calls in any of the 3 systems' source.
- [ ] A unit test for `#2`'s enemy composition sampling demonstrates duplicates are possible (with-replacement) using a fixed seed.
- [ ] A unit test for `#9`'s companion pool shuffle demonstrates all 3 ids are returned exactly once with no repeats (without-replacement) using a fixed seed.
- [ ] `RunManager.reset()` clears or reassigns `_run_rng` so no seeded state leaks between runs.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/랜덤-던전.md` (lines 44, 93-99) | #2 랜덤 던전 | "rng를 외부 주입받음 — 테스트에서 결정적 결과 강제 가능"; enemy composition must use with-replacement sampling (documented bug fix from non-replacement `random.sample()`) | Formalizes `generate_floor(floor_index, rng: RandomNumberGenerator)` as the standard signature; documents the with-replacement pattern explicitly as a named cautionary case |
| `design/gdd/장비.md` (lines 100-105) | #4 장비 | "rng 주입 명시, 테스트 결정성 확보"; `DROP_CHANCE=0.5` roll, explicit indexed pick instead of `Array.pick_random()` (global RNG) | `roll_drop(rng: RandomNumberGenerator)` signature standardized to match `#2`/`#9`; reuses the GDD's own noted rejection of `pick_random()` |
| `design/gdd/히든-트리거.md` (lines 31-34) | #9 히든 트리거 | "런 시작 시(rng 주입받아) 셔플 후 순서대로 히든방에 배정"; each of 3 hidden ids assigned exactly once per run | `shuffle_companion_pool(rng: RandomNumberGenerator)` formalized as without-replacement Fisher-Yates, consumed via `get_next_companion_id()` |
| `.claude/docs/coding-standards.md` | Cross-cutting | "Determinism: no random seeds... Dependency Injection over singletons for testability" | The entire ADR's injection-parameter contract exists to satisfy this project-wide testing standard |

## Related

- ADR-0002 (Autoload init order) — independent; `RunManager` is one of the 7 Autoloads ordered there, and this ADR adds `_run_rng` as internal state to that same Autoload.
- ADR-0006 (data registry shared utility) — independent; no shared concern with RNG injection.
