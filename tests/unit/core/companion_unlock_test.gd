extends GutTest
## Covers design/gdd/동료-해금.md Acceptance Criteria 1-5 (AC5/AC6 old numbers
## were deleted in the 2026-07-26 GDD revision -- #14/#13 and #20 own those).

func before_each() -> void:
	RunManager.reset()

func _start_exploring() -> void:
	RunManager.start_run([
		{"companion_id": "companion_balance_01", "weapon_slot": "", "armor_slot": ""},
	])

func test_discovered_companion_is_added_to_run_manager_list() -> void: # AC1
	_start_exploring()

	CompanionUnlock.handle_discovered("companion_dealer_01")

	assert_eq(RunManager.discovered_companions, ["companion_dealer_01"])

func test_discovered_companion_emits_unlocked_signal_with_full_data() -> void: # AC2
	_start_exploring()
	var received: Array = []
	CompanionUnlock.companion_unlocked_this_run.connect(
		func(id, comp_name, description, portrait_id, color_accent):
			received.append([id, comp_name, description, portrait_id, color_accent])
	)
	var expected: CompanionData = CompanionRegistry.get_by_id("companion_dealer_01")

	CompanionUnlock.handle_discovered("companion_dealer_01")

	assert_eq(received.size(), 1)
	assert_eq(received[0], ["companion_dealer_01", expected.name, expected.description, expected.portrait_id, expected.color_accent])

func test_already_discovered_companion_does_not_duplicate_or_resignal() -> void: # AC3
	_start_exploring()
	CompanionUnlock.handle_discovered("companion_dealer_01")
	var received: Array = []
	CompanionUnlock.companion_unlocked_this_run.connect(func(id, _n, _d, _p, _c): received.append(id))

	CompanionUnlock.handle_discovered("companion_dealer_01")

	assert_eq(RunManager.discovered_companions, ["companion_dealer_01"])
	assert_eq(received, [])

func test_unknown_companion_id_warns_and_does_not_add_or_signal() -> void: # AC4
	_start_exploring()
	var received: Array = []
	CompanionUnlock.companion_unlocked_this_run.connect(func(id, _n, _d, _p, _c): received.append(id))

	CompanionUnlock.handle_discovered("존재하지않는ID")

	assert_eq(RunManager.discovered_companions, [])
	assert_eq(received, [])
	assert_push_warning("Unknown companion_id in unlock flow")

func test_discovery_outside_exploring_state_errors_and_does_not_add() -> void: # AC5
	# RunManager.reset() in before_each leaves state=IDLE

	CompanionUnlock.handle_discovered("companion_dealer_01")

	assert_eq(RunManager.discovered_companions, [])
	assert_push_error("companion_discovered received while state=IDLE")

func test_hidden_trigger_signal_reaches_companion_unlock() -> void:
	_start_exploring()
	var received: Array = []
	CompanionUnlock.companion_unlocked_this_run.connect(func(id, _n, _d, _p, _c): received.append(id))

	HiddenTrigger.companion_discovered.emit("companion_support_01")

	assert_eq(received, ["companion_support_01"])
