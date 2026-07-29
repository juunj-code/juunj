extends GutTest
## Covers design/gdd/적-AI.md Acceptance Criteria 1-9.

func test_normal_enemy_targets_lowest_hp() -> void: # AC1
	# Arrange
	var companions := [
		{"current_hp": 60, "base_atk": 10, "index": 0},
		{"current_hp": 30, "base_atk": 10, "index": 1},
		{"current_hp": 80, "base_atk": 10, "index": 2},
	]
	var enemy := {"current_sp": 0, "skill_cost_sp": 99, "is_boss": false}

	# Act
	var result := EnemyAI.decide_action(enemy, companions, [])

	# Assert
	assert_eq(result["target"]["index"], 1)

func test_normal_enemy_tie_break_lowest_index() -> void: # AC2
	# Arrange
	var companions := [
		{"current_hp": 50, "base_atk": 10, "index": 0},
		{"current_hp": 50, "base_atk": 10, "index": 1},
	]
	var enemy := {"current_sp": 0, "skill_cost_sp": 99, "is_boss": false}

	# Act
	var result := EnemyAI.decide_action(enemy, companions, [])

	# Assert
	assert_eq(result["target"]["index"], 0)

func test_boss_targets_highest_atk() -> void: # AC3
	# Arrange
	var companions := [
		{"current_hp": 50, "base_atk": 28, "index": 0},
		{"current_hp": 50, "base_atk": 14, "index": 1},
		{"current_hp": 50, "base_atk": 18, "index": 2},
	]
	var enemy := {"current_sp": 0, "skill_cost_sp": 99, "is_boss": true}

	# Act
	var result := EnemyAI.decide_action(enemy, companions, [])

	# Assert
	assert_eq(result["target"]["index"], 0)

func test_action_uses_skill_when_sp_sufficient() -> void: # AC4
	# Arrange
	var companions := [{"current_hp": 50, "base_atk": 10, "index": 0}]
	var enemy := {"current_sp": 3, "skill_cost_sp": 3, "is_boss": false}

	# Act
	var result := EnemyAI.decide_action(enemy, companions, [])

	# Assert
	assert_eq(result["action"], EnemyAI.ACTION_SKILL)

func test_action_uses_basic_attack_when_sp_insufficient() -> void: # AC5
	# Arrange
	var companions := [{"current_hp": 50, "base_atk": 10, "index": 0}]
	var enemy := {"current_sp": 2, "skill_cost_sp": 3, "is_boss": false}

	# Act
	var result := EnemyAI.decide_action(enemy, companions, [])

	# Assert
	assert_eq(result["action"], EnemyAI.ACTION_BASIC_ATTACK)

func test_dispersion_two_enemies_pick_different_targets() -> void: # AC6
	# Arrange
	var companions := [
		{"current_hp": 20, "base_atk": 10, "index": 0}, # X
		{"current_hp": 50, "base_atk": 10, "index": 1}, # Y
	]
	var enemy := {"current_sp": 0, "skill_cost_sp": 99, "is_boss": false}
	var targeted_this_turn: Array = []

	# Act
	var result_a := EnemyAI.decide_action(enemy, companions, targeted_this_turn)
	var result_b := EnemyAI.decide_action(enemy, companions, targeted_this_turn)

	# Assert
	assert_eq(result_a["target"]["index"], 0)
	assert_eq(result_b["target"]["index"], 1)
	assert_eq(targeted_this_turn, [0, 1])

func test_dispersion_three_enemies_three_survivors_no_repeat() -> void: # AC6b
	# Arrange
	var companions := [
		{"current_hp": 20, "base_atk": 10, "index": 0}, # X
		{"current_hp": 50, "base_atk": 10, "index": 1}, # Y
		{"current_hp": 80, "base_atk": 10, "index": 2}, # Z
	]
	var enemy := {"current_sp": 0, "skill_cost_sp": 99, "is_boss": false}
	var targeted_this_turn: Array = []

	# Act
	EnemyAI.decide_action(enemy, companions, targeted_this_turn) # -> X
	EnemyAI.decide_action(enemy, companions, targeted_this_turn) # -> Y
	var result_c := EnemyAI.decide_action(enemy, companions, targeted_this_turn)

	# Assert
	assert_eq(result_c["target"]["index"], 2)

func test_dispersion_three_enemies_two_survivors_repeats_lowest_hp() -> void: # AC6c
	# Arrange
	var companions := [
		{"current_hp": 20, "base_atk": 10, "index": 0}, # X
		{"current_hp": 50, "base_atk": 10, "index": 1}, # Y
	]
	var enemy := {"current_sp": 0, "skill_cost_sp": 99, "is_boss": false}
	var targeted_this_turn: Array = []

	# Act
	EnemyAI.decide_action(enemy, companions, targeted_this_turn) # -> X
	EnemyAI.decide_action(enemy, companions, targeted_this_turn) # -> Y
	var result_c := EnemyAI.decide_action(enemy, companions, targeted_this_turn)

	# Assert
	assert_eq(result_c["target"]["index"], 0)

func test_dispersion_exempt_when_one_survivor() -> void: # AC7
	# Arrange
	var companions := [{"current_hp": 20, "base_atk": 10, "index": 0}]
	var enemy := {"current_sp": 0, "skill_cost_sp": 99, "is_boss": false}
	var targeted_this_turn: Array = []

	# Act
	var result_a := EnemyAI.decide_action(enemy, companions, targeted_this_turn)
	var result_b := EnemyAI.decide_action(enemy, companions, targeted_this_turn)
	var result_c := EnemyAI.decide_action(enemy, companions, targeted_this_turn)

	# Assert
	assert_eq(result_a["target"]["index"], 0)
	assert_eq(result_b["target"]["index"], 0)
	assert_eq(result_c["target"]["index"], 0)

func test_deterministic_same_input_same_output() -> void: # AC8
	# Arrange
	var companions := [
		{"current_hp": 60, "base_atk": 10, "index": 0},
		{"current_hp": 30, "base_atk": 10, "index": 1},
	]
	var enemy := {"current_sp": 0, "skill_cost_sp": 99, "is_boss": false}

	# Act
	var result_1 := EnemyAI.decide_action(enemy, companions, [])
	var result_2 := EnemyAI.decide_action(enemy, companions, [])

	# Assert
	assert_eq(result_1["target"]["index"], result_2["target"]["index"])

func test_defensively_excludes_dead_companion_from_candidates() -> void: # AC9
	# Arrange -- caller contract violation: a defeated companion (HP=0) sneaks in
	var companions := [
		{"current_hp": 0, "base_atk": 10, "index": 0}, # A, defeated -- should never be picked
		{"current_hp": 30, "base_atk": 10, "index": 1}, # B, alive
	]
	var enemy := {"current_sp": 0, "skill_cost_sp": 99, "is_boss": false}

	# Act
	var result := EnemyAI.decide_action(enemy, companions, [])

	# Assert
	assert_eq(result["target"]["index"], 1)
