# ADR-0002: Autoload Initialization Order & RunManager Signal Catalog

## Status

Proposed

## Date

2026-07-26

## Last Verified

2026-07-26

## Decision Makers

technical-director (architecture session), godot-specialist (consulted for Autoload boot semantics)

## Summary

Fixes the concrete boot order of all Godot Autoload singletons in `project.godot` (the one hard constraint being `SaveManager` before `ProgressManager`), and publishes the first exhaustive catalog of `RunManager`'s 5 signals against every GDD's stated dependencies — closing a documented specification gap where "9+ systems subscribe" was asserted but never enumerated per-signal.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — Autoload boot ordering and signal declarations are pure GDScript/project-config behavior unchanged since early 4.x; no post-cutoff API involved |
| **References Consulted** | `design/gdd/런-상태-관리.md`, `design/gdd/영구-진행.md`, `design/gdd/로컬-세이브.md`, `design/gdd/씬-관리.md`, `design/gdd/광고-통합.md`, `design/gdd/동료-데이터.md`, `design/gdd/적-데이터.md`, `docs/architecture/architecture.md` (Data Flow §4, Required ADRs #2) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — Autoload order is declared in `project.godot` and is not an engine-version-sensitive behavior |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Writing the `[autoload]` section of `project.godot`; any story implementing `RunManager`, `SaveManager`, `ProgressManager`, `SceneManager`, `AdManager`, `CompanionRegistry`, `EnemyRegistry`, or any UI/system that subscribes to `RunManager` signals |
| **Blocks** | Epic: Foundation Autoload Setup — cannot register `[autoload]` entries in `project.godot` until this ADR is Accepted (per TD-ARCHITECTURE gate condition in `architecture.md`) |
| **Ordering Note** | Independent of ADR-0005 (RNG injection) and ADR-0006 (data registry utility) — no sequencing constraint between them, though CompanionRegistry/EnemyRegistry appear in both this ADR's boot order and ADR-0006's scope |

## Context

### Problem Statement

Godot Autoloads boot in the exact order they are listed in `project.godot`'s `[autoload]` section — not alphabetically, not by dependency graph inference. `architecture.md` identifies one hard runtime constraint: `ProgressManager._ready()` calls `SaveManager.load_section()` synchronously to restore `unlocked_companions`/`highest_floor_reached` at boot (`design/gdd/영구-진행.md` §초기화, lines 34-45). If `SaveManager` is listed after `ProgressManager` in `[autoload]`, this call will fail against an uninitialized Autoload. No other Autoload has an equivalent `_ready()`-time cross-call, but the order still has to be written down somewhere authoritative before any of these 7 systems exist as code — otherwise every implementer picks their own order ad hoc.

Separately, `RunManager`'s 5 signals (`floor_changed`, `combat_entered`, `combat_exited`, `run_ended`, `state_changed`) are described in `design/gdd/런-상태-관리.md` (lines 91-101) as being subscribed to by "9개 이상의 다운스트림 시스템," but no GDD enumerates which system subscribes to which signal. `architecture.md`'s Data Flow §2 table explicitly flags this as unresolved ("문서상 명시적 구독자 미기재") and routes it to this ADR (Open Question QQ-05).

### Current State

No code exists yet (`src/` is empty). `project.godot` has no `[autoload]` section written. This is a pre-implementation decision, not a migration.

### Constraints

- Godot 4.6 Autoload boot order is strictly list-order, not dependency-resolved.
- `ProgressManager._ready()` → `SaveManager.load_section()` is the only confirmed `_ready()`-time cross-Autoload call among the 7 Foundation-layer Autoloads (`design/gdd/영구-진행.md` line 37).
- All 7 Autoloads in scope: `SceneManager` (#19), `CompanionRegistry` (#10), `EnemyRegistry` (#11), `SaveManager` (#17), `ProgressManager` (#14), `RunManager` (#13), `AdManager` (#18).

### Requirements

- A single, written, authoritative Autoload order in `project.godot`.
- A signal catalog for `RunManager`'s 5 signals that lists every GDD-confirmed subscriber, with no invented subscribers.

## Decision

### Architecture

```
project.godot [autoload] order (top to bottom = boot order):

1. SceneManager      (#19 — no dependency on any other Autoload's _ready())
2. CompanionRegistry  (#10 — data registry, no _ready() cross-calls)
3. EnemyRegistry      (#11 — data registry, no _ready() cross-calls)
4. SaveManager        (#17 — MUST precede ProgressManager)
5. ProgressManager    (#14 — _ready() calls SaveManager.load_section())
6. RunManager         (#13 — conceptually sits above persistent progression)
7. AdManager          (#18 — most "leaf"/platform-facing, nothing depends on
                        its _ready() completing before their own boot)
```

### Key Interfaces

```
# project.godot
[autoload]

SceneManager="*res://src/core/scene_manager.gd"
CompanionRegistry="*res://src/core/companion_registry.gd"
EnemyRegistry="*res://src/core/enemy_registry.gd"
SaveManager="*res://src/core/save_manager.gd"
ProgressManager="*res://src/core/progress_manager.gd"
RunManager="*res://src/core/run_manager.gd"
AdManager="*res://src/core/ad_manager.gd"
```

### Implementation Guidelines

- **Only one ordering rule is load-bearing**: `SaveManager` must appear before `ProgressManager`. If a future Autoload gains a `_ready()`-time cross-call, that pair's relative order becomes load-bearing too and must be documented here (Superseding ADR, not silent edit).
- `SceneManager`/`CompanionRegistry`/`EnemyRegistry` have no `_ready()`-time dependency on each other or on anything below them — their relative order among themselves is a free choice, fixed here purely for readability (Foundation data layer before Foundation state layer).
- `RunManager` is placed after `ProgressManager` because `RunManager`'s own lifecycle (a single run) conceptually sits above persistent cross-run progression, even though no code-level `_ready()` call requires this ordering today. If a future revision adds one (e.g. `RunManager._ready()` reading `ProgressManager.get_unlocked_companions()`), this ordering already supports it for free.
- `AdManager` is placed last because it is the most platform-facing/leaf system — nothing in `_ready()` of any other Autoload calls into it, and it calls nothing at `_ready()` time itself (`design/gdd/광고-통합.md` `_ready()` only registers a `JavaScriptBridge` callback, no cross-Autoload calls).
- **Signal Catalog** (RunManager, #13) — authoritative reference, supersedes re-deriving subscribers from scattered GDD text:

| Signal | Emitter | Confirmed Subscribers (GDD text) | Status |
|--------|---------|-----------------------------------|--------|
| `floor_changed(new_floor: int)` | RunManager | None found by exact-name grep across `design/gdd/*.md` | **No confirmed subscriber yet — verify at implementation time.** `#20 UI/HUD`'s GDD reads `RunManager.current_floor`/`current_room_index` directly (property access, `design/gdd/UI-HUD.md` line 25) rather than citing this signal by name — Architecture Principle 2 ("시그널 우선, 폴링 금지") implies `#20` *should* subscribe to this signal instead of polling the property, but the GDD text does not confirm it does. |
| `combat_entered(enemies: Array[EnemyRunState])` | RunManager | None found by exact-name grep | **No confirmed subscriber yet — verify at implementation time.** Plausible candidate: `#1 턴제 전투` (battle screen needs to know combat has started), but `design/gdd/턴제-전투.md` was not in this ADR's read scope and no other GDD names this signal. |
| `combat_exited(victory: bool)` | RunManager | None found by exact-name grep | **No confirmed subscriber yet — verify at implementation time.** |
| `run_ended(success: bool)` | RunManager | None found by exact-name grep | **No confirmed subscriber yet — verify at implementation time.** Plausible candidate: `#16 런 결과` (result screen needs to know the run ended and whether it succeeded), but not confirmed by exact signal name in `design/gdd/런-결과.md` (not read in this ADR's scope). |
| `state_changed(old_state: String, new_state: String)` | RunManager | None found by exact-name grep | **No confirmed subscriber yet — verify at implementation time.** |

**Why the catalog is mostly "unconfirmed" rather than populated**: a targeted grep for the 5 exact signal names (`floor_changed`, `combat_entered`, `combat_exited`, `run_ended`, `state_changed`) across every file in `design/gdd/` returns matches **only** in `design/gdd/런-상태-관리.md` itself (the emitter's own GDD). `architecture.md`'s claim of "9개 이상 시스템이 구독" (Data Flow §2, System Layer Map) is not backed by any GDD citing these signals by name — every other GDD that depends on `#13` does so via **property reads** (`current_floor`, `party`, `state`) or via **method calls** (`advance_floor()`, `add_discovered_companion()`), not documented signal subscriptions. This is the specification gap this ADR closes by making it explicit and visible, rather than leaving it implied by an uncited "9+" claim. **Action for implementers**: when building any system in the Downstream Dependents table of `design/gdd/런-상태-관리.md` (§Dependencies), check at implementation time whether that system's UI-update or state-sync logic should subscribe to one of these 5 signals (per Architecture Principle 2, polling is forbidden) — do not assume the absence of a citation here means no subscription is needed.

## Alternatives Considered

### Alternative 1: Alphabetical Autoload order

- **Description**: List Autoloads alphabetically in `project.godot` (`AdManager, CompanionRegistry, EnemyRegistry, ProgressManager, RunManager, SaveManager, SceneManager`).
- **Pros**: Trivially discoverable order, no judgment calls.
- **Cons**: Breaks the one hard constraint — `ProgressManager` would boot before `SaveManager` alphabetically, causing `ProgressManager._ready()`'s `SaveManager.load_section()` call to fail against an uninitialized Autoload.
- **Estimated Effort**: Same as chosen approach (a single list to write).
- **Rejection Reason**: Alphabetical order is incompatible with the one confirmed runtime dependency. Rejected outright.

### Alternative 2: Defer signal catalog to implementation time, no ADR now

- **Description**: Skip formalizing the signal catalog until each downstream system is actually implemented and its subscription need becomes concrete.
- **Pros**: Avoids guessing at subscribers that don't exist in GDD text yet.
- **Cons**: Leaves the "9+ systems subscribe" claim in `architecture.md` unaudited indefinitely, and risks each implementer re-deriving (and possibly disagreeing on) the subscriber list independently — exactly the scattered-re-derivation problem this ADR exists to prevent.
- **Estimated Effort**: Lower now, higher later (repeated re-investigation cost per system).
- **Rejection Reason**: `architecture.md`'s TD-ARCHITECTURE gate explicitly requires this ADR before coding starts (Foundation-layer Required ADR #2). Documenting "currently unconfirmed, verify at implementation" is strictly more useful than silence, and costs nothing extra to write down now.

## Consequences

### Positive

- `project.godot`'s `[autoload]` section can be written directly from this ADR with no further architectural judgment calls.
- The one load-bearing ordering constraint (`SaveManager` before `ProgressManager`) is explicit and traceable to its source (`design/gdd/영구-진행.md` line 37), preventing a future refactor from silently reordering Autoloads and reintroducing the bug.
- The signal catalog gap is now visible and tracked instead of silently assumed — future GDD revisions or implementation stories can close each "unconfirmed" row with a citation instead of rediscovering the gap from scratch.

### Negative

- The signal catalog is mostly "unconfirmed" rather than a clean reference table — it documents a gap rather than closing it, which may read as incomplete to a story author expecting a finished answer.
- If a future Autoload (e.g. `#5 클라우드 세이브`, `#23 설정`) is added with its own `_ready()`-time cross-call, this ADR must be revisited (Superseded) rather than silently patched.

### Neutral

- The relative order of `SceneManager`/`CompanionRegistry`/`EnemyRegistry` (positions 1-3) is a stylistic choice with no functional consequence today — a future ADR revision could reorder these three without breaking anything.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A future Autoload gains a `_ready()`-time cross-call not covered by this order | Medium | Medium — boot-time null reference / push_error | Any new Autoload's `_ready()` logic must be checked against this ADR's ordering before merging; if it introduces a new cross-call constraint, supersede this ADR |
| Implementers assume "no confirmed subscriber" means "no subscription needed" and skip wiring UI updates to these signals | Medium | Medium — UI silently falls back to polling, violating Architecture Principle 2 | This ADR's catalog explicitly instructs implementers to verify subscription need per downstream system at implementation time, not just at GDD-authoring time |
| `architecture.md`'s "9+ systems" claim is never fully reconciled against this catalog | Low | Low — cosmetic documentation mismatch | Flag for `/architecture-review` to cross-check `architecture.md`'s Data Flow §2 table against this ADR's catalog in a future pass |

## Performance Implications

N/A — no implementation exists yet.

## Migration Plan

N/A — no implementation exists yet. This is a greenfield decision for `project.godot`, not a migration of existing Autoload registrations.

## Validation Criteria

- [ ] `project.godot`'s `[autoload]` section lists the 7 Autoloads in exactly the order specified in this ADR.
- [ ] `ProgressManager._ready()` successfully calls `SaveManager.load_section()` without a null-reference error at boot (manual smoke test or integration test).
- [ ] Every future story that implements a system in the Downstream Dependents table of `design/gdd/런-상태-관리.md` explicitly states, in its own notes, whether it subscribes to any of the 5 `RunManager` signals — closing a row in this ADR's catalog with a citation rather than leaving it "unconfirmed."

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/영구-진행.md` (line 37) | #14 영구 진행 | "`ProgressManager._ready()`에서 `SaveManager.load_section()`을 호출하므로 SaveManager보다 반드시 나중이어야 함" | Fixes `SaveManager` (position 4) before `ProgressManager` (position 5) in the Autoload boot order |
| `design/gdd/런-상태-관리.md` (lines 91-101) | #13 런 상태 관리 | 5 signals declared, described as consumed by "9개 이상의 다운스트림 시스템" with no per-signal subscriber list | Builds and publishes the first explicit signal catalog, marking each signal's subscriber status honestly rather than repeating the uncited "9+" claim |
| `docs/architecture/architecture.md` (Data Flow §4, "초기화 순서") | Cross-cutting | "제안 순서: SceneManager → CompanionRegistry → EnemyRegistry → SaveManager → ProgressManager → RunManager → AdManager ... 이 순서를 Foundation 레이어 Required ADR로 기록" | Formalizes exactly this proposed order as an Accepted-track decision with explicit justification per Autoload |
| `docs/architecture/architecture.md` (Required ADRs #2, TR-run-state-004) | #13 런 상태 관리 | "Autoload 초기화 순서 및 RunManager 시그널 카탈로그" | This ADR is that required decision |

## Related

- `docs/architecture/architecture.md` — Master architecture doc; Required ADR #2 traces directly to this file.
- ADR-0005 (RNG injection pattern) and ADR-0006 (data registry shared utility) — independent decisions, no dependency, but ADR-0006 covers the internal implementation of `CompanionRegistry`/`EnemyRegistry`, which this ADR only places in the boot order.
