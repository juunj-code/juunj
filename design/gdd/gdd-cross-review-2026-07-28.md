## Cross-GDD Review Report

**Date**: 2026-07-28
**GDDs Reviewed (18)**: 동료-데이터, 적-데이터, 전투-공식, 적-AI, 상태이상, 턴제-전투, 랜덤-던전, 동료-해금, 히든-트리거, 파티-구성, 장비, 런-상태-관리, 영구-진행, 런-결과, 로컬-세이브, 광고-통합, 씬-관리, UI-HUD
**Also read**: game-concept.md, systems-index.md, design/registry/entities.yaml, .claude/docs/technical-preferences.md

Baseline note: `entities.yaml`'s `entities:` and `items:` sections are both empty (`[]`) — only the `constants:` section is populated. The registry could not serve as a conflict baseline for any named companion, enemy, equipment, or status-effect ID — those were cross-checked by reading all 18 GDDs directly.

---

### Consistency Issues

#### Blocking (must resolve before architecture begins)

**1. Equipment stat bonuses never reach the combat damage formula — as specified, `장비` has zero mechanical effect.**
`전투-공식.md` Formula ① input table declares: `atk | 공격 유닛의 base_atk (+장비·버프 수정)`. But `턴제-전투.md` delegates all stat modification to `#12`'s `get_modified_stats()` only, and its Upstream Dependencies list never includes `#4`. `상태이상.md`'s `get_modified_stats()` computes `modified_atk = base_atk + sum(...)` starting from raw `base_atk`, not from `장비.md`'s `get_effective_atk()` (`base_atk + weapon.bonus`). No document in the call chain (#1, #6, #12) ever invokes `#4`'s getters. Meanwhile `파티-구성.md` AC6c promises a live "+5 DEF" stat-delta preview when equipping gear. As written, equipping gear changes the preview but not actual combat damage.

**2. Hidden-room equipment drop: direct contradiction between `히든-트리거.md` and `장비.md`.**
`히든-트리거.md` Core Rule 3 states drop logic from `#4` is called for already-cleared hidden rooms (AC4 asserts this). `장비.md` Core Rule 4 states "히든방·보스방 드롭 없음 — YAGNI," and its own AC7 explicitly tests that `equipment_dropped` is NOT emitted for hidden rooms. These ACs cannot both pass for the same game state. `장비.md`'s Downstream Dependents table also omits `#9` entirely, even though `히든-트리거.md` declares a Hard dependency on `#4`; `systems-index.md`'s `#9` dependency row was never updated to add `#4`.

**3. `#3 동료 해금` calls a `SceneManager.go_to()` signature `#19 씬 관리` never defines.**
`동료-해금.md` calls `await SceneManager.go_to(current_scene, FLASH, companion.color_accent)` (3-arg, per-companion color override). `씬-관리.md` documents `go_to(scene_id, transition)` as strictly 2-argument everywhere, and its own Player Fantasy section admits FlashOverlay is a fixed `#FFFFFF` flash — actually reflecting `color_accent` is called "`#3`'s responsibility," but no parameter/override mechanism exists in `씬-관리.md`'s API for `#3` to inject that color. The promised companion-color flash (game-concept.md Visual Identity Anchor #2) has no working call path.

#### Warnings (should resolve, but won't block)

- **Hard/Soft dependency-strength mismatches**: `턴제-전투.md` lists `#15 파티 구성` as Hard, `파티-구성.md` labels the reverse as Soft. Same pattern between `적-AI.md` (labels `#6` Hard) and `전투-공식.md` (labels `#7` Soft).
- **`entities.yaml` not populated**: companion/equipment/status-effect IDs each cross 3+ GDDs but were never registered. Several `constants` entries' `referenced_by` lists are incomplete.
- **`전투-공식.md` Open Question #2 is stale** — asks whether equipment stats apply additively/multiplicatively; `#4` (written since) confirms additive, but the question was never marked resolved.
- **`랜덤-던전.md` room-count table is internally inconsistent** — "방 수: 3개" for every floor, but the "구성" column sums to 2 or 3 depending on hidden-room presence. No downstream system hardcodes an assumed count, so documentation-precision only.
- **`씬-관리.md`'s cumulative-fade budget assumes 전투 8~12회**, but `랜덤-던전.md`'s actual structure yields 6 total battle encounters (5 combat + 1 boss) per MVP run — errs safe (overestimates black-screen time), but not sourced from `#2`'s real numbers.

---

### Game Design Issues

#### Blocking

**1. "런 내 합류" (mid-run companion joining) is promised in `game-concept.md` but implemented nowhere.**
`game-concept.md` Core Mechanics #3: "동료 수집 및 영구 해금 시스템 — **런 내 합류**, 런 종료 후 영구 로스터 추가." But `동료-해금.md`'s discovery flow only appends to `RunManager.discovered_companions` (tracking) and shows a popup — never touches `RunManager.party` (active roster). `파티-구성.md` confirms party composition only happens pre-run. No GDD implements mid-run joining, and "Explicitly NOT in MVP" never calls this out as a cut. Either the concept doc's core hook is silently under-delivered, or 3-4 approved GDDs are missing a mechanic — needs an explicit decision, not a silent gap.

#### Warnings

- **Difficulty scaling by unlocked-companion-count** is promised in `game-concept.md` Flow State Design but neither `적-데이터.md` nor `랜덤-던전.md` reference it anywhere — likely a Full Vision feature never marked as an MVP cut.
- **Status-effect combo depth is thin** — `상태이상.md`'s own Open Question #1 flags this; cross-GDD view confirms it's structurally real (4 MVP companions × 1 skill each = tiny combo space), not speculative.
- Clean: no anti-pillar violations found; Player Fantasy sections converge coherently ("solo explorer discovering permanent companions through fair, legible tactical combat"); economic loops are simple/bounded given per-run resets; per-turn decision load stays within a healthy attention budget.

---

### Cross-System Scenario Issues

**Scenarios walked (5)**: (1) Party wipe via DOT mid-combat → run-end → save → result screen; (2) Hidden room discovery (first-time) vs. "런 내 합류" concept promise; (3) Hidden room re-entry (already unlocked) → equipment drop; (4) Equipment drop + inventory + stat recalculation (party-select preview vs. actual combat); (5) Ad-gate + save + run-result sequencing.

#### Blockers

**Hidden-room entry trigger ownership is undefined across `#2`/`#9`/`#13`/`#20`.**
`히든-트리거.md` asserts `#2 랜덤 던전`이 히든방 타입 방에 진입 시 이 시스템의 평가 함수를 호출한다고 서술하지만, `랜덤-던전.md`에는 그런 런타임 동작이 전혀 없음 — `#9`와의 유일한 접점은 생성 시점(탐험 이전)의 `get_next_companion_id()` 호출뿐. `#20`의 유일한 던전 탐험 입력("다음 방으로" 버튼 → `advance_room()`/`advance_floor()`)도 `HiddenTrigger.evaluate(room_data)` 호출과 연결되지 않음. 히든 발견이라는 필라 핵심 인터랙션의 실제 트리거 호출이 어느 문서에도 명시적 책임으로 없음.

#### Warnings

- Scenario 3 surfaces Consistency Finding #2 as its concrete failure mode.
- Scenario 4 surfaces Consistency Finding #1 (preview vs. actual combat divergence).
- Scenario 2 surfaces Game Design Finding #1 (discovered companion unusable for rest of that run — may or may not be intended).

#### Info

- **Scenario 1** (party wipe → run-end → save → result): clean, fully specified, matching ACs at every handoff.
- **Scenario 5** (ad-gate → save → result): clean, `#16` correctly gates on `#13`'s `progress_committed`, `#18`'s 5s timeout prevents blocking.

---

### GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|---|---|---|---|
| 턴제-전투.md | Never calls `#4` to fetch equipment-modified stats before invoking `#6` | Consistency | Blocking |
| 장비.md | Contradicts `히든-트리거.md` on hidden-room drops; omits `#9` as downstream dependent | Consistency | Blocking |
| 히든-트리거.md | Claims Hard dependency on `#4` for drop logic `#4` denies; claims `#2` calls `evaluate()` at room-entry, uncorroborated | Consistency | Blocking |
| 동료-해금.md | Calls `SceneManager.go_to(scene, FLASH, color)`, a 3-arg signature `#19` never defines | Consistency | Blocking |
| 씬-관리.md | FlashOverlay color hardcoded, no override path for `#3`'s delegated responsibility | Consistency | Blocking |
| 랜덤-던전.md | No described runtime trigger for hidden-room entry evaluation; room-count table inconsistency | Consistency | Blocking (trigger) / Warning (table) |
| game-concept.md | "런 내 합류" and "적 강도 자동 조절" promised, absent from all 18 GDDs, no explicit MVP-cut recorded | Design Theory | Blocking (합류) / Warning (난이도 스케일링) |
| 전투-공식.md | Open Question #2 already resolved by `장비.md` but not marked closed | Consistency | Warning |
| systems-index.md | `#9` dependency row not updated to include `#4` | Consistency | Warning |
| design/registry/entities.yaml | `entities:`/`items:` sections empty despite cross-cutting IDs | Consistency | Warning |
| 파티-구성.md | Dependency-strength mismatch with `#1`; stat-delta preview undermined by Finding 1 | Consistency | Warning |
| 적-데이터.md | No mechanism for enemy-strength scaling by unlocked-companion-count | Design Theory | Warning |
| 상태이상.md | Shallow combo depth remains open given fixed 4-companion/1-skill MVP scope | Design Theory | Warning |

---

### Verdict: **FAIL**

Blocking issues exist across three categories: two silently-broken integration paths that would make an entire approved Economy-layer system (`장비`) mechanically inert in combat and produce contradictory equipment-drop behavior; one broken cross-system API contract (color-accent flash); one unresolved concept-vs-system fork on a core hook mechanic (mid-run companion joining); and one entirely undefined trigger ownership for the hidden-room discovery flow. None of these are visible from any single-GDD review — each half of every contradiction reads as internally complete and self-consistent in isolation. No code exists yet (`src/` is empty), so this is the cheapest possible point to catch them.

### Required actions before re-running

1. Decide how equipment bonuses actually reach the combat formula — either `턴제-전투.md` calls `장비.md`'s getters before invoking `전투-공식.md`, or fold equipment modification into `#12`'s `get_modified_stats()` pipeline — update all four GDDs' Dependencies/Formulas tables to agree.
2. Pick one behavior for already-cleared hidden rooms (drop reused, or no drop) and make `히든-트리거.md`/`장비.md`/their ACs agree; update `systems-index.md`'s `#9` row.
3. Define the real API contract for the discovery-moment FLASH color — add a color parameter to `씬-관리.md`'s `go_to()`/`FlashOverlay`, or move color application into `#3`'s own code.
4. Resolve "런 내 합류" in `game-concept.md` — scope it to Full Vision explicitly (add to "Explicitly NOT in MVP"), or add mid-run party-join mechanics to `#1`/`#3`/`#13`/`#15`.
5. Specify which system calls `HiddenTrigger.evaluate()` on room entry — add to `랜덤-던전.md` (or reassign to `#13`/`#20`) and update Dependencies tables.
6. Re-run `/review-all-gdds` after these five are resolved. Lower-priority cleanup (registry population, stale Open Questions, systems-index sync, budget-number correction, difficulty-scaling scope note) can happen in the same pass but doesn't block re-running the review.
