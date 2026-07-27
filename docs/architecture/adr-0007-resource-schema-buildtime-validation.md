# ADR-0007: Resource Data Schema Conventions & Build-Time Static Validation

## Status

Accepted

## Date

2026-07-26

## Last Verified

2026-07-27 (Accepted after `/architecture-review` — dependency direction fixed (no longer depends on ADR-0006) during that review, no other unresolved verification items)

## Decision Makers

architecture session (`/create-architecture`), Technical Director self-review (TD-ARCHITECTURE)

## Summary

Standardizes the shape every `Resource`-based data schema (`CompanionData`, `SkillData`, `EnemyData`, `StatusEffect`) must follow — typed `@export` fields, native `Color` for color fields, and a single validation-severity policy (`base_hp ≤ 0` rejects the resource, all other out-of-range stats warn-only) — and specifies a build-time static validation tool that catches duplicate IDs, dangling `skill_id` references, and out-of-range `damage_multiplier` values before runtime.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (data/Resource system) |
| **Knowledge Risk** | LOW — `Resource`, `@export`, `class_name`, `push_error`/`push_warning`, and `Color` are stable pre-4.3 APIs, well within training-data coverage. No post-cutoff API surface involved. |
| **References Consulted** | `design/gdd/동료-데이터.md`, `design/gdd/적-데이터.md`, `design/gdd/상태이상.md`, `design/gdd/전투-공식.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — standard `Resource`/`@export` behavior confirmed stable across 4.3-4.6 in `docs/engine-reference/godot/breaking-changes.md` (no entries touch `@export` typing or `push_error`/`push_warning`). |

> **Note**: Knowledge Risk is LOW; no re-validation trigger tied to engine upgrades.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Implementation of `CompanionData`, `SkillData`, `EnemyData`, `StatusEffect` `.gd` classes and their `.tres` assets; Story work for `#10 동료 데이터` and `#11 적 데이터` |
| **Blocks** | Any story that creates or loads `.tres` Resource data files (all Foundation-layer data stories) |
| **Ordering Note** | Must be Accepted before ADR-0006's registries can be implemented against real schemas, since the registries load these exact Resource types. |

## Context

### Problem Statement

Three separate GDDs (`동료-데이터`, `적-데이터`, `상태이상`) each define a `Resource`-based data schema with overlapping conventions (typed IDs, stat ranges, a color field, a shared `SkillData` type used by two different owners). Without a single ADR pinning the conventions, each schema risks drifting independently — e.g. one class using a hex-string color while another uses `Color`, or one schema clamping bad stats while another rejects them. The GDD review process already caught one such drift (a hex-string `color_accent` field was corrected to native `Color` during `#10`'s design review) and one real balance bug (an enemy skill `damage_multiplier` of up to 3.0 produces a 70-damage hit against a 60-HP companion — a proven instakill, fixed by capping enemy-skill multipliers at 1.4). Both fixes must be locked in as project-wide rules, not left as tribal knowledge in two GDD files, or the same class of bug will reappear the next time someone adds a Resource schema.

### Current State

No code exists yet (`src/` is empty). No ADR currently governs Resource schema shape or data validation. The GDDs describe the schemas and validation policy in prose; nothing enforces it mechanically before this ADR.

### Constraints

- Godot's typed `String` cannot represent `null` — schemas use `""` sentinel per Architecture Principle 5.
- `SkillData` is shared between `CompanionData.skill_id` and `EnemyData.skill_id` — it cannot carry asymmetric validation rules itself; the *severity* of a rule can differ per consumer (companion vs. enemy) even though the schema is one class.
- The validation tool must run before runtime (build-time / CI), per `.claude/docs/coding-standards.md`'s requirement that gameplay values be data-driven and verifiable, and per the project's `godot --headless` CI pattern.
- No implementation exists yet — this ADR is Foundation-layer and gates all data-driven stories per `docs/CLAUDE.md`'s ADR lifecycle rule.

### Requirements

- `CompanionData`, `SkillData`, `EnemyData`, `StatusEffect` must all be `class_name X extends Resource` with fully typed `@export` fields — no untyped `Variant`.
- Any color field must be native `Color`, never a hex string.
- `base_hp ≤ 0` must reject the resource at load time (`push_error`, not registered) for both `CompanionData` and `EnemyData` — never clamped, never silently accepted.
- Every other out-of-range stat (`base_atk`/`base_def`/`base_spd`, and `SkillData`'s `damage_multiplier`/`heal_multiplier`/`cost_sp`) must warn-only (`push_warning`) and load with the value unchanged — never clamped, never rejected.
- A build-time static validation tool must catch, before runtime: duplicate `id`s within a data folder, dangling `skill_id` references from `EnemyData`/`CompanionData` into the `SkillData` registry, and `damage_multiplier` values outside the applicable range (0.5-3.0 general / 0.5-1.4 for enemy-referenced `SkillData` specifically).

## Decision

Adopt two project-wide standing rules, both binding on every current and future Resource-based data schema:

**1. Resource Schema Conventions (applies to any `#10`/`#11`/`#12`-style data class):**
- `class_name X extends Resource`, never a plain `Resource` instance built ad hoc.
- Every field is a typed `@export var name: Type` — no untyped `Variant`, no dynamically-typed fields.
- Any field representing a color uses the native `Color` type (e.g. `@export var color_accent: Color`), never a hex string or int-packed representation. Consumers read `Color` directly; no parsing/fallback logic is duplicated per consumer.
- **Validation severity asymmetry is the standard policy**: any field documented as "crash-class" (currently: `base_hp ≤ 0`, because it causes an unwinnable/broken combat state) is load-rejecting — `push_error()` and the resource is not registered. Every other out-of-range value (any other stat, any multiplier/cost field) is warn-only — `push_warning()` and the value loads unchanged, no clamping. This asymmetry must be preserved consistently for every future stat-bearing Resource schema; a new schema does not get to invent a third severity tier without a new ADR.

**2. Build-Time Static Validation Tool** (builds on ADR-0006's shared registry/folder-enumeration utility — see ADR Dependencies):
A standalone script (invoked via `godot --headless --script tools/validate_data.gd` or equivalent, run in CI per `.claude/docs/coding-standards.md`) that, before any runtime load, checks across `assets/data/companions/`, `assets/data/enemies/`, `assets/data/skills/`, `assets/data/status_effects/`:
- **Duplicate ID detection**: any two `.tres` files in the same folder sharing an `id` field is a warning (registry itself already handles this at runtime per ADR-0006 with sorted-first-wins; the build tool exists to catch it *before* a runtime warning is the only signal).
- **Dangling reference detection**: every `CompanionData.skill_id` / `EnemyData.skill_id` must resolve to an existing `SkillData.id` in the skills registry; every `unlock_condition_id` reference (future `#9`) follows the same pattern.
- **Range violation detection specific to the instakill fix**: any `SkillData` referenced by an `EnemyData.skill_id` must have `damage_multiplier` within **0.5-1.4** (not the general companion range of 0.5-3.0). This is the direct fix for the provable instakill (`floor(25 × 3.0) − 5 = 70` against a 60-HP companion) found during `#11 적-데이터`'s design review — the build tool enforcing this is regression prevention, not general hygiene.

### Architecture

```
Build/CI step (before runtime)
┌─────────────────────────────────────────────┐
│ validate_data.gd (headless script)           │
│  ├─ uses ADR-0006 shared folder-enumeration  │
│  │  utility (read-only, no registration)     │
│  ├─ Check 1: duplicate id within folder      │
│  ├─ Check 2: dangling skill_id references    │
│  └─ Check 3: enemy-skill damage_multiplier   │
│              outside 0.5-1.4                 │
└─────────────────────────────────────────────┘
        │ warnings (non-blocking, MVP)
        ▼
Runtime (CompanionRegistry / EnemyRegistry, ADR-0006)
  base_hp ≤ 0            → push_error, reject, do not register
  other out-of-range stat → push_warning, load as-is
```

### Key Interfaces

```gdscript
# CompanionData.gd
class_name CompanionData
extends Resource

@export var id: String
@export var name: String
@export var description: String
@export var class_type: String
@export var portrait_id: String
@export var color_accent: Color        # native Color, never hex string
@export var base_hp: int                # ≤0 → reject at load (push_error)
@export var base_atk: int               # out-of-range → push_warning only
@export var base_def: int
@export var base_spd: int
@export var skill_id: String
@export var is_hidden: bool = false
@export var unlock_condition_id: String

# SkillData.gd — shared by CompanionData and EnemyData
class_name SkillData
extends Resource

@export var id: String
@export var name: String
@export var description: String
@export var target_type: String = "enemy"
@export var damage_multiplier: float = 1.0   # 0.5-3.0 general; 0.5-1.4 when referenced by EnemyData
@export var heal_multiplier: float = 0.0
@export var effect_id: String
@export var cost_sp: int = 0

# EnemyData.gd
class_name EnemyData
extends Resource

@export var id: String
@export var name: String
@export var sprite_id: String
@export var base_hp: int                # ≤0 → reject at load (push_error)
@export var base_atk: int
@export var base_def: int
@export var base_spd: int
@export var skill_id: String            # referenced SkillData.damage_multiplier capped at 1.4
@export var is_boss: bool = false

# StatusEffect.gd
class_name StatusEffect
extends Resource

@export var id: String
@export var name: String
@export var type: String
@export var value: int = 0
@export var stat_target: String
@export var duration: int
```

### Implementation Guidelines

- Do not add a schema-specific severity tier without amending this ADR — any new stat-bearing Resource follows base_hp-style-field-rejects / everything-else-warns.
- The build-time tool is read-only against the data folders — it must not mutate or register resources; that remains ADR-0006's registries' job at runtime.
- The enemy-skill `damage_multiplier` cap (1.4) is enforced only for `SkillData` instances reachable via `EnemyData.skill_id` — the same `SkillData` class reachable via `CompanionData.skill_id` is validated against the wider 0.5-3.0 range. The validator must trace the reference direction (enemy vs. companion) before applying the range check, not validate `SkillData` in isolation.

## Alternatives Considered

### Alternative 1: Runtime-only validation (no build-time tool)

- **Description**: Rely entirely on `CompanionRegistry`/`EnemyRegistry`'s runtime `push_error`/`push_warning` calls at game boot; no separate static tool.
- **Pros**: Less tooling to build and maintain; one less script to keep in sync with schema changes.
- **Cons**: Bad data is only caught when someone actually boots the game with that data loaded — CI can't gate a PR on it, and a broken `.tres` can sit unnoticed until a manual playtest.
- **Estimated Effort**: Lower short-term, higher long-term (bugs surface later, cost more to trace).
- **Rejection Reason**: The instakill bug this ADR exists to prevent was found through design review, not runtime testing — a build-time gate is exactly the mechanism that would have caught it automatically and repeatedly for every future data entry.

### Alternative 2: Clamp out-of-range stats instead of warn-only

- **Description**: Silently clamp any stat outside its documented range to the nearest valid bound, for all fields including `base_hp`.
- **Pros**: Game never crashes on bad data; no rejected resources.
- **Cons**: Masks designer error — a `base_hp` of `-10` clamped to `1` still produces a barely-alive unit that is functionally broken, and clamping other stats prevents intentional out-of-range testing the GDDs explicitly want to allow.
- **Estimated Effort**: Comparable.
- **Rejection Reason**: GDDs explicitly reject clamping ("디자이너가 범위 외 값을 의도적으로 테스트할 수 있어야 함") for non-crash-class stats, and `base_hp ≤ 0` is defined as crash-class specifically because it is not a tunable-range problem.

## Consequences

### Positive

- One documented severity policy prevents each new Resource schema from re-deciding (and possibly getting wrong) how to handle bad data.
- The proven instakill bug class gets a permanent, automated regression check instead of relying on manual design review to catch it again.
- Native `Color` usage removes an entire class of hex-parsing bugs/fallback duplication across every consumer of `color_accent`.

### Negative

- An extra build/CI step (the validation script) must be written, maintained, and kept in sync whenever a new Resource schema or reference relationship is added.
- Enemy-skill `damage_multiplier` is now a narrower, asymmetric range from companion skills despite sharing one `SkillData` class — this is a deliberate constraint that must be documented clearly wherever `SkillData` is touched, or a future contributor may "fix" the asymmetry thinking it's a bug.

### Neutral

- The validation tool is static/offline — it does not affect runtime performance since no implementation exists yet to measure against.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Future schema author adds a new stat-bearing Resource without following the base_hp-rejects/others-warn asymmetry | Medium | Medium — reintroduces inconsistent crash handling | This ADR is the required reference point; code review checklist should cite ADR-0007 for any new `Resource` subclass |
| Build-time tool drifts out of sync with schema changes (new field added, validator not updated) | Medium | Medium — silent gap in coverage | Tool should be extended in the same PR that adds a new schema field; treat as part of Definition of Done for schema changes |
| Enemy vs. companion `SkillData` range asymmetry is missed by a future story that generates enemy skill data via companion-authoring tooling | Low | High — reintroduces the instakill bug | Build-time tool is the primary safeguard; this ADR documents the exact bug and formula as a permanent reference |

## Performance Implications

N/A — no implementation exists yet.

## Migration Plan

N/A — no implementation exists yet.

## Validation Criteria

- [ ] `CompanionData`, `SkillData`, `EnemyData`, `StatusEffect` are implemented as `class_name X extends Resource` with fully typed `@export` fields, no `Variant`.
- [ ] `color_accent` is a native `Color` field with no hex-string parsing anywhere in the codebase.
- [ ] Loading a `CompanionData` or `EnemyData` with `base_hp ≤ 0` produces exactly one `push_error` and the resource is absent from the registry's registered set.
- [ ] Loading any other out-of-range stat produces exactly one `push_warning` and the value is retained unchanged (no clamping).
- [ ] Build-time validation tool flags: duplicate IDs, dangling `skill_id` references, and enemy-referenced `damage_multiplier` values outside 0.5-1.4.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/동료-데이터.md` | #10 동료 데이터 | "네이티브 Color 타입 사용 (hex 문자열 금지 — 소비 시스템마다 파싱/폴백을 재구현하지 않도록)" | Establishes native `Color` as the project-wide rule for any color field, not just `color_accent` |
| `design/gdd/동료-데이터.md` | #10 동료 데이터 | "`base_hp`가 0 이하인 경우 ... 로드하지 않는다" | Codifies base_hp-rejects/others-warn as standing policy, applied identically to `EnemyData` |
| `design/gdd/동료-데이터.md` | #10 동료 데이터 | "빌드 검증 도구가 이를 경고로 잡아야 한다" (duplicate id, dangling skill_id) | Specifies the build-time validation tool and its three checks |
| `design/gdd/적-데이터.md` | #11 적 데이터 | "적 스킬(`target_type=\"enemy\"`)의 `damage_multiplier` 유효 범위: 0.5~1.4" | Build-time tool enforces this narrower range specifically for enemy-referenced `SkillData` |
| `design/gdd/적-데이터.md` | #11 적 데이터 | "이 범위 위반은 빌드 검증 도구가 경고로 잡아야 한다" | Same validation tool, same enforcement point |
| `design/gdd/상태이상.md` | #12 상태이상 | `StatusEffect extends Resource` schema definition | Schema follows the same typed-`@export` convention established here |

## Related

- ADR-0006 (Data Registry Shared Utility) — this ADR's build-time tool is a static sibling of that ADR's runtime `CompanionRegistry`/`EnemyRegistry` shared folder-enumeration logic.
- ADR-0008 (Combat Formula Float/Sort Stability) — shares the same "recurring bug found during review → codify as standing rule" pattern, applied to a different bug class.
- `.claude/docs/coding-standards.md` — worked-damage-example rule is a sibling precedent from the same review process (see ADR-0008 for the direct cross-reference).
