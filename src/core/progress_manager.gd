extends Node
## Autoload (ProgressManager). Cross-run persistent progression -- unlocked
## companions + highest floor reached. See design/gdd/영구-진행.md.
## Separate Autoload from RunManager on purpose: different lifecycles
## (RunManager resets every run, this persists) per the GDD's own resolved
## Open Question 1.

const BASE_COMPANION_ID := "companion_balance_01" ## our actual base (is_hidden=false) companion

signal companion_unlocked(id: String)
signal highest_floor_updated(floor: int)
signal progress_committed(newly_unlocked: Array, save_success: bool)

var unlocked_companions: Array[String] = []
var highest_floor_reached: int = 0

func _ready() -> void:
	_load_from_save()

func _load_from_save() -> void:
	var loaded_unlocks = SaveManager.get_section("companion_unlocks")
	if loaded_unlocks == null:
		unlocked_companions = [BASE_COMPANION_ID]
	else:
		unlocked_companions = []
		for id in loaded_unlocks:
			if CompanionRegistry.get_by_id(id) == null:
				push_warning("Unknown unlocked companion id on load: %s" % id)
				continue
			unlocked_companions.append(id)
		if not unlocked_companions.has(BASE_COMPANION_ID):
			unlocked_companions.append(BASE_COMPANION_ID) # Core Rule 3

	var loaded_floor = SaveManager.get_section("floor_reached")
	highest_floor_reached = int(loaded_floor) if loaded_floor != null else 0

func is_unlocked(id: String) -> bool:
	return unlocked_companions.has(id)

func get_unlocked_companions() -> Array:
	return unlocked_companions

## Debug/QA-only -- the run-end path uses commit_run_end(), not this.
## Immediate save (unlike commit_run_end()'s single batched save).
func unlock_companion(id: String) -> void:
	if CompanionRegistry.get_by_id(id) == null:
		push_warning("Unknown companion id: %s" % id)
		return
	if unlocked_companions.has(id):
		return
	unlocked_companions.append(id)
	SaveManager.save_section("companion_unlocks", unlocked_companions)
	SaveManager.save()
	companion_unlocked.emit(id)

## Debug/QA-only, same caveat as unlock_companion().
func update_highest_floor(floor: int) -> void:
	if floor <= highest_floor_reached:
		return
	highest_floor_reached = floor
	SaveManager.save_section("floor_reached", highest_floor_reached)
	SaveManager.save()
	highest_floor_updated.emit(floor)

## The only run-end entry point. Batches both fields into memory, flushes
## with exactly one SaveManager.save() call regardless of how many companions
## were discovered, then emits signals -- progress_committed fires even on
## save failure so #13 (which waits for it before showing RunResultScreen)
## never hangs.
func commit_run_end(discovered_ids: Array, floor: int) -> Array:
	var newly_unlocked: Array[String] = []
	for id in discovered_ids:
		if CompanionRegistry.get_by_id(id) == null:
			push_warning("Unknown companion id: %s" % id)
			continue
		if not unlocked_companions.has(id):
			unlocked_companions.append(id)
			newly_unlocked.append(id)

	var floor_updated := floor > highest_floor_reached
	if floor_updated:
		highest_floor_reached = floor

	SaveManager.save_section("companion_unlocks", unlocked_companions)
	SaveManager.save_section("floor_reached", highest_floor_reached)
	var success := SaveManager.save()

	for id in newly_unlocked:
		companion_unlocked.emit(id)
	if floor_updated:
		highest_floor_updated.emit(floor)
	progress_committed.emit(newly_unlocked, success)

	return newly_unlocked
