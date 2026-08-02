# Status Effect Icon Generation Prompts

Prepared 2026-08-02. Blocked on generation: Gemini (nanobanana) free-tier quota
is 0 for `gemini-3.1-flash-image` (same block companion portraits hit on
2026-07-31, see `design/art/portrait-prompts.md` — resolved once quota opened
up). Higgsfield not attempted here — has real credit cost, needs explicit
user go-ahead before spending. Run these once nanobanana is unblocked (or the
user approves a Higgsfield spend) — square 1:1, save to
`assets/art/icons/status_<id>.png`, then set each `StatusEffect.icon_id` in
`assets/data/status_effects/*.tres` to the resulting `res://` path.

Spec source: `design/art/art-bible.md` Section 5 (아이콘 프레임/색상/픽토그램 규칙).

Shared style line (repeat in every prompt for consistency across the set):
> Flat 16-bit pixel-art style square UI status-effect icon for a 2D indie JRPG
> game HUD called "Wind Tower" (바람의탑). Simple bold pictogram silhouette,
> centered, symmetrical, filling most of the frame. Solid flat color fill only
> for the pictogram — no gradients, no bevels, no drop shadow, no glow
> outlines. Dark 2px charcoal border square frame around the icon; background
> inside the frame is flat dark blue-gray stone color #2A3040. No text, no
> numbers, no watermark, no UI chrome outside the frame.

## status_poison — `poison` (DOT)

Pictogram: a skull silhouette with two crossed drip/poison droplets.

**Color**: flat threatening red `#C0392B` (art-bible 4-2 위협홍 — DOT/디버프 채널).

## status_stun — `stun` (SKIP_TURN)

Pictogram: a dizzy starburst/swirl silhouette (spinning stars).

**Color**: flat threatening red `#C0392B` (same 위협홍 채널 as poison — both are debuffs).

## status_defense_up — `defense_up` (STAT_MODIFY, value > 0)

Pictogram: a shield silhouette with an upward arrow overlaid.

**Color**: flat vivid green, hue ≈145° (art-bible 4-2 초록 — "버프 아이콘" 채널, DOT/SKIP_TURN의 위협홍과 명확히 분리).
