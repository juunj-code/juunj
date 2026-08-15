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

	_style_popup_panel()
	_render_floor_room()
	_render_party_hp()
	_popup_panel.visible = false
	# start_run() doesn't emit room_entered (only advance_room()/advance_floor()
	# do) -- bootstrap against whatever room we're already standing in.
	_handle_room(RunManager.current_room_data)

func _render_floor_room() -> void:
	_floor_room_label.text = HudRules.floor_room_text(RunManager.current_floor, RunManager.current_room_index)

## design/art/art-bible.md Section 4-2: 발견금(Discovery gold) marks "탑이
## 비밀을 내어줄 때의 색" -- this popup is exactly that (companion/item finds),
## so it gets a gold-bordered card instead of the default flat gray panel.
func _style_popup_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.15, 0.18, 0.96)
	style.border_color = Color(0.909804, 0.784314, 0.290196) # #E8C84A Discovery
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 10)
	_popup_panel.add_theme_stylebox_override("panel", style)

## Same bordered-card language as battle_screen.gd's unit cards (reuses
## CompanionData.color_accent, no new asset) so the HP readout while exploring
## matches what the player already saw in combat.
func _render_party_hp() -> void:
	for child in _party_hp_container.get_children():
		child.queue_free()
	for run_state in RunManager.party:
		var data: CompanionData = CompanionRegistry.get_by_id(run_state.companion_id)
		_party_hp_container.add_child(_build_hp_card(data, run_state.current_hp))

func _build_hp_card(data: CompanionData, current_hp: int) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.15, 0.18, 0.8)
	style.border_color = data.color_accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	var name_label := Label.new()
	name_label.text = data.name
	name_label.custom_minimum_size = Vector2(100, 0)
	row.add_child(name_label)

	var hp_bar := ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = data.base_hp
	hp_bar.value = current_hp
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, 10)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(hp_bar)

	var hp_label := Label.new()
	hp_label.text = "%d/%d" % [current_hp, data.base_hp]
	row.add_child(hp_label)

	return card

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
