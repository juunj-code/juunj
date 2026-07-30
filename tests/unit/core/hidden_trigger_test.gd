extends GutTest
## Covers design/gdd/히든-트리거.md Acceptance Criteria 1-7.
## Companion ids used are the real is_hidden=true roster (companion_dealer_01/
## support_01/tank_01) -- the GDD's own placeholder pool names (hidden_mage_02
## etc.) predate #10's actual data and were never registered; the pool is
## derived from CompanionRegistry, not a hardcoded list, so these are correct.

func before_each() -> void:
	ProgressManager.unlocked_companions = [ProgressManager.BASE_COMPANION_ID]
	RunManager.inventory = []

func _hidden_room(companion_id: String) -> Dictionary:
	return {"type": "hidden", "enemy_ids": [], "companion_id": companion_id}

func test_undiscovered_companion_emits_companion_discovered() -> void: # AC1
	var received: Array = []
	HiddenTrigger.companion_discovered.connect(func(id): received.append(id))

	HiddenTrigger.evaluate(_hidden_room("companion_dealer_01"), RandomNumberGenerator.new())

	assert_eq(received, ["companion_dealer_01"])

func test_already_unlocked_companion_emits_already_cleared_not_discovered() -> void: # AC2
	ProgressManager.unlocked_companions.append("companion_tank_01")
	var discovered: Array = []
	var cleared: Array = []
	HiddenTrigger.companion_discovered.connect(func(id): discovered.append(id))
	HiddenTrigger.hidden_room_already_cleared.connect(func(id): cleared.append(id))

	HiddenTrigger.evaluate(_hidden_room("companion_tank_01"), RandomNumberGenerator.new())

	assert_eq(cleared, ["companion_tank_01"])
	assert_eq(discovered, [])

func test_unknown_companion_id_warns_and_treats_as_already_cleared() -> void: # AC3
	var cleared: Array = []
	HiddenTrigger.hidden_room_already_cleared.connect(func(id): cleared.append(id))

	HiddenTrigger.evaluate(_hidden_room("존재하지않는ID"), RandomNumberGenerator.new())

	assert_eq(cleared, ["존재하지않는ID"])
	assert_push_warning("Unknown companion_id")

func test_already_unlocked_companion_rolls_equipment_drop() -> void: # AC4
	ProgressManager.unlocked_companions.append("companion_tank_01")
	var hit_rng := _seeded_rng_for_first_roll(true)
	var dropped: Array = []
	RunManager.equipment_dropped.connect(func(item): dropped.append(item))

	HiddenTrigger.evaluate(_hidden_room("companion_tank_01"), hit_rng)

	assert_eq(dropped.size(), 1)
	assert_eq(RunManager.inventory.size(), 1)

func test_get_next_companion_id_returns_each_hidden_companion_once_in_shuffle_order() -> void: # AC5
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	HiddenTrigger.start_new_run(rng)

	var hidden_ids: Array = CompanionRegistry.get_all_ids().filter(
		func(id): return CompanionRegistry.get_by_id(id).is_hidden
	)
	var drawn: Array = []
	for i in range(hidden_ids.size()):
		drawn.append(HiddenTrigger.get_next_companion_id())

	drawn.sort()
	var expected: Array = hidden_ids.duplicate()
	expected.sort()
	assert_eq(drawn, expected)
	assert_eq(HiddenTrigger.get_next_companion_id(), "") # 4th call, pool exhausted

func test_room_entered_hidden_room_triggers_evaluate() -> void: # AC6
	var discovered: Array = []
	HiddenTrigger.companion_discovered.connect(func(id): discovered.append(id))

	RunManager.room_entered.emit(_hidden_room("companion_support_01"))

	assert_eq(discovered, ["companion_support_01"])

func test_room_entered_non_hidden_room_does_not_trigger_evaluate() -> void: # AC7
	var discovered: Array = []
	var cleared: Array = []
	HiddenTrigger.companion_discovered.connect(func(id): discovered.append(id))
	HiddenTrigger.hidden_room_already_cleared.connect(func(id): cleared.append(id))

	RunManager.room_entered.emit({"type": "combat", "enemy_ids": [], "companion_id": ""})

	assert_eq(discovered, [])
	assert_eq(cleared, [])

## Same seed-search technique as equipment_test.gd's helper.
func _seeded_rng_for_first_roll(want_hit: bool) -> RandomNumberGenerator:
	var s := 1
	while true:
		var probe := RandomNumberGenerator.new()
		probe.seed = s
		if (probe.randf() < Equipment.DROP_CHANCE) == want_hit:
			var fresh := RandomNumberGenerator.new()
			fresh.seed = s
			return fresh
		s += 1
	return null # unreachable
