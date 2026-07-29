class_name Equipment
extends RefCounted
## Drop rolling + effective-stat computation. See design/gdd/장비.md.
## Doesn't own UI or #2's room-type dispatch -- callers (a combat-room-clear
## handler, or #9 히든 트리거 reusing this for an already-unlocked hidden room
## revisit) decide *whether* to call roll_and_apply_drop() at all; this class
## doesn't know about room types.

const DROP_CHANCE := 0.5

## rng is caller-injected (ADR-0005 pattern) for test determinism. No-op if
## the roll misses. On hit, appends the picked item to run_manager.inventory
## and emits run_manager.equipment_dropped.
static func roll_and_apply_drop(run_manager: Object, rng: RandomNumberGenerator) -> void:
	if rng.randf() >= DROP_CHANCE:
		return
	var pool: Array = EquipmentDatabase.get_all_ids()
	var item_id: String = pool[rng.randi() % pool.size()]
	run_manager.inventory.append(item_id)
	run_manager.equipment_dropped.emit(EquipmentDatabase.get_by_id(item_id))

static func get_effective_atk(companion_state: CompanionRunState) -> int:
	var base: int = CompanionRegistry.get_by_id(companion_state.companion_id).base_atk
	return base + _slot_bonus(companion_state.weapon_slot, "atk")

static func get_effective_def(companion_state: CompanionRunState) -> int:
	var base: int = CompanionRegistry.get_by_id(companion_state.companion_id).base_def
	return base + _slot_bonus(companion_state.armor_slot, "def")

static func _slot_bonus(item_id: String, wanted_stat: String) -> int:
	if item_id == "":
		return 0
	var item: EquipmentData = EquipmentDatabase.get_by_id(item_id)
	if item == null:
		push_warning("Unknown equipment_id: %s" % item_id)
		return 0
	if item.stat != wanted_stat:
		return 0
	return item.bonus

## slot: "weapon" | "armor". Swaps item_id into the slot, returns the previous
## item to run_manager.inventory (if any), and removes item_id from the
## inventory (if present there).
static func equip(run_manager: Object, companion_state: CompanionRunState, slot: String, item_id: String) -> void:
	var previous: String
	if slot == "weapon":
		previous = companion_state.weapon_slot
		companion_state.weapon_slot = item_id
	else:
		previous = companion_state.armor_slot
		companion_state.armor_slot = item_id

	if previous != "":
		run_manager.inventory.append(previous)
	run_manager.inventory.erase(item_id)
