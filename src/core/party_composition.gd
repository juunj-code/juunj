class_name PartyComposition
extends RefCounted
## PartySelectScreen (S-03) orchestration logic. See design/gdd/파티-구성.md.
## Screen rendering is #20's job -- this is the pure selection state + the
## RunManager.start_run() call that "출발" triggers. SceneManager.go_to(S-04)
## is NOT called here -- RunManager.start_run() already does that itself
## (#13's own start_run() step 4), so calling it again here would double-fire
## a scene transition (Core Rule 2 would drop the second one with a warning).

const MAX_PARTY_SIZE := 3
const MIN_PARTY_SIZE := 1

var unlocked_companions: Array[String]
var selected: Array[String] = []
var equipment: Dictionary = {} # companion_id -> {"weapon_slot": String, "armor_slot": String}

## Auto-selects the sole unlocked companion when there's only one (AC8 --
## first-ever run, only the base companion is unlocked).
func _init(unlocked: Array[String]) -> void:
	unlocked_companions = unlocked
	if unlocked.size() == 1:
		select_companion(unlocked[0])

## Returns true if the companion was added. False (no-op) if not unlocked,
## already selected, or the party is already full.
func select_companion(id: String) -> bool:
	if not unlocked_companions.has(id):
		return false
	if selected.has(id):
		return false
	if selected.size() >= MAX_PARTY_SIZE:
		return false
	selected.append(id)
	equipment[id] = {"weapon_slot": "", "armor_slot": ""}
	return true

func deselect_companion(id: String) -> void:
	selected.erase(id)
	equipment.erase(id)

func is_start_active() -> bool:
	return selected.size() >= MIN_PARTY_SIZE

## slot: "weapon" | "armor". No-op if companion_id isn't currently selected.
func equip(companion_id: String, slot: String, item_id: String) -> void:
	if not equipment.has(companion_id):
		return
	equipment[companion_id]["%s_slot" % slot] = item_id

## RunManager.start_run()-shaped party_config. weapon_slot/armor_slot are
## always "" (never null) for unequipped slots.
func build_party_config() -> Array:
	var config := []
	for id in selected:
		var eq: Dictionary = equipment.get(id, {"weapon_slot": "", "armor_slot": ""})
		config.append({
			"companion_id": id,
			"weapon_slot": eq.get("weapon_slot", ""),
			"armor_slot": eq.get("armor_slot", ""),
		})
	return config

## No-op if is_start_active() is false (mirrors #20's disabled-button guard --
## defense in depth in case a caller bypasses the UI state).
func start_run(run_manager: Object) -> void:
	if not is_start_active():
		return
	run_manager.start_run(build_party_config())
