extends Node
## Autoload (HiddenTrigger). Evaluates hidden-room companion discovery.
## See design/gdd/히든-트리거.md. Owns the per-hidden-room companion-id
## assignment (2026-07-26 GDD revision moved this here from #2). The pool
## itself is derived from CompanionRegistry's is_hidden=true companions
## rather than the GDD's hardcoded placeholder id list -- #10's actual data
## (companion_dealer_01/support_01/tank_01, each carrying an
## unlock_condition_id built for exactly this) postdates the GDD text and is
## the real source of truth; deriving from it means this never drifts out of
## sync as the roster changes. Subscribes to RunManager.room_entered itself
## -- #13 never calls into this system directly (Core->Feature dependency
## direction only).

signal companion_discovered(id: String)
signal hidden_room_already_cleared(id: String)

var _remaining_pool: Array[String] = []

func _ready() -> void:
	RunManager.room_entered.connect(_on_room_entered)

## Called by DungeonGenerator (#2) once per run, before it generates any
## hidden rooms -- reshuffles the full hidden-companion pool so every run
## offers all of them regardless of what prior runs already discovered.
func start_new_run(rng: RandomNumberGenerator) -> void:
	_remaining_pool.clear()
	for id in CompanionRegistry.get_all_ids():
		if CompanionRegistry.get_by_id(id).is_hidden:
			_remaining_pool.append(id)
	_shuffle(_remaining_pool, rng)

## Called by DungeonGenerator (#2) once per hidden room it generates.
func get_next_companion_id() -> String:
	if _remaining_pool.is_empty():
		return ""
	return _remaining_pool.pop_front()

## rng is caller-injected (ADR-0005 pattern, same as Equipment.roll_and_apply_drop)
## for test determinism -- only consumed on the already-unlocked path's drop roll.
func evaluate(room_data: Dictionary, rng: RandomNumberGenerator) -> void:
	var companion_id: String = room_data.get("companion_id", "")
	if CompanionRegistry.get_by_id(companion_id) == null:
		push_warning("Unknown companion_id: %s" % companion_id)
		hidden_room_already_cleared.emit(companion_id)
		return
	if ProgressManager.is_unlocked(companion_id):
		hidden_room_already_cleared.emit(companion_id)
		Equipment.roll_and_apply_drop(RunManager, rng)
	else:
		companion_discovered.emit(companion_id)

func _on_room_entered(room_data) -> void:
	if room_data == null or room_data.get("type") != "hidden":
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	evaluate(room_data, rng)

func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
