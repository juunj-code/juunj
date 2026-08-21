# Skill Icon Generation Prompts

Prepared 2026-08-21. Generated via Higgsfield `nano_banana_pro` (user approved
the credit spend, following the same tool/procedure as
`status-icon-prompts.md` and `art-bible.md` Section 9's documented order:
free tier first, credits after approval — skipped straight to the paid path
here since the free tier has been blocked on every prior asset). Saved to
`assets/art/icons/skill_<id>.png`, `SkillData.icon_id` set on all 4
companion-skill `.tres` files, wired into `scenes/battle_screen.gd`'s skill
button (icon replaces plain "스킬" text label, alongside the existing
name/cost/tooltip text). Prompts kept for reference / regenerating if the art
direction changes.

Spec source: `design/art/art-bible.md` Section 5 (아이콘 프레임/색상/픽토그램
규칙) — Section 9's aikonography note states these status-icon rules are the
project-wide standard for all UI icons, including skill icons.

Scope: the 4 companion-usable skills only (`skill_guard_bash`,
`skill_heavy_strike`, `skill_heal_light`, `skill_slash`). Enemy-only skills
(`skill_enemy_bite`, `skill_enemy_crush`, `skill_enemy_slam`,
`skill_boss_gale`) have no UI surface that shows a skill icon — enemies act
automatically, the player never picks their skill from a button — so they're
out of scope (YAGNI, same as the UI-tap-sound scope cut in 오디오.md).

Shared style line (repeat in every prompt for consistency across the set,
same base line as `status-icon-prompts.md`):
> Flat 16-bit pixel-art style square UI skill icon for a 2D indie JRPG game
> HUD called "Wind Tower" (바람의탑). Simple bold pictogram silhouette,
> centered, symmetrical, filling most of the frame. Solid flat color fill
> only for the pictogram — no gradients, no bevels, no drop shadow, no glow
> outlines. Dark 2px charcoal border square frame around the icon;
> background inside the frame is flat dark blue-gray stone color #2A3040. No
> text, no numbers, no watermark, no UI chrome outside the frame.

**Color choice**: not the buff/debuff semantic channels (art-bible 4-2,
already owned by status icons) — skill icons use each owning companion's own
`color_accent` so a skill button visually matches its companion's card
border, except the heal skill, which uses the existing healing-green channel
(art-bible 4-2, `H:140–155°`) since that color is already reserved
project-wide for "회복되거나 강해진다".

## skill_guard_bash — `skill_guard_bash` (방패 강타, tank/`companion_tank_01`)

Pictogram: a round shield silhouette, viewed face-on, with a small angular
impact burst overlapping its front edge.

**Color**: flat muted olive-brown `#856D45` (tank's `color_accent`).

## skill_heavy_strike — `skill_heavy_strike` (강타, dealer/`companion_dealer_01`)

Pictogram: a two-handed warhammer mid-downswing, head angled down-left, with
a small impact burst at the point of contact.

**Color**: flat deep wine-maroon `#8C3652` (dealer's `color_accent`).

## skill_heal_light — `skill_heal_light` (가벼운 치유, support/`companion_support_01`)

Pictogram: a plus/cross shape with a thin soft ring around it (gentle glow,
still flat-filled, no actual gradient).

**Color**: flat vivid green, hue ≈145° `#27AE60` (art-bible 4-2 healing
channel — same channel as `status_defense_up`, not support's own accent).

## skill_slash — `skill_slash` (베기, balance/`companion_balance_01`)

Pictogram: a single diagonal blade-swipe mark (a bold diagonal stroke with a
short motion-trail taper at one end), bottom-left to top-right.

**Color**: flat amber-orange `#C77329` (balance's `color_accent`).
