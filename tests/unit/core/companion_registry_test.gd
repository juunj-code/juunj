extends GutTest
## Covers design/gdd/동료-데이터.md Acceptance Criteria 1, 2, 5, 6.
## AC3/AC7 are #15 파티 구성 / portrait-loader UI concerns, not this system's.
## AC4 (build-time skill_id validator) needs EnemyRegistry too — deferred to #11.

func test_companion_registry_loads_all_five_mvp_companions() -> void: # AC1
	# Act
	var companions := DataRegistryLoader.load_all(
		"res://assets/data/companions/",
		func(r: CompanionData) -> bool: return r.base_hp <= 0
	)

	# Assert
	assert_eq(companions.size(), 5)
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

## Regression test (2026-08-02): a real web export was confirmed (browser
## smoke test) to list resource files with a ".remap" suffix appended
## (e.g. "foo.tres.remap") instead of the bare "foo.tres" the editor/desktop
## loose filesystem shows -- the old ends_with(".tres") filter silently
## dropped every single data file on web, so EVERY registry loaded empty.
## This fixture has a same-named .tres + .tres.remap sibling pair, which is
## the closest a loose-filesystem GUT run can get to that packed listing
## shape (both strip to the same clean name -> load() runs twice -> the
## second hit is a "duplicate", same mechanism as the dup test above). The
## assertion that matters is that the .remap entry wasn't silently dropped.
func test_remap_suffixed_filename_is_still_discovered() -> void:
	# Act
	var companions := DataRegistryLoader.load_all(
		"res://tests/fixtures/companions_remap/",
		func(r: CompanionData) -> bool: return r.base_hp <= 0
	)

	# Assert
	assert_eq(companions.size(), 1)
	assert_eq(companions["remap_test_id"].name, "Remap Test")
	assert_push_error("duplicate id")
