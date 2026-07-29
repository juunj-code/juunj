class_name StatusEffect
extends Resource
## Status effect blueprint. See design/gdd/상태이상.md.
## Applied instances are duplicate()'d copies -- never share this resource
## across units (Godot resource caching would otherwise alias duration).

@export var id: String
@export var name: String
@export var type: String ## "DOT" | "SKIP_TURN" | "STAT_MODIFY"
@export var value: int = 0 ## DOT: damage amount / STAT_MODIFY: stat delta / SKIP_TURN: unused
@export var stat_target: String = "" ## STAT_MODIFY only: "atk" | "def"
@export var duration: int ## remaining turns; runtime copies decrement this
