# Enemy Sprite Generation Prompts

Prepared & generated 2026-08-02 via Higgsfield `nano_banana_pro` (user approved
the credit spend — 2 credits/image, 8 total). Square 1:1, saved to
`assets/art/sprites/<enemy_id>.png`, `EnemyData.sprite_id` set to the
resulting `res://` path, wired into `scenes/battle_screen.gd`.

Spec sources: `design/art/art-bible.md` Section 3-1 (실루엣 철학, 크기별 규칙)
and Section 4-2's 2026-08-02 addendum (적 스프라이트 기본 색 = 냉석/안개 청회색,
위협홍은 눈/균열 등 포인트 액센트로만).

**2026-08-23 art-direction regeneration**: same pivot as
`design/art/portrait-prompts.md` — enemies regenerated alongside companions so
the two don't visually diverge (flat cel-shaded monsters next to 3D-rendered
heroes would look worse than either alone). Silhouette/color rules unchanged.

Shared style line (repeat in every prompt for consistency across the set):
> 3D-rendered stylized monster character for a 2D indie JRPG called "Wind
> Tower" (바람의탑) — mobile-game-quality stylized 3D render look (think
> Genshin Impact / Clash Royale-adjacent monster art), NOT flat vector
> illustration, NOT flat cel-shading, NOT pixel art, NOT a photo. Soft
> directional studio lighting creates real volumetric shading and ambient
> occlusion. Materials read distinctly: rough cracked stone texture, worn
> cloth, glowing cracks with real light falloff. Minimal to no black outline —
> silhouette and form are defined by light and shadow, not linework. Full
> body, centered, filling most of the square frame. Base body color is cool
> desaturated blue-gray (around #2A3040-#4A5568 range), NOT red — red is used
> only as a small glowing accent (eyes, cracks, markings), never as the main
> body color. No text, no logos, no UI frame baked into the image, no
> watermark. Flat dark blue-gray stone background `#2A3040`, no scenery detail.

## enemy_speed_01 — 고블린 정찰병 (Goblin Scout, 소형/속도형)

Small lean goblin-like scout creature, crouched alert pose, ready to dart
away. Silhouette must read with sharp triangular projections — at least 2
spiky protrusions (jagged ears and a row of small back quills/spikes).
Ashen gray-skinned, ragged dark cloth wrap, small crude dagger. Glowing red
accent: eyes only.

## enemy_balance_01 — 떠도는 병사 (Wandering Soldier, 중형/밸런스형)

Medium corrupted/lost soldier, humanoid but wrong — broken mismatched armor
plates. Silhouette: inverted-triangle upper body (broad shoulders tapering to
a narrow waist) OR one asymmetric oversized arm/pauldron (only one side).
Ashen gray-blue tone armor and skin, rusted notched sword. Glowing red
accent: eyes and a crack down the armor chest-plate only.

## enemy_tank_01 — 돌 수문장 (Stone Gatekeeper, 중형/탱커형)

Squat, heavily-built stone golem guardian, slow and immovable stance.
Silhouette: at least one concave notch (a chunk visibly missing/broken from
the stone body) or clear left-right asymmetry (one arm much larger/blockier
than the other, like an oversized stone club-fist). Rough cracked gray stone
texture. Glowing red accent: rune-carved eyes and the cracks only.

## enemy_boss_01 — 바람의 수호자 (Guardian of the Wind, 보스)

Large wind-elemental guardian — roughly 4x the visual mass/area of the other
three enemies, towering and imposing. Body formed of swirling stone-gray wind
currents and tattered cloth/robe fragments caught in the wind. Silhouette
MUST include at least one clear internal negative space — a hollow
gap/opening (e.g. a ring-shaped torso, or open space between wind-formed
limbs and the core body) that shows the background through the character.
Glowing red accent: a single core/eye at the center and thin cracks along the
wind-formed limbs only.

## enemy_wisp_01 — 바람 정령 (Wind Wisp, 2026-08-24 신규, 소형/속도형)

Small, fast wind spirit — a compact swirling wisp-creature with at least 2
sharp, jagged wind-tendril protrusions curling off its body (like small
tornado tendrils), crouched and alert as if about to dart away. Glowing red
accent: a pair of small glowing eyes only.

## enemy_boss_02 — 서리 파수꾼 (Frost Warden, 2026-08-24 신규, 보스)

Towering frost/ice guardian golem, slow and immovable, encased in thick
frozen armor plating — contrast to 바람의 수호자's fast swirling form with a
bulkier, tankier silhouette (base_hp 180 vs 150, base_def 10 vs 8, base_spd 4
vs 6). Silhouette MUST include at least one clear internal negative space — a
hollow gap in the icy chest/torso (e.g. a hollow frozen ribcage or gap
between frost-armor plates). Glowing accent: pale icy-blue cracks and a
single glowing core (not red — cool blue matches the frost theme instead of
the wind guardian's red).

**Boss selection**: `dungeon_generator.gd`'s `_boss_enemy_id()` now picks
randomly among every `is_boss=true` enemy (previously just returned the
first found, which would have silently ignored this boss forever) — floor
3's boss room can hand the player either boss. Both are independently
verified solo-winnable with optimal play (`boss_balance_test.gd`).
