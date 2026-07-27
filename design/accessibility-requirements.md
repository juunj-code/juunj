# Accessibility Requirements: 바람의 탑 (Wind Tower)

> **Status**: Draft — proposed by Claude while the producer was away, needs confirmation before treating as committed.
> **Author**: Claude (proposal only — not a `/ux-design` session with the producer)
> **Last Updated**: 2026-07-28
> **Accessibility Tier Target**: Basic (proposed — see Rationale)
> **Platform(s)**: Mobile web browser (PC + mobile), no console
> **External Standards Targeted**: None formally — no console cert (Xbox/PlayStation guidelines N/A, no ID@Xbox program), no dedicated accessibility consultant (solo indie project)
> **Linked Documents**: `design/gdd/systems-index.md`, `design/ux/interaction-patterns.md`, `.claude/docs/technical-preferences.md`

---

## This Project's Commitment

**Target Tier**: Basic (proposed)

**Rationale**: Solo indie project, MVP scope, browser/mobile-web deployment
with no console certification requirements (no XAG/PlayStation guideline
obligations). No dedicated accessibility budget or consultant. The genre
(turn-based combat, no real-time reflex requirement, no timed inputs — `#1
턴제-전투` explicitly waits unboundedly for player input per ADR-0010) already
eliminates the most severe motor-skill barriers common in action games by
design, independent of any accessibility feature work. Standard tier's
biggest cost items (full input remapping, platform-specific subtitle
customization) don't clearly apply here: there's no complex control scheme to
remap (touch-tap-only, no gamepad) and no planned voice-over per the current
GDD set. Basic tier's commitments (readable text, no color-only signaling,
independent volume controls, no photosensitivity risk) are all low-cost,
design-time constraints rather than dedicated engineering work, making them
achievable without expanding scope. **This is a proposal, not a locked
decision** — revisit if scope/budget changes or if playtesting surfaces a
concrete barrier.

**Features explicitly in scope (beyond tier baseline)**:
- Colorblind-safe companion/enemy differentiation — `art-bible.md`'s visual
  identity ("동료만이 빛을 가진다") already relies on light/glow rather than
  hue alone to distinguish companions, which happens to help here; confirm
  this holds once actual sprite colors are locked.

**Features explicitly out of scope**:
- Full input remapping — no complex control scheme exists to remap (single
  tap-to-select, tap-to-confirm interaction model per `interaction-patterns.md`).
  Revisit only if a future control scheme adds complexity.
- Screen reader support (menus or in-game) — beyond current solo-dev capacity;
  would require dedicated engine-level work (Godot's AccessKit support,
  introduced in 4.5, is unverified for this project — see
  `docs/engine-reference/godot/VERSION.md`).
- Console-specific guidelines (XAG, PlayStation) — no console release planned.

---

## Visual Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Minimum text size — UI/HUD text | Basic | All screens | Not Started | No implementation yet (`src/` empty). Target: comfortably readable on a mobile browser viewport at typical phone viewing distance — set a concrete px minimum once the first HUD screen (`#20`) is implemented and can be measured against real device viewports. |
| Text contrast — UI text on backgrounds | Basic | All UI text | Not Started | Aim for WCAG AA (4.5:1 body text) as a design-time constraint when `art-bible.md`'s color palette is finalized (sections 5-9 currently incomplete). |
| No color-only signaling for gameplay-critical info | Basic | Companion/enemy identity, status effects, HP thresholds | Not Started | `#12 상태이상` and combat HP/threat indicators must not rely on hue alone — pair with icon/shape/text. Flag for `art-bible.md` sections 5-9 when written. |
| Colorblind consideration | Basic (elevated, see above) | Companion/enemy visual identity | Not Started | Project's stated visual identity already favors light/glow over hue differentiation — verify once real sprites exist. |

## Audio Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Independent volume controls (music/SFX) | Basic | Global settings | Not Started | `#23 설정` system not yet designed (per `systems-index.md`, deferred past MVP) — add this requirement when that GDD is written. |
| No audio-only critical information | Basic | Combat feedback | Not Started | No GDD currently specifies audio-only signals (all combat feedback is visual per `UI-HUD.md`) — re-check once `#22` (if any audio-cue system exists) is designed. |
| Photosensitivity — no uncontrolled strobing/flashing | Basic | All VFX | Not Started | No VFX system designed yet — flag for `art-bible.md`/VFX work when it starts. |

## Motor Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| No timed inputs without extension/toggle | Basic (already satisfied by design) | All player input | Satisfied by design | `#1 턴제-전투`'s input wait is unbounded by design (ADR-0010) — turn-based genre structurally avoids this barrier, no extra work needed. |
| Minimum touch target size | Basic | All tappable elements | Not Started (design committed, not implemented) | 44×44px minimum already committed in `technical-preferences.md` and `interaction-patterns.md` Global Rules — implementation-time check, not a new commitment. |

---

## Known Intentional Limitations

- No screen reader support (menus or in-game) — solo-dev capacity constraint, not a design choice against accessibility. Revisit if project scope/team grows.
- No input remapping — no complex control scheme exists to remap.
- No console accessibility certification — no console release planned for MVP.

## Audit History

_(None yet — first audit should happen alongside `#20 UI/HUD`'s first implementation pass.)_
