class_name CombatFormula
extends RefCounted
## Stateless combat math for 바람의 탑 (Wind Tower).
## Pure functions only -- no side effects, same input always yields same output.
## See design/gdd/전투-공식.md for formula derivations and
## docs/architecture/adr-0008-combat-formula-float-sort-stability.md for the
## floori()/epsilon/stable-sort rules these functions follow.

const SP_MAX := 5
const SP_GAIN_PER_TURN := 1

## Basic attack damage (formula ①): max(1, atk - def).
static func basic_attack_damage(atk: int, def: int) -> int:
	return max(1, atk - def)

## Skill damage (formula ②): max(1, floori(atk * multiplier + epsilon) - def).
## `skill_id` is only used in the below-1.0-multiplier warning message.
static func skill_damage(atk: int, multiplier: float, def: int, skill_id: String = "") -> int:
	if multiplier < 1.0:
		push_warning("Skill multiplier below 1.0 on skill: %s" % skill_id)
	return max(1, floori(atk * multiplier + 0.0001) - def)

## Heal amount (formula ⑥), capped by missing HP and by base_hp * heal_multiplier.
## No overheal -- returns 0 at full HP.
static func heal_amount(target_base_hp: int, target_current_hp: int, heal_multiplier: float) -> int:
	var missing := target_base_hp - target_current_hp
	var cap := floori(target_base_hp * heal_multiplier + 0.0001)
	return min(missing, cap)

## Applies damage to current_hp, floored at 0 (formula ⑤ HP lower bound).
static func apply_damage(current_hp: int, damage: int) -> int:
	return max(0, current_hp - damage)

## Recovers SP by `gain`, capped at `max_sp` (formula ④).
static func sp_recover(sp: int, gain: int = SP_GAIN_PER_TURN, max_sp: int = SP_MAX) -> int:
	return min(max_sp, sp + gain)

## True when every enemy's current_hp <= 0 (formula ⑤ victory). Each element
## needs a "current_hp" key.
static func is_victory(enemies: Array) -> bool:
	for enemy in enemies:
		if enemy["current_hp"] > 0:
			return false
	return true

## True when every companion's current_hp <= 0 (formula ⑤ defeat). Each
## element needs a "current_hp" key.
static func is_defeat(companions: Array) -> bool:
	for companion in companions:
		if companion["current_hp"] > 0:
			return false
	return true

## Sorts units by base_spd descending (formula ③). Ties: companions before
## enemies, then ascending "index" (party slot for companions).
## Array.sort_custom() is not a stable sort (ADR-0008 Rule 3), so both
## tie-break keys are explicit here rather than relying on incidental order.
## Each unit needs "spd" (int), "is_companion" (bool), "index" (int) keys.
static func turn_order(units: Array) -> Array:
	var sorted_units := units.duplicate()
	sorted_units.sort_custom(func(a, b):
		if a["spd"] != b["spd"]:
			return a["spd"] > b["spd"]
		if a["is_companion"] != b["is_companion"]:
			return a["is_companion"]
		return a["index"] < b["index"]
	)
	return sorted_units
