class_name EquipmentData
extends Resource
## Equipment blueprint. See design/gdd/장비.md.

@export var id: String
@export var name: String
@export var slot: String ## "weapon" | "armor"
@export var stat: String ## "atk" | "def"
@export var bonus: int
