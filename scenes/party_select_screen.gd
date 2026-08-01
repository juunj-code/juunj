extends Control
## S-03 PartySelectScreen. See design/gdd/파티-구성.md. Equipment slot picking
## (weapon/armor) is skipped for this pass -- PartyComposition.build_party_config()
## already defaults every slot to "" and #4's stat bonuses just won't apply;
## noted as a follow-up, not a blocker for a playable loop.

@onready var _roster_container: VBoxContainer = %RosterContainer
@onready var _start_button: Button = %StartButton

var _composition: PartyComposition
var _buttons: Dictionary = {} # companion_id -> Button

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

func _on_companion_toggled(is_pressed: bool, id: String, button: Button) -> void:
	if is_pressed:
		if not _composition.select_companion(id):
			button.button_pressed = false # rejected -- already full
	else:
		_composition.deselect_companion(id)
	_refresh_start_button()

func _refresh_start_button() -> void:
	_start_button.disabled = not _composition.is_start_active()

func _on_start_pressed() -> void:
	_composition.start_run(RunManager) # start_run() itself transitions to S-04
