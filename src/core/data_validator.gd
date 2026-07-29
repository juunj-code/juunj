class_name DataValidator
extends RefCounted
## Build-time cross-reference checks that no single registry can do alone
## (needs CompanionData + EnemyData + SkillData loaded together). See ADR-0006.
## Pure function: takes loaded registries, returns warning strings. Does not
## push_warning itself -- callers (tools/validate_data.gd, tests) decide what
## to do with the result.

const ENEMY_DAMAGE_MULTIPLIER_MAX := 1.4

## companions/enemies/skills: Dictionary[String, Resource] as returned by
## DataRegistryLoader.load_all() for assets/data/{companions,enemies,skills}/.
static func validate(companions: Dictionary, enemies: Dictionary, skills: Dictionary) -> Array[String]:
	var warnings: Array[String] = []

	for id in companions:
		var companion: CompanionData = companions[id]
		if not skills.has(companion.skill_id):
			warnings.append("Companion '%s' references missing skill_id '%s'" % [id, companion.skill_id])

	for id in enemies:
		var enemy: EnemyData = enemies[id]
		if not skills.has(enemy.skill_id):
			warnings.append("Enemy '%s' references missing skill_id '%s'" % [id, enemy.skill_id])
			continue
		var skill: SkillData = skills[enemy.skill_id]
		if skill.target_type != "enemy":
			warnings.append("Enemy '%s' skill '%s' has target_type '%s', expected 'enemy'" % [id, skill.id, skill.target_type])
		if skill.damage_multiplier > ENEMY_DAMAGE_MULTIPLIER_MAX:
			warnings.append("Enemy '%s' skill '%s' damage_multiplier %s exceeds enemy cap %s" % [id, skill.id, skill.damage_multiplier, ENEMY_DAMAGE_MULTIPLIER_MAX])

	return warnings
