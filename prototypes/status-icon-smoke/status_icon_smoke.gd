extends Control
## Throwaway visual smoke check for #20 UI-HUD AC8 (status effect icons).
## Drives BattleScreen standalone (no real scene transition) with a companion
## that has all 3 MVP status effects active, then screenshots and quits.
## See design/art/status-icon-prompts.md / art-bible.md Section 5.

func _ready() -> void:
	RunManager.reset()
	RunManager._scene_navigator_override = func(_scene_id, _transition): pass # no real scene swap
	RunManager.start_run([{"companion_id": "companion_balance_01", "weapon_slot": "", "armor_slot": ""}])
	RunManager.enter_combat(["enemy_tank_01"])
	var poison: StatusEffect = StatusEffectRegistry.get_by_id("poison").duplicate()
	var stun: StatusEffect = StatusEffectRegistry.get_by_id("stun").duplicate()
	var defense_up: StatusEffect = StatusEffectRegistry.get_by_id("defense_up").duplicate()
	RunManager.party[0].active_effects = [poison, stun, defense_up]

	var battle_screen := preload("res://scenes/BattleScreen.tscn").instantiate()
	add_child(battle_screen)

	await get_tree().process_frame
	await get_tree().process_frame
	# --headless uses the dummy rendering driver -- get_viewport().get_texture()
	# is null, so no screenshot is possible here (see README.md). This just
	# confirms the icon load()/TextureRect wiring in battle_screen.gd runs
	# without error when active_effects has all 3 MVP status effects.
	print("status icon smoke: reached end of _ready() without error -- PASS (see README for what this does/doesn't prove)")
	get_tree().quit()
