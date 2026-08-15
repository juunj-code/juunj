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

## dungeon_room_01 — DungeonExplorationScreen(S-04) 배경

> Generated 2026-08-15 via Higgsfield `nano_banana_pro` (user approved the
> credit spend). Saved to `assets/art/backgrounds/dungeon_room_01.png`.
>
> Spec sources: `design/art/art-bible.md` Section 2 "2. 던전 탐색" mood (Cool
> 3500-4200K, ambient/무방향광, 낮은 명도, 집중 에너지 -- deliberately *not*
> battle's Neutral-Cool directional hard light / extra -10 명도) and Section
> 3-2 환경 지오메트리 (직각 + 45° 대각선만, 일반 방 = 직사각형, 반복 타일 바닥).

> Top-down 2D game background for a JRPG dungeon exploration room, empty of
> any characters. Flat 16-bit pixel-art style rendered as a clean flat
> cel-shaded illustration with bold dark outlines, matching a stylized indie
> game called "Wind Tower" (바람의탑). Rectangular ancient stone dungeon
> corridor/chamber, pure right-angle stone walls, floor made of a repeating
> 16x16 cold gray-blue stone tile pattern (colors in the #2A3040 to #4A5568
> range), cracked and worn with age. Cool ambient lighting around 3800K,
> diffuse with no single strong directional light source, low background
> brightness, muted lower contrast than a battle scene, quiet oppressive
> unknown atmosphere, tense and still. Completely empty center floor space
> (no characters, no creatures, no furniture, no props). No text, no logos,
> no UI elements, no watermark.

16:9, 1k. Wired into `scenes/DungeonExplorationScreen.tscn` the same way as
`battle_arena_01` -- full-rect `TextureRect` (`STRETCH_KEEP_ASPECT_COVERED`)
behind the existing HP cards/popup, no layout changes.

## tower_lobby_01 — MainMenuScreen(S-02)/PartySelectScreen(S-03)/RunResultScreen(S-06) 배경

> Generated 2026-08-15 via Higgsfield `nano_banana_pro` (user approved the
> credit spend). Saved to `assets/art/backgrounds/tower_lobby_01.png`.
>
> Spec source: `design/art/art-bible.md` Section 2 "1. 메인 메뉴 / 로비" mood
> (Warm ambient light sources but background stays desaturated blue-black
> `#0D0F14`-range, 사색 energy, "고요한/초대하는/잠재적인/따뜻한"). These three
> screens are grouped under one "메인 메뉴 / 로비" mood definition in the doc,
> so one background is reused across all three instead of generating three
> near-identical images -- also the credit-efficient choice.

> Top-down 2D game background for a JRPG tower lobby / main menu room, empty
> of any characters. Flat 16-bit pixel-art style rendered as a clean flat
> cel-shaded illustration with bold dark outlines, matching a stylized indie
> game called "Wind Tower" (바람의탑). Rectangular ancient stone antechamber
> at the base of a tower, pure right-angle stone walls, floor made of a
> repeating 16x16 cold gray-blue stone tile pattern (colors in the #2A3040
> to #4A5568 range), cracked and worn with age. A few small warm
> torches/braziers mounted on the walls giving limited warm glow, but the
> overall background stays low-saturation desaturated blue-black (#0D0F14
> range) -- the warm light is a subtle accent, not a wash over the whole
> scene. No strong directional hard shadows, ambient and calm. Quiet,
> inviting, contemplative, softly hopeful mood -- not tense. Completely
> empty center floor space (no characters, no creatures, no furniture, no
> stairs, no props). No text, no logos, no UI elements, no watermark.

16:9, 1k. Wired into all three screens' `.tscn` files the same way as the
other two backgrounds -- full-rect `TextureRect`
(`STRETCH_KEEP_ASPECT_COVERED`) as the first child (renders behind
everything else), no layout changes to existing content.
