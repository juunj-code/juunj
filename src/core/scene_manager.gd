extends Node
## Autoload (SceneManager). Engine-integrated half of #19 씬 관리 -- Tween-driven
## fade/flash overlay + scene swap, built on top of the already-tested pure
## logic in SceneTransitionRules (durations/graph/color). See design/gdd/
## 씬-관리.md and architecture.md's `SceneManager` API Boundary.
##
## ponytail: ADR-0004 picked non-threaded export as the safe default (COOP/COEP
## unverified), so scene loads here are synchronous (ResourceLoader.load() via
## change_scene_to_file()) -- no load-progress/timeout/loading-indicator
## plumbing, since local .tscn loads are effectively instant and there's
## nothing to show progress for. Add threaded loading + SceneTransitionRules'
## timeout/indicator thresholds if real web load times ever require it.

const SCENE_PATHS := {
	"S-01": "res://scenes/Boot.tscn",
	"S-02": "res://scenes/MainMenuScreen.tscn",
	"S-03": "res://scenes/PartySelectScreen.tscn",
	"S-04": "res://scenes/DungeonExplorationScreen.tscn",
	"S-05": "res://scenes/BattleScreen.tscn",
	"S-06": "res://scenes/RunResultScreen.tscn",
}

var current_scene_id: String = "S-01"

var _overlay: ColorRect
var _is_transitioning := false
var _active_tween: Tween

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay)
	add_child(layer)

## architecture.md boundary contract: re-entrant calls during a transition are
## ignored (no double-transition).
func go_to(scene_id: String, transition: String, color: Color = Color.WHITE) -> void:
	if _is_transitioning:
		push_warning("SceneManager.go_to(%s) ignored -- transition already in progress" % scene_id)
		return
	if not SCENE_PATHS.has(scene_id):
		push_error("SceneManager.go_to: unknown scene_id %s" % scene_id)
		return
	if not SceneTransitionRules.is_declared_edge(current_scene_id, scene_id):
		push_warning("SceneManager.go_to: %s -> %s is not a declared transition edge" % [current_scene_id, scene_id])

	_is_transitioning = true
	var durations := SceneTransitionRules.transition_durations(transition)
	var overlay_color := Color.BLACK if transition == SceneTransitionRules.TRANSITION_FADE else SceneTransitionRules.resolve_flash_color(color)

	await _fade(overlay_color, 0.0, 1.0, durations["in_ms"] / 1000.0)
	get_tree().change_scene_to_file(SCENE_PATHS[scene_id])
	current_scene_id = scene_id
	# Flag drops here, not after the fade-out below -- "이중 전환 방지" only
	# needs to prevent two change_scene_to_file() calls racing. The incoming
	# scene's own _ready() can legitimately call go_to() again immediately
	# (e.g. #4 auto-entering combat on room 1), and blocking that until a
	# cosmetic fade-out finishes would silently drop a real transition.
	_is_transitioning = false
	await _fade(overlay_color, 1.0, 0.0, durations["out_ms"] / 1000.0)

func _fade(color: Color, from_alpha: float, to_alpha: float, duration_sec: float) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill() # a fade-out can be interrupted by the next fade-in (chained transitions)
	_overlay.color = Color(color.r, color.g, color.b, from_alpha)
	if duration_sec <= 0.0:
		_overlay.color.a = to_alpha
		return
	_active_tween = create_tween()
	_active_tween.tween_property(_overlay, "color:a", to_alpha, duration_sec)
	await _active_tween.finished
