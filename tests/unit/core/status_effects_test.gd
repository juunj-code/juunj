extends GutTest
## Covers design/gdd/상태이상.md Acceptance Criteria 1-11. AC9 is #13 런
## 상태 관리's responsibility (this system exposes no combat-end hook).

func _unit(hp: int = 100, base_atk: int = 10, base_def: int = 5) -> Dictionary:
	return {"current_hp": hp, "base_atk": base_atk, "base_def": base_def, "active_effects": []}

func test_poison_deals_damage_and_decrements_duration() -> void: # AC1
	# Arrange
	var unit := _unit(100)
	StatusEffects.apply_effect(unit, "poison")

	# Act
	var result := StatusEffects.tick_effects(unit)

	# Assert
	assert_eq(result["dot_damage"], 5)
	assert_eq(unit["current_hp"], 95)
	assert_eq(unit["active_effects"][0].duration, 2)

func test_poison_expires_after_three_ticks() -> void: # AC2
	# Arrange
	var unit := _unit(100)
	StatusEffects.apply_effect(unit, "poison")

	# Act
	StatusEffects.tick_effects(unit)
	StatusEffects.tick_effects(unit)
	StatusEffects.tick_effects(unit)

	# Assert
	assert_eq(unit["active_effects"].size(), 0)

func test_poison_can_reduce_hp_to_zero() -> void: # AC3
	# Arrange
	var unit := _unit(3)
	StatusEffects.apply_effect(unit, "poison")

	# Act
	StatusEffects.tick_effects(unit)

	# Assert
	assert_eq(unit["current_hp"], 0)

func test_stun_reports_skip_turn() -> void: # AC4
	# Arrange
	var unit := _unit(100)
	StatusEffects.apply_effect(unit, "stun")

	# Act
	var result := StatusEffects.tick_effects(unit)

	# Assert
	assert_true(result["skip_turn"])

func test_stun_expires_after_one_turn() -> void: # AC5
	# Arrange
	var unit := _unit(100)
	StatusEffects.apply_effect(unit, "stun")

	# Act
	StatusEffects.tick_effects(unit)

	# Assert
	assert_eq(unit["active_effects"].size(), 0)

func test_defense_up_modifies_def() -> void: # AC6
	# Arrange
	var unit := _unit(100, 10, 5)
	StatusEffects.apply_effect(unit, "defense_up")

	# Act
	var stats := StatusEffects.get_modified_stats(unit)

	# Assert
	assert_eq(stats["def"], 13)

func test_reapplying_same_effect_replaces_not_stacks() -> void: # AC7
	# Arrange
	var unit := _unit(100)
	StatusEffects.apply_effect(unit, "poison")
	StatusEffects.tick_effects(unit) # duration 3 -> 2

	# Act
	StatusEffects.apply_effect(unit, "poison") # reset to 3

	# Assert
	assert_eq(unit["active_effects"].size(), 1)
	assert_eq(unit["active_effects"][0].duration, 3)

func test_modified_stat_clamped_to_zero() -> void: # AC8
	# Arrange
	var unit := _unit(100, 10, 5)
	unit["active_effects"].append(load("res://assets/data/status_effects/defense_up.tres").duplicate())
	unit["active_effects"][0].value = -20 # hypothetical debuff magnitude

	# Act
	var stats := StatusEffects.get_modified_stats(unit)

	# Assert
	assert_eq(stats["def"], 0)

func test_stun_and_poison_together_dot_ticks_and_skip_reported() -> void: # AC10
	# Arrange
	var unit := _unit(100)
	StatusEffects.apply_effect(unit, "poison")
	StatusEffects.apply_effect(unit, "stun")

	# Act
	var result := StatusEffects.tick_effects(unit)

	# Assert
	assert_eq(result["dot_damage"], 5)
	assert_eq(unit["current_hp"], 95)
	assert_true(result["skip_turn"])

func test_applied_instances_are_independent_copies() -> void: # AC11
	# Arrange
	var unit_a := _unit(100)
	var unit_b := _unit(100)
	StatusEffects.apply_effect(unit_a, "poison")
	StatusEffects.apply_effect(unit_b, "poison")

	# Act
	StatusEffects.tick_effects(unit_a) # A's duration 3 -> 2

	# Assert
	assert_eq(unit_a["active_effects"][0].duration, 2)
	assert_eq(unit_b["active_effects"][0].duration, 3)
	assert_eq(StatusEffectRegistry.get_by_id("poison").duration, 3)
