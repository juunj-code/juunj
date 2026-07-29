class_name EnemyAI
extends RefCounted
## Deterministic enemy action/target selection. See design/gdd/적-AI.md.
## Does not compute damage -- only decides action + target; #6 전투 공식 computes damage.
##
## Companion units are plain Dictionaries (not CompanionData) with keys
## "current_hp"(int), "base_atk"(int), "index"(int) -- the same duck-typed
## shape combat_formula.gd's turn_order()/is_victory()/is_defeat() already use,
## since #13 런 상태 관리 (which owns runtime HP) doesn't exist yet.

const ACTION_SKILL := "skill"
const ACTION_BASIC_ATTACK := "basic_attack"

## enemy: Dictionary {"current_sp": int, "skill_cost_sp": int, "is_boss": bool}.
## targeted_this_turn: Array[int] of party indices already targeted this round --
## owned/initialized by #1 턴제 전투, mutated in place here (the chosen target's
## index is appended) per the dispersion rule.
## Returns {"action": String, "target": Dictionary}.
static func decide_action(enemy: Dictionary, alive_companions: Array, targeted_this_turn: Array) -> Dictionary:
	var action: String = ACTION_SKILL if enemy["current_sp"] >= enemy["skill_cost_sp"] else ACTION_BASIC_ATTACK
	var target := _pick_target(enemy["is_boss"], alive_companions, targeted_this_turn)
	targeted_this_turn.append(target["index"])
	return {"action": action, "target": target}

static func _pick_target(is_boss: bool, alive_companions: Array, targeted_this_turn: Array) -> Dictionary:
	# Defensive: exclude anyone already at 0 HP even if the caller's contract
	# (only-living-companions) was violated (AC9).
	var living: Array = alive_companions.filter(func(c): return c["current_hp"] > 0)
	var candidates: Array = living.filter(func(c): return not targeted_this_turn.has(c["index"]))
	if candidates.is_empty():
		candidates = living # dispersion candidates exhausted -- duplicate targeting allowed

	var best: Dictionary = candidates[0]
	for i in range(1, candidates.size()):
		if _is_better_target(candidates[i], best, is_boss):
			best = candidates[i]
	return best

static func _is_better_target(candidate: Dictionary, current_best: Dictionary, is_boss: bool) -> bool:
	if is_boss and candidate["base_atk"] != current_best["base_atk"]:
		return candidate["base_atk"] > current_best["base_atk"]
	if candidate["current_hp"] != current_best["current_hp"]:
		return candidate["current_hp"] < current_best["current_hp"]
	return candidate["index"] < current_best["index"]
