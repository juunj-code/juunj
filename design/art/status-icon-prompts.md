# Status Effect Icon Generation Prompts

Prepared 2026-08-02. **Generated 2026-08-02** via Higgsfield `nano_banana_pro`
(user approved the credit spend — 2 credits/image, 6 total) after nanobanana
(Gemini free tier, quota 0) was blocked again, same as the companion portrait
block on 2026-07-31. Saved to `assets/art/icons/status_<id>.png`,
`StatusEffect.icon_id` set on all 3 `.tres` files, wired into
`scenes/battle_screen.gd` (icon + duration replaces the old name+duration
text). Prompts below kept for reference / regenerating if the art direction
changes.

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
