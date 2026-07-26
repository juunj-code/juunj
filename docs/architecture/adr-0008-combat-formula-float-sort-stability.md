# ADR-0008: Combat Formula Float Precision & Array Sort Stability Rules

## Status

Proposed

## Date

2026-07-26

## Last Verified

2026-07-26

## Decision Makers

architecture session (`/create-architecture`), Technical Director self-review (TD-ARCHITECTURE)

## Summary

Codifies three GDScript/Godot correctness facts — `floori()` must replace `floor()` for int-typed damage math, an epsilon guard is required against float precision loss, and `Array.sort_custom()` is not stable so turn/target ordering needs an explicit secondary key — as MANDATORY project-wide coding rules, because the same bug class was independently rediscovered twice already (`#6 전투-공식`'s turn order and `#7 적-AI`'s targeting).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Scripting / GDScript language semantics) |
| **Knowledge Risk** | LOW — these are GDScript/math correctness facts already empirically discovered and fixed during this project's own design review (documented in `design/gdd/전투-공식.md` and `design/gdd/적-AI.md`), not post-cutoff engine API risk. `floori()` exists since Godot 4.2 and `Array.sort()`/`sort_custom()` instability is a documented, stable behavior across 4.x — neither depends on 4.4/4.5/4.6 changes. |
| **References Consulted** | `design/gdd/전투-공식.md`, `design/gdd/적-AI.md`, `.claude/docs/coding-standards.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — `floori()` and `Array.sort_custom()` behavior confirmed unchanged across 4.3-4.6 in `docs/engine-reference/godot/breaking-changes.md` and `deprecated-apis.md` (no entries touch integer division/rounding builtins or `Array.sort`). |

> **Note**: Knowledge Risk is LOW; no re-validation trigger tied to engine upgrades. This ADR concerns language-level math/sort semantics, not engine surface area.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Correct implementation of `CombatFormula.skill_damage()`, `CombatFormula.turn_order()`, and `EnemyAI`'s targeting reduce/scan logic. Any future system doing integer damage math or Godot `Array` sorting should check against this ADR first. |
| **Blocks** | `#1 턴제 전투`, `#6 전투 공식`, `#7 적 AI` story implementation |
| **Ordering Note** | No sequencing dependency on other ADRs — this is a standalone language-correctness rule that any Core/Feature layer story can reference independently. |

## Context

### Problem Statement

Godot's GDScript has two correctness traps that are easy to miss and were each found *twice, independently* during this project's own design review process — a strong signal they will recur in new code if not made an explicit standing rule rather than a fact buried in two GDD files:

1. `floor()` returns `float`, not `int`. Assigning its result toward an `int current_hp` field either requires an implicit/explicit cast or silently produces type friction. `floori()` (Godot 4.2+) returns `int` directly and is the correct choice for damage math.
2. Even `floori()` is not enough on its own — float precision error can make a value like `25 * 1.16` evaluate to `28.999999999999996` instead of `29.0`, so a naive `floori(atk * multiplier)` silently under-deals damage by 1. An epsilon guard (`+ 0.0001`) is required.
3. `Array.sort()`/`sort_custom()` in Godot is not a stable sort — equal-key elements' relative order is not guaranteed. `#6 전투-공식`'s turn-order-by-speed sort needs an explicit secondary key (party index) so "companions go first on speed ties" doesn't silently break under an unstable sort. The exact same bug class was independently rediscovered in `#7 적-AI`'s targeting logic (needing a tie-break by party index / HP when comparing candidates).

### Current State

No code exists yet (`src/` is empty). The GDDs (`전투-공식.md`, `적-AI.md`) already document the bugs, the fixes, and worked corrections in prose (dated 2026-07-26 revisions), but nothing in the codebase or ADR set yet makes these MANDATORY rules that apply beyond the two systems that happened to discover them.

### Constraints

- Damage/HP fields are typed `int` project-wide (Architecture Principle: pure functions, deterministic — `#6 전투 공식`).
- The turn-order tie-break rule ("동료 우선" / companions before enemies on equal speed) is a GDD-mandated behavior, not just an implementation nicety — if the sort silently drops it, a design requirement is violated invisibly.
- `#7 적 AI`'s targeting only needs the single best/worst candidate (not a full sort), so its fix takes a different but related shape (linear scan/reduce instead of a sort with a tie-break comparator).

### Requirements

- All int-typed damage/HP calculations must use `floori()`, never bare `floor()`.
- Any float multiplication feeding into `floori()` for damage math must include an epsilon guard (`+ 0.0001`) to absorb float precision loss.
- Any code sorting units by a numeric key where ties must resolve deterministically (turn order by speed, target selection by HP/ATK) must use an explicit secondary key in the comparator, or avoid `sort_custom()` entirely in favor of a linear scan when only an extremum is needed.

## Decision

Formalize all three facts as MANDATORY project-wide GDScript coding rules — not facts local to `#6`/`#7` — and make this ADR the authoritative reference any future system doing integer damage math or Godot `Array` sorting must check against. The same bug class recurring twice already (turn order in `#6`, targeting in `#7`) is treated as proof it will recur again in new code without a standing rule.

**Rule 1 — `floori()` over `floor()`**: Any expression whose result is assigned to, compared against, or otherwise consumed as an `int` (HP, damage, stat values) must use `floori()`. Bare `floor()` returning `float` into an `int`-typed context is forbidden.

**Rule 2 — Epsilon guard on multiplier math**: Any `floori(x * multiplier)` pattern where `multiplier` is a `float` (e.g. `damage_multiplier`) must be written as `floori(x * multiplier + 0.0001)` to absorb float precision loss. This applies to every current and future skill/damage formula that multiplies an int stat by a float multiplier.

**Rule 3 — Explicit secondary sort key, or avoid sorting**: Any comparator passed to `Array.sort_custom()` where ties must resolve deterministically must include an explicit secondary (tie-break) key — never rely on `Array.sort()`/`sort_custom()`'s incidental ordering of equal elements. Where only a single extremum (min/max) is needed rather than a full ordering (e.g. AI target selection), prefer a linear scan/reduce over sorting — this sidesteps the instability question entirely rather than requiring a tie-break comparator.

This ADR also cross-references a sibling "recurring bug class → codified rule" precedent already in `.claude/docs/coding-standards.md`: the rule that worked damage examples must use the skill formula (`floor(atk*multiplier)-def`), not the basic-attack formula (`atk-def`), when justifying survivability/threat claims — found independently across `동료-데이터`/`적-데이터`/`전투-공식`/`적-AI`/`상태이상` during the same review process. Both this ADR and that coding-standards rule exist because the project's review process found the *same class* of "looks right, is subtly wrong" bug more than once; both are now standing, checkable rules rather than one-off fixes.

### Architecture

```
Any system computing int damage from (atk: int, multiplier: float, def: int)
        │
        ▼
  floori(atk * multiplier + 0.0001) - def   ← Rule 1 (floori) + Rule 2 (epsilon)
        │
        ▼
  max(1, result)                             ← existing "no full nullification" rule (#6)


Any system ordering units where ties matter (turn order, targeting)
        │
        ├─ full ordering needed? ──► sort_custom() WITH explicit secondary key   ← Rule 3a
        │                             (e.g. turn_order: spd desc, then party_index asc)
        │
        └─ single best/worst needed? ──► linear scan/reduce, no sort at all     ← Rule 3b
                                          (e.g. #7 적 AI targeting)
```

### Key Interfaces

```gdscript
# Rule 1 + Rule 2: correct int damage formula pattern
static func skill_damage(atk: int, multiplier: float, defense: int) -> int:
    return max(1, floori(atk * multiplier + 0.0001) - defense)

# Rule 3a: correct turn-order pattern — explicit secondary key, real GDScript
# ternary syntax is `value if cond else other`, NOT C-style `?:`
static func turn_order(units: Array) -> Array:
    var sorted_units := units.duplicate()
    sorted_units.sort_custom(func(a, b):
        return (a.spd > b.spd) if a.spd != b.spd else (a.party_index < b.party_index)
    )
    return sorted_units

# Rule 3b: correct targeting pattern (#7 적 AI) — linear scan, no sort needed
# since only the single best candidate is required
static func pick_lowest_hp_target(candidates: Array) -> Variant:
    var best = null
    for c in candidates:
        if best == null or c.current_hp < best.current_hp \
           or (c.current_hp == best.current_hp and c.party_index < best.party_index):
            best = c
    return best
```

### Implementation Guidelines

- Never use bare `floor()` where the result feeds an `int`-typed field or comparison — this is a project-wide lint-checkable rule, not a per-system judgment call.
- Any new formula multiplying an int stat by a float multiplier must include the `+ 0.0001` epsilon guard; do not assume documented discrete tier values (e.g. 1.0/1.2/1.4/1.5/1.8/2.0/2.5, per `전투-공식.md`) are exempt just because they "look safe" — the guard is unconditional.
- Before writing any `sort_custom()` call, ask whether only a single extremum is actually needed. If so, use a linear scan (Rule 3b) — it sidesteps stability concerns entirely and is simpler than a tie-break comparator.
- If a full ordering is genuinely required (turn order across all combatants), the comparator's tie-break key must be documented in the same function (see `turn_order()` above) — do not scatter the tie-break rationale in a comment elsewhere.

## Alternatives Considered

### Alternative 1: Fix each occurrence locally, no standing ADR

- **Description**: Let `#6`'s turn order and `#7`'s targeting each carry their own fix in their own GDD, without a project-wide rule.
- **Pros**: No additional ADR to maintain; each system's GDD is already self-contained.
- **Cons**: The bug class was already found twice independently without a standing rule in place — nothing stops a third system (or a future revision of `#6`/`#7`) from reintroducing it, since there's no single place a new contributor is pointed to.
- **Estimated Effort**: Lower short-term.
- **Rejection Reason**: Two independent rediscoveries of the same bug class is precisely the signal that a local fix is insufficient — the task brief for this ADR explicitly treats this as project-wide-rule-worthy, not GDD-local.

### Alternative 2: Use a stable sort implementation (custom merge sort) instead of tie-break keys

- **Description**: Implement or import a stable sort so `sort_custom()`'s ties preserve insertion order without needing an explicit secondary key.
- **Pros**: Comparator code becomes marginally simpler (no explicit tie-break needed).
- **Cons**: Godot's built-in `Array.sort()`/`sort_custom()` is not stable and there is no built-in stable-sort alternative in GDScript; writing and maintaining a custom stable sort is meaningfully more code than an explicit secondary key, for equivalent behavior. It also doesn't help `#7`'s single-extremum case at all (Rule 3b), which needs no sort in the first place.
- **Estimated Effort**: Higher (custom sort implementation + testing) for less benefit than a one-line secondary key.
- **Rejection Reason**: YAGNI — an explicit secondary key is the minimum code that reliably fixes the actual problem; a custom stable sort is unrequested generality.

## Consequences

### Positive

- One documented, checkable rule prevents the same "found twice already" bug class from recurring a third time in new combat/AI code.
- The epsilon-guard fix removes a subtle, hard-to-notice off-by-one damage bug that would otherwise silently under-deal damage in specific multiplier/atk combinations.
- Explicit tie-break keys make turn order and targeting fully deterministic and testable (supports Architecture Principle 3: formulas as pure, deterministic functions).

### Negative

- Every comparator involving a numeric sort now carries slightly more code (the tie-break clause) than a naive single-key comparator would.
- Contributors must remember to apply the epsilon guard on any *new* float-multiplier formula, not just the two documented in `전투-공식.md` — the rule generalizes beyond the current known instances.

### Neutral

- No behavior changes to existing shipped features since no implementation exists yet — this ADR fixes the pattern before first implementation, at zero migration cost.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A future formula multiplies floats without the epsilon guard because the author doesn't know the rule | Medium | Medium — silent 1-point damage underdelivery, hard to notice in playtesting | This ADR is the standing reference; code review checklist should cite ADR-0008 for any new float-multiplier damage formula |
| A future sort introduces ties without a secondary key because `sort_custom()`'s default behavior looks fine in ad-hoc testing (small arrays often appear ordered) | Medium | Medium — silently breaks a documented tie-break rule (e.g. "companions go first") | Unit tests per Acceptance Criteria in `전투-공식.md`/`적-AI.md` explicitly test tie cases with fixed inputs |
| Someone "fixes" the epsilon guard away later, believing `28.999999999999996` was a one-off | Low | Medium — reintroduces the exact bug this ADR documents | This ADR + `전투-공식.md`'s worked example (`atk=25, multiplier=1.16`) stands as the permanent regression reference |

## Performance Implications

N/A — no implementation exists yet.

## Migration Plan

N/A — no implementation exists yet.

## Validation Criteria

- [ ] `CombatFormula.skill_damage()` uses `floori(atk * multiplier + 0.0001) - defense`, verified against the documented regression case (`atk=25, multiplier=1.16` → 29, not 28).
- [ ] `CombatFormula.turn_order()` produces "companions before enemies" on exact speed ties, verified by a unit test with fixed equal-speed inputs (per `전투-공식.md` AC 5).
- [ ] `EnemyAI` targeting logic uses a linear scan (not `sort_custom()`) for single-extremum selection, or if sorting, includes an explicit tie-break key.
- [ ] No bare `floor()` call exists anywhere feeding an `int`-typed damage/HP value.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/전투-공식.md` | #6 전투 공식 | "GDScript의 `floor()`는 `float`를 반환하므로 ... `floori()`를 대신 사용한다" | Rule 1 codifies `floori()` as mandatory project-wide, not just for `skill_damage()` |
| `design/gdd/전투-공식.md` | #6 전투 공식 | "`atk=25, multiplier=1.16` ... `28.999999999999996` ... `+ 0.0001` 엡실론 가드로 흡수" | Rule 2 codifies the epsilon guard as mandatory for any future float-multiplier formula |
| `design/gdd/전투-공식.md` | #6 전투 공식 | "Godot의 `Array.sort()`/`sort_custom()`은 안정 정렬이 아니다 ... 파티 인덱스를 명시적 2차 정렬 키로 사용해야 한다" | Rule 3a codifies the explicit secondary-key requirement for turn order |
| `design/gdd/적-AI.md` | #7 적 AI | "여기서는 최고/최저 1개 후보만 필요하므로 전체 정렬 대신 선형 스캔(reduce)... 방식을 권장" | Rule 3b codifies linear-scan-over-sort as the standing pattern for single-extremum selection |

## Related

- ADR-0007 (Resource Schema & Build-Time Validation) — sibling ADR from the same architecture pass, same "review found a real bug → codify as standing rule" motivation, different bug class (data validation vs. math/sort correctness).
- `.claude/docs/coding-standards.md` — carries the related permanent rule that worked damage examples must use the skill formula, not the basic-attack formula, when justifying threat/survivability claims. Same review process (2026-07-26), same "recurring bug class → codified rule" pattern, found independently across `동료-데이터`/`적-데이터`/`전투-공식`/`적-AI`/`상태이상`.
