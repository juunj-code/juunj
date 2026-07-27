# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7 |
| **Release Date** | ~Mid 2026 |
| **Project Pinned** | 2026-07-27 (changed from 4.6 — see below) |
| **Last Docs Verified** | 2026-07-27 |
| **LLM Knowledge Cutoff** | January 2026 |

## Version Change Note (2026-07-27)

Project was originally scoped for 4.6 (all 12 ADRs and 18 GDDs were written and
architecture-reviewed against 4.6). The actual installed engine turned out to be
**4.7**, so the project is now pinned to 4.7 instead of reinstalling 4.6.

Checked the official 4.6→4.7 migration guide against every area this project's
existing ADRs depend on (JavaScriptBridge/web export, dual-focus UI, RNG,
Array.sort_custom() stability, floor()/floori(), Resource.duplicate(),
push_error/push_warning): **no documented changes in any of them.** No ADR
required rework as a result of this version bump.

Real breaking changes 4.6→4.7 (none currently touch this project's code, since
src/ is still empty — noted here for whoever writes the affected code first):
- A method overriding a typed-return parent method now inherits that return
  type and requires an explicit `return` statement (GH-115763).
- Setting an element of a packed array (e.g. `PackedInt32Array`) no longer
  calls the setter for the whole array property (GH-113228).
- Mouse/keyboard input `device` IDs changed from literal `0` to
  `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` (GH-116274) — relevant
  to `#20 UI/HUD` touch-input code once written; compare against the named
  constants, not `0`.
- `AudioEffectSpectrumAnalyzer.tap_back_pos` property removed (GH-114355) — not used by this project.

## Knowledge Gap Warning

The LLM's training data covers Godot up to ~4.6 (Jan 2026 release). **4.7 is
fully post-cutoff for this assistant** — nothing about it is known from
training data; every claim about 4.7 behavior in this file was pulled from the
official migration guide/release notes, not memory. Always cross-reference
this directory before suggesting Godot API calls, and re-verify against the
live docs for anything not listed above.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | ~Mid 2025 | MEDIUM | Jolt physics option, FileAccess return types, shader texture type changes |
| 4.5 | ~Late 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | ~Mid 2026 | HIGH (fully post-cutoff) | HDR output, Asset Store, Android XR/Steam Frame, wasm64 web export, typed-return inheritance, packed-array setter change, input device ID constants |

## Verified Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration: https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- Release notes: https://godotengine.org/releases/4.7/
