class_name SceneTransitionRules
extends RefCounted
## Pure decision logic for #19 씬 관리 -- transition timing, graph validation,
## flash color defaulting. No Node/Tween/scene dependency, so it's testable
## in isolation. See design/gdd/씬-관리.md.
##
## The engine-integrated half (actual Tweens, CanvasLayer overlays,
## ResourceLoader.load_threaded_request/get) is SceneManager
## (src/core/scene_manager.gd, autoload) -- this module is the tested
## contract it calls into.

const FADE_IN_MS := 300
const FADE_OUT_MS := 300
const FLASH_IN_MS := 150
const FLASH_OUT_MS := 150
const SCENE_LOAD_TIMEOUT_MS := 10000
const LOADING_INDICATOR_THRESHOLD_MS := 2500
const BOOT_PRELOAD_TIMEOUT_MS := 8000

const TRANSITION_FADE := "FADE"
const TRANSITION_FLASH := "FLASH"
const TRANSITION_INSTANT := "INSTANT"

const DEFAULT_FLASH_COLOR := Color.WHITE

const BOOT_PRELOAD_SCENE_IDS: Array[String] = ["S-02", "S-03", "S-05"] # MainMenu, PartySelect, BattleScreen

## Declared Transition Graph edges (design/gdd/씬-관리.md). Off-graph requests
## are still allowed (AC11) -- this is only used to decide whether to warn.
const TRANSITION_GRAPH := {
	"S-01": ["S-02"],
	"S-02": ["S-03"],
	"S-03": ["S-04"],
	"S-04": ["S-05", "S-06"],
	"S-05": ["S-04", "S-06"], # victory -> back to dungeon, defeat -> run result
	"S-06": ["S-03", "S-02"],
}

## {"in_ms": int, "out_ms": int} for the given transition type. AC4/AC5.
static func transition_durations(transition: String) -> Dictionary:
	match transition:
		TRANSITION_FADE:
			return {"in_ms": FADE_IN_MS, "out_ms": FADE_OUT_MS}
		TRANSITION_FLASH:
			return {"in_ms": FLASH_IN_MS, "out_ms": FLASH_OUT_MS}
		_:
			return {"in_ms": 0, "out_ms": 0}

## flash_color is only meaningful for FLASH; FADE always uses black (owned by
## the overlay itself, not this rule set). AC5b/AC5c.
static func resolve_flash_color(flash_color: Variant) -> Color:
	if flash_color == null:
		return DEFAULT_FLASH_COLOR
	return flash_color

## True if (from_scene_id -> to_scene_id) is a declared Transition Graph edge.
## False does not mean "blocked" -- callers should push_warning, not refuse. AC11.
static func is_declared_edge(from_scene_id: String, to_scene_id: String) -> bool:
	return TRANSITION_GRAPH.get(from_scene_id, []).has(to_scene_id)

## True once elapsed_ms has crossed the hard load-failure threshold. AC6.
static func has_load_timed_out(elapsed_ms: int) -> bool:
	return elapsed_ms > SCENE_LOAD_TIMEOUT_MS

## True once elapsed_ms warrants the soft "loading..." indicator (not a failure).
static func should_show_loading_indicator(elapsed_ms: int) -> bool:
	return elapsed_ms > LOADING_INDICATOR_THRESHOLD_MS

## True once Boot preload has run long enough to stop waiting and proceed with
## whatever finished (Core Rule 4).
static func has_boot_preload_timed_out(elapsed_ms: int) -> bool:
	return elapsed_ms > BOOT_PRELOAD_TIMEOUT_MS
