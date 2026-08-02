extends Control
## Throwaway debug scene -- isolates whether a long-running Tween (matching
## SceneManager._fade()'s Tween-driven overlay) resumes cleanly after the
## browser tab sits backgrounded for 30+ seconds (ADR-0004 Verification
## Required item (d) / TR-scene-management-008). See README.md.

const TWEEN_DURATION_SEC := 8.0
const SUSPICIOUS_DELTA_SEC := 0.2 ## flag any frame delta above this

var _label: Label
var _overlay: ColorRect
var _elapsed_sec := 0.0
var _last_heartbeat_sec := 0.0

func _ready() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 20)
	add_child(_label)
	_append("web=%s" % OS.has_feature("web"))
	_append("starting %ds tween -- background the tab now" % int(TWEEN_DURATION_SEC))

	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, TWEEN_DURATION_SEC)
	tween.finished.connect(_on_tween_finished)

func _process(delta: float) -> void:
	_elapsed_sec += delta
	if delta > SUSPICIOUS_DELTA_SEC:
		var msg := "SUSPICIOUS delta=%.3fs at elapsed=%.2fs overlay_a=%.4f" % [delta, _elapsed_sec, _overlay.color.a]
		push_warning(msg)
		_append(msg)
	if _elapsed_sec - _last_heartbeat_sec >= 1.0:
		_last_heartbeat_sec = _elapsed_sec
		_append("heartbeat elapsed=%.1fs overlay_a=%.4f" % [_elapsed_sec, _overlay.color.a])

func _on_tween_finished() -> void:
	var final_a := _overlay.color.a
	var is_exact := is_equal_approx(final_a, 1.0)
	var is_nan := is_nan(final_a)
	var msg := "TWEEN FINISHED final_a=%.6f exact_1.0=%s is_nan=%s" % [final_a, is_exact, is_nan]
	push_warning(msg)
	_append(msg)

func _append(s: String) -> void:
	_label.text += "\n" + s
