# Background Generation Prompts

Prepared & generated 2026-08-13 via Higgsfield `nano_banana_pro` (user approved
the credit spend — 2 credits). Saved to `assets/art/backgrounds/<name>.png`.

Spec sources: `design/art/art-bible.md` Section 2 "3. 전투" mood (Neutral-Cool,
명도 -10, 방향광, high contrast) and Section 3-2 환경 지오메트리 (직각 + 45°
대각선만, 일반 전투 방 = 직사각형, 반복 타일 바닥).

## battle_arena_01 — BattleScreen(S-05) 배경

> Top-down 2D game background for a JRPG battle arena, empty of any
> characters. Flat 16-bit pixel-art style rendered as clean flat cel-shaded
> illustration with bold dark outlines, matching a stylized indie game called
> "Wind Tower" (바람의탑). Rectangular ancient stone dungeon chamber, pure
> right-angle stone walls, floor made of a repeating 16x16 cold gray-blue
> stone tile pattern (colors in the #2A3040 to #4A5568 range), cracked and
> worn with age. Neutral-cool directional lighting, high contrast, subtle
> vignette darkening toward the edges and corners, moody and tense
> atmosphere, no warm colors. Completely empty center floor space (no
> characters, no creatures, no furniture, no props). No text, no logos, no UI
> elements, no watermark.

16:9, 1k. Wired into `scenes/BattleScreen.tscn` as a full-rect `TextureRect`
(`STRETCH_KEEP_ASPECT_COVERED`) behind the existing unit cards/HUD -- no
layout changes needed since the room's proportions already read well behind
the existing left(party)/right(enemy) card split.
