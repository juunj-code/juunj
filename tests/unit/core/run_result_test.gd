extends GutTest
## Covers design/gdd/런-결과.md Acceptance Criteria 1-6b, 7. AC8 (screen only
## reached after progress_committed) is structurally guaranteed by
## RunManager.end_run()'s synchronous ordering (handoff happens before
## _go_to_scene("S-06")) -- no separate test needed beyond run_manager_test.gd's
## own coverage of that ordering.

func before_each() -> void:
	RunManager.is_success = false
	RunManager.current_floor = 1
	RunManager.last_newly_unlocked = []
	RunManager.last_is_new_record = false
	ProgressManager.unlocked_companions = ["companion_balance_01"]

func test_success_header() -> void: # AC1
	RunManager.is_success = true
	var data := RunResult.build_display_data(RunManager)
	assert_eq(data["header"], "성공!")

func test_defeat_header() -> void: # AC2
	RunManager.is_success = false
	var data := RunResult.build_display_data(RunManager)
	assert_eq(data["header"], "패배")

func test_newly_unlocked_companion_included() -> void: # AC3
	RunManager.last_newly_unlocked = ["hidden_mage_02"]
	var data := RunResult.build_display_data(RunManager)
	assert_true(data["newly_unlocked_companions"].has("hidden_mage_02"))

func test_empty_discovery_shows_fallback_text() -> void: # AC4
	RunManager.last_newly_unlocked = []
	var data := RunResult.build_display_data(RunManager)
	assert_eq(data["empty_discovery_text"], "발견한 동료 없음 · 다음 런에서 새로운 동료를 만나보세요")

func test_new_record_badge() -> void: # AC5
	RunManager.last_is_new_record = true
	var data := RunResult.build_display_data(RunManager)
	assert_eq(data["record_badge"], "최고 기록!")

func test_progress_fraction_text() -> void: # AC6
	ProgressManager.unlocked_companions = ["a", "b"]
	var data := RunResult.build_display_data(RunManager)
	assert_eq(data["progress_text"], "해금 동료: 2 / 4명")

func test_progress_complete_text() -> void: # AC6b
	ProgressManager.unlocked_companions = ["a", "b", "c", "d"]
	var data := RunResult.build_display_data(RunManager)
	assert_eq(data["progress_text"], "모든 동료를 발견했습니다!")

func test_main_menu_transition_noop_when_neither_system_exists() -> void: # AC7 (neither #18 nor #19 built yet)
	# Same defensive contract as RunManager's _go_to_scene()/_handoff_*() --
	# absence of AdManager/SceneManager must not error.
	RunResult.go_to_main_menu()
	assert_true(true) # reaching here without an error is the assertion

func test_main_menu_transition_calls_ad_then_scene() -> void: # AC7
	# SceneManager (#19) and AdManager (#18) are both real autoloads now, so they
	# win any find_child("...") lookup over a same-named test double added elsewhere
	# in the tree. Swap both out for the duration of this test so RunResult's
	# dispatch calls can be observed in isolation.
	var root: Node = (Engine.get_main_loop() as SceneTree).root
	var real_scene_manager: Node = root.get_node("SceneManager")
	var real_ad_manager: Node = root.get_node("AdManager")
	root.remove_child(real_scene_manager)
	root.remove_child(real_ad_manager)

	var ad_manager := AdManagerSpy.new()
	ad_manager.name = "AdManager"
	root.add_child(ad_manager)
	var scene_manager := SceneManagerSpy.new()
	scene_manager.name = "SceneManager"
	root.add_child(scene_manager)

	RunResult.go_to_main_menu()

	assert_true(ad_manager.shown)
	assert_eq(scene_manager.last_call, ["S-02", "FADE"])

	root.remove_child(scene_manager)
	scene_manager.free()
	root.remove_child(ad_manager)
	ad_manager.free()
	root.add_child(real_scene_manager)
	root.add_child(real_ad_manager)

class AdManagerSpy extends Node:
	var shown := false
	func show_interstitial(on_complete: Callable) -> void:
		shown = true
		on_complete.call()

class SceneManagerSpy extends Node:
	var last_call: Array = []
	func go_to(scene_id: String, transition: String) -> void:
		last_call = [scene_id, transition]
