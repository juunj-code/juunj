# ADR-0006: Shared Data Registry Loader Utility (Companion/Enemy Registry)

## Status

Proposed

## Date

2026-07-26

## Last Verified

2026-07-26

## Decision Makers

technical-director (architecture session)

## Summary

Defines one shared loader utility that both `CompanionRegistry` and `EnemyRegistry` call — parameterized by folder path and Resource type — instead of each registry duplicating identical enumerate/sort/load/duplicate-check logic, and separates that runtime loader from a distinct build-time static validation tool that cross-checks `skill_id` references.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — `DirAccess`, `ResourceLoader`, and `Resource` typed loading are stable GDScript APIs; no post-cutoff behavior involved |
| **References Consulted** | `design/gdd/동료-데이터.md`, `design/gdd/적-데이터.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Implementation of `CompanionRegistry` (#10) and `EnemyRegistry` (#11), and the separate build-time validation tool referenced by both GDDs' Acceptance Criteria |
| **Blocks** | Any story implementing `CompanionRegistry`/`EnemyRegistry`, and the build-time validation tool story (which needs both registries' contract to cross-check `skill_id` references) |
| **Ordering Note** | Independent of ADR-0002 and ADR-0005. Overlaps with ADR-0002 only in that `CompanionRegistry`/`EnemyRegistry` are two of the 7 Autoloads ordered there — this ADR defines their internal implementation, ADR-0002 only fixes their boot position. |

## Context

### Problem Statement

`design/gdd/동료-데이터.md` and `design/gdd/적-데이터.md` independently specify near-identical requirements for their respective registries:

- Enumerate `.tres` Resource files under a folder (`assets/data/companions/` and `assets/data/enemies/` respectively).
- **Sort filenames ascending** before loading — both GDDs state this explicitly, for deterministic duplicate-id resolution, because directory scan order is not guaranteed identical between the editor and a web export (`동료-데이터.md` line 82, `적-데이터.md` line 58).
- Load each file into a typed Resource (`CompanionData` / `EnemyData`).
- Detect duplicate ids — keep the first (by sorted order), `push_error` and discard the rest.

Both GDDs also call for a separate build-time static validation tool that catches duplicate ids and dangling `skill_id` references **before runtime** — distinct from the runtime fallback path, because the runtime loader alone cannot see across both registries (`skill_id` on a `CompanionData`/`EnemyData` references a `SkillData` resource that neither registry itself owns or validates).

Writing this enumerate → sort → load → duplicate-check logic twice — once per registry — is exactly the kind of literal duplication `.claude/rules/ecc/common/coding-style.md`'s DRY principle exists to prevent, and both GDDs already say as much: `적-데이터.md` states "동일 로직(폴더 열거 → 정렬 → 로드 → 중복 검사)은 `#11 적 데이터`의 `EnemyRegistry`도 필요로 하므로, 공용 유틸리티 함수로 구현해 두 레지스트리가 공유한다."

### Current State

No code exists yet. This is a greenfield decision to prevent the duplication from ever being written, rather than a refactor of existing duplicated code.

### Constraints

- Both registries must sort ascending by filename before load (directory scan order is not portable between editor and web export — this is a correctness requirement, not a style preference).
- Duplicate-id resolution must keep the sorted-first file and discard the rest with `push_error`.
- The build-time validator needs both registries loaded simultaneously to cross-validate `skill_id` → `SkillData` references, which the runtime loader (loading one folder at a time) cannot do alone.
- `CompanionData.base_hp <= 0` and `EnemyData.base_hp <= 0` are load-rejection conditions (not just warnings) per both GDDs' Edge Cases — the shared utility must support a per-Resource-type validation hook, since the specific reject condition differs slightly in spirit (both are "base_hp must be > 0," but the utility must not hardcode a single field name if a third registry with different fields is ever added).

### Requirements

- One shared enumerate/sort/load/duplicate-check function, parameterized by folder path and Resource type, called by thin per-registry wrappers.
- A build-time validation tool, run separately from the game (manually or via CI), that checks duplicate ids and dangling `skill_id` references across both registries together.
- No literal logic duplication between `CompanionRegistry` and `EnemyRegistry`.

## Decision

Define a single `class_name DataRegistryLoader` static helper that both `CompanionRegistry` and `EnemyRegistry` call internally. Each registry becomes a thin wrapper: it knows its own folder path and Resource type, and delegates enumerate/sort/load/duplicate-check to the shared loader. The build-time validator is a separate `@tool`-annotated Godot editor script under `tools/`, run manually or via CI — **not** the same code path as the runtime loader — because it needs both registries loaded together to cross-validate `skill_id` references, something the runtime loader (which only ever sees one folder at a time) structurally cannot do.

### Architecture

```
                    ┌─────────────────────────┐
                    │   DataRegistryLoader     │   (class_name, static methods)
                    │   load_all(folder_path,  │
                    │            resource_type,│
                    │            validate_fn)  │
                    │     -> Dictionary        │   (id -> Resource instance)
                    └───────────┬─────────────┘
                     called by  │  called by
              ┌──────────────────┴──────────────────┐
              ▼                                       ▼
     ┌─────────────────┐                    ┌─────────────────┐
     │ CompanionRegistry │                   │  EnemyRegistry   │
     │ (Autoload)        │                   │  (Autoload)      │
     │ folder:            │                  │ folder:           │
     │  assets/data/       │                 │  assets/data/      │
     │  companions/         │                │  enemies/           │
     └─────────────────┘                    └─────────────────┘

                    ┌─────────────────────────┐
                    │  tools/validate_data.gd  │   (@tool script, NOT runtime path)
                    │  - loads BOTH registries │
                    │  - cross-checks skill_id │
                    │    against SkillRegistry │
                    │  - run manually / CI     │
                    └─────────────────────────┘
```

### Key Interfaces

```gdscript
# DataRegistryLoader (class_name, static utility — src/core/data_registry_loader.gd)
class_name DataRegistryLoader

static func load_all(
    folder_path: String,
    reject_if_invalid: Callable  # func(resource: Resource) -> bool — e.g. base_hp <= 0 check
) -> Dictionary:
    # 1. DirAccess.open(folder_path) — enumerate all .tres files
    # 2. Sort filenames ascending (String comparison)
    # 3. For each file in sorted order:
    #      load as Resource
    #      if reject_if_invalid.call(resource): push_error(...) and skip (not registered)
    #      if resource.id already in result: push_error("Duplicate id: ...") and skip
    #      else: result[resource.id] = resource
    # 4. return result   # id -> Resource, first-by-sort-order wins on duplicate
    pass

# CompanionRegistry (Autoload) — thin wrapper
extends Node
var _companions: Dictionary = {}

func _ready() -> void:
    _companions = DataRegistryLoader.load_all(
        "res://assets/data/companions/",
        func(r: CompanionData) -> bool: return r.base_hp <= 0
    )

func get_by_id(id: String) -> CompanionData:
    return _companions.get(id)

func get_all_ids() -> Array[String]:
    return _companions.keys()

# EnemyRegistry (Autoload) — identical shape, different folder + reject predicate
extends Node
var _enemies: Dictionary = {}

func _ready() -> void:
    _enemies = DataRegistryLoader.load_all(
        "res://assets/data/enemies/",
        func(r: EnemyData) -> bool: return r.base_hp <= 0
    )

func get_by_id(id: String) -> EnemyData:
    return _enemies.get(id)
```

### Implementation Guidelines

- `DataRegistryLoader.load_all()` is stateless and holds no data itself — it is a pure function from `(folder_path, reject predicate)` to a `Dictionary`. Each registry Autoload owns its own resulting `Dictionary` as instance state; the loader is not itself a singleton or Autoload.
- The `reject_if_invalid: Callable` parameter exists because the specific invalid-data condition differs per Resource type (`CompanionData.base_hp <= 0` vs. `EnemyData.base_hp <= 0` today — same field name coincidentally, but the utility must not hardcode `base_hp` since a future third registry, e.g. `#8 시너지` or narrative data, might reject on a different field or condition entirely). This keeps the shared utility genuinely shared rather than companion/enemy-specific with a enemy-only branch bolted on.
- Ascending filename sort must happen **before** load, not after — this is what makes "first-by-sort-order wins" a deterministic, platform-independent duplicate-resolution rule per both GDDs' explicit requirement (directory scan order is not portable between editor and web export).
- The build-time validator (`tools/validate_data.gd` or similar, `@tool`-annotated) is a **separate concern**, not a code path shared with the runtime loader:
  - It loads both `CompanionRegistry`'s and `EnemyRegistry`'s folders (via the same `DataRegistryLoader.load_all()`, reused for the enumerate/sort/load step — no duplication here either), plus the `SkillData` registry.
  - It then cross-validates every loaded `CompanionData.skill_id` / `EnemyData.skill_id` against the loaded `SkillData` set, flagging dangling references as build-time warnings.
  - It additionally re-confirms duplicate-id detection as a build-time warning (redundant with the runtime `push_error`, but useful as a pre-commit/CI gate that doesn't require running the game).
  - This tool is run manually or via CI — never invoked as part of normal game boot — because cross-registry validation requires both registries loaded together, which the runtime loader intentionally never does (each registry only ever loads its own folder, keeping runtime boot decoupled from the other registry's presence).

## Alternatives Considered

### Alternative 1: Each registry implements its own load/sort/duplicate-check independently

- **Description**: `CompanionRegistry` and `EnemyRegistry` each write their own enumerate → sort → load → duplicate-check logic inline, with no shared utility.
- **Pros**: No shared abstraction to design or agree on; each registry is fully self-contained and could diverge if one ever needs slightly different behavior.
- **Cons**: Exact duplicate logic per this project's DRY principle (`.claude/rules/ecc/common/coding-style.md`); any future third data-driven registry (e.g. if `#8 시너지` or narrative data ever need one) would be a third copy-paste of the identical enumerate/sort/load/duplicate-check sequence. Both GDDs already explicitly call for the shared-utility approach — this alternative would mean overriding both GDDs' stated intent for no compensating benefit.
- **Estimated Effort**: Nominally lower per-registry in isolation, but higher in aggregate the moment a third registry is added, and any bug fix to the shared logic (e.g. a sort-stability issue) would need to be applied twice and could silently drift out of sync.
- **Rejection Reason**: Both source GDDs already specify the shared-utility requirement explicitly; this alternative would need to override an explicit, already-agreed design decision with no new information justifying the reversal.

### Alternative 2: Fold build-time validation into the runtime loader (single code path)

- **Description**: Have `DataRegistryLoader.load_all()` itself perform the `skill_id` cross-reference check against a `SkillData` registry, at runtime, during normal game boot.
- **Pros**: One code path total, no separate `tools/` script to maintain.
- **Cons**: Requires the runtime loader for `CompanionRegistry` to know about `EnemyRegistry`'s existence (or a shared `SkillData` registry both depend on) purely to validate cross-references that have no bearing on gameplay correctness once the game has actually shipped with valid data — this couples registries together at runtime for a check that only matters at build/CI time, and slows down every game boot with a validation pass that should have already been caught before the build was made. It also means a dangling `skill_id` reference is only discovered by actually launching the game, rather than by CI on every commit.
- **Estimated Effort**: Slightly lower initially (no separate tool to write), but pushes a build-time concern into the runtime hot path indefinitely.
- **Rejection Reason**: Both GDDs explicitly call for the build-time tool to be "distinct from the runtime fallback" (`동료-데이터.md`/`적-데이터.md` Acceptance Criteria both separate "런타임 폴백" from "빌드 검증 도구"). Runtime should stay decoupled and fast; validation should happen before runtime ever sees the data.

## Consequences

### Positive

- `CompanionRegistry` and `EnemyRegistry` become thin, near-identical wrappers around one tested utility — a bug fix to sort/duplicate logic (e.g. discovering the ascending-sort comparator needs locale-independent byte comparison) is fixed once and applies to both.
- A future third data-driven registry (e.g. narrative data, `#8 시너지` config) can reuse `DataRegistryLoader.load_all()` immediately with zero new enumerate/sort/load logic — only a folder path and a reject predicate.
- The build-time validator is free to evolve independently (e.g. adding more cross-reference checks later) without touching the runtime loader's contract at all.

### Negative

- Introduces one more shared class (`DataRegistryLoader`) that both registries depend on — a bug in the shared utility affects both registries simultaneously rather than being isolated to one.
- The `Callable`-based `reject_if_invalid` parameter is a slightly more abstract interface than a hardcoded `base_hp` check would be — a future maintainer must read the call site to know what "invalid" means for a given registry, rather than finding it inline in the loader itself.

### Neutral

- Whether `DataRegistryLoader` is implemented as a `class_name` with static methods (chosen) versus an Autoload singleton with no state is a style choice with equivalent testability — static methods were chosen because the loader itself is stateless and doesn't need Autoload lifecycle/boot-order participation (unlike `CompanionRegistry`/`EnemyRegistry`, which do need Autoload status per ADR-0002's boot order).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A future registry's "invalid data" condition doesn't fit the single-predicate `reject_if_invalid: Callable` shape (e.g. needs multiple independent reject reasons with different log messages) | Low | Low — would require a small interface extension, not a redesign | `reject_if_invalid` can be extended to return a reason string instead of bool without breaking existing callers (empty string = valid) |
| The build-time validator and runtime loader's duplicate-id logic drift out of sync (e.g. one is updated, the other isn't) | Low | Medium — CI could pass while runtime silently discards duplicates differently, or vice versa | Both share the same `DataRegistryLoader.load_all()` for the enumerate/sort/load step, so duplicate-resolution logic itself cannot drift — only the validator's additional `skill_id` cross-check is unique to it |
| Sort comparator behaves differently between editor (desktop) and web export for non-ASCII filenames | Low | Medium — could reorder duplicate-id resolution unpredictably between platforms, the exact failure mode this ADR's sort requirement exists to prevent | MVP filenames are ASCII-only (`id`-based, e.g. `warrior_01.tres`); if non-ASCII filenames are ever introduced, this must be re-verified against Godot 4.6's `String` comparison behavior on both platforms |

## Performance Implications

N/A — no implementation exists yet.

## Migration Plan

N/A — no implementation exists yet. This is a greenfield contract for `CompanionRegistry`/`EnemyRegistry`, not a migration of existing duplicated code.

## Validation Criteria

- [ ] `CompanionRegistry` and `EnemyRegistry` both call `DataRegistryLoader.load_all()` — no independent enumerate/sort/load/duplicate-check logic exists in either registry's own source file.
- [ ] A unit test with two fixture `.tres` files sharing the same `id` confirms the sorted-first file is kept and the second is discarded with a logged error, for both `CompanionRegistry` and `EnemyRegistry`.
- [ ] The build-time validation tool (`tools/`) runs independently of game boot, loads both registries plus `SkillData`, and flags at least one intentionally-broken fixture (`skill_id` pointing to a non-existent `SkillData`) as a warning.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/동료-데이터.md` (line 82) | #10 동료 데이터 (TR-companion-data-003,004,005) | "`CompanionRegistry`는 ... 파일명 오름차순으로 정렬한 뒤 순서대로 로드한다 ... 동일한 로직 ... `#11 적 데이터`의 `EnemyRegistry`도 필요로 하므로, 공용 유틸리티 함수로 구현해 두 레지스트리가 공유한다" | `DataRegistryLoader.load_all()` is exactly this shared utility, called by both registries |
| `design/gdd/적-데이터.md` (line 58) | #11 적 데이터 (TR-enemy-data-002) | "`EnemyRegistry`는 `CompanionRegistry`와 동일한 로직(폴더 열거 → 파일명 오름차순 정렬 → 로드 → `id` 중복 검사)을 공용 유틸리티 함수로 공유한다 — 폴더 경로와 대상 타입만 다른 얇은 wrapper" | `EnemyRegistry` implemented as exactly this kind of thin wrapper over `DataRegistryLoader.load_all()` |
| `design/gdd/동료-데이터.md` (Acceptance Criteria #4) / `design/gdd/적-데이터.md` (Acceptance Criteria #9) | #10 / #11 | Build-time validation tool must catch duplicate ids and dangling `skill_id` references "before runtime," distinct from the runtime fallback | Separate `@tool`-annotated `tools/` script, run manually or via CI, not sharing the runtime loader's code path — loads both registries together to perform the cross-reference check neither registry can do alone |

## Related

- ADR-0002 (Autoload init order) — `CompanionRegistry`/`EnemyRegistry` are ordered as Autoloads there (positions 2-3); this ADR defines what happens inside their `_ready()`.
- ADR-0005 (RNG injection pattern) — independent; no shared concern.
