class_name EnemyData
extends Resource
## Immutable enemy blueprint. See design/gdd/적-데이터.md.
## Runtime HP/buffs live in #13 런 상태 관리; AI behavior logic lives in #7 적 AI.

@export var id: String
@export var name: String
@export var sprite_id: String = ""

@export var base_hp: int ## normal: 25~65, boss: 150~300; <= 0 is a load-rejection condition
@export var base_atk: int ## normal: 8~18, boss: 15~25
@export var base_def: int ## normal: 3~12, boss: 10~20
@export var base_spd: int ## normal: 1~9, boss: 4~9

@export var skill_id: String ## references a SkillData with target_type="enemy", damage_multiplier 0.5~1.4

@export var is_boss: bool = false
