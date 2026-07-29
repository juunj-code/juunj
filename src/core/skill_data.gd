class_name SkillData
extends Resource
## Static skill blueprint. See design/gdd/동료-데이터.md "SkillData 스키마".

@export var id: String
@export var name: String
@export var description: String
@export var target_type: String = "enemy" ## "enemy" | "self" | "ally" | "all_allies"
@export var damage_multiplier: float = 1.0 ## valid range 0.5~3.0, used when target_type == "enemy"
@export var heal_multiplier: float = 0.0 ## valid range 0.0~1.0, used when target_type in self/ally/all_allies
@export var effect_id: String = "" ## #12 상태이상 reference, "" = none
@export var cost_sp: int = 0 ## valid range 0~5
