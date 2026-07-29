class_name CompanionRunState
extends RefCounted
## Runtime companion state for the current run. See design/gdd/런-상태-관리.md.
## Owned by RunManager; never a local copy elsewhere (Core Rule 1).

var companion_id: String
var current_hp: int
var current_sp: int = 0
var active_effects: Array = [] # Array[StatusEffect] runtime instances, owned by #12
var weapon_slot: String = ""
var armor_slot: String = ""
