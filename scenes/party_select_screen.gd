extends Control
## S-03 PartySelectScreen. See design/gdd/파티-구성.md.

@onready var _roster_container: VBoxContainer = %RosterContainer
@onready var _start_button: Button = %StartButton

var _composition: PartyComposition
var _buttons: Dictionary = {} # companion_id -> Button
var _weapon_pickers: Dictionary = {} # companion_id -> OptionButton
var _armor_pickers: Dictionary = {} # companion_id -> OptionButton

func _ready() -> void:
	_composition = PartyComposition.new(ProgressManager.get_unlocked_companions())
	_build_roster()
	_start_button.pressed.connect(_on_start_pressed)
	_refresh_start_button()

func _build_roster() -> void:
	for id in _composition.unlocked_companions:
		var data: CompanionData = CompanionRegistry.get_by_id(id)
		var button := Button.new()
		button.text = data.name
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 44)
		button.button_pressed = _composition.selected.has(id)
		if data.portrait_id != "":
			button.icon = load(data.portrait_id)
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 40)
		button.toggled.connect(_on_companion_toggled.bind(id, button))
		_roster_container.add_child(button)
		_buttons[id] = button

		var weapon_picker := _build_equipment_picker(id, "weapon")
		var armor_picker := _build_equipment_picker(id, "armor")
		_roster_container.add_child(weapon_picker)
		_roster_container.add_child(armor_picker)
		_weapon_pickers[id] = weapon_picker
		_armor_pickers[id] = armor_picker

	_refresh_all_pickers()

func _build_equipment_picker(id: String, slot: String) -> OptionButton:
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(0, 44)
	picker.item_selected.connect(_on_equipment_selected.bind(id, slot, picker))
	return picker

func _on_companion_toggled(is_pressed: bool, id: String, button: Button) -> void:
	if is_pressed:
		if not _composition.select_companion(id):
			button.button_pressed = false # rejected -- already full
	else:
		_return_equipment_to_inventory(id)
		_composition.deselect_companion(id)
	_refresh_all_pickers()
	_refresh_start_button()

## Deselecting a companion drops its slot picks -- return them to the shared
## inventory instead of silently discarding the items.
func _return_equipment_to_inventory(id: String) -> void:
	var eq: Dictionary = _composition.equipment.get(id, {})
	for slot_key in ["weapon_slot", "armor_slot"]:
		var item_id: String = eq.get(slot_key, "")
		if item_id != "":
			RunManager.inventory.append(item_id)

func _on_equipment_selected(index: int, id: String, slot: String, picker: OptionButton) -> void:
	var new_item_id: String = picker.get_item_metadata(index)
	var old_item_id: String = _composition.equipment[id]["%s_slot" % slot]
	if old_item_id != "":
		RunManager.inventory.append(old_item_id)
	if new_item_id != "":
		RunManager.inventory.erase(new_item_id)
	_composition.equip(id, slot, new_item_id)
	_refresh_all_pickers()

## Rebuilds every visible picker's option list from the current shared
## inventory (an equip on one companion removes that item from every other
## companion's choices) and shows/hides pickers by selection state.
func _refresh_all_pickers() -> void:
	for id in _weapon_pickers:
		var is_selected: bool = _composition.selected.has(id)
		_weapon_pickers[id].visible = is_selected
		_armor_pickers[id].visible = is_selected
		if is_selected:
			_rebuild_picker(_weapon_pickers[id], id, "weapon")
			_rebuild_picker(_armor_pickers[id], id, "armor")

func _rebuild_picker(picker: OptionButton, id: String, slot: String) -> void:
	picker.clear()
	picker.add_item("장착 안 함")
	picker.set_item_metadata(0, "")
	var equipped: String = _composition.equipment[id]["%s_slot" % slot]
	var seen: Dictionary = {}
	var index := 1
	if equipped != "":
		_add_picker_item(picker, index, equipped)
		seen[equipped] = true
		index += 1
	for item_id in RunManager.inventory:
		if seen.has(item_id):
			continue
		var item: EquipmentData = EquipmentDatabase.get_by_id(item_id)
		if item.slot != slot:
			continue
		_add_picker_item(picker, index, item_id)
		seen[item_id] = true
		index += 1
	picker.select(1 if equipped != "" else 0)

func _add_picker_item(picker: OptionButton, index: int, item_id: String) -> void:
	picker.add_item(EquipmentDatabase.get_by_id(item_id).name)
	picker.set_item_metadata(index, item_id)

func _refresh_start_button() -> void:
	_start_button.disabled = not _composition.is_start_active()

func _on_start_pressed() -> void:
	_composition.start_run(RunManager) # start_run() itself transitions to S-04
