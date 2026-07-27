extends SceneTree
## Baseline v3: diagnose whether gui_input reaches the Control AT ALL in headless.

var _button_fired := false
var _gui_input_count := 0

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var win := get_root()
	print("window visible=", win.visible, " size=", win.size, " has_focus=", win.has_focus())

	var button := Button.new()
	button.text = "Action"
	button.position = Vector2(10, 10)
	button.size = Vector2(88, 44)
	button.pressed.connect(func(): _button_fired = true)
	button.gui_input.connect(func(e): _gui_input_count += 1; print("  gui_input received: ", e))
	win.add_child(button)

	await process_frame
	await process_frame

	print("button global_rect=", button.get_global_rect())

	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(50, 30)
	down.global_position = Vector2(50, 30)
	win.push_input(down)
	await process_frame

	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(50, 30)
	up.global_position = Vector2(50, 30)
	win.push_input(up)
	await process_frame
	await process_frame

	print("=== RESULT ===")
	print("gui_input events received by Button: ", _gui_input_count)
	print("Button.pressed fired: ", _button_fired)
	quit(0 if _button_fired else 1)
