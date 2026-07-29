extends GutTest
## Covers design/gdd/전투-공식.md Acceptance Criteria 1-4b, 5, 6, 7, 8, 10, 11, 12.
## AC 5b and 9 are #1 턴제-전투 integration scenarios and are not covered here --
## #1 does not exist yet.

func test_combat_formula_basic_attack_normal_stats_returns_27() -> void: # AC1
	# Arrange
	var atk := 30
	var def := 3

	# Act
	var damage := CombatFormula.basic_attack_damage(atk, def)

	# Assert
	assert_eq(damage, 27)

func test_combat_formula_basic_attack_def_exceeds_atk_returns_minimum_one() -> void: # AC2
	# Arrange
	var atk := 10
	var def := 20

	# Act
	var damage := CombatFormula.basic_attack_damage(atk, def)

	# Assert
	assert_eq(damage, 1)

func test_combat_formula_skill_damage_standard_multiplier_returns_42() -> void: # AC3
	# Arrange
	var atk := 30
	var multiplier := 1.5
	var def := 3

	# Act
	var damage := CombatFormula.skill_damage(atk, multiplier, def)

	# Assert
	assert_eq(damage, 42)

func test_combat_formula_skill_damage_def_exceeds_atk_returns_minimum_one() -> void: # AC4
	# Arrange
	var atk := 10
	var multiplier := 1.5
	var def := 20

	# Act
	var damage := CombatFormula.skill_damage(atk, multiplier, def)

	# Assert
	assert_eq(damage, 1)

func test_combat_formula_skill_damage_epsilon_guard_prevents_float_underflow() -> void: # AC4b, ADR-0008
	# Arrange -- 25 * 1.16 evaluates to 28.999999999999996 in float without the guard
	var atk := 25
	var multiplier := 1.16
	var def := 0

	# Act
	var damage := CombatFormula.skill_damage(atk, multiplier, def)

	# Assert
	assert_eq(damage, 29, "epsilon guard must prevent 28.999... from flooring to 28")

func test_combat_formula_turn_order_speed_tie_returns_companion_first() -> void: # AC5
	# Arrange
	var companion := {"spd": 8, "is_companion": true, "index": 1}
	var enemy := {"spd": 8, "is_companion": false, "index": 0}

	# Act
	var order: Array = CombatFormula.turn_order([enemy, companion])

	# Assert
	assert_true(order[0]["is_companion"], "companion must come first on speed tie")

func test_combat_formula_sp_recover_two_turns_returns_two() -> void: # AC6
	# Arrange
	var sp := 0

	# Act
	sp = CombatFormula.sp_recover(sp)
	sp = CombatFormula.sp_recover(sp)

	# Assert
	assert_eq(sp, 2)

func test_combat_formula_sp_recover_at_cap_returns_max() -> void: # AC7
	# Arrange
	var sp := 4

	# Act
	sp = CombatFormula.sp_recover(sp)

	# Assert
	assert_eq(sp, 5)
	assert_eq(CombatFormula.sp_recover(sp), 5, "recovering past SP_MAX must stay capped")

func test_combat_formula_is_victory_all_enemies_defeated_returns_true() -> void: # AC8
	# Arrange
	var enemies := [{"current_hp": 0}]

	# Act
	var victory := CombatFormula.is_victory(enemies)

	# Assert
	assert_true(victory)

func test_combat_formula_is_victory_enemy_alive_returns_false() -> void:
	# Arrange
	var enemies := [{"current_hp": 5}]

	# Act
	var victory := CombatFormula.is_victory(enemies)

	# Assert
	assert_false(victory)

func test_combat_formula_is_defeat_all_companions_fallen_returns_true() -> void:
	# Arrange
	var companions := [{"current_hp": 0}]

	# Act
	var defeat := CombatFormula.is_defeat(companions)

	# Assert
	assert_true(defeat)

func test_combat_formula_apply_damage_overkill_returns_zero() -> void: # AC10
	# Arrange
	var current_hp := 5
	var damage := 100

	# Act
	var result := CombatFormula.apply_damage(current_hp, damage)

	# Assert
	assert_eq(result, 0)

func test_combat_formula_heal_amount_partial_hp_returns_24() -> void: # AC11
	# Arrange
	var base_hp := 80
	var current_hp := 40
	var heal_multiplier := 0.3

	# Act
	var healed := CombatFormula.heal_amount(base_hp, current_hp, heal_multiplier)

	# Assert
	assert_eq(healed, 24)

func test_combat_formula_heal_amount_full_hp_returns_zero() -> void: # AC12
	# Arrange
	var base_hp := 80
	var current_hp := 80
	var heal_multiplier := 0.3

	# Act
	var healed := CombatFormula.heal_amount(base_hp, current_hp, heal_multiplier)

	# Assert
	assert_eq(healed, 0)
