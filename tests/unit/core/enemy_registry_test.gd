extends GutTest
## Covers design/gdd/적-데이터.md Acceptance Criteria 1, 6, 7, 8, 11.
## AC2/3/4/5/10/13 are field-presence/UI/rendering checks not meaningfully
## distinct from AC1 given GDScript's typed non-null fields. AC9 (build-time
## skill_id/target_type/multiplier validator) is covered by data_validator_test.gd.
## AC12 (soft out-of-range warning) is not enforced yet -- add when balance
## tooling needs it (ponytail: YAGNI, no AC blocks on it today).

func test_enemy_registry_loads_all_four_mvp_enemies() -> void: # AC1
	# Act
	var enemies := DataRegistryLoader.load_all(
		"res://assets/data/enemies/", func(r: EnemyData) -> bool: return r.base_hp <= 0
	)

	# Assert
	assert_eq(enemies.size(), 4)

func test_normal_enemy_stats_within_range() -> void: # AC6
	# Arrange
	var enemies := DataRegistryLoader.load_all(
		"res://assets/data/enemies/", func(r: EnemyData) -> bool: return r.base_hp <= 0
	)

	# Act / Assert
	for id in enemies:
		var enemy: EnemyData = enemies[id]
		if enemy.is_boss:
			continue
		assert_between(enemy.base_hp, 25, 65, "%s base_hp" % id)
		assert_between(enemy.base_atk, 8, 18, "%s base_atk" % id)
		assert_between(enemy.base_def, 3, 12, "%s base_def" % id)
		assert_between(enemy.base_spd, 1, 9, "%s base_spd" % id)

func test_boss_enemy_stats_within_range() -> void: # AC7
	# Arrange
	var enemies := DataRegistryLoader.load_all(
		"res://assets/data/enemies/", func(r: EnemyData) -> bool: return r.base_hp <= 0
	)
	var boss: EnemyData = enemies["enemy_boss_01"]

	# Assert
	assert_true(boss.is_boss)
	assert_between(boss.base_hp, 150, 300)
	assert_between(boss.base_atk, 15, 25)
	assert_between(boss.base_def, 10, 20)
	assert_between(boss.base_spd, 4, 9)

func test_duplicate_id_keeps_sorted_first_file() -> void: # AC8
	# Act
	var enemies := DataRegistryLoader.load_all(
		"res://tests/fixtures/enemies_dup/", func(r: EnemyData) -> bool: return r.base_hp <= 0
	)

	# Assert
	assert_eq(enemies.size(), 1)
	assert_eq(enemies["dup_enemy_id"].name, "First (kept)")
	assert_push_error("duplicate id")

func test_base_hp_zero_or_less_is_rejected_not_loaded() -> void: # AC11
	# Act
	var enemies := DataRegistryLoader.load_all(
		"res://tests/fixtures/enemies_invalid/", func(r: EnemyData) -> bool: return r.base_hp <= 0
	)

	# Assert
	assert_false(enemies.has("bad_hp_enemy"))
	assert_push_error("rejected invalid")
