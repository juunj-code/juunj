extends Node
## Autoload. Thin wrapper over DataRegistryLoader for CompanionData. See ADR-0006.

const FOLDER := "res://assets/data/companions/"

var _companions: Dictionary = {}

func _ready() -> void:
	_companions = DataRegistryLoader.load_all(
		FOLDER,
		func(r: CompanionData) -> bool: return r.base_hp <= 0
	)

func get_by_id(id: String) -> CompanionData:
	return _companions.get(id)

func get_all_ids() -> Array:
	return _companions.keys()
