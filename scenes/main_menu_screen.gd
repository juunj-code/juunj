extends Control
## S-02 MainMenuScreen. See design/gdd/UI-HUD.md.

@onready var _start_button: Button = %StartButton

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	SceneManager.go_to("S-03", SceneTransitionRules.TRANSITION_FADE)
