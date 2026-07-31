extends Control
## S-04 DungeonExplorationScreen. See design/gdd/UI-HUD.md. Owns the single
## popup queue for #3/#9/#4's discovery/drop signals (Core Rule 3) and the
## room-progression button. Combat/boss rooms auto-enter (#2's room data
## carries no player choice about whether to fight).

@onready var _floor_room_label: Label = %FloorRoomLabel
@onready var _party_hp_container: VBoxContainer = %PartyHpContainer
@onready var _advance_button: Button = %AdvanceButton
@onready var _popup_panel: PanelContainer = %PopupPanel
@onready var _popup_title: Label = %PopupTitle
@onready var _popup_body: Label = %PopupBody
@onready var _popup_confirm: Button = %PopupConfirm

var _popup_queue := HudPopupQueue.new()

func _ready() -> void:
	if RunManager.state != "EXPLORING":
		push_warning("DungeonExplorationScreen loaded while RunManager.state=%s -- ignoring" % RunManager.state)
		return
	CompanionUnlock.companion_unlocked_this_run.connect(_on_companion_unlocked)
	HiddenTrigger.hidden_room_already_cleared.connect(_on_hidden_room_already_cleared)
	RunManager.equipment_dropped.connect(_on_equipment_dropped)
	RunManager.room_entered.connect(_on_room_entered)
	_advance_button.pressed.connect(_on_advance_pressed)
	_popup_confirm.pressed.connect(_on_popup_confirm_pressed)

	_render_floor_room()
	_render_party_hp()
	_popup_panel.visible = false
	# start_run() doesn't emit room_entered (only advance_room()/advance_floor()
	# do) -- bootstrap against whatever room we're already standing in.
	_handle_room(RunManager.current_room_data)

func _render_floor_room() -> void:
	_floor_room_label.text = HudRules.floor_room_text(RunManager.current_floor, RunManager.current_room_index)

func _render_party_hp() -> void:
	for child in _party_hp_container.get_children():
		child.queue_free()
	for run_state in RunManager.party:
		var data: CompanionData = CompanionRegistry.get_by_id(run_state.companion_id)
		var label := Label.new()
		label.text = "%s  %d/%d" % [data.name, run_state.current_hp, data.base_hp]
		_party_hp_container.add_child(label)

func _on_room_entered(room_data) -> void:
	_render_floor_room()
	_handle_room(room_data)

func _handle_room(room_data) -> void:
	if room_data == null:
		return
	if room_data.get("type") in ["combat", "boss"]:
		_advance_button.disabled = true
		RunManager.enter_combat(room_data["enemy_ids"])

func _on_advance_pressed() -> void:
	var rooms: Array = RunManager.floor_rooms[RunManager.current_floor - 1]
	if RunManager.current_room_index >= rooms.size():
		if RunManager.current_floor >= RunManager.MAX_FLOOR:
			RunManager.end_run(true)
		else:
			RunManager.advance_floor()
	else:
		RunManager.advance_room()
	_render_party_hp()

func _on_companion_unlocked(_id: String, comp_name: String, description: String, _portrait_id: String, _color_accent: Color) -> void:
	_popup_queue.enqueue({
		"type": "companion",
		"title": "%s가 동료가 되었다!" % comp_name,
		"body": "%s\n도감에 영구 등록됨" % description,
	})
	_try_show_popup()

func _on_hidden_room_already_cleared(_id: String) -> void:
	_popup_queue.enqueue({"type": "cleared", "title": "이미 동료가 되어 있어요", "body": ""})
	_try_show_popup()

func _on_equipment_dropped(item_data: EquipmentData) -> void:
	var stat_label := "공격력" if item_data.stat == "atk" else "방어력"
	_popup_queue.enqueue({
		"type": "equipment",
		"title": item_data.name,
		"body": "%s +%d" % [stat_label, item_data.bonus],
	})
	_try_show_popup()

func _try_show_popup() -> void:
	if not _popup_panel.visible and _popup_queue.is_blocking():
		_render_popup()

func _render_popup() -> void:
	_popup_title.text = _popup_queue.current["title"]
	_popup_body.text = _popup_queue.current["body"]
	_popup_panel.visible = true
	_advance_button.disabled = true

func _on_popup_confirm_pressed() -> void:
	var was_companion: bool = _popup_queue.current.get("type", "") == "companion"
	_popup_queue.confirm()
	if was_companion:
		CompanionUnlock.popup_confirmed.emit()
	if _popup_queue.is_blocking():
		_render_popup()
	else:
		_popup_panel.visible = false
		_advance_button.disabled = false
