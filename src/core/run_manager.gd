extends Node
## Autoload (RunManager). Owns all dynamic state for the current run --
## party/enemy runtime stats, floor/room position, discovered companions.
## See design/gdd/런-상태-관리.md.
##
## ponytail: SceneManager (#19) and ProgressManager (#14) autoloads don't
## exist yet, so calls to them go through defensive get_node_or_null() checks
## (no-op if absent) plus an overridable Callable test seam. Once those
## autoloads exist this needs no changes -- remove the seam only if it stops
## earning its keep.

const MAX_FLOOR := 3

signal floor_changed(new_floor: int)
signal combat_entered(enemies: Array)
signal combat_exited(victory: bool)
signal run_ended(success: bool)
signal state_changed(old_state: String, new_state: String)
signal room_entered(room_data)

var state: String = "IDLE"
var current_floor: int = 0
var current_room_index: int = 0
var is_success: bool = false
var current_room_data: Variant = null # populated externally by #2 랜덤 던전 (not built yet)

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

## Test seams -- see ponytail note above.
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

func exit_combat_victory() -> void:
	_current_enemies.clear()
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
	current_floor = 0
	current_room_index = 0
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
	floor_changed.emit(current_floor)
	room_entered.emit(current_room_data)

func advance_room() -> void:
	if state == "IDLE" or state == "RUN_ENDED":
		push_error("RunManager.advance_room() called while state=%s" % state)
		return
	current_room_index += 1
	room_entered.emit(current_room_data)

func add_discovered_companion(id: String) -> void:
	if state == "IDLE" or state == "RUN_ENDED":
		push_error("RunManager.add_discovered_companion() called while state=%s" % state)
		return
	if not discovered_companions.has(id):
		discovered_companions.append(id)

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
		_progress_handoff_override.call(discovered_companions)
		return
	var progress_manager := get_node_or_null("/root/ProgressManager")
	if progress_manager and progress_manager.has_method("commit_discovered"):
		progress_manager.commit_discovered(discovered_companions)
