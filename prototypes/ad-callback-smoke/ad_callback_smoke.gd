extends Control
## Throwaway debug scene -- isolates AdManager.show_interstitial()'s JS->GDScript
## callback relay against a real web export, without replaying a full dungeon run.
## See prototypes/ad-callback-smoke/README.md.

var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.text = "booting..."
	_label.add_theme_font_size_override("font_size", 20)
	add_child(_label)

	_append("web=%s" % OS.has_feature("web"))
	_append("calling show_interstitial()...")
	AdManager.show_interstitial(func(): _append("CALLBACK FIRED"))
	_append("show_interstitial() returned, waiting for callback...")

func _append(s: String) -> void:
	_label.text += "\n" + s
