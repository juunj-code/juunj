extends Node
## S-01 Boot. No splash content (no art assets yet) -- immediately hands off
## to MainMenu. See design/gdd/씬-관리.md.

func _ready() -> void:
	SceneManager.go_to("S-02", SceneTransitionRules.TRANSITION_FADE)
