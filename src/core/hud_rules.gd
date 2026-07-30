class_name HudRules
extends RefCounted
## Pure decision/formatting logic for #20 UI/HUD. See design/gdd/UI-HUD.md.
## No Control/CanvasLayer/Node here -- same reasoning as #19's
## SceneTransitionRules: there are no real scene files yet (S-03/S-04/S-05/S-06
## .tscn don't exist), so building actual UI Nodes now would be untestable
## boilerplate. This is the tested contract those Nodes will call into once
## they exist. AC1 (HP bar) and AC8 (status icon) are direct signal->render
## passthroughs with no decision logic, so they have no function here.

const SP_MAX := 5

## AC7.
static func sp_dots(current_sp: int, sp_max: int = SP_MAX) -> String:
	return "●".repeat(current_sp) + "○".repeat(sp_max - current_sp)

## AC6. current_floor/current_room_index are both 1-based (RunManager).
static func floor_room_text(current_floor: int, current_room_index: int) -> String:
	return "%d층 · %d번 방" % [current_floor, current_room_index]

## AC2.
static func is_skill_disabled(current_sp: int, cost_sp: int) -> bool:
	return current_sp < cost_sp

## AC3. enemies is duck-typed (EnemyRunState-shaped: .enemy_id, .current_hp).
## Returns enemy_id for every still-alive entry, in input order.
static func alive_target_ids(enemies: Array) -> Array[String]:
	var ids: Array[String] = []
	for enemy in enemies:
		if enemy.current_hp > 0:
			ids.append(enemy.enemy_id)
	return ids
