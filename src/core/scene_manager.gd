extends Node
## Autoload (SceneManager). Engine-integrated half of #19 씬 관리 -- Tween-driven
## fade/flash overlay + scene swap, built on top of the already-tested pure
## logic in SceneTransitionRules (durations/graph/color). See design/gdd/
## 씬-관리.md and architecture.md's `SceneManager` API Boundary.
##
## ponytail: ADR-0004 picked non-threaded export as the safe default (COOP/COEP
## unverified). Real-web-build measurement (2026-08-03, ADR-0004 Last Verified)
## found ResourceLoader.load() blocking 27-48ms for DungeonExploration/
## BattleScreen -- over the 16.6ms frame budget, all of it in the resource
## load itself (scene swap is <2ms). Fixed per Godot's documented threaded-load
## pattern: load_threaded_request() before the fade-in Tween, then poll
## load_threaded_get_status() once per frame while the fade runs (this is what
## actually advances the load in the non-threaded/degraded case -- without
## polling, the "background" load does not progress at all until get() is
## called). load_threaded_get() after the fade then just blocks on whatever
## sliver is left, usually ~0ms since the ~300ms fade is far longer than any
## measured load. No SceneTransitionRules timeout/indicator plumbing added:
## the fade already comfortably covers every measured load time, and
## load_threaded_get() still blocks safely as a fallback if a future scene
## doesn't fit. Re-confirmed in a real web build (2026-08-04): S-02 4.5ms,
## S-03 1.0ms, S-04 1.3ms, S-05 1.4ms -- all now well under the 16.6ms
## budget (previously 6.4/17.1/27.6/48.7ms). Re-measure if scenes grow
## heavier.

## 씬-관리.md Core Rule 5 -- #18/#21/#23 subscribe to hook scene-scoped
## behavior (ad timing, BGM crossfade, settings) without SceneManager knowing
## about any of them. Added 2026-08-08: the GDD documented these since
## authoring, but the signals themselves were never implemented until now
## (found while authoring #21 오디오, which depends on scene_ready/exited).
signal scene_loading_started(scene_id: String)
signal scene_ready(scene_id: String)
signal scene_exited(scene_id: String)

const SCENE_PATHS := {
	"S-01": "res://scenes/Boot.tscn",
	"S-02": "res://scenes/MainMenuScreen.tscn",
	"S-03": "res://scenes/PartySelectScreen.tscn",
	"S-04": "res://scenes/DungeonExplorationScreen.tscn",
	"S-05": "res://scenes/BattleScreen.tscn",
	"S-06": "res://scenes/RunResultScreen.tscn",
	"S-07": "res://scenes/SettingsScreen.tscn",
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
	scene_loading_started.emit(scene_id)
	var scene_path: String = SCENE_PATHS[scene_id]
	# ponytail: threaded preload only under real (non-headless) runs -- GUT's
	# headless desktop loads are already instant (nothing to hide behind the
	# fade), and there's no reason to route through the threaded API there.
	# 2026-08-08: was `not OS.has_feature("headless")`, which is always false
	# under the --headless *runtime flag* (that feature tag only reflects a
	# headless-*compiled* export template) -- verified empirically, this branch
	# was silently always taking the real-threaded-load path during every GUT
	# run. DisplayServer.get_name() == "headless" is the correct runtime check.
	var use_threaded_load := DisplayServer.get_name() != "headless"
	if use_threaded_load:
		ResourceLoader.load_threaded_request(scene_path)
		_poll_loading(scene_path) # unawaited -- runs concurrently with the fade below
	var durations := SceneTransitionRules.transition_durations(transition)
	var overlay_color := Color.BLACK if transition == SceneTransitionRules.TRANSITION_FADE else SceneTransitionRules.resolve_flash_color(color)

	await _fade(overlay_color, 0.0, 1.0, durations["in_ms"] / 1000.0)
	scene_exited.emit(current_scene_id)
	if use_threaded_load:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene_path))
	else:
		get_tree().change_scene_to_file(scene_path)
	current_scene_id = scene_id
	scene_ready.emit(scene_id)
	# Flag drops here, not after the fade-out below -- "이중 전환 방지" only
	# needs to prevent two change_scene_to_file() calls racing. The incoming
	# scene's own _ready() can legitimately call go_to() again immediately
	# (e.g. #4 auto-entering combat on room 1), and blocking that until a
	# cosmetic fade-out finishes would silently drop a real transition.
	_is_transitioning = false
	await _fade(overlay_color, 1.0, 0.0, durations["out_ms"] / 1000.0)

## Advances a load_threaded_request() in progress by polling get_status() once
## per frame -- required even on platforms without real thread support, since
## the "background" load only makes progress when this status check is called.
func _poll_loading(scene_path: String) -> void:
	while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame

func _fade(color: Color, from_alpha: float, to_alpha: float, duration_sec: float) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill() # a fade-out can be interrupted by the next fade-in (chained transitions)
	_overlay.color = Color(color.r, color.g, color.b, from_alpha)
	# ponytail: --headless (GUT's CI/test runner, per coding-standards.md) has no
	# visible window to fade, so skip the Tween/await entirely there. This also
	# makes go_to() run fully synchronously under GUT instead of leaving a
	# suspended coroutine that resumes several frames later during an unrelated
	# test -- that exact staleness previously hung TurnBattle.run_battle() on an
	# empty turn_order and crashed EnemyAI on a mismatched RunManager snapshot.
	# 2026-08-08: the headless check itself was wrong (see go_to()'s comment on
	# use_threaded_load) -- this fast path was never actually being taken during
	# GUT runs, meaning every go_to() call in every test suspended on a real
	# Tween. The intermittent "transition already in progress" warnings seen in
	# full-suite runs (previously assumed harmless) were this bug's symptom:
	# a prior test's go_to() genuinely hadn't finished yet.
	if duration_sec <= 0.0 or DisplayServer.get_name() == "headless":
		_overlay.color.a = to_alpha
		return
	_active_tween = create_tween()
	_active_tween.tween_property(_overlay, "color:a", to_alpha, duration_sec)
	await _active_tween.finished
