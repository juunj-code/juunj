extends GutTest
## Covers design/gdd/UI-HUD.md AC2/AC3/AC6/AC7 (the decision-logic ACs --
## AC1/AC4/AC5/AC8 need real signal/Node wiring, out of scope until #20's
## actual scenes exist; see HudRules/HudPopupQueue top comments).

func test_sp_dots_shows_filled_and_empty() -> void: # AC7
	assert_eq(HudRules.sp_dots(2, 5), "●●○○○")

func test_sp_dots_full() -> void:
	assert_eq(HudRules.sp_dots(5, 5), "●●●●●")

func test_sp_dots_empty() -> void:
	assert_eq(HudRules.sp_dots(0, 5), "○○○○○")

func test_floor_room_text_formats_1_based_values() -> void: # AC6
	assert_eq(HudRules.floor_room_text(2, 2), "2층 · 2번 방")

func test_skill_disabled_when_sp_below_cost() -> void: # AC2
	assert_true(HudRules.is_skill_disabled(1, 2))

func test_skill_enabled_when_sp_meets_cost() -> void: # AC2
	assert_false(HudRules.is_skill_disabled(2, 2))

func _enemy(id: String, hp: int) -> EnemyRunState:
	var e := EnemyRunState.new()
	e.enemy_id = id
	e.current_hp = hp
	return e

func test_alive_target_ids_excludes_defeated_enemies() -> void: # AC3
	var enemies: Array = [_enemy("e1", 10), _enemy("e2", 0), _enemy("e3", 5)]

	assert_eq(HudRules.alive_target_ids(enemies), ["e1", "e3"])
