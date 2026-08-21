extends Control
## S-06 RunResultScreen. See design/gdd/런-결과.md. Pure render of
## RunResult.build_display_data() -- all decision logic lives there.
##
## UI Requirement #3 asks for "동료 카드 (초상화 + 이름)" for newly unlocked
## companions -- this used to just join names into DiscoveryLabel's plain
## text (no portrait), a gap the GDD's own AC scope note (line 134, AC
## verification deferred to #20 UI/HUD) let slip through. Cards reuse the
## same portrait/color_accent CompanionData fields the hidden-discovery
## popup and battle cards already use -- no new art.

const _CARD_PORTRAIT_SIZE := Vector2(72, 72)

@onready var _header_label: Label = %HeaderLabel
@onready var _floor_label: Label = %FloorLabel
@onready var _record_label: Label = %RecordLabel
@onready var _discovery_label: Label = %DiscoveryLabel
@onready var _discovery_cards: HBoxContainer = %DiscoveryCards
@onready var _progress_label: Label = %ProgressLabel
@onready var _main_menu_button: Button = %MainMenuButton

func _ready() -> void:
	var display := RunResult.build_display_data(RunManager)
	_header_label.text = display["header"]
	_floor_label.text = display["floor_text"]
	_record_label.visible = display["record_badge"] != ""
	_record_label.text = display["record_badge"]
	_render_discovery(display)
	_progress_label.text = display["progress_text"]
	_main_menu_button.pressed.connect(RunResult.go_to_main_menu)

func _render_discovery(display: Dictionary) -> void:
	var newly_unlocked: Array = display["newly_unlocked_companions"]
	_discovery_label.visible = newly_unlocked.is_empty()
	_discovery_label.text = display["empty_discovery_text"]
	for id in newly_unlocked:
		_discovery_cards.add_child(_build_discovery_card(CompanionRegistry.get_by_id(id)))

func _build_discovery_card(data: CompanionData) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.15, 0.18, 0.78)
	style.border_color = data.color_accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var portrait := TextureRect.new()
	portrait.texture = load(data.portrait_id)
	portrait.custom_minimum_size = _CARD_PORTRAIT_SIZE
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	vbox.add_child(portrait)

	var name_label := Label.new()
	name_label.text = data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(0.941176, 0.929412, 0.901961, 1))
	vbox.add_child(name_label)

	return card
