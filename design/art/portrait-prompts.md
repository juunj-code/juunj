# Companion Portrait Generation Prompts

Prepared 2026-07-31. Blocked on generation: Higgsfield workspace out of credits,
Gemini (nanobanana) free-tier quota is 0 for `gemini-3.1-flash-image`. Run these
once either is unblocked — square 1:1, save to `assets/art/portraits/<companion_id>.png`.

**2026-08-15 regeneration note**: the original `companion_tank_01`/`companion_dealer_01`
generations drifted from this spec (tank came out full-body instead of chest-up
bust; dealer came out with a baked-in decorative panel frame despite the "no UI
frame baked in" line). Both regenerated via `nano_banana_pro` with the same
character descriptions below, plus an explicit "flat solid background,
absolutely no border/frame/vignette" emphasis for the dealer retry (first retry
still produced a frame; second attempt succeeded). `companion_balance_01` and
`companion_support_01` already matched spec and were left untouched.

**2026-08-23 art-direction regeneration**: user feedback after playtesting —
characters read as flat cel-shaded cutouts, wanted them pushed toward a
3D-rendered look instead. See `design/art/art-bible.md` Section 6 for the
rationale. All 4 regenerated with the new shared style line below (silhouette/
color rules unchanged — only shading/material treatment changed).

Shared style line (repeat in every prompt for consistency across the set):
> 3D-rendered stylized character bust portrait for a 2D indie JRPG called
> "Wind Tower" (바람의탑) — mobile-game-quality stylized 3D render look (think
> Genshin Impact / Clash Royale-adjacent character art), NOT flat vector
> illustration, NOT flat cel-shading, NOT pixel art, NOT a photo. Soft
> directional studio lighting creates real volumetric shading and ambient
> occlusion across hair, skin, and armor. Materials read distinctly: specular
> highlights on metal/steel, soft sheen on leather, subtle woven texture on
> cloth. Minimal to no black outline — silhouette and form are defined by
> light and shadow, not linework. Semi-realistic proportions (not chibi/SD).
> Front-facing bust portrait, chest-up, centered, symmetrical. No text, no
> logos, no UI frame/border baked into the image, no watermark. Character
> fills most of the square frame.

Colors are locked to `design/art/art-bible.md`'s 동료 컬러 레지스터 (2026-07-31).
Background for all four: flat cool dark blue-gray stone `#2A3040`, no scenery detail.

## companion_balance_01 — 검사 아이라 (전사/근접)

Warm, welcoming female sword-fighter who always greets newcomers to a dark,
ancient stone tower. Calm, confident expression. Simple leather-and-steel
armor, short sword hilt visible near her shoulder. Rounded, convex silhouette —
broad shoulders, no sharp spiky shapes.

**Accent color**: `#C77329` (hair + armor accents — the single most important color).

## companion_tank_01 — 방패지기 도른 (탱커/방어)

Large, heavily-built male shield-bearer found deep in the tower under a
collapsed rampart. Stoic, weathered expression. Battered round shield, thick
plate armor. Muted, low-saturation "묵직함" (weighty) presence — not bright or
flashy, deliberately subdued.

**Accent color**: `#856E45` (muted brownish-orange — armor trim/shield accents).

## companion_dealer_01 — 빠른 손 리사 (도적/정찰)

Agile, hooded rogue — no one knows how long she's been in the tower. Sly,
alert expression, twin daggers visible. Asymmetric/dynamic pose within the
bust framing (slight tilt), leaner silhouette than the other three.

**Accent color**: `#8C3652` (crimson/magenta — hood, cloak trim, dagger wraps).

## companion_support_01 — 노래하는 유이 (힐러/지원)

Gentle female healer/bard — rooms where her song is heard are said to always
be safe. Warm, serene expression, faint musical motif (small harp or songbird
detail near her shoulder is optional, don't overdo it). Soft, rounded
silhouette.

**Accent color**: `#D1B857` (warm gold — robe trim, hair accent).
