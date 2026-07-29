extends GutTest
## Covers design/gdd/장비.md Acceptance Criteria 1-5, 8. AC6/7/7b are about
## *who calls* the drop function (#2/#9's ownership, not built yet) --
## Equipment itself doesn't know about room types, so there's nothing of
## this system's own to assert for those.

func before_each() -> void:
	RunManager.reset()

func _companion_state(companion_id: String = "companion_balance_01") -> CompanionRunState:
	var s := CompanionRunState.new()
	s.companion_id = companion_id
	s.current_hp = 100
	return s

## Finds a seed whose very first randf() call is a hit/miss (as requested),
## and returns a *fresh, unused* generator with that seed -- so the caller's
## own first randf() call inside Equipment.roll_and_apply_drop() reproduces
## the exact same result deterministically.
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

func test_drop_hit_adds_item_and_emits_signal() -> void: # AC1
	# Arrange
	var hit_rng := _seeded_rng_for_first_roll(true)
	var received: Array = []
	RunManager.equipment_dropped.connect(func(item): received.append(item))

	# Act
	Equipment.roll_and_apply_drop(RunManager, hit_rng)

	# Assert
	assert_eq(RunManager.inventory.size(), 1)
	assert_eq(received.size(), 1)

func test_drop_miss_leaves_inventory_unchanged() -> void: # AC2
	# Arrange
	var miss_rng := _seeded_rng_for_first_roll(false)

	# Act
	Equipment.roll_and_apply_drop(RunManager, miss_rng)

	# Assert
	assert_eq(RunManager.inventory.size(), 0)

func test_effective_atk_includes_weapon_bonus() -> void: # AC3
	# Arrange
	var state := _companion_state()
	state.weapon_slot = "iron_sword"
	var base: int = CompanionRegistry.get_by_id("companion_balance_01").base_atk

	# Act
	var effective := Equipment.get_effective_atk(state)

	# Assert
	assert_eq(effective, base + 3)

func test_effective_atk_unmodified_when_slot_empty() -> void: # AC4
	# Arrange
	var state := _companion_state()
	var base: int = CompanionRegistry.get_by_id("companion_balance_01").base_atk

	# Act
	var effective := Equipment.get_effective_atk(state)

	# Assert
	assert_eq(effective, base)

func test_equip_swap_returns_previous_and_removes_new_from_inventory() -> void: # AC5
	# Arrange
	var state := _companion_state()
	state.weapon_slot = "iron_sword"
	RunManager.inventory.append("steel_sword")

	# Act
	Equipment.equip(RunManager, state, "weapon", "steel_sword")

	# Assert
	assert_eq(state.weapon_slot, "steel_sword")
	assert_true(RunManager.inventory.has("iron_sword"))
	assert_false(RunManager.inventory.has("steel_sword"))

func test_unknown_equipment_id_warns_and_returns_zero_bonus() -> void: # AC8
	# Arrange
	var state := _companion_state()
	state.weapon_slot = "nonexistent_item"
	var base: int = CompanionRegistry.get_by_id("companion_balance_01").base_atk

	# Act
	var effective := Equipment.get_effective_atk(state)

	# Assert
	assert_eq(effective, base)
	assert_push_warning("Unknown equipment_id")
