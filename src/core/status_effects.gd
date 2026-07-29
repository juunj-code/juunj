class_name StatusEffects
extends RefCounted
## Buff/debuff runtime processing. See design/gdd/상태이상.md.
## Units are plain Dictionaries (same duck-typed shape as combat_formula.gd /
## enemy_ai.gd) with "active_effects": Array[StatusEffect] (runtime, duplicated
## instances -- never the registry's shared blueprint), "current_hp": int,
## "base_atk": int, "base_def": int.

## Applies effect_id from StatusEffectRegistry to unit. Same-id effect already
## active is replaced (duration reset), not stacked.
static func apply_effect(unit: Dictionary, effect_id: String) -> void:
	var blueprint: StatusEffect = StatusEffectRegistry.get_by_id(effect_id)
	var instance: StatusEffect = blueprint.duplicate()
	var active: Array = unit["active_effects"]
	for i in range(active.size()):
		if active[i].id == effect_id:
			active[i] = instance
			return
	active.append(instance)

## Turn-start processing (GDD order): DOT tick -> SKIP_TURN detect -> duration
## decrement -> expire removal. Mutates unit's current_hp and active_effects.
## Returns {"dot_damage": int, "skip_turn": bool}.
static func tick_effects(unit: Dictionary) -> Dictionary:
	var dot_damage := 0
	var skip_turn := false
	var active: Array = unit["active_effects"]

	for effect in active:
		if effect.type == "DOT":
			var dmg: int = max(1, effect.value)
			unit["current_hp"] = max(0, unit["current_hp"] - dmg)
			dot_damage += dmg
		elif effect.type == "SKIP_TURN":
			skip_turn = true

	for effect in active:
		effect.duration -= 1
	unit["active_effects"] = active.filter(func(e): return e.duration > 0)

	return {"dot_damage": dot_damage, "skip_turn": skip_turn}

## STAT_MODIFY sum over base stats, clamped to >= 0 (this system's responsibility,
## not #6 전투 공식's -- see GDD "입력 계약").
static func get_modified_stats(unit: Dictionary) -> Dictionary:
	var atk: int = unit["base_atk"]
	var def: int = unit["base_def"]
	for effect in unit["active_effects"]:
		if effect.type == "STAT_MODIFY":
			if effect.stat_target == "atk":
				atk += effect.value
			elif effect.stat_target == "def":
				def += effect.value
	return {"atk": max(0, atk), "def": max(0, def)}
