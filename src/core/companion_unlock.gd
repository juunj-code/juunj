extends Node
## Autoload (CompanionUnlock). Orchestrates the "discovery moment" for #9's
## companion_discovered signal. See design/gdd/동료-해금.md. Owns only the
## in-run discovery flow (dedupe -> #10 lookup -> RunManager.add_discovered_
## companion() -> FLASH -> companion_unlocked_this_run signal); persistence
## after run end is #13/#14's job, not this system's (GDD explicitly scopes
## that out).
##
## ponytail: GDD's flow also has this system `await popup_confirmed` before
## returning (blocking dungeon input until #20's popup closes). Skipped --
## #20 UI/HUD doesn't exist yet, no AC covers it (old AC6 was moved to #20's
## scope), and there's nothing downstream to resume. Add the await once #20
## exists and needs this system to stay suspended across the popup.

signal companion_unlocked_this_run(id: String, comp_name: String, description: String, portrait_id: String, color_accent: Color)

func _ready() -> void:
	HiddenTrigger.companion_discovered.connect(_on_companion_discovered)

func _on_companion_discovered(id: String) -> void:
	handle_discovered(id)

func handle_discovered(id: String) -> void:
	if RunManager.state != "EXPLORING":
		push_error("CompanionUnlock: companion_discovered received while state=%s" % RunManager.state)
		return
	if RunManager.discovered_companions.has(id):
		return
	var data: CompanionData = CompanionRegistry.get_by_id(id)
	if data == null:
		push_warning("Unknown companion_id in unlock flow: %s" % id)
		return
	RunManager.add_discovered_companion(id)
	_trigger_flash(data.color_accent)
	companion_unlocked_this_run.emit(id, data.name, data.description, data.portrait_id, data.color_accent)

## Defensive lookup (same pattern as RunManager._go_to_scene()) -- #19 씬 관리
## doesn't exist yet, so this is a no-op until it does.
func _trigger_flash(color: Color) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene_manager := tree.root.find_child("SceneManager", true, false)
	if scene_manager and scene_manager.has_method("go_to"):
		scene_manager.go_to("S-04", SceneTransitionRules.TRANSITION_FLASH, color)
