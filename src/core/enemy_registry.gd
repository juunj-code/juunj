extends Node
## Autoload. Thin wrapper over DataRegistryLoader for EnemyData. See ADR-0006.

const FOLDER := "res://assets/data/enemies/"

var _enemies: Dictionary = {}

func _ready() -> void:
	_enemies = DataRegistryLoader.load_all(
		FOLDER,
		func(r: EnemyData) -> bool: return r.base_hp <= 0
	)

func get_by_id(id: String) -> EnemyData:
	return _enemies.get(id)

func get_all_ids() -> Array:
	return _enemies.keys()
