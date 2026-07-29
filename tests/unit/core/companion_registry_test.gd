extends GutTest
## Covers design/gdd/동료-데이터.md Acceptance Criteria 1, 2, 5, 6.
## AC3/AC7 are #15 파티 구성 / portrait-loader UI concerns, not this system's.
## AC4 (build-time skill_id validator) needs EnemyRegistry too — deferred to #11.

func test_companion_registry_loads_all_four_mvp_companions() -> void: # AC1
	# Act
	var companions := DataRegistryLoader.load_all(
		"res://assets/data/companions/",
		func(r: CompanionData) -> bool: return r.base_hp <= 0
	)

	# Assert
	assert_eq(companions.size(), 4)
	for id in companions:
		assert_not_null(companions[id])

func test_base_companion_is_not_hidden() -> void: # AC2
	# Arrange
	var companions := DataRegistryLoader.load_all(
		"res://assets/data/companions/",
		func(r: CompanionData) -> bool: return r.base_hp <= 0
	)

	# Act
	var base_companion: CompanionData = companions["companion_balance_01"]

	# Assert
	assert_false(base_companion.is_hidden)
	assert_eq(base_companion.unlock_condition_id, "")

func test_duplicate_id_keeps_sorted_first_file() -> void: # AC5
	# Act
	var companions := DataRegistryLoader.load_all(
		"res://tests/fixtures/companions_dup/",
		func(r: CompanionData) -> bool: return r.base_hp <= 0
	)

	# Assert
	assert_eq(companions.size(), 1)
	assert_eq(companions["dup_test_id"].name, "First (kept)")
	assert_push_error("duplicate id")

func test_base_hp_zero_or_less_is_rejected_not_loaded() -> void: # AC6
	# Act
	var companions := DataRegistryLoader.load_all(
		"res://tests/fixtures/companions_invalid/",
		func(r: CompanionData) -> bool: return r.base_hp <= 0
	)

	# Assert
	assert_false(companions.has("bad_hp_companion"))
	assert_eq(companions.size(), 0)
	assert_push_error("rejected invalid")
