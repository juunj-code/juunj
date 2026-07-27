# Interaction Pattern Library: 바람의 탑 (Wind Tower)

> **Status**: Draft — consolidates patterns already decided in ADR-0010/0011/0012 and `technical-preferences.md`. Not yet reviewed by a `/ux-design` session with the producer; add new patterns there, don't invent them here.
> **Author**: Claude (consolidated from existing ADRs, not a new design pass)
> **Last Updated**: 2026-07-28
> **Engine**: Godot 4.7 / GDScript
> **UI Framework**: Godot Control nodes (touch-only, no gamepad)
> **Related Documents**: `.claude/docs/technical-preferences.md`, `docs/architecture/adr-0010-await-coroutine-pattern.md`, `docs/architecture/adr-0011-dual-focus-ui-strategy.md`, `docs/architecture/adr-0012-ui-signal-subscription-convention.md`

**Scope note**: This project is touch-only on mobile browsers, has no gamepad
support, and keyboard is secondary input only (`technical-preferences.md`).
The full generic template (keyboard nav, gamepad focus rings, controller
haptics, complex desktop form patterns) does not apply — this document only
covers patterns this project actually uses. Add sections here as new UI
systems get designed; don't pre-fill patterns nothing calls for yet.

---

## Global Rules (apply to every pattern below)

- **44×44px minimum tap target** — every interactive element (`technical-preferences.md` Input & Platform).
- **No hover-only interactions** — anything a mouse-hover can trigger, a tap must be able to trigger identically. Verified empirically for the base case in `prototypes/touch-input-smoke/` (ADR-0011).
- **Never use Godot's native Focus system** (`grab_focus()`, `has_focus()`, focus StyleBox) for any custom tap interaction — ADR-0011. This project has no gamepad/keyboard-navigation requirement, so native Focus provides no value while carrying documented-gap risk on Godot 4.6/4.7.
- **Signal-first, never polling** — UI never reads another system's state in `_process()`/`_physics_process()` by comparing against a stored previous value, and never holds a duplicated local copy of another system's owned data for that comparison (ADR-0012). Self-owned presentation state (e.g. a popup queue) is not covered by this ban.
- **`await custom_signal`, never a bool-flag poll or a timeout, for player-input waits** — ADR-0010. GDScript's `yield()` (3.x) must never be used.

---

## Pattern: Tappable Action Button

**Status**: Draft (design decided, not yet implemented — `src/` is empty)

- A plain Godot `Button` node reacting to its own `pressed` signal (confirmed to reach native touch/click in `prototypes/touch-input-smoke/`, PASS 2026-07-27).
- Minimum size 44×44px.
- No custom focus-ring styling — Button's default pressed/disabled states are fine; do not wire anything to `has_focus()`.
- Used by: `#1 턴제-전투`'s action buttons.

## Pattern: Tap-Selectable Highlight (target selection, list items)

**Status**: Draft (design decided, not yet implemented)

- A `Control` with an explicit `enum HighlightState { NONE, SELECTABLE, SELECTED }` field, toggled directly by a `gui_input` handler on `InputEventScreenTouch`/`InputEventMouseButton` press — never by `grab_focus()`/`has_focus()`.
- Visual state (`queue_redraw()` + `_draw()`, or a `StyleBoxFlat` swap) is driven purely by `highlight_state`, not by any native focus/hover signal.
- Reference implementation: `docs/architecture/adr-0011-dual-focus-ui-strategy.md` Key Interfaces (`EnemyTargetHighlight`), empirically verified in `prototypes/touch-input-smoke/touch_smoke_scene.gd`.
- Used by: `#1 턴제-전투` enemy target selection (mode-gated: only active after `player_input_requested` + action selected, per `UI-HUD.md` Core Rule 5).

## Pattern: Single-Popup Confirm

**Status**: Draft (design decided, not yet implemented)

- A popup's "confirm" button is a plain Tappable Action Button (above).
- The awaiting code does `await popup_confirmed` — never a manually-toggled bool (ADR-0010's Core Rule 3 rationale: a bool flag doesn't reset on exception/early-return paths and can permanently lock input).
- Only one popup visible at a time; additional triggers append to a queue and show in order — this queue is UI-owned presentation state, not subject to the no-local-cache rule (ADR-0012).
- Used by: `#3 동료-해금` discovery flow, `#20 UI/HUD` popup system generally.

## Pattern: Signal-Driven Display (HUD text/bars/labels)

**Status**: Draft (design decided, not yet implemented)

- Every HUD element subscribes to its data source's signal once in `_ready()` and updates immediately on receipt — never polls, never diffs against a stored previous value (ADR-0012).
- Open item carried from `/architecture-review` (2026-07-27): `UI-HUD.md`'s "현재 층/방 표시" currently reads `RunManager.current_floor`/`current_room_index` as a direct property, and none of `RunManager`'s 5 signals (`floor_changed`, `combat_entered`, `combat_exited`, `run_ended`, `state_changed`) has a confirmed subscriber anywhere yet. Before implementing this display, either wire it to a signal or explicitly document in `UI-HUD.md` that it's a one-time read at scene entry (not a poll).

---

## Patterns Explicitly Not Needed (scope note, not gaps)

- Keyboard focus navigation / tab order — no gamepad, keyboard is secondary only.
- Gamepad-specific prompts/glyphs — `Gamepad Support: None`.
- Hover-revealed tooltips/menus — hover-only interactions are banned project-wide.
- Drag-and-drop — not used by any current MVP GDD.
