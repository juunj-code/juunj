extends GutTest
## Covers design/gdd/영구-진행.md Acceptance Criteria 1,2,3,5,6,7,8,9,9b,10.
## AC4 needs an actual process restart (Integration, real #17 required) --
## not unit-testable in a single GUT run, same class of exemption other
## systems' GDDs already flag for similar cases.

func before_each() -> void:
	var dir := DirAccess.open("user://")
	for f in ["savegame.dat", "savegame.dat.tmp", "savegame.dat.corrupted.bak"]:
		if dir.file_exists(f):
			dir.remove(f)
	SaveManager._sections = {}
	ProgressManager.unlocked_companions = []
	ProgressManager.highest_floor_reached = 0

func after_all() -> void:
	var dir := DirAccess.open("user://")
	for f in ["savegame.dat", "savegame.dat.tmp", "savegame.dat.corrupted.bak"]:
		if dir.file_exists(f):
			dir.remove(f)

func test_fresh_init_defaults_to_base_companion_only() -> void: # AC1
	ProgressManager._load_from_save()
	assert_eq(ProgressManager.unlocked_companions, [ProgressManager.BASE_COMPANION_ID])
	assert_eq(ProgressManager.highest_floor_reached, 0)

func test_init_restores_from_save() -> void: # AC2
	SaveManager.save_section("companion_unlocks", ["companion_balance_01", "companion_tank_01"])
	ProgressManager._load_from_save()
	assert_eq(ProgressManager.unlocked_companions, ["companion_balance_01", "companion_tank_01"])

func test_unlock_companion_adds_and_saves() -> void: # AC3
	ProgressManager.unlocked_companions = ["companion_balance_01"]
	ProgressManager.unlock_companion("companion_tank_01")

	assert_eq(ProgressManager.unlocked_companions, ["companion_balance_01", "companion_tank_01"])
	assert_eq(SaveManager.get_section("companion_unlocks"), ["companion_balance_01", "companion_tank_01"])

func test_unlock_companion_is_idempotent() -> void: # AC5
	ProgressManager.unlocked_companions = ["companion_balance_01", "companion_tank_01"]
	ProgressManager.unlock_companion("companion_tank_01")
	assert_eq(ProgressManager.unlocked_companions.size(), 2)

func test_update_highest_floor_when_higher() -> void: # AC6
	ProgressManager.highest_floor_reached = 2
	ProgressManager.update_highest_floor(3)

	assert_eq(ProgressManager.highest_floor_reached, 3)
	assert_eq(SaveManager.get_section("floor_reached"), 3)

func test_update_highest_floor_ignores_lower() -> void: # AC7
	ProgressManager.highest_floor_reached = 3
	ProgressManager.update_highest_floor(2)
	assert_eq(ProgressManager.highest_floor_reached, 3)

func test_empty_unlocked_list_recovers_base_companion() -> void: # AC8
	SaveManager.save_section("companion_unlocks", [])
	ProgressManager._load_from_save()
	assert_true(ProgressManager.unlocked_companions.has(ProgressManager.BASE_COMPANION_ID))

func test_commit_run_end_saves_both_sections_once_each_and_emits() -> void: # AC9
	ProgressManager.unlocked_companions = [ProgressManager.BASE_COMPANION_ID]
	var received: Array = []
	var success_flags: Array = []
	ProgressManager.progress_committed.connect(func(ids, ok): received.assign(ids); success_flags.append(ok))

	var newly := ProgressManager.commit_run_end(["companion_tank_01"], 2)

	assert_eq(newly, ["companion_tank_01"])
	assert_eq(ProgressManager.unlocked_companions, [ProgressManager.BASE_COMPANION_ID, "companion_tank_01"])
	assert_eq(ProgressManager.highest_floor_reached, 2)
	assert_eq(received, ["companion_tank_01"])
	assert_eq(success_flags, [true])

	# Both sections actually persisted in the single save() flush.
	SaveManager._sections = {}
	SaveManager.load_from_disk()
	assert_eq(SaveManager.get_section("companion_unlocks"), [ProgressManager.BASE_COMPANION_ID, "companion_tank_01"])
	assert_eq(int(SaveManager.get_section("floor_reached")), 2)

func test_commit_run_end_multiple_discoveries_single_batch() -> void: # AC9b
	ProgressManager.unlocked_companions = [ProgressManager.BASE_COMPANION_ID]

	var newly := ProgressManager.commit_run_end(["companion_tank_01", "companion_dealer_01"], 1)

	assert_eq(newly, ["companion_tank_01", "companion_dealer_01"])
	assert_eq(ProgressManager.unlocked_companions.size(), 3)

func test_commit_run_end_unknown_id_warns_and_is_skipped() -> void: # AC10
	ProgressManager.unlocked_companions = [ProgressManager.BASE_COMPANION_ID]

	var newly := ProgressManager.commit_run_end(["nonexistent_companion"], 1)

	assert_eq(newly, [])
	assert_eq(ProgressManager.unlocked_companions, [ProgressManager.BASE_COMPANION_ID])
	assert_push_warning("Unknown companion id")
