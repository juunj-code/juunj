extends Node
## Autoload (CompanionUnlock). Orchestrates the "discovery moment" for #9's
## companion_discovered signal. See design/gdd/동료-해금.md. Owns only the
## in-run discovery flow (dedupe -> #10 lookup -> RunManager.add_discovered_
## companion() -> FLASH -> companion_unlocked_this_run signal); persistence
## after run end is #13/#14's job, not this system's (GDD explicitly scopes
## that out).
##
signal companion_unlocked_this_run(id: String, comp_name: String, description: String, portrait_id: String, color_accent: Color)
signal popup_confirmed ## #20 emits this when the player taps confirm on the discovery popup (ADR-0010 pattern).

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
	await popup_confirmed
	if not is_inside_tree(): # ADR-0010 guard -- scene torn down while popup was up
		return

## Defensive lookup (same pattern as RunManager._go_to_scene()) -- SceneManager
## (#19) exists now, so this actually fires the flash transition.
func _trigger_flash(color: Color) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene_manager := tree.root.find_child("SceneManager", true, false)
	if scene_manager and scene_manager.has_method("go_to"):
		scene_manager.go_to("S-04", SceneTransitionRules.TRANSITION_FLASH, color)
