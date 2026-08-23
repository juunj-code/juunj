extends Node
## Autoload (RunManager). Owns all dynamic state for the current run --
## party/enemy runtime stats, floor/room position, discovered companions.
## See design/gdd/런-상태-관리.md.
##
## ponytail: SceneManager (#19) and ProgressManager (#14) autoloads now exist
## (registered in project.godot), but calls to them still go through defensive
## get_node_or_null() checks (no-op if absent) plus an overridable Callable
## test seam -- kept for test isolation (e.g. swapping in a spy without the
## real autoload in the tree). Remove the seam only if it stops earning its
## keep.

const MAX_FLOOR := 3

signal floor_changed(new_floor: int)
signal combat_entered(enemies: Array)
signal combat_exited(victory: bool)
signal run_ended(success: bool)
signal state_changed(old_state: String, new_state: String)
signal room_entered(room_data)
signal equipment_dropped(item_data: EquipmentData)

var state: String = "IDLE"
var current_floor: int = 0
var current_room_index: int = 0
var is_success: bool = false
var current_room_data: Variant = null # derived from floor_rooms by _refresh_current_room_data()
var floor_rooms: Array = [] ## Array[Array[Dictionary]] from DungeonGenerator.generate_run(), set in start_run()

var _run_rng: RandomNumberGenerator = null

var _party: Array = []
var party: Array:
	get:
		if state == "IDLE" or state == "RUN_ENDED":
			push_error("RunManager.party accessed while state=%s" % state)
			return []
		return _party

var _current_enemies: Array = []
var current_enemies: Array:
	get:
		if state == "IDLE" or state == "RUN_ENDED":
			push_error("RunManager.current_enemies accessed while state=%s" % state)
			return []
		return _current_enemies

var discovered_companions: Array[String] = []
var inventory: Array[String] = [] ## equipment_id list, owned per design/gdd/장비.md

## Result data #16 런 결과 reads (assembled here per its GDD -- #16 doesn't
## talk to #14 directly). Set by end_run()'s progress handoff.
var last_newly_unlocked: Array = []
var last_is_new_record: bool = false

## Test seams -- see ponytail note above. Handoff override signature:
## func(discovered_ids: Array, floor: int) -> Dictionary{newly_unlocked, is_new_record}
var _scene_navigator_override: Callable = Callable()
var _progress_handoff_override: Callable = Callable()

func start_run(party_config: Array) -> void:
	_party.clear()
	for entry in party_config:
		var data: CompanionData = CompanionRegistry.get_by_id(entry["companion_id"])
		var run_state := CompanionRunState.new()
		run_state.companion_id = entry["companion_id"]
		run_state.current_hp = data.base_hp
		run_state.current_sp = 0
		run_state.weapon_slot = entry.get("weapon_slot", "")
		run_state.armor_slot = entry.get("armor_slot", "")
		_party.append(run_state)

	current_floor = 1
	current_room_index = 1
	discovered_companions.clear()
	_run_rng = RandomNumberGenerator.new()
	floor_rooms = DungeonGenerator.generate_run(_run_rng)
	_refresh_current_room_data()
	_set_state("EXPLORING")
	_go_to_scene("S-04", "FADE")

func enter_combat(enemy_ids: Array) -> void:
	_current_enemies.clear()
	for enemy_id in enemy_ids:
		var data: EnemyData = EnemyRegistry.get_by_id(enemy_id)
		var run_state := EnemyRunState.new()
		run_state.enemy_id = enemy_id
		run_state.current_hp = data.base_hp
		run_state.current_sp = 0
		_current_enemies.append(run_state)
	_set_state("IN_COMBAT")
	combat_entered.emit(_current_enemies)
	_go_to_scene("S-05", "FADE")

## 장비.md AC1/AC6 -- combat-room clear rolls a drop, boss rooms don't. Found
## via GDD-vs-implementation audit (2026-08-23): Equipment.roll_and_apply_drop()
## previously had no caller anywhere on this path (only #9's already-unlocked
## hidden-room-revisit called it) -- the game's stated main gear-acquisition
## loop never actually fired.
##
## 상태이상.md AC9 -- also found via the same audit method (2026-08-23):
## CompanionRunState persists across every battle in a run (unlike
## EnemyRunState, recreated fresh per enter_combat()), and nothing ever
## cleared active_effects here -- a defense_up/poison still active when a
## fight ends in victory silently carried into the next combat room.
func exit_combat_victory() -> void:
	_current_enemies.clear()
	if current_room_data != null and current_room_data.get("type", "") == "combat":
		Equipment.roll_and_apply_drop(self, _run_rng)
	for companion in _party:
		companion.active_effects = []
	_set_state("EXPLORING")
	combat_exited.emit(true)
	_go_to_scene("S-04", "FADE")

## Idempotent -- a second call while already RUN_ENDED is a no-op (AC9b).
func end_run(success: bool) -> void:
	if state == "RUN_ENDED":
		return
	is_success = success
	_set_state("RUN_ENDED")
	_handoff_discovered_companions()
	run_ended.emit(success)
	_go_to_scene("S-06", "FADE")

func reset() -> void:
	_party.clear()
	_current_enemies.clear()
	discovered_companions.clear()
	inventory.clear()
	current_floor = 0
	current_room_index = 0
	floor_rooms = []
	current_room_data = null
	_run_rng = null
	is_success = false
	_set_state("IDLE")

func advance_floor() -> void:
	if state == "IDLE" or state == "RUN_ENDED":
		push_error("RunManager.advance_floor() called while state=%s" % state)
		return
	if current_floor >= MAX_FLOOR:
		push_error("RunManager.advance_floor() called at max floor %d" % MAX_FLOOR)
		return
	current_floor += 1
	current_room_index = 1
	_refresh_current_room_data()
	floor_changed.emit(current_floor)
	room_entered.emit(current_room_data)

func advance_room() -> void:
	if state == "IDLE" or state == "RUN_ENDED":
		push_error("RunManager.advance_room() called while state=%s" % state)
		return
	current_room_index += 1
	_refresh_current_room_data()
	room_entered.emit(current_room_data)

func add_discovered_companion(id: String) -> void:
	if state == "IDLE" or state == "RUN_ENDED":
		push_error("RunManager.add_discovered_companion() called while state=%s" % state)
		return
	if not discovered_companions.has(id):
		discovered_companions.append(id)

func _refresh_current_room_data() -> void:
	if floor_rooms.is_empty():
		current_room_data = null
		return
	var floor: Array = floor_rooms[current_floor - 1]
	current_room_data = floor[current_room_index - 1] if current_room_index - 1 < floor.size() else null

func _set_state(new_state: String) -> void:
	var old_state := state
	state = new_state
	state_changed.emit(old_state, new_state)

func _go_to_scene(scene_id: String, transition: String) -> void:
	if _scene_navigator_override.is_valid():
		_scene_navigator_override.call(scene_id, transition)
		return
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("go_to"):
		scene_manager.go_to(scene_id, transition)

func _handoff_discovered_companions() -> void:
	if _progress_handoff_override.is_valid():
		var result: Dictionary = _progress_handoff_override.call(discovered_companions, current_floor)
		last_newly_unlocked = result.get("newly_unlocked", [])
		last_is_new_record = result.get("is_new_record", false)
		return
	var progress_manager := get_node_or_null("/root/ProgressManager")
	if progress_manager and progress_manager.has_method("commit_run_end"):
		last_is_new_record = current_floor > progress_manager.highest_floor_reached
		last_newly_unlocked = progress_manager.commit_run_end(discovered_companions, current_floor)
	else:
		last_newly_unlocked = []
		last_is_new_record = false
