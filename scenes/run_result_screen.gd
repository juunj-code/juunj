extends Control
## S-06 RunResultScreen. See design/gdd/런-결과.md. Pure render of
## RunResult.build_display_data() -- all decision logic lives there.

@onready var _header_label: Label = %HeaderLabel
@onready var _floor_label: Label = %FloorLabel
@onready var _record_label: Label = %RecordLabel
@onready var _discovery_label: Label = %DiscoveryLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _main_menu_button: Button = %MainMenuButton

func _ready() -> void:
	var display := RunResult.build_display_data(RunManager)
	_header_label.text = display["header"]
	_floor_label.text = display["floor_text"]
	_record_label.visible = display["record_badge"] != ""
	_record_label.text = display["record_badge"]
	_discovery_label.text = _discovery_text(display)
	_progress_label.text = display["progress_text"]
	_main_menu_button.pressed.connect(RunResult.go_to_main_menu)

func _discovery_text(display: Dictionary) -> String:
	var newly_unlocked: Array = display["newly_unlocked_companions"]
	if newly_unlocked.is_empty():
		return display["empty_discovery_text"]
	var names: Array = []
	for id in newly_unlocked:
		var data: CompanionData = CompanionRegistry.get_by_id(id)
		names.append(data.name)
	return "새로운 동료: %s" % ", ".join(names)
