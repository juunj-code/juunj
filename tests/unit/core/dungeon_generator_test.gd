extends GutTest
## Covers design/gdd/랜덤-던전.md Acceptance Criteria 1,1b,2,2b,3,4,5,6.
## Calls _generate_floor() directly (not just generate_run()) for the
## hidden-room-probability ACs -- it's the entry point whose *first* rng
## call is the hidden roll when not forced, which makes seed-searching for
## a deterministic hit/miss (same technique as equipment_test.gd) tractable
## without hand-tracing generate_run()'s full multi-floor call sequence.

func _seeded_rng_for_first_roll(want_hit: bool) -> RandomNumberGenerator:
	var s := 1
	while true:
		var probe := RandomNumberGenerator.new()
		probe.seed = s
		if (probe.randf() < DungeonGenerator.HIDDEN_ROOM_CHANCE) == want_hit:
			var fresh := RandomNumberGenerator.new()
			fresh.seed = s
			return fresh
		s += 1
	return null # unreachable

func _has_hidden_room(rooms: Array) -> bool:
	return rooms.any(func(r): return r["type"] == "hidden")

func test_floor2_hidden_room_forced_when_floor1_missed() -> void: # AC1
	var rng := _seeded_rng_for_first_roll(false) # even a roll that would miss...
	var floor2 := DungeonGenerator._generate_floor(2, rng, true) # ...is overridden by force_hidden
	assert_true(_has_hidden_room(floor2))

func test_floor2_hidden_room_follows_rng_when_not_forced() -> void: # AC1b
	var hit_rng := _seeded_rng_for_first_roll(true)
	var miss_rng := _seeded_rng_for_first_roll(false)

	var floor2_hit := DungeonGenerator._generate_floor(2, hit_rng, false)
	var floor2_miss := DungeonGenerator._generate_floor(2, miss_rng, false)

	assert_true(_has_hidden_room(floor2_hit))
	assert_false(_has_hidden_room(floor2_miss))

func test_boss_room_is_last_room_of_floor3() -> void: # AC2
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var floors := DungeonGenerator.generate_run(rng)
	var floor3: Array = floors[2]
	assert_eq(floor3[floor3.size() - 1]["type"], "boss")

func test_exactly_one_boss_room_in_floor3() -> void: # AC2b
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var floors := DungeonGenerator.generate_run(rng)
	var floor3: Array = floors[2]

	var boss_rooms := floor3.filter(func(r): return r["type"] == "boss")
	assert_eq(boss_rooms.size(), 1)
	assert_eq(floor3.find(boss_rooms[0]), floor3.size() - 1)

func test_combat_room_enemies_sampled_with_replacement() -> void: # AC3
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var floors := DungeonGenerator.generate_run(rng)
	var combat_room = floors[0].filter(func(r): return r["type"] == "combat")[0]

	assert_eq(combat_room["enemy_ids"].size(), 2)
	for id in combat_room["enemy_ids"]:
		assert_false(EnemyRegistry.get_by_id(id).is_boss)

func test_boss_room_has_single_boss_enemy() -> void: # AC4
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var floors := DungeonGenerator.generate_run(rng)
	var floor3: Array = floors[2]
	var boss_room = floor3[floor3.size() - 1]

	assert_eq(boss_room["enemy_ids"].size(), 1)
	assert_true(EnemyRegistry.get_by_id(boss_room["enemy_ids"][0]).is_boss)

## 2026-08-23: added when a 2nd boss (enemy_boss_02) shipped -- the old
## _boss_enemy_id() just returned the first is_boss found in registry order,
## which would have silently ignored the new boss forever. Runs many seeds
## and requires both boss ids to show up at least once.
func test_boss_selection_covers_all_boss_ids_across_seeds() -> void:
	var seen: Dictionary = {}
	for s in range(1, 50):
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var floors := DungeonGenerator.generate_run(rng)
		var floor3: Array = floors[2]
		seen[floor3[floor3.size() - 1]["enemy_ids"][0]] = true

	assert_true(seen.has("enemy_boss_01"))
	assert_true(seen.has("enemy_boss_02"))

func test_generate_run_produces_all_three_floors() -> void: # AC5
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var floors := DungeonGenerator.generate_run(rng)
	assert_eq(floors.size(), 3)
	for floor_rooms in floors:
		assert_true(floor_rooms.size() >= 2) # combat rooms + (floor3's boss); hidden room is optional

func test_max_three_hidden_rooms_when_all_rolls_hit() -> void: # AC6
	var seed := _find_seed_with_hidden_count(3)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var floors := DungeonGenerator.generate_run(rng)

	var hidden_count := 0
	for floor_rooms in floors:
		for room in floor_rooms:
			if room["type"] == "hidden":
				hidden_count += 1
	assert_eq(hidden_count, 3)

func _find_seed_with_hidden_count(want_count: int) -> int:
	var s := 1
	while s < 10000:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var floors := DungeonGenerator.generate_run(rng)
		var count := 0
		for floor_rooms in floors:
			for room in floor_rooms:
				if room["type"] == "hidden":
					count += 1
		if count == want_count:
			return s
		s += 1
	return -1
