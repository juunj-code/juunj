class_name Synergy
extends RefCounted
## Party-composition flat ATK bonus by class_type pair. See design/gdd/시너지.md.
## #1 owns calling this at battle setup (once per unit, via
## get_applied_synergy_bonus) -- this class only computes, no state.

const APPLIED_CAP_RATIO := 0.5

## Keyed by "typeA-typeB" with types alphabetically sorted (see _pair_key) so
## the same pair can't be defined twice with different values (GDD AC13).
const TABLE := {
	"dealer-support": 5,
	"dealer-tank": 4,
	"balance-dealer": 3,
	"balance-support": 3,
	"support-tank": 2,
	"balance-tank": 2,
}

## Team-level raw value: sum of every distinct class_type pair present in the
## party. Dedup is by pair *type*, not by companion count -- two tanks in one
## party still only trigger the tank-X pair once (GDD Edge Cases).
static func calculate_party_synergy_bonus(companion_ids: Array) -> int:
	var types: Array = []
	for id in companion_ids:
		var data: CompanionData = CompanionRegistry.get_by_id(id)
		if data.class_type not in types:
			types.append(data.class_type)

	var total := 0
	for i in range(types.size()):
		for j in range(i + 1, types.size()):
			total += TABLE.get(_pair_key(types[i], types[j]), 0)
	return total

## Per-unit value actually applied to effective_atk: the team-level bonus
## above, capped at 50% of the receiving unit's own (registry, pre-equipment)
## base_atk -- added 2026-08-08 revision so a low-atk unit in a high-synergy
## party doesn't see a wildly larger relative swing than its teammates.
static func get_applied_synergy_bonus(companion_ids: Array, unit_base_atk: int) -> int:
	var team_bonus := calculate_party_synergy_bonus(companion_ids)
	var applied: int = mini(team_bonus, floori(unit_base_atk * APPLIED_CAP_RATIO + 0.0001))
	if applied > 0:
		print("[Synergy] party=%s -> team=%d, applied=%d (base_atk=%d)" % [companion_ids, team_bonus, applied, unit_base_atk])
	return applied

static func _pair_key(a: String, b: String) -> String:
	return "%s-%s" % [a, b] if a < b else "%s-%s" % [b, a]
