extends SceneTree
## Build-time data validation. Run via:
## godot --headless -s res://tools/validate_data.gd
## Cross-checks skill_id references across CompanionData/EnemyData/SkillData --
## the runtime registries never load all three folders together, so this is
## the only place these checks can run. See ADR-0006.

func _init() -> void:
	var companions := DataRegistryLoader.load_all(
		"res://assets/data/companions/", func(r: CompanionData) -> bool: return r.base_hp <= 0
	)
	var enemies := DataRegistryLoader.load_all(
		"res://assets/data/enemies/", func(r: EnemyData) -> bool: return r.base_hp <= 0
	)
	var skills := DataRegistryLoader.load_all(
		"res://assets/data/skills/", func(_r: SkillData) -> bool: return false
	)

	var warnings := DataValidator.validate(companions, enemies, skills)
	for warning in warnings:
		push_warning(warning)

	print("validate_data: %d companions, %d enemies, %d skills, %d warnings" % [
		companions.size(), enemies.size(), skills.size(), warnings.size()
	])
	quit(0 if warnings.is_empty() else 1)
