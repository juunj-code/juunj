extends GutTest
## Covers design/gdd/파티-구성.md Acceptance Criteria 1-8.

func before_each() -> void:
	RunManager.reset()

func test_unlocked_list_is_exposed_as_given() -> void: # AC1
	# Arrange
	var ids: Array[String] = ["warrior_base_01", "hidden_archer_03"]

	# Act
	var pc := PartyComposition.new(ids)

	# Assert
	assert_eq(pc.unlocked_companions, ids)

func test_selecting_companion_adds_to_party() -> void: # AC2
	# Arrange
	var pc := PartyComposition.new(["a", "b"])

	# Act
	var ok := pc.select_companion("a")

	# Assert
	assert_true(ok)
	assert_eq(pc.selected, ["a"])

func test_selecting_beyond_max_party_size_ignored() -> void: # AC3
	# Arrange
	var pc := PartyComposition.new(["a", "b", "c", "d"])
	pc.select_companion("a")
	pc.select_companion("b")
	pc.select_companion("c")

	# Act
	var ok := pc.select_companion("d")

	# Assert
	assert_false(ok)
	assert_eq(pc.selected.size(), 3)

func test_reselecting_same_companion_ignored() -> void: # AC3b
	# Arrange
	var pc := PartyComposition.new(["a"])
	pc.select_companion("a")

	# Act
	var ok := pc.select_companion("a")

	# Assert
	assert_false(ok)
	assert_eq(pc.selected, ["a"])

func test_start_inactive_when_party_empty() -> void: # AC4
	# Arrange -- 2+ unlocked so there's no AC8 auto-select
	var pc := PartyComposition.new(["a", "b"])

	# Assert
	assert_false(pc.is_start_active())

func test_start_active_when_one_or_more_selected() -> void: # AC5
	# Arrange
	var pc := PartyComposition.new(["a", "b"])
	pc.select_companion("a")

	# Assert
	assert_true(pc.is_start_active())

func test_equip_weapon_sets_party_config_slot() -> void: # AC6
	# Arrange
	var pc := PartyComposition.new(["a"])

	# Act
	pc.equip("a", "weapon", "iron_sword")

	# Assert
	assert_eq(pc.build_party_config()[0]["weapon_slot"], "iron_sword")

func test_unequipped_slots_are_empty_string_not_null() -> void: # AC6b
	# Arrange
	var pc := PartyComposition.new(["a", "b"])
	pc.select_companion("b")

	# Act
	var config := pc.build_party_config()

	# Assert
	for entry in config:
		assert_eq(entry["weapon_slot"], "")
		assert_eq(entry["armor_slot"], "")

func test_start_run_calls_run_manager_with_party_config() -> void: # AC7
	# Arrange
	var pc := PartyComposition.new(["companion_balance_01", "companion_tank_01"])
	pc.select_companion("companion_balance_01")
	pc.equip("companion_balance_01", "weapon", "iron_sword")

	# Act
	pc.start_run(RunManager)

	# Assert
	assert_eq(RunManager.state, "EXPLORING")
	assert_eq(RunManager.party.size(), 1)
	assert_eq(RunManager.party[0].companion_id, "companion_balance_01")
	assert_eq(RunManager.party[0].weapon_slot, "iron_sword")

func test_sole_unlocked_companion_auto_selected() -> void: # AC8
	# Act
	var pc := PartyComposition.new(["companion_balance_01"])

	# Assert
	assert_eq(pc.selected, ["companion_balance_01"])
	assert_true(pc.is_start_active())
