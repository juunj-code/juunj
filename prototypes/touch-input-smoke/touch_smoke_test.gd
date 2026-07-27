extends SceneTree
## ADR-0011 mandated throwaway smoke test — see docs/architecture/adr-0011-dual-focus-ui-strategy.md
## Verifies: (a) touch reaches Button.pressed, (b) a native-Focus-independent
## boolean/enum highlight (per ADR-0011's EnemyTargetHighlight pseudocode)
## responds to tap without ever calling grab_focus().
## Run: godot --headless --script prototypes/touch-input-smoke/touch_smoke_test.gd

enum HighlightState { NONE, SELECTABLE, SELECTED }

var _button_fired := false
var _highlight_state: int = HighlightState.NONE
var _highlight_tapped := false

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var win := get_root()

	var button := Button.new()
	button.text = "Action"
	button.position = Vector2(10, 10)
	button.size = Vector2(88, 44)
	button.pressed.connect(func(): _button_fired = true)
	win.add_child(button)

	var highlight := Control.new()
	highlight.position = Vector2(200, 10)
	highlight.size = Vector2(88, 44)
	highlight.mouse_filter = Control.MOUSE_FILTER_STOP
	_highlight_state = HighlightState.SELECTABLE
	highlight.gui_input.connect(_on_highlight_gui_input)
	win.add_child(highlight)

	await process_frame
	await process_frame

	print("--- pre-tap ---")
	print("button.has_focus(): ", button.has_focus())
	print("highlight.has_focus(): ", highlight.has_focus())

	_push_touch(Vector2(50, 30), true)
	await process_frame
	_push_touch(Vector2(50, 30), false)
	await process_frame
	await process_frame

	_push_touch(Vector2(240, 30), true)
	await process_frame
	_push_touch(Vector2(240, 30), false)
	await process_frame
	await process_frame

	print("=== RESULTS ===")
	print("a) Button.pressed fired from InputEventScreenTouch: ", _button_fired)
	print("b) Custom highlight (no grab_focus() call anywhere in this script) reached SELECTED via tap: ", _highlight_tapped, " (state=", _highlight_state, ", 2=SELECTED expected)")
	print("c) button.has_focus() after tap (native focus state, irrelevant to our tap logic by design): ", button.has_focus())

	quit(0 if (_button_fired and _highlight_tapped) else 1)

func _on_highlight_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if _highlight_state == HighlightState.SELECTABLE:
			_highlight_state = HighlightState.SELECTED
			_highlight_tapped = true

func _push_touch(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.position = pos
	ev.pressed = pressed
	Input.parse_input_event(ev)
