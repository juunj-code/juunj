extends Control
## ADR-0011 mandated smoke test — run this scene (F6) and tap/click both
## elements. See docs/architecture/adr-0011-dual-focus-ui-strategy.md.
## Neither element ever calls grab_focus() — highlight state is a plain
## enum toggled directly by the signal handler, per ADR-0011's Decision.

enum HighlightState { NONE, SELECTABLE, SELECTED }
var highlight_state: int = HighlightState.SELECTABLE

var button_fired := false
var highlight_tapped := false

func _ready() -> void:
	$ActionButton.pressed.connect(_on_button_pressed)
	$Highlight.gui_input.connect(_on_highlight_gui_input)
	$Highlight.mouse_filter = Control.MOUSE_FILTER_STOP
	_update_label()
	queue_redraw()

func _on_button_pressed() -> void:
	button_fired = true
	print("a) Button.pressed fired")
	_update_label()

func _on_highlight_gui_input(event: InputEvent) -> void:
	var is_tap: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if is_tap and highlight_state == HighlightState.SELECTABLE:
		highlight_state = HighlightState.SELECTED
		highlight_tapped = true
		print("b) Highlight reached SELECTED via tap, no grab_focus() ever called")
		queue_redraw()
		_update_label()

func _draw() -> void:
	var rect: Rect2 = Rect2($Highlight.position, $Highlight.size)
	var color := Color.GRAY if highlight_state == HighlightState.SELECTABLE else Color.YELLOW
	draw_rect(rect, color, false, 4.0)

func _update_label() -> void:
	$ResultLabel.text = (
		"a) Button.pressed fired: %s\n"
		+ "b) Highlight box tapped (SELECTED, no grab_focus used): %s\n\n"
		+ "Tap/click the button above, then the outlined box below.\n"
		+ "When both say YES, close and report PASS to Claude.\n"
		+ "If tapping does nothing, report FAIL."
	) % [
		("YES" if button_fired else "not yet"),
		("YES" if highlight_tapped else "not yet"),
	]
