extends Node
## Autoload. Thin wrapper over DataRegistryLoader for StatusEffect. See ADR-0006.

const FOLDER := "res://assets/data/status_effects/"

var _effects: Dictionary = {}

func _ready() -> void:
	_effects = DataRegistryLoader.load_all(FOLDER, func(_r: StatusEffect) -> bool: return false)

func get_by_id(id: String) -> StatusEffect:
	return _effects.get(id)
