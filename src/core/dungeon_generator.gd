class_name DungeonGenerator
extends RefCounted
## Procedural (room-catalog-based) dungeon generation. See design/gdd/랜덤-던전.md.
## Pure except for two runtime lookups: EnemyRegistry (real, always present)
## and #9 히든 트리거's start_new_run()/get_next_companion_id() (looked up
## defensively via find_child(), same pattern as run_result.gd's AdManager/
## SceneManager lookups -- keeps this Core-layer file from hard-depending on
## a Feature-layer autoload).

const COMBAT_ROOMS_PER_FLOOR := {1: 2, 2: 2, 3: 1}
const ENEMIES_PER_COMBAT_ROOM := {1: 2, 2: 3, 3: 3}
const HIDDEN_ROOM_CHANCE := 0.5

## Returns Array[Array[Dictionary]] -- one array of room dicts per floor
## (index 0 = floor 1). Each room: {"type": "combat"|"hidden"|"boss",
## "enemy_ids": Array[String], "companion_id": String ("" unless hidden)}.
static func generate_run(rng: RandomNumberGenerator) -> Array:
	_reset_hidden_trigger_pool(rng)
	var floors: Array = []
	var floor1_had_hidden := false

	for floor_index in range(1, 4):
		var force_hidden := floor_index == 2 and not floor1_had_hidden
		var rooms := _generate_floor(floor_index, rng, force_hidden)
		if floor_index == 1:
			floor1_had_hidden = rooms.any(func(r): return r["type"] == "hidden")
		floors.append(rooms)

	return floors

static func _generate_floor(floor_index: int, rng: RandomNumberGenerator, force_hidden: bool) -> Array:
	# Hidden-room roll happens first (before any combat-room rng draws) so
	# it's deterministically the *first* rng call when not forced -- tests
	# rely on this to seed-search a guaranteed hit/miss without hand-tracing
	# the rest of the draw sequence.
	var has_hidden: bool = force_hidden or rng.randf() < HIDDEN_ROOM_CHANCE

	var rooms: Array = []
	for i in range(COMBAT_ROOMS_PER_FLOOR[floor_index]):
		rooms.append(_make_combat_room(rng, ENEMIES_PER_COMBAT_ROOM[floor_index]))

	if has_hidden:
		rooms.append(_make_hidden_room())

	_shuffle(rooms, rng) # boss room (added below) is never part of this shuffle

	if floor_index == 3:
		rooms.append(_make_boss_room())

	return rooms

static func _make_combat_room(rng: RandomNumberGenerator, enemy_count: int) -> Dictionary:
	var pool := _normal_enemy_pool()
	var enemy_ids: Array[String] = []
	for i in range(enemy_count):
		enemy_ids.append(pool[rng.randi() % pool.size()]) # sampling with replacement -- see GDD's revision note
	return {"type": "combat", "enemy_ids": enemy_ids, "companion_id": ""}

static func _make_hidden_room() -> Dictionary:
	return {"type": "hidden", "enemy_ids": [], "companion_id": _next_companion_id_for_hidden_room()}

static func _make_boss_room() -> Dictionary:
	return {"type": "boss", "enemy_ids": [_boss_enemy_id()], "companion_id": ""}

static func _normal_enemy_pool() -> Array:
	var pool: Array = []
	for id in EnemyRegistry.get_all_ids():
		if not EnemyRegistry.get_by_id(id).is_boss:
			pool.append(id)
	return pool

static func _boss_enemy_id() -> String:
	for id in EnemyRegistry.get_all_ids():
		if EnemyRegistry.get_by_id(id).is_boss:
			return id
	return ""

static func _next_companion_id_for_hidden_room() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return ""
	var trigger := tree.root.find_child("HiddenTrigger", true, false)
	if trigger and trigger.has_method("get_next_companion_id"):
		return trigger.get_next_companion_id()
	return ""

## Reshuffles #9's companion-id pool for this run, before any hidden rooms
## below draw from it. No-op if the HiddenTrigger autoload isn't present
## (e.g. isolated unit tests calling _generate_floor()/generate_run() without
## the full autoload tree).
static func _reset_hidden_trigger_pool(rng: RandomNumberGenerator) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var trigger := tree.root.find_child("HiddenTrigger", true, false)
	if trigger and trigger.has_method("start_new_run"):
		trigger.start_new_run(rng)

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
