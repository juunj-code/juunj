extends GutTest
## Covers design/gdd/씬-관리.md Core Rule 5 / AC1 / AC8: scene_loading_started/
## scene_ready/scene_exited signals. Added 2026-08-08 -- these signals were
## documented in the GDD since authoring but never implemented until now
## (found while authoring #21 오디오, whose BGM crossfade depends on them).
##
## go_to() runs fully synchronously under --headless (see scene_manager.gd's
## _fade() comment), so no await/yield needed here to observe the signals.

func after_each() -> void:
	SceneManager.current_scene_id = "S-01" # don't leak state into other tests

func test_go_to_emits_loading_started_ready_and_exited_in_order() -> void:
	# Arrange
	SceneManager.current_scene_id = "S-01"
	var emitted: Array = []
	SceneManager.scene_loading_started.connect(func(id): emitted.append(["loading_started", id]))
	SceneManager.scene_exited.connect(func(id): emitted.append(["exited", id]))
	SceneManager.scene_ready.connect(func(id): emitted.append(["ready", id]))

	# Act
	SceneManager.go_to("S-02", SceneTransitionRules.TRANSITION_FADE)

	# Assert
	assert_eq(emitted, [
		["loading_started", "S-02"],
		["exited", "S-01"], # the scene being left, not the destination
		["ready", "S-02"],
	])

