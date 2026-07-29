extends GutTest
## Covers design/gdd/동료-데이터.md AC4 and design/gdd/적-데이터.md AC9 --
## the build-time cross-reference checks no single registry can do alone.

func _make_skill(id: String, target_type: String, damage_multiplier: float) -> SkillData:
	var s := SkillData.new()
	s.id = id
	s.target_type = target_type
	s.damage_multiplier = damage_multiplier
	return s

func _make_enemy(id: String, skill_id: String) -> EnemyData:
	var e := EnemyData.new()
	e.id = id
	e.skill_id = skill_id
	e.base_hp = 30
	return e

func _make_companion(id: String, skill_id: String) -> CompanionData:
	var c := CompanionData.new()
	c.id = id
	c.skill_id = skill_id
	c.base_hp = 100
	return c

func test_valid_data_produces_no_warnings() -> void:
	# Arrange
	var skills := {"skill_a": _make_skill("skill_a", "enemy", 1.0)}
	var enemies := {"e1": _make_enemy("e1", "skill_a")}
	var companions := {"c1": _make_companion("c1", "skill_a")}

	# Act
	var warnings := DataValidator.validate(companions, enemies, skills)

	# Assert
	assert_eq(warnings.size(), 0)

func test_companion_dangling_skill_id_warns() -> void: # #10 AC4
	# Arrange
	var companions := {"c1": _make_companion("c1", "missing_skill")}

	# Act
	var warnings := DataValidator.validate(companions, {}, {})

	# Assert
	assert_eq(warnings.size(), 1)
	assert_true(warnings[0].contains("c1"))

func test_enemy_skill_wrong_target_type_warns() -> void: # #11 AC9
	# Arrange
	var skills := {"skill_a": _make_skill("skill_a", "ally", 1.0)}
	var enemies := {"e1": _make_enemy("e1", "skill_a")}

	# Act
	var warnings := DataValidator.validate({}, enemies, skills)

	# Assert
	assert_eq(warnings.size(), 1)
	assert_true(warnings[0].contains("target_type"))

func test_enemy_skill_damage_multiplier_over_cap_warns() -> void: # #11 AC9
	# Arrange
	var skills := {"skill_a": _make_skill("skill_a", "enemy", 1.5)}
	var enemies := {"e1": _make_enemy("e1", "skill_a")}

	# Act
	var warnings := DataValidator.validate({}, enemies, skills)

	# Assert
	assert_eq(warnings.size(), 1)
	assert_true(warnings[0].contains("exceeds"))
