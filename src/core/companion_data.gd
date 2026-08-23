class_name CompanionData
extends Resource
## Immutable companion blueprint. See design/gdd/동료-데이터.md.
## Runtime HP/buffs live in #13 런 상태 관리; unlock state lives in #14 영구 진행.

@export var id: String
@export var name: String
@export var description: String
@export var class_type: String ## "tank" | "dealer" | "balance" | "support" — pure tag, not used in math

@export var backstory: String = "" ## #22 동료 내러티브 — party select 화면에 노출되는 배경 서사
@export var meeting_line: String = "" ## #22 동료 내러티브 — 해금 팝업에 노출되는 1인칭 만남 대사

@export var portrait_id: String = ""
@export var color_accent: Color

@export var base_hp: int ## 60~150; <= 0 is a load-rejection condition, not a soft warning
@export var base_atk: int ## 10~30
@export var base_def: int ## 5~20
@export var base_spd: int ## 1~10

@export var skill_id: String

@export var is_hidden: bool = false
@export var unlock_condition_id: String = ""
