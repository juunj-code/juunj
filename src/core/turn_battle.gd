class_name TurnBattle
extends Node
## #1 턴제 전투 orchestrator. See design/gdd/턴제-전투.md. Does not compute
## damage/turn-order/SP itself -- delegates to #6 CombatFormula, #7 EnemyAI,
## #12 StatusEffects. Owns only sequencing, input awaiting, and dispatch.
##
## Units are plain Dictionaries (the same duck-typed shape CombatFormula/
## EnemyAI/StatusEffects already use), built once at setup() from RunManager's
## CompanionRunState/EnemyRunState + the data registries, with a "run_state"
## backref so results sync back (_sync()). Companion base_atk/base_def are
## equipment-inclusive (#4.get_effective_atk/def), computed once at setup --
## equipment can't change mid-battle (#4 Core Rule 3).

signal action_selected(action: String)
signal target_selected(target: Dictionary)
signal battle_ended(victory: bool)

## #20 UI/HUD signal contract (UI-HUD.md "신호 구독 목록" / ADR-0010) -- added
## once #20 existed to actually consume them. unit_id is the unit's "id" field
## (== enemy_id for enemies), NOT guaranteed unique: sampling-with-replacement
## in DungeonGenerator can put two same-enemy_id units in one battle, and a
## signal keyed by that id can't disambiguate which one changed. Known
## ceiling, not fixed here -- see BattleScreen's note.
signal unit_hp_changed(unit_id: String, new_hp: int)
signal unit_sp_changed(unit_id: String, new_sp: int)
signal player_input_requested(unit_id: String)
signal turn_started(unit_id: String)
signal status_effects_changed(unit_id: String, effects: Array)

var party_units: Array = []
var enemy_units: Array = []
var ended := false
var victory := false

var _targeted_this_turn: Array = []

func setup(companions: Array, enemies: Array) -> void:
	party_units = _build_companion_units(companions)
	enemy_units = _build_enemy_units(enemies)

func _build_companion_units(companions: Array) -> Array:
	var units: Array = []
	for i in range(companions.size()):
		var c: CompanionRunState = companions[i]
		var data: CompanionData = CompanionRegistry.get_by_id(c.companion_id)
		units.append({
			"id": c.companion_id, "is_companion": true, "index": i,
			"current_hp": c.current_hp, "base_hp": data.base_hp,
			"base_atk": Equipment.get_effective_atk(c), "base_def": Equipment.get_effective_def(c),
			"spd": data.base_spd, "current_sp": c.current_sp,
			"active_effects": c.active_effects, "skill_id": data.skill_id,
			"run_state": c,
		})
	return units

func _build_enemy_units(enemies: Array) -> Array:
	var units: Array = []
	for i in range(enemies.size()):
		var e: EnemyRunState = enemies[i]
		var data: EnemyData = EnemyRegistry.get_by_id(e.enemy_id)
		units.append({
			"id": e.enemy_id, "is_companion": false, "index": i,
			"current_hp": e.current_hp, "base_hp": data.base_hp,
			"base_atk": data.base_atk, "base_def": data.base_def,
			"spd": data.base_spd, "current_sp": e.current_sp,
			"active_effects": e.active_effects, "skill_id": data.skill_id,
			"is_boss": data.is_boss, "run_state": e,
		})
	return units

## Player turn input -- called externally (eventually by #20's UI) while
## run_battle() is suspended awaiting it.
func submit_action(action: String) -> void:
	action_selected.emit(action)

func submit_target(target: Dictionary) -> void:
	target_selected.emit(target)

func run_battle() -> void:
	var turn_order := _compute_turn_order()
	if turn_order.is_empty():
		push_error("TurnBattle.run_battle() called with no living units -- ending immediately")
		ended = true
		return
	_targeted_this_turn = []

	while true:
		for unit in turn_order:
			if _is_dead(unit):
				continue

			var tick_result := StatusEffects.tick_effects(unit)
			_sync(unit)
			if tick_result["dot_damage"] > 0:
				_check_end_of_battle()
				if ended:
					return
			if tick_result["skip_turn"]:
				continue

			turn_started.emit(unit["id"])

			var action_data: Dictionary
			if unit["is_companion"]:
				action_data = await _get_player_action(unit)
			else:
				action_data = _get_ai_action(unit)

			_execute_action(unit, action_data)
			_check_end_of_battle()
			if ended:
				return

			unit["current_sp"] = CombatFormula.sp_recover(unit["current_sp"])
			_sync(unit)

		turn_order = _compute_turn_order()
		_targeted_this_turn = []

func _compute_turn_order() -> Array:
	var alive: Array = []
	for u in party_units + enemy_units:
		if not _is_dead(u):
			alive.append(u)
	return CombatFormula.turn_order(alive)

func _is_dead(unit: Dictionary) -> bool:
	return unit["current_hp"] <= 0

func _skill_cost(unit: Dictionary) -> int:
	var skill: SkillData = SkillRegistry.get_by_id(unit["skill_id"])
	return skill.cost_sp if skill else 0

func _get_player_action(unit: Dictionary) -> Dictionary:
	player_input_requested.emit(unit["id"])
	var action: String = await action_selected
	if action == "skill" and unit["current_sp"] < _skill_cost(unit):
		push_warning("Skill selected without enough SP on %s, falling back to basic_attack" % unit["id"])
		action = "basic_attack"
	var target: Dictionary = await target_selected
	return {"action": action, "target": target}

func _get_ai_action(unit: Dictionary) -> Dictionary:
	var alive_companions: Array = party_units.filter(func(u): return not _is_dead(u))
	var ai_enemy := {
		"current_sp": unit["current_sp"],
		"skill_cost_sp": _skill_cost(unit),
		"is_boss": unit.get("is_boss", false),
	}
	var decision := EnemyAI.decide_action(ai_enemy, alive_companions, _targeted_this_turn)
	return {"action": decision["action"], "target": decision["target"]}

func _execute_action(unit: Dictionary, action_data: Dictionary) -> void:
	var action: String = action_data["action"]
	var target: Dictionary = action_data["target"]
	var attacker_stats := StatusEffects.get_modified_stats(unit)

	if action == "basic_attack":
		var defender_stats := StatusEffects.get_modified_stats(target)
		var damage := CombatFormula.basic_attack_damage(attacker_stats["atk"], defender_stats["def"])
		target["current_hp"] = CombatFormula.apply_damage(target["current_hp"], damage)
		_sync(target)
		_sync(unit)
		return

	# action == "skill"
	var skill: SkillData = SkillRegistry.get_by_id(unit["skill_id"])
	match skill.target_type:
		"enemy":
			var defender_stats := StatusEffects.get_modified_stats(target)
			var damage := CombatFormula.skill_damage(attacker_stats["atk"], skill.damage_multiplier, defender_stats["def"], skill.id)
			target["current_hp"] = CombatFormula.apply_damage(target["current_hp"], damage)
			if skill.effect_id != "":
				StatusEffects.apply_effect(target, skill.effect_id)
			_sync(target)
		"self", "ally":
			if skill.heal_multiplier > 0:
				var healed := CombatFormula.heal_amount(target["base_hp"], target["current_hp"], skill.heal_multiplier)
				target["current_hp"] += healed
			if skill.effect_id != "":
				StatusEffects.apply_effect(target, skill.effect_id)
			_sync(target)
		"all_allies":
			var allies: Array = party_units if unit["is_companion"] else enemy_units
			for ally in allies:
				if _is_dead(ally):
					continue
				if skill.heal_multiplier > 0:
					var healed := CombatFormula.heal_amount(ally["base_hp"], ally["current_hp"], skill.heal_multiplier)
					ally["current_hp"] += healed
				if skill.effect_id != "":
					StatusEffects.apply_effect(ally, skill.effect_id)
				_sync(ally)

	unit["current_sp"] -= skill.cost_sp
	_sync(unit)

func _check_end_of_battle() -> void:
	if CombatFormula.is_victory(enemy_units):
		_end_battle(true)
	elif CombatFormula.is_defeat(party_units):
		_end_battle(false)

func _end_battle(is_victory: bool) -> void:
	ended = true
	victory = is_victory
	battle_ended.emit(is_victory)
	if is_victory:
		RunManager.exit_combat_victory()
	else:
		RunManager.end_run(false)

func _sync(unit: Dictionary) -> void:
	var rs = unit["run_state"]
	rs.current_hp = unit["current_hp"]
	rs.current_sp = unit["current_sp"]
	rs.active_effects = unit["active_effects"]
	unit_hp_changed.emit(unit["id"], unit["current_hp"])
	unit_sp_changed.emit(unit["id"], unit["current_sp"])
	status_effects_changed.emit(unit["id"], unit["active_effects"])
