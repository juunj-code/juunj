extends Node
## Autoload. Thin wrapper over DataRegistryLoader for EquipmentData. See
## ADR-0006 (same pattern as CompanionRegistry/EnemyRegistry/StatusEffectRegistry,
## even though design/gdd/장비.md calls this a "static dictionary" -- 6 fixed
## items don't need sort/duplicate-check, but reusing the existing registry
## shape beats hand-rolling a second lookup pattern for one system).

const FOLDER := "res://assets/data/equipment/"

var _items: Dictionary = {}

func _ready() -> void:
	_items = DataRegistryLoader.load_all(FOLDER, func(_r: EquipmentData) -> bool: return false)

func get_by_id(id: String) -> EquipmentData:
	return _items.get(id)

func get_all_ids() -> Array:
	return _items.keys()
