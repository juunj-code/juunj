extends Control
## Throwaway debug scene, round 6 -- verifies the redesigned localStorage-based
## SaveManager (see save_manager.gd header) against a real web export: save a
## section, wipe in-memory state, reload, confirm the value round-tripped.

var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.text = "booting..."
	_label.add_theme_font_size_override("font_size", 20)
	add_child(_label)

	_append("web=%s" % OS.has_feature("web"))

	SaveManager.save_section("smoke_test", {"value": 42, "ts": Time.get_ticks_msec()})
	var ok := SaveManager.save()
	_append("save() returned %s" % ok)

	SaveManager._sections = {}
	SaveManager.load_from_disk()
	var loaded = SaveManager.get_section("smoke_test")
	_append("reloaded section: %s" % loaded)
	_append("PASS" if loaded != null and loaded.get("value") == 42 else "FAIL")

func _append(s: String) -> void:
	_label.text += "\n" + s
