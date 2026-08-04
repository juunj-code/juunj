# Accessibility Requirements: 바람의 탑 (Wind Tower)

> **Status**: Confirmed (2026-08-04) — re-checked against the actual MVP implementation (all 6 screens wired, real sprites/icons/portraits in place); every claim below is backed by a specific file/line, not a proposal anymore.
> **Author**: Claude (2026-07-28 proposal; 2026-08-04 confirmation pass)
> **Last Updated**: 2026-08-04
> **Accessibility Tier Target**: Basic (confirmed)
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
| Minimum text size — UI/HUD text | Basic | All screens | **Not Started** (real gap) | No explicit minimum set — every `Label` uses Godot's default theme font size, only the font face is overridden (`project.godot` `[gui] theme/custom_font`). Never measured against a real mobile-browser viewport (touch-input/COOP-COEP/frame-budget mobile checks all happened, but not text legibility). Needs a real-device pass, not a design-time decision — flagged for the next mobile playtest. |
| Text contrast — UI text on backgrounds | Basic | All UI text | Likely Satisfied, unverified | No custom `Theme` resource exists anywhere in the project (confirmed via search) — every screen runs on Godot 4's unmodified default runtime theme (light text on dark panels, historically well above 4.5:1). Nothing has been overridden in a way that could regress this, but no one has actually screenshotted and run a contrast checker either — downgrade from "Not Started" to "likely fine by default, still unmeasured" rather than claiming a false Satisfied. |
| No color-only signaling for gameplay-critical info | Basic | Companion/enemy identity, status effects, HP thresholds | **Satisfied** | `battle_screen.gd:92-102` renders status effects as icon (`StatusEffect.icon_id`, 24×24, art-bible Section 5) + name + remaining-turn count side by side — never color alone. HP/SP shown as numeric labels (`_render_label`, `_sp_labels`), not color-coded bars. |
| Colorblind consideration | Basic (elevated, see above) | Companion/enemy visual identity | **Satisfied** | Confirmed with real generated sprites (2026-08-02 session): companion identity leans on light/glow per the "동료만이 빛을 가진다" visual pillar; enemy threat-red is confined to eyes/crack points only (art-bible Section 4-2), never used as an overall body hue — both checked by eye against the actual generated assets, not just intent. |

## Audio Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Independent volume controls (music/SFX) | Basic | Global settings | Not Started | Still no audio system at all in the codebase (`assets/audio/` is still just `.gitkeep`) — `#23 설정` remains undesigned. Unchanged since the last pass, correctly still open. |
| No audio-only critical information | Basic | Combat feedback | N/A for now | No audio exists yet, so nothing currently violates this — re-check the moment any audio system lands, since that's exactly when this requirement becomes live. |
| Photosensitivity — no uncontrolled strobing/flashing | Basic | All VFX | **Satisfied** | The only flash-style effect in the codebase is `SceneManager`'s single FLASH transition (`scene_transition_rules.gd`: `FLASH_IN_MS=150`, `FLASH_OUT_MS=150` — one 300ms in/out flash per companion-unlock event, not a repeating strobe). Nowhere near the WCAG "3 flashes/second" seizure threshold — this is a one-shot camera-flash-style transition, the same convention as any other UI fade. |

## Motor Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| No timed inputs without extension/toggle | Basic (already satisfied by design) | All player input | Satisfied by design | `#1 턴제-전투`'s input wait is unbounded by design (ADR-0010) — turn-based genre structurally avoids this barrier, no extra work needed. |
| Minimum touch target size | Basic | All tappable elements | **Satisfied** | Verified in code, not just committed on paper: every `Button`/`OptionButton` across all 6 scenes — both static (`.tscn`) and dynamically created (`party_select_screen.gd`, `battle_screen.gd`) — sets `custom_minimum_size` with height `44` (grepped across `scenes/*.tscn` and `scenes/*.gd`, no exceptions found). |

---

## Known Intentional Limitations

- No screen reader support (menus or in-game) — solo-dev capacity constraint, not a design choice against accessibility. Revisit if project scope/team grows.
- No input remapping — no complex control scheme exists to remap.
- No console accessibility certification — no console release planned for MVP.

## Audit History

**2026-08-04 (first real audit)**: Re-checked every row against the actual MVP implementation (all 6 screens wired, real generated sprites/icons/portraits, 182/182 GUT passing). 5 of 9 rows flipped from "Not Started" to confirmed/Satisfied with a code citation; Basic tier target itself moved from proposed to confirmed given the overwhelming pass rate. Two genuine gaps remain open, both requiring a real device/human check rather than more code: minimum text size (needs a real mobile-browser viewing pass) and text contrast (default theme is almost certainly fine but has never actually been screenshotted and measured). Both are cheap, low-risk checks to fold into whatever the next mobile playtest session already is — not worth a dedicated pass on their own.
