# Architecture Review Report

**Date**: 2026-07-27
**GDDs reviewed**: 18 (all in `design/gdd/`, plus `systems-index.md` and `game-concept.md` as context)
**ADRs reviewed**: 12 (`docs/architecture/adr-0001` through `adr-0012`, all Status: Proposed at review time)
**Also read**: `docs/architecture/architecture.md` (v1.0), `docs/architecture/tr-registry.yaml`, `docs/registry/architecture.yaml`, `docs/engine-reference/godot/{VERSION.md, breaking-changes.md, deprecated-apis.md, current-best-practices.md, modules/*.md}`

**Process note**: `tr-registry.yaml` and `docs/registry/architecture.yaml` were unpopulated templates at review time — see "Follow-ups" below; this review's own findings were used to seed them.

---

## Traceability Summary

architecture.md's own Phase 0b claims ~60 TRs, 60/60 mapped to a Proposed ADR, 0/60 Accepted. Independently verified by cross-checking TR-IDs cited in each ADR's "GDD Requirements Addressed" table against source GDD text.

| Metric | Count |
|---|---|
| TRs with an explicit dedicated ADR citation | 38 |
| — Covered (concrete decision, no self-flagged open risk) | 24 |
| — Partial (decided, but explicitly self-flags unresolved real-device/real-browser verification) | 14 |
| TRs deliberately left to GDD text only, no ADR needed | ~22 |
| Gaps (no ADR, and one arguably should exist) | 0 at Foundation/Core layer |

**The 14 "Partial" TRs:**

| TR-ID(s) | System | ADR | Why Partial |
|---|---|---|---|
| TR-local-save-001,005,006,007 | #17 로컬 세이브 | ADR-0001 | `FS.syncfs()` durability approach decided, but 3 items unverified (auto-sync on `FileAccess.close()`? callback fires on real mobile Safari/Chrome? 5000ms timeout real or placeholder?) |
| TR-ad-integration-001~005 | #18 광고 통합 | ADR-0003 | JS bridge pattern solid, but `JavaScriptBridge.create_callback()`/`get_interface()` exact 4.6 signature undocumented in this project's engine-reference library (0 grep matches) |
| TR-scene-management-002,004,005,008 | #19 씬 관리 | ADR-0004 | Regular (non-threaded) export is sound, but frame-budget impact and Tween-resume-after-background NaN/overshoot behavior unmeasured |
| TR-ui-hud-005 | #20 UI/HUD | ADR-0011 | ADR explicitly states it cannot fully resolve from documentation alone; mandates a throwaway scene test before `#20` stories start. Highest-consequence unresolved item — gates the entire touch input surface |

None of these are design flaws — they're honest ADRs that name exactly what still needs a real device/browser to confirm.

---

## Coverage Gaps (no ADR exists)

**None at Foundation or Core layer.**

Two soft items, neither rising to "missing ADR":

1. `#13`'s 5 signals (`floor_changed`, `combat_entered`, `combat_exited`, `run_ended`, `state_changed`) have zero confirmed subscribers — ADR-0002 already audits and honestly flags this ("unconfirmed, verify at implementation"). Partial coverage of a documented gap, not an unaddressed gap.
2. `#15 파티 구성` and `#16 런 결과` have no dedicated ADR — checked deliberately, both fully consistent with existing ADRs, correctly left to GDD text.

No new ADR required for Foundation acceptance.

---

## Cross-ADR Conflicts

### 1. ADR-0006 ↔ ADR-0007 dependency direction contradicted itself (FIXED 2026-07-27)

ADR-0007 stated "Depends On: ADR-0006" while its own Ordering Note said ADR-0007 must be Accepted before ADR-0006. ADR-0006 stated "Depends On: None." Substantively, ADR-0006's `CompanionRegistry`/`EnemyRegistry` code types against `CompanionData`/`EnemyData`, which ADR-0007 defines — so ADR-0007 must gate ADR-0006, not the reverse.

**Resolution applied**: ADR-0007's "Depends On" changed to "None"; ADR-0006's "Depends On" changed to "ADR-0007" with Ordering Note updated to match.

### 2. `#18` GDD "Hard Upstream: `#19`" vs. runtime coupling — already resolved

`architecture.md`'s API Boundary section already fixed this before any ADR was written (AdManager only receives an opaque `Callable`, never calls SceneManager directly). Not a live conflict.

No data-ownership, signal-vs-direct-call, or performance-budget conflicts found.

---

## ADR Dependency Order

**Foundation (must be Accepted before coding starts):**
```
ADR-0002 (autoload order + signal catalog)   — no deps
ADR-0003 (JS bridge pattern)                  — no deps
ADR-0004 (scene threading / COOP-COEP)        — no deps
ADR-0005 (RNG injection)                      — no deps
ADR-0007 (resource schema)                    — no deps
ADR-0006 (data registry shared utility)       — depends on ADR-0007
ADR-0001 (local save durability)              — no hard dep; reuses ADR-0003's pattern (soft)
```
Status: 0 of 7 Accepted (known, intentional gate — architecture.md's own TD-ARCHITECTURE self-review already flagged this).

**Core:** ADR-0008, ADR-0009 — no deps, 0 of 2 Accepted, no issues.

**Feature/UI:** ADR-0010, ADR-0011, ADR-0012 — no ordering issues among these three; only need Accepted immediately before their system's implementation starts. ADR-0011 is the one to watch (gates `#20`, the only input surface).

No cycles remain after the 0006/0007 fix.

---

## GDD Revision Flags

| GDD | Assumption | Reality (per ADR) | Action |
|---|---|---|---|
| `design/gdd/UI-HUD.md` (S-04) | "현재 층/방 표시" data source listed as direct property read: `RunManager.current_floor, current_room_index` | ADR-0002 confirms no `#13` signal has a confirmed subscriber; ADR-0012 mandates signal-first, no polling. Ambiguous whether this is a one-time read at scene entry (fine) or implicit poll (violates ADR-0012). | At `#20` implementation: either wire to `floor_changed`/a `room_changed`-style signal, or explicitly state in the GDD this is a one-time read at `DungeonScreen._ready()`. |
| `design/gdd/로컬-세이브.md` (AC 6, 10, 22) | Success/failure signal and "저장 완료" only tested against `_write_temp()`+`_swap()` success | ADR-0001 adds a mandatory second stage (`FS.syncfs()` callback confirmation) between `_swap()` and the actual "Save Complete" signal — GDD's ACs predate this 2-stage design. | Extend AC6/AC22 to assert "Save Complete" isn't emitted until `_on_indexeddb_sync_done` fires, not merely after `_swap()`. |

No GDD assumes engine behavior any ADR found flatly wrong — every HIGH RISK item (`#17`–`#20`) was already hedged with an Open Question in its own GDD before its ADR was written.

---

## Engine Compatibility Issues

- **Version agreement**: all 12 ADRs + architecture.md consistently state Godot 4.6. No disagreement.
- **Deprecated API usage**: none found (no `yield()`, no string-based `connect()`, no `.instance()`, no `Texture2D`-in-shader-param misuse; ADR-0009 correctly reasons through why `duplicate_deep()` isn't needed).
- **Post-cutoff risk correctly flagged, not assumed**: `JavaScriptBridge.*` (ADR-0001/0003) and 4.6 dual-focus (ADR-0011) both grepped engine-reference and got zero matches — handled honestly rather than assuming training-data behavior.
- **Missing Engine Compatibility section**: none — all 12 ADRs have one.
- **Domains not touched**: Jolt 3D, D3D12, glow/tonemap, IK, SDL3 gamepad changes are all correctly out of scope (2D-only, no gamepad, no networking).

---

## Architecture Document Coverage

`architecture.md` covers 22 of 23 systems in `systems-index.md` (all except `#23 설정`, correctly deferred — "Not Started," no GDD yet). No orphaned architecture.

---

## Verdict: CONCERNS

No GDD requirement is left unaddressed by any ADR — traceability is strong. What keeps this from PASS:

1. ~~ADR-0006/0007 dependency contradiction~~ — **fixed during this review.**
2. Four Foundation/high-risk ADRs (0001, 0003, 0004, 0011) are self-admittedly incomplete pending real-device/real-browser verification.
3. Two GDDs (`UI-HUD.md`, `로컬-세이브.md`) have Acceptance Criteria lagging one step behind their own downstream ADRs.

None are structural design flaws — exactly what a pre-implementation gate exists to catch.

---

## Blocking Issues

- ~~ADR-0006/ADR-0007 dependency contradiction~~ — resolved.
- **ADR-0011 should not be treated as resolved** — `#20 UI/HUD` implementation should not start until the mandated throwaway-scene touch test has run and the ADR's "Last Verified" date reflects real results.

## Required ADRs (prioritized)

No new ADRs needed to close a coverage gap. Prioritized follow-ups instead:

1. ~~Fix ADR-0006/ADR-0007 dependency direction~~ — **done 2026-07-27.**
2. Run the ADR-0011 throwaway touch-input scene test before any `#20` story starts — highest-consequence unresolved item, gates the entire input surface.
3. Run ADR-0001/ADR-0003 real-browser verification (mobile Safari/Chrome save durability timing, JS bridge callback signature) before implementing `#17`/`#18`.
4. Populate `docs/registry/architecture.yaml` and `docs/architecture/tr-registry.yaml` from the 12 existing ADRs (seeded as part of this review — see those files).
5. Two small GDD revisions: `UI-HUD.md` signal-vs-property-read clarification; `로컬-세이브.md` stage-2 durability AC.
