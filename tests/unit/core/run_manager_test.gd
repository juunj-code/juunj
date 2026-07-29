extends GutTest
## Covers design/gdd/런-상태-관리.md Acceptance Criteria 1-10 (Logic-testable
## subset; AC8 stubs #14 via the progress-handoff test seam per the AC's own
## "mock/stub" instruction).

func before_each() -> void:
	RunManager.reset()
	RunManager._scene_navigator_override = Callable()
	RunManager._progress_handoff_override = Callable()
	var dir := DirAccess.open("user://")
	for f in ["savegame.dat", "savegame.dat.tmp", "savegame.dat.corrupted.bak"]:
		if dir.file_exists(f):
			dir.remove(f)
	SaveManager._sections = {}
	ProgressManager.unlocked_companions = [ProgressManager.BASE_COMPANION_ID]
	ProgressManager.highest_floor_reached = 0

func _party_config() -> Array:
	return [
		{"companion_id": "companion_balance_01", "weapon_slot": "iron_sword", "armor_slot": ""},
		{"companion_id": "companion_tank_01", "weapon_slot": "", "armor_slot": "leather_armor"},
	]

func test_start_run_initializes_party_and_floor() -> void: # AC1
	# Act
	RunManager.start_run(_party_config())

	# Assert
	assert_eq(RunManager.party.size(), 2)
	var a: CompanionRunState = RunManager.party[0]
	assert_eq(a.companion_id, "companion_balance_01")
	assert_eq(a.current_sp, 0)
	assert_eq(a.active_effects.size(), 0)
	assert_eq(a.weapon_slot, "iron_sword")
	assert_eq(a.armor_slot, "")
	assert_eq(RunManager.current_floor, 1)
	assert_eq(RunManager.state, "EXPLORING")

func test_hp_persists_across_combat_exit() -> void: # AC2
	# Arrange
	RunManager.start_run(_party_config())
	RunManager.party[0].current_hp = 40
	RunManager.enter_combat(["enemy_speed_01"])

	# Act
	RunManager.exit_combat_victory()

	# Assert
	assert_eq(RunManager.party[0].current_hp, 40)

func test_enter_combat_populates_enemies() -> void: # AC3
	# Arrange
	RunManager.start_run(_party_config())

	# Act
	RunManager.enter_combat(["enemy_speed_01", "enemy_tank_01"])

	# Assert
	assert_eq(RunManager.current_enemies.size(), 2)
	assert_eq(RunManager.state, "IN_COMBAT")

func test_exit_combat_victory_clears_enemies_and_returns_to_exploring() -> void: # AC4
	# Arrange
	RunManager.start_run(_party_config())
	RunManager.enter_combat(["enemy_speed_01"])

	# Act
	RunManager.exit_combat_victory()

	# Assert
	assert_eq(RunManager.current_enemies.size(), 0)
	assert_eq(RunManager.state, "EXPLORING")

func test_end_run_defeat_sets_state_and_success_flag() -> void: # AC5
	# Arrange
	RunManager.start_run(_party_config())

	# Act
	RunManager.end_run(false)

	# Assert
	assert_eq(RunManager.state, "RUN_ENDED")
	assert_false(RunManager.is_success)

func test_advance_floor_increments_and_resets_room() -> void: # AC6
	# Arrange
	RunManager.start_run(_party_config())
	RunManager.current_room_index = 3

	# Act
	RunManager.advance_floor()

	# Assert
	assert_eq(RunManager.current_floor, 2)
	assert_eq(RunManager.current_room_index, 1)

func test_advance_room_increments() -> void: # AC6b
	# Arrange
	RunManager.start_run(_party_config())

	# Act
	RunManager.advance_room()

	# Assert
	assert_eq(RunManager.current_room_index, 2)

func test_advance_room_emits_room_entered_with_room_data() -> void: # AC6c
	# Arrange -- start_run() now generates real floor_rooms via #2 DungeonGenerator
	RunManager.start_run(_party_config())
	var expected_next_room = RunManager.floor_rooms[0][1] # floor 1, room index 2 (0-based 1)
	var received: Array = []
	RunManager.room_entered.connect(func(room_data): received.append(room_data))

	# Act
	RunManager.advance_room()

	# Assert
	assert_eq(received.size(), 1)
	assert_eq(received[0], expected_next_room)
	assert_eq(RunManager.current_room_data, expected_next_room)

func test_add_discovered_companion_dedupes() -> void: # AC7
	# Arrange
	RunManager.start_run(_party_config())

	# Act
	RunManager.add_discovered_companion("hidden_mage_02")
	RunManager.add_discovered_companion("hidden_mage_02")

	# Assert
	assert_eq(RunManager.discovered_companions, ["hidden_mage_02"])

func test_end_run_hands_off_discovered_companions_to_progress_manager() -> void: # AC8
	# Arrange
	RunManager.start_run(_party_config())
	RunManager.add_discovered_companion("hidden_mage_02")
	var received: Array = []
	RunManager._progress_handoff_override = func(ids, _floor):
		received.assign(ids)
		return {"newly_unlocked": ids, "is_new_record": false}

	# Act
	RunManager.end_run(true)

	# Assert
	assert_eq(received, ["hidden_mage_02"])

func test_reset_clears_all_fields() -> void: # AC8b
	# Arrange
	RunManager.start_run(_party_config())
	RunManager.add_discovered_companion("hidden_mage_02")
	RunManager.enter_combat(["enemy_speed_01"])

	# Act
	RunManager.reset()

	# Assert
	assert_eq(RunManager.state, "IDLE")
	assert_eq(RunManager.current_floor, 0)
	assert_eq(RunManager.current_room_index, 0)
	assert_false(RunManager.is_success)
	assert_eq(RunManager.discovered_companions.size(), 0)

func test_party_access_blocked_when_idle() -> void: # AC9
	# Arrange -- RunManager.reset() in before_each leaves state=IDLE

	# Act
	var result := RunManager.party

	# Assert
	assert_eq(result, [])
	assert_push_error("state=IDLE")

func test_party_access_blocked_when_run_ended() -> void: # AC9
	# Arrange
	RunManager.start_run(_party_config())
	RunManager.end_run(true)

	# Act
	var result := RunManager.party

	# Assert
	assert_eq(result, [])
	assert_push_error("state=RUN_ENDED")

func test_end_run_is_idempotent() -> void: # AC9b
	# Arrange
	RunManager.start_run(_party_config())
	var call_count := [0] # mutable box -- GDScript lambdas capture outer ints by value
	RunManager._progress_handoff_override = func(_ids, _floor):
		call_count[0] += 1
		return {"newly_unlocked": [], "is_new_record": false}

	# Act
	RunManager.end_run(true)
	RunManager.end_run(true) # second call must be a no-op

	# Assert
	assert_eq(call_count[0], 1)

func test_advance_floor_at_max_floor_rejected() -> void: # AC10
	# Arrange
	RunManager.start_run(_party_config())
	RunManager.current_floor = 3

	# Act
	RunManager.advance_floor()

	# Assert
	assert_eq(RunManager.current_floor, 3)
	assert_push_error("max floor")

func test_end_run_wires_into_real_progress_manager() -> void:
	# Regression test: the defensive get_node_or_null() handoff used to check
	# for a "commit_discovered" method that ProgressManager never actually
	# had (its real method is commit_run_end) -- so real end_run() silently
	# never persisted anything even with ProgressManager fully built. This
	# proves the wiring against the real autoload, not the test-seam override.

	# Arrange
	RunManager.start_run(_party_config())
	RunManager.add_discovered_companion("companion_tank_01")
	RunManager.current_floor = 2

	# Act
	RunManager.end_run(true)

	# Assert
	assert_eq(RunManager.last_newly_unlocked, ["companion_tank_01"])
	assert_true(RunManager.last_is_new_record)
	assert_true(ProgressManager.is_unlocked("companion_tank_01"))
	assert_eq(ProgressManager.highest_floor_reached, 2)
