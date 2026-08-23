class_name RunResult
extends RefCounted
## RunResultScreen (S-06) data assembly. See design/gdd/런-결과.md. Pure data
## binding -- actual rendering is #20's job. Reads is_success/floor_reached/
## last_newly_unlocked/last_is_new_record off RunManager (assembled there by
## #13's progress handoff) rather than talking to #14 directly, per this
## GDD's stated ownership ("#16이 #14와 직접 통신하지 않는다").

const TOTAL_COMPANIONS := 5

static func build_display_data(run_manager: Object) -> Dictionary:
	var newly_unlocked: Array = run_manager.last_newly_unlocked
	return {
		"header": "성공!" if run_manager.is_success else "패배",
		"floor_text": "%d층 도달" % run_manager.current_floor,
		"record_badge": "최고 기록!" if run_manager.last_is_new_record else "",
		"newly_unlocked_companions": newly_unlocked,
		"empty_discovery_text": "" if not newly_unlocked.is_empty() else "발견한 동료 없음 · 다음 런에서 새로운 동료를 만나보세요",
		"progress_text": _progress_text(),
	}

static func _progress_text() -> String:
	var unlocked_count: int = ProgressManager.get_unlocked_companions().size()
	if unlocked_count >= TOTAL_COMPANIONS:
		return "모든 동료를 발견했습니다!"
	return "해금 동료: %d / %d명" % [unlocked_count, TOTAL_COMPANIONS]

## "메인메뉴로" button handler: ad (if #18 exists) -> SceneManager.go_to(S-02).
## Both are looked up defensively -- AdManager (#18) doesn't exist yet;
## SceneManager (#19) does now, but the lookup stays the same shape (same
## pattern as RunManager's _go_to_scene()) so this needs no changes if #18
## lands later.
static func go_to_main_menu() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var ad_manager := tree.root.find_child("AdManager", true, false)
	if ad_manager and ad_manager.has_method("show_interstitial"):
		ad_manager.show_interstitial(func(): _transition_to_main_menu(tree))
	else:
		_transition_to_main_menu(tree)

static func _transition_to_main_menu(tree: SceneTree) -> void:
	var scene_manager := tree.root.find_child("SceneManager", true, false)
	if scene_manager and scene_manager.has_method("go_to"):
		scene_manager.go_to("S-02", "FADE")
