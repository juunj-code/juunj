extends GutTest
## Covers design/gdd/오디오.md's testable surface: SFX/BGM playback tracking
## (get_last_played_sfx_id/get_current_bgm_id -- added because there's no
## real audio device under GUT) and the bind_battle() hit/heal/victory/
## defeat wiring. AudioManager is an autoload (shared across tests), so each
## test drives it through a fresh local TurnBattle rather than asserting on
## leftover global state.

func _make_companion(id: String) -> CompanionRunState:
	var data: CompanionData = CompanionRegistry.get_by_id(id)
	var c := CompanionRunState.new()
	c.companion_id = id
	c.current_hp = data.base_hp
	c.current_sp = 0
	return c

func _make_enemy(id: String) -> EnemyRunState:
	var data: EnemyData = EnemyRegistry.get_by_id(id)
	var e := EnemyRunState.new()
	e.enemy_id = id
	e.current_hp = data.base_hp
	e.current_sp = 0
	return e

func _make_bound_battle() -> TurnBattle:
	var battle := TurnBattle.new()
	add_child_autofree(battle)
	battle.setup([_make_companion("companion_balance_01")], [_make_enemy("enemy_tank_01")])
	AudioManager.bind_battle(battle)
	return battle

func test_play_sfx_unknown_id_warns() -> void:
	AudioManager.play_sfx("not_a_real_sfx")
	assert_push_warning("unknown id")

func test_play_sfx_known_id_updates_last_played() -> void:
	AudioManager.play_sfx("victory")
	assert_eq(AudioManager.get_last_played_sfx_id(), "victory")

func test_play_bgm_switches_current_bgm_id() -> void:
	AudioManager.play_bgm("exploration")
	assert_eq(AudioManager.get_current_bgm_id(), "exploration")
	AudioManager.play_bgm("combat")
	assert_eq(AudioManager.get_current_bgm_id(), "combat")

func test_bind_battle_hp_decrease_plays_hit_sfx() -> void:
	var battle := _make_bound_battle()
	var unit: Dictionary = battle.party_units[0]

	battle.unit_hp_changed.emit(unit["id"], unit["index"], unit["current_hp"] - 5)

	assert_eq(AudioManager.get_last_played_sfx_id(), "hit")

func test_bind_battle_hp_increase_plays_heal_sfx() -> void:
	var battle := _make_bound_battle()
	var unit: Dictionary = battle.party_units[0]

	battle.unit_hp_changed.emit(unit["id"], unit["index"], unit["current_hp"] + 5)

	assert_eq(AudioManager.get_last_played_sfx_id(), "heal")

func test_bind_battle_victory_plays_victory_sfx() -> void:
	var battle := _make_bound_battle()

	battle.battle_ended.emit(true)

	assert_eq(AudioManager.get_last_played_sfx_id(), "victory")

func test_bind_battle_defeat_plays_defeat_sfx() -> void:
	var battle := _make_bound_battle()

	battle.battle_ended.emit(false)

	assert_eq(AudioManager.get_last_played_sfx_id(), "defeat")

func test_bind_battle_starts_combat_bgm() -> void:
	_make_bound_battle()

	assert_eq(AudioManager.get_current_bgm_id(), "combat")

func test_bind_battle_with_boss_enemy_starts_boss_bgm() -> void:
	var battle := TurnBattle.new()
	add_child_autofree(battle)
	battle.setup([_make_companion("companion_balance_01")], [_make_enemy("enemy_boss_01")])

	AudioManager.bind_battle(battle)

	assert_eq(AudioManager.get_current_bgm_id(), "combat_boss")

func test_audio_synth_tone_produces_expected_frame_count() -> void:
	var stream := AudioSynth.tone(440.0, 0.1, "square", 0.5)

	assert_eq(stream.data.size(), int(0.1 * 44100) * 2) # 16-bit mono -> 2 bytes/frame
	assert_eq(stream.mix_rate, 44100)

func test_audio_synth_sequence_loop_sets_loop_mode() -> void:
	var stream := AudioSynth.sequence([[220.0, 0.05]], "triangle", 0.5, true)

	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(stream.loop_end, int(stream.data.size() / 2))
