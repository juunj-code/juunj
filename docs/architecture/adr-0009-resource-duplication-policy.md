# ADR-0009: Resource Instance Duplication Policy (Aliasing Prevention)

## Status

Proposed

## Date

2026-07-26

## Last Verified

2026-07-26

## Decision Makers

architecture session (`/create-architecture`), Technical Director self-review (TD-ARCHITECTURE)

## Summary

Mandates `.duplicate()` before attaching any Resource-based "template/blueprint" (e.g. `StatusEffect`) as a runtime instance to a unit, to prevent Godot's Resource caching from silently sharing one instance across every unit that receives it. For `StatusEffect` specifically, shallow `duplicate()` is sufficient — not `duplicate_deep()` — because its schema has no nested Resource fields.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Resource system) |
| **Knowledge Risk** | MEDIUM — touches `Resource.duplicate()`/`duplicate_deep()` behavior. `duplicate_deep()` was added in Godot 4.5, a post-cutoff version relative to the LLM's ~4.3 training coverage, so its existence and exact semantics were verified against project engine references rather than assumed from training data. |
| **References Consulted** | `design/gdd/상태이상.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | `duplicate_deep()` is referenced/considered but **not adopted** in this decision — see Decision below for why shallow `duplicate()` is chosen instead. |
| **Verification Required** | If `StatusEffect`'s schema ever gains a nested `Resource`-typed field (e.g. a reference to another Resource object rather than a primitive/String), this decision must be re-evaluated — shallow `duplicate()` would then share the nested Resource by reference across copies, reintroducing the exact aliasing bug this ADR exists to prevent. |

> **Note**: Knowledge Risk is MEDIUM. This ADR must be re-validated if `StatusEffect`'s schema changes to add a nested Resource field, or if the project upgrades past Godot 4.6 and `duplicate()`/`duplicate_deep()` semantics change further.

### `duplicate()` vs. `duplicate_deep()` — verified conclusion

Per `docs/engine-reference/godot/breaking-changes.md`: `duplicate_deep()` was **added** in Godot 4.5 as "a new explicit method for deep duplication of nested resources." Per `docs/engine-reference/godot/current-best-practices.md`: "Old `duplicate()` behavior retained for backward compatibility... Use `duplicate_deep()` when you need per-instance copies of nested resources." Per `docs/engine-reference/godot/deprecated-apis.md`, the deprecation note ("`duplicate()` for nested resources` → `duplicate_deep()`, 4.5, Explicit deep copy control") applies specifically to the case where the duplicated Resource **contains other Resource-typed fields that also need independent copies**.

`StatusEffect`'s schema (per `design/gdd/상태이상.md`) is:
```gdscript
@export var id: String
@export var name: String
@export var type: String
@export var value: int = 0
@export var stat_target: String
@export var duration: int
```
Every field is a primitive (`String`, `int`) — **none is a nested `Resource` reference**. A shallow `duplicate()` copies all of these fields by value already (Godot's shallow duplicate always copies primitive/exported value-type fields; it only shares *nested Resource objects* by reference, which is precisely the case `duplicate_deep()` exists to solve). Since there is no nested Resource to alias, shallow `duplicate()` is sufficient for `StatusEffect` today. **This conclusion is schema-dependent, not permanent** — see Verification Required above.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Correct implementation of `#12 상태이상`'s `apply_effect()`; establishes the standing pattern any future "template → runtime instance" Resource usage (e.g. a hypothetical mutable `EquipmentData` or `SkillData` instance) must follow if that assumption ever changes |
| **Blocks** | `#12 상태이상` story implementation (`apply_effect()` specifically) |
| **Ordering Note** | No sequencing dependency on ADR-0006/0007/0008 — this is a standalone Resource-lifecycle rule, though it shares the "Resource is a shared-by-reference asset" concern that ADR-0007's schema conventions also touch on tangentially. |

## Context

### Problem Statement

Godot Resources loaded via `load()`/`preload()` are cached and shared by reference. If a `StatusEffect` blueprint Resource (e.g. `poison_basic.tres`) is attached directly to a unit without `.duplicate()`, every unit that receives "poison" shares the *same* Resource instance — decrementing one unit's `duration` field corrupts the shared blueprint and leaks the mutation into every other unit that also has "poison" active (and potentially into the original `.tres` asset itself, depending on caching scenario). This is a real bug class found during `#12 상태이상`'s design review, not a hypothetical concern.

### Current State

No code exists yet (`src/` is empty). `design/gdd/상태이상.md`'s Core Rule 1 already mandates `effect_resource.duplicate()` before attaching a runtime copy, and Acceptance Criterion 11 explicitly tests that duplicated instances don't cross-contaminate. This ADR formalizes that GDD-local fix as a project-wide Resource-lifecycle rule.

### Constraints

- Godot's Resource caching/sharing-by-reference behavior is an engine primitive, not something this project can opt out of — the mitigation must be applied at every attachment point, not centrally suppressed.
- `duplicate_deep()` exists (4.5+) but is unnecessary overhead/complexity for a schema with no nested Resource fields — using it anyway would be premature generalization for a problem `StatusEffect` doesn't have.
- The same aliasing risk is schema-shape-dependent: it applies to *any* Resource type that is (a) loaded from a shared registry/cache and (b) subsequently mutated in place after being handed to a consumer. It does not apply to Resource types that are always treated as read-only templates.

### Requirements

- `apply_effect()` (owned by `#12 상태이상`) must call `.duplicate()` on the `StatusEffect` blueprint before storing the resulting instance in a unit's `active_effects`, never assign the loaded Resource reference directly.
- This must be documented as a MANDATORY pattern for any future Resource-based "template → runtime instance" relationship project-wide, not scoped narrowly to `StatusEffect`.
- Existing read-only-by-convention Resource consumers (e.g. `#4 장비`'s `EquipmentDatabase`, which currently never mutates `EquipmentData` in place) must be flagged as "currently safe, re-check if this assumption changes" rather than silently assumed safe forever.

## Decision

Adopt `.duplicate()`-before-attach as a MANDATORY project-wide rule for **any** Resource-based "template/blueprint → runtime instance" pattern, not only `StatusEffect`. Any system that (a) loads a Resource from a shared registry/cache and (b) subsequently mutates a field on the resulting object after attaching it to a specific unit/entity must duplicate first. Systems that only ever read Resource fields without mutation (true read-only templates) are exempt — but any change that introduces in-place mutation to a previously-read-only Resource type must re-evaluate against this ADR before shipping.

**Concretely for `StatusEffect`**: `apply_effect(unit, effect_id)` must resolve `effect_id` to its `StatusEffect` Resource via the effect registry, then call `.duplicate()` (shallow — see verified conclusion above) on it before appending the result to the unit's `active_effects` array. The duplicated instance's `duration` (and any other field) can then be freely mutated per-unit without affecting the shared blueprint or any other unit's copy.

**Cross-reference to `#4 장비`'s `EquipmentDatabase`**: `EquipmentData` is currently read-only/never-mutated-in-place per its GDD — this aliasing risk does not currently apply to it. This is flagged explicitly as a rule to re-check if that assumption ever changes (e.g. if a future feature mutates an equipped item's stats in place rather than swapping to a new `EquipmentData` reference).

**`SkillData` note**: `SkillData` instances (read by both `CompanionData.skill_id` and `EnemyData.skill_id`, per ADR-0007) are likewise currently read-only templates — combat code reads `damage_multiplier`/`cost_sp`/etc. but does not mutate them per-unit. The same "re-check if this assumption ever changes" flag applies.

### Architecture

```
Shared Resource cache/registry (load()/preload())
        │
        │  StatusEffectRegistry.get("poison") → same cached instance every call
        ▼
┌───────────────────────────────────────────────────┐
│  apply_effect(unit, effect_id):                    │
│    var blueprint = StatusEffectRegistry.get(effect_id)
│    var instance = blueprint.duplicate()   ← REQUIRED
│    unit.active_effects.append(instance)            │
└───────────────────────────────────────────────────┘
        │
        ▼
Unit A's active_effects: [instance_A]  (duration mutated independently)
Unit B's active_effects: [instance_B]  (separate object, no cross-contamination)
Original poison.tres blueprint: unchanged
```

### Key Interfaces

```gdscript
# #12 상태이상 — apply_effect() MUST duplicate before attaching
func apply_effect(unit, effect_id: String) -> void:
    var blueprint: StatusEffect = StatusEffectRegistry.get(effect_id)
    if blueprint == null:
        push_warning("Unknown status effect id: %s" % effect_id)
        return
    # Shallow duplicate() is sufficient — StatusEffect has no nested Resource fields.
    var instance: StatusEffect = blueprint.duplicate()
    # Replace-not-stack policy (per StatusEffect GDD Core Rule 2):
    var existing_index := _find_active_effect_index(unit, effect_id)
    if existing_index != -1:
        unit.active_effects[existing_index] = instance
    else:
        unit.active_effects.append(instance)
```

### Implementation Guidelines

- Never assign a loaded/cached Resource reference directly into a per-unit mutable collection (`active_effects`, or any future equivalent) — always `.duplicate()` first at the attachment point.
- Do not reach for `duplicate_deep()` for `StatusEffect` — it is unnecessary given the schema has no nested Resource fields, and using it anyway would be premature generalization (YAGNI) for a cost this schema doesn't need to pay.
- If `StatusEffect`'s schema is ever revised to add a field referencing another `Resource` (e.g. a nested icon/config Resource rather than a `String` id), this decision must be re-opened — shallow `duplicate()` would then share that nested Resource by reference across all copies, exactly reproducing this ADR's original bug in a new location.
- Apply the same review lens to any new "blueprint → runtime instance" Resource pattern introduced later: ask "is this ever mutated after being read from a shared registry?" If yes, duplicate before attach.

## Alternatives Considered

### Alternative 1: Use `duplicate_deep()` unconditionally for all Resource attachments

- **Description**: Always call `duplicate_deep()` instead of `duplicate()` for any Resource being attached to a unit, regardless of whether the schema has nested Resources, as a defensive blanket policy.
- **Pros**: Future-proofs against schema changes that add nested Resource fields without needing to revisit this ADR.
- **Cons**: `duplicate_deep()` is a Godot 4.5+ API — using it unconditionally where shallow `duplicate()` already suffices is unrequested complexity (YAGNI) for a schema (`StatusEffect`) that has no nested Resources today, and it papers over the actual verification this ADR is supposed to do (confirming whether deep duplication is actually needed).
- **Estimated Effort**: Marginally higher runtime cost (deep duplication recurses through fields that don't need it) for no current benefit.
- **Rejection Reason**: Ponytail/YAGNI — the shallow `duplicate()` is proven sufficient for the current schema; the correct response to "the schema might change later" is documenting a Verification Required trigger (done above), not paying the deep-copy cost preemptively.

### Alternative 2: Redesign `StatusEffect` as a plain Dictionary/struct instead of a Resource

- **Description**: Avoid the Resource-caching aliasing problem entirely by not using `Resource` for `StatusEffect` — use a plain GDScript class or Dictionary that is naturally value-like/always freshly constructed.
- **Pros**: Sidesteps the aliasing bug class structurally rather than requiring every call site to remember `.duplicate()`.
- **Cons**: Loses `Resource`'s built-in editor integration (`.tres` authoring, inspector editing, `ResourceLoader` caching for the *blueprint* lookup itself), and contradicts the project-wide convention (ADR-0007) that all data schemas are `Resource`-based for consistency with `CompanionData`/`EnemyData`/`SkillData`.
- **Estimated Effort**: Higher — would require re-authoring the schema and its `.tres` assets, and breaks consistency with ADR-0007's established Resource conventions.
- **Rejection Reason**: The GDD explicitly designs `StatusEffect` as a Resource blueprint intentionally (for `.tres` authoring); the aliasing problem has a well-known, cheap, one-line fix (`.duplicate()`) that doesn't require abandoning the Resource pattern project-wide.

## Consequences

### Positive

- Prevents a proven, real aliasing bug (shared mutable state across units and potentially the original asset) with a one-line fix at each attachment point.
- Establishes a general project-wide pattern ("duplicate before mutating a shared-registry Resource") that future systems can check against without rediscovering the bug themselves.
- Explicitly documents why shallow `duplicate()` (not `duplicate_deep()`) is correct for `StatusEffect` today, with a concrete re-check trigger, avoiding both under-protection (no duplicate at all) and over-engineering (deep duplication nobody needs yet).

### Negative

- Every future Resource schema addition must be manually reviewed against "does this get mutated after being read from a shared registry?" — there's no automated enforcement (e.g. a linter can't easily catch "forgot to call `.duplicate()`" the way a type checker catches a type error).
- If `StatusEffect`'s schema changes to add a nested Resource field without anyone remembering to re-check this ADR, the aliasing bug could silently reappear in a new form.

### Neutral

- No measurable runtime cost difference from this decision alone, since shallow `duplicate()` is already the minimal necessary operation for the current schema.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A future contributor attaches a `StatusEffect` (or any registry-sourced Resource) directly without `.duplicate()`, reintroducing aliasing | Medium | High — silent cross-unit state corruption, hard to debug (looks like a totally unrelated unit's poison duration changing) | GDD Acceptance Criterion 11 (`상태이상.md`) is a required regression test; this ADR is the standing reference for code review |
| `StatusEffect` schema gains a nested Resource field later and shallow `duplicate()` silently becomes insufficient | Low (MVP schema is simple) | High — reintroduces this exact bug in a new form | Verification Required section above flags this explicitly; must be checked whenever `StatusEffect`'s fields change |
| `EquipmentData`/`SkillData`'s "currently read-only" assumption is broken by a future feature without revisiting this ADR | Low | Medium — same aliasing bug class in a different system | Explicitly flagged in Decision section as a re-check trigger for both systems |

## Performance Implications

N/A — no implementation exists yet.

## Migration Plan

N/A — no implementation exists yet.

## Validation Criteria

- [ ] `apply_effect()` always calls `.duplicate()` on the resolved `StatusEffect` blueprint before appending/replacing it in `active_effects` — verified by GDD Acceptance Criterion 11 (two units receiving the same blueprint, one unit's duration mutates, the other's and the original `.tres` do not).
- [ ] No call site anywhere assigns a `StatusEffectRegistry.get(...)` result directly into a mutable per-unit collection without an intervening `.duplicate()`.
- [ ] `duplicate_deep()` is NOT used for `StatusEffect` (shallow `duplicate()` confirmed sufficient given no nested Resource fields).

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/상태이상.md` | #12 상태이상 | "`apply_effect()`는 반드시 `effect_resource.duplicate()`로 새 인스턴스를 생성한 뒤 저장해야 한다" (Core Rule 1) | Formalizes this as the MANDATORY project-wide duplication policy, with the shallow-vs-deep decision made explicit |
| `design/gdd/상태이상.md` | #12 상태이상 | Acceptance Criterion 11 — "동일한 `poison` 블루프린트를 유닛 A와 유닛 B에게 각각 적용 ... A의 인스턴스만 duration 감소 ... B와 원본 `.tres`는 영향받지 않음" | This ADR's Validation Criteria adopt AC 11 directly as the regression test for the duplication policy |

## Related

- ADR-0007 (Resource Schema & Build-Time Validation) — establishes that all data schemas including `StatusEffect` are `class_name X extends Resource`; this ADR governs how instances of those schemas are safely mutated at runtime once loaded.
- `#4 장비`'s `EquipmentDatabase` — flagged as currently exempt (read-only usage) but subject to re-check if `EquipmentData` is ever mutated in place.
