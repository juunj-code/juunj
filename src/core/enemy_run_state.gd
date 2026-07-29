class_name EnemyRunState
extends RefCounted
## Runtime enemy state for the current combat. See design/gdd/런-상태-관리.md.

var enemy_id: String
var current_hp: int
var current_sp: int = 0
var active_effects: Array = [] # Array[StatusEffect] runtime instances, owned by #12
