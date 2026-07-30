extends Node
## Autoload. Thin wrapper over DataRegistryLoader for SkillData. See ADR-0006.

const FOLDER := "res://assets/data/skills/"

var _skills: Dictionary = {}

func _ready() -> void:
	_skills = DataRegistryLoader.load_all(FOLDER, func(_r: SkillData) -> bool: return false)

func get_by_id(id: String) -> SkillData:
	return _skills.get(id)
