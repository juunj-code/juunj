extends GutTest
## Covers design/gdd/로컬-세이브.md AC1,3,4,5,7,8,11-15,17-22 -- the
## synchronous core. AC2/6/9/10/16 (auto-save absence, explicit-signal
## timing, timeout, queue) need the deferred retry/timeout FSM -- see the
## ponytail note in save_manager.gd.

func before_each() -> void:
	var dir := DirAccess.open("user://")
	for f in ["savegame.dat", "savegame.dat.tmp", "savegame.dat.corrupted.bak"]:
		if dir.file_exists(f):
			dir.remove(f)
	SaveManager._sections = {}

func after_all() -> void:
	var dir := DirAccess.open("user://")
	for f in ["savegame.dat", "savegame.dat.tmp", "savegame.dat.corrupted.bak"]:
		if dir.file_exists(f):
			dir.remove(f)

func test_section_round_trips_through_save_and_reload() -> void: # AC1
	# JSON has no int type -- 5 round-trips as 5.0, see save_manager.gd's note.
	SaveManager.save_section("settings", {"volume": 5.0})
	SaveManager.save_section("companion_unlocks", ["a", "b"])
	assert_true(SaveManager.save())

	SaveManager._sections = {}
	SaveManager.load_from_disk()

	assert_eq(SaveManager.get_section("settings"), {"volume": 5.0})
	assert_eq(SaveManager.get_section("companion_unlocks"), ["a", "b"])

func test_single_file_holds_all_sections() -> void: # AC3
	SaveManager.save_section("a", 1)
	SaveManager.save_section("b", 2)
	SaveManager.save()
	assert_true(FileAccess.file_exists("user://savegame.dat"))

func test_write_temp_without_swap_leaves_existing_save_untouched() -> void: # AC4
	SaveManager.save_section("x", "original")
	SaveManager.save()
	var original_bytes := FileAccess.get_file_as_bytes("user://savegame.dat")

	SaveManager.save_section("x", "changed")
	var json_str := JSON.stringify({"schema_version": 1, "sections": SaveManager._sections})
	SaveManager._write_temp(json_str) # no _swap() -- simulates a kill before swap

	assert_eq(FileAccess.get_file_as_bytes("user://savegame.dat"), original_bytes)
	assert_true(FileAccess.file_exists("user://savegame.dat.tmp"))

func test_saved_file_has_schema_version_one() -> void: # AC5
	SaveManager.save_section("x", 1)
	SaveManager.save()

	var content := FileAccess.get_file_as_string("user://savegame.dat")
	var parsed = JSON.parse_string(content)

	assert_eq(typeof(parsed["schema_version"]), TYPE_FLOAT) # Godot JSON numbers decode as float
	assert_eq(int(parsed["schema_version"]), 1)

func test_over_budget_save_is_rejected() -> void: # AC7
	SaveManager.save_section("huge", "x".repeat(SaveManager.SAVE_FILE_SIZE_BUDGET_BYTES))
	var ok := SaveManager.save()
	assert_false(ok)
	assert_push_error("exceeds budget")

func test_warn_threshold_still_succeeds() -> void: # AC8
	var size_target := SaveManager.SAVE_FILE_SIZE_WARN_BYTES + 100
	SaveManager.save_section("big", "x".repeat(size_target))
	var ok := SaveManager.save()
	assert_true(ok)
	assert_push_warning("approaching budget")

func test_corrupted_on_parse_error() -> void: # AC11
	assert_true(SaveManager._is_corrupted("{not valid json"))
	assert_engine_error_count(1, "JSON.parse_string logs an engine-level error for malformed syntax")

func test_corrupted_on_non_dictionary_top_level() -> void: # AC12
	assert_true(SaveManager._is_corrupted("[1, 2, 3]"))

func test_corrupted_on_missing_schema_version() -> void: # AC13
	assert_true(SaveManager._is_corrupted(JSON.stringify({"sections": {}})))

func test_corrupted_on_schema_version_below_range() -> void: # AC14
	assert_true(SaveManager._is_corrupted(JSON.stringify({"schema_version": 0, "sections": {}})))

func test_corrupted_on_zero_byte_content() -> void: # AC15
	assert_true(SaveManager._is_corrupted(""))

func test_load_with_no_save_file_is_not_an_error() -> void: # AC17
	SaveManager.load_from_disk() # before_each already removed any save file
	assert_eq(SaveManager.get_section("anything"), null)

func test_corrupted_save_is_backed_up_and_reset() -> void: # AC18
	var f := FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	f.store_string("not json at all {{{")
	f.close()

	SaveManager.load_from_disk()

	assert_true(FileAccess.file_exists("user://savegame.dat.corrupted.bak"))
	assert_push_error("corrupted")
	assert_engine_error_count(1, "JSON.parse_string logs an engine-level error for malformed syntax")

func test_corrupted_on_future_schema_version() -> void: # AC19
	assert_true(SaveManager._is_corrupted(JSON.stringify({"schema_version": 2, "sections": {}})))

func test_over_budget_save_leaves_prior_save_intact() -> void: # AC20
	SaveManager.save_section("x", "original")
	SaveManager.save()
	var original_bytes := FileAccess.get_file_as_bytes("user://savegame.dat")

	SaveManager.save_section("huge", "x".repeat(SaveManager.SAVE_FILE_SIZE_BUDGET_BYTES))
	SaveManager.save()
	assert_push_error("exceeds budget")

	assert_eq(FileAccess.get_file_as_bytes("user://savegame.dat"), original_bytes)

func test_valid_save_loads_and_emits_load_completed() -> void: # AC21
	SaveManager.save_section("settings", {"volume": 7.0})
	SaveManager.save()
	SaveManager._sections = {}
	var fired := [false]
	SaveManager.load_completed.connect(func(): fired[0] = true)

	SaveManager.load_from_disk()

	assert_true(fired[0])
	assert_eq(SaveManager.get_section("settings"), {"volume": 7.0})

func test_successful_save_returns_true_and_emits_save_succeeded() -> void: # AC22
	var fired := [false]
	SaveManager.save_succeeded.connect(func(): fired[0] = true)

	SaveManager.save_section("x", 1)
	var ok := SaveManager.save()

	assert_true(ok)
	assert_true(fired[0])
