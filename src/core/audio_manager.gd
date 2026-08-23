extends Node
## Autoload (AudioManager). #21 오디오 -- pure signal-subscribe output layer:
## owns no game state, never blocks gameplay if playback misbehaves (Graceful
## Degradation). See design/gdd/오디오.md.
##
## Uses AudioSynth (procedural square/triangle/sine) instead of authored/
## generated assets -- no new asset production needed for a "minimal 8-bit"
## sound palette. get_current_bgm_id()/get_last_played_sfx_id() exist purely
## so tests can observe playback without a real audio device.
##
## Boss BGM branching (오디오.md's "보스 BGM 판별"): bind_battle() checks
## battle.enemy_units for an is_boss unit directly -- TurnBattle already
## resolves that field into each unit dict (turn_battle.gd _build_enemy_units),
## so no EnemyRegistry.get_by_id() lookup is needed here (GDD's original
## reasoning assumed only enemy_id was available at this point; it isn't the
## case in the actual implementation).

const _SFX_BUS := "SFX"
const _BGM_BUS := "BGM"
const _CROSSFADE_SEC := 1.2

var _sfx_streams: Dictionary = {}
var _bgm_streams: Dictionary = {}
var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
var _current_bgm_id := ""
var _last_played_sfx_id := ""
var _last_hp: Dictionary = {} # "id#index" -> int, bind_battle()'s hit/heal diff baseline

func _ready() -> void:
	_ensure_bus(_SFX_BUS)
	_ensure_bus(_BGM_BUS)
	_build_sfx_library()
	_build_bgm_library()
	_bgm_a = AudioStreamPlayer.new()
	_bgm_a.bus = _BGM_BUS
	add_child(_bgm_a)
	_bgm_b = AudioStreamPlayer.new()
	_bgm_b.bus = _BGM_BUS
	add_child(_bgm_b)
	SceneManager.scene_ready.connect(_on_scene_ready)
	CompanionUnlock.companion_unlocked_this_run.connect(_on_companion_unlocked)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

func _build_sfx_library() -> void:
	_sfx_streams["hit"] = AudioSynth.sequence([[280.0, 0.05], [160.0, 0.06]], "square", 0.35)
	_sfx_streams["heal"] = AudioSynth.sequence([[440.0, 0.06], [660.0, 0.09]], "triangle", 0.3)
	_sfx_streams["victory"] = AudioSynth.sequence([[523.0, 0.1], [659.0, 0.1], [784.0, 0.18]], "square", 0.35)
	_sfx_streams["defeat"] = AudioSynth.sequence([[392.0, 0.14], [330.0, 0.14], [262.0, 0.22]], "square", 0.3)
	_sfx_streams["discovery"] = AudioSynth.sequence([[784.0, 0.08], [988.0, 0.08], [1175.0, 0.16]], "sine", 0.3)

## 2026-08-23 (user feedback: BGM too flat/monotone) -- each track now mixes
## a bass voice under the melody (single-channel chiptune reads thin), and
## combat/combat_boss (previously ~1.1-1.3s loops, by far the shortest/most
## repetitive) get an answering second phrase so the loop period roughly
## doubles. exploration/lobby melodies unchanged -- only combat's were short
## enough to be the likely main offender in a multi-minute fight.
func _build_bgm_library() -> void:
	_bgm_streams["exploration"] = AudioSynth.mix_tracks([
		{"notes": [[220.0, 0.4], [262.0, 0.4], [330.0, 0.4], [262.0, 0.4], [196.0, 0.4], [262.0, 0.4], [220.0, 0.8]],
			"waveform": "triangle", "volume": 0.18},
		{"notes": [[110.0, 1.6], [98.0, 1.6]], "waveform": "triangle", "volume": 0.1},
	], true)
	_bgm_streams["combat"] = AudioSynth.mix_tracks([
		{"notes": [[220.0, 0.18], [220.0, 0.18], [262.0, 0.18], [220.0, 0.18], [196.0, 0.18], [196.0, 0.18], [220.0, 0.36],
				[262.0, 0.18], [294.0, 0.18], [262.0, 0.18], [220.0, 0.18], [196.0, 0.18], [220.0, 0.18], [262.0, 0.36]],
			"waveform": "square", "volume": 0.16},
		{"notes": [[110.0, 0.63], [98.0, 0.63], [110.0, 0.72], [82.0, 0.72]], "waveform": "triangle", "volume": 0.09},
	], true)
	_bgm_streams["combat_boss"] = AudioSynth.mix_tracks([
		{"notes": [[147.0, 0.14], [147.0, 0.14], [175.0, 0.14], [147.0, 0.14], [131.0, 0.14], [110.0, 0.14], [131.0, 0.28],
				[131.0, 0.14], [131.0, 0.14], [110.0, 0.14], [131.0, 0.14], [98.0, 0.14], [87.0, 0.14], [98.0, 0.28]],
			"waveform": "square", "volume": 0.2},
		{"notes": [[73.5, 1.12], [65.4, 1.12]], "waveform": "triangle", "volume": 0.12},
	], true)
	_bgm_streams["lobby"] = AudioSynth.mix_tracks([
		{"notes": [[196.0, 0.5], [247.0, 0.5], [294.0, 0.5], [247.0, 0.5]], "waveform": "triangle", "volume": 0.16},
		{"notes": [[98.0, 1.0], [131.0, 1.0]], "waveform": "triangle", "volume": 0.09},
	], true)

func play_sfx(id: String) -> void:
	if not _sfx_streams.has(id):
		push_warning("AudioManager.play_sfx: unknown id %s" % id)
		return
	var player := AudioStreamPlayer.new()
	player.stream = _sfx_streams[id]
	player.bus = _SFX_BUS
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	_last_played_sfx_id = id

## Equal-power crossfade (sin/cos, not linear dB lerp -- linear guts the
## midpoint loudness, a finding from #21's independent /design-review).
func play_bgm(id: String) -> void:
	if id == _current_bgm_id:
		return
	if not _bgm_streams.has(id):
		push_warning("AudioManager.play_bgm: unknown id %s" % id)
		return
	var incoming := _bgm_b if _bgm_a.playing else _bgm_a
	var outgoing := _bgm_a if incoming == _bgm_b else _bgm_b
	var outgoing_was_playing := outgoing.playing
	incoming.stream = _bgm_streams[id]
	incoming.volume_db = linear_to_db(0.0001)
	incoming.play()

	var tw := create_tween().set_parallel(true)
	tw.tween_method(_apply_equal_power_gain.bind(incoming, true), 0.0, 1.0, _CROSSFADE_SEC)
	if outgoing_was_playing:
		tw.tween_method(_apply_equal_power_gain.bind(outgoing, false), 0.0, 1.0, _CROSSFADE_SEC)
		tw.chain().tween_callback(outgoing.stop)
	_current_bgm_id = id

func _apply_equal_power_gain(t: float, player: AudioStreamPlayer, fading_in: bool) -> void:
	var gain := sin(t * PI / 2.0) if fading_in else cos(t * PI / 2.0)
	player.volume_db = linear_to_db(maxf(gain, 0.0001))

func _on_scene_ready(scene_id: String) -> void:
	match scene_id:
		"S-02", "S-03", "S-06":
			play_bgm("lobby")
		"S-04":
			play_bgm("exploration")
		# S-05 (combat) is started by BattleScreen via bind_battle() instead --
		# it needs the battle's own context, which SceneManager doesn't have.

func _on_companion_unlocked(_id: String, _comp_name: String, _description: String, _portrait_id: String, _color_accent: Color) -> void:
	play_sfx("discovery")

## Called once per battle (from BattleScreen, same as its other TurnBattle
## signal wiring). unit_hp_changed only carries the new value, not a delta --
## diffed here against a local baseline, same pattern BattleScreen already
## uses for its damage-number popups.
func bind_battle(battle: Node) -> void:
	_last_hp.clear()
	for unit in battle.party_units + battle.enemy_units:
		_last_hp[_unit_key(unit["id"], unit["index"])] = unit["current_hp"]
	battle.unit_hp_changed.connect(_on_battle_unit_hp_changed)
	battle.battle_ended.connect(_on_battle_ended)
	var has_boss: bool = battle.enemy_units.any(func(u): return u.get("is_boss", false))
	play_bgm("combat_boss" if has_boss else "combat")

func _unit_key(id: String, index: int) -> String:
	return "%s#%d" % [id, index]

func _on_battle_unit_hp_changed(unit_id: String, unit_index: int, new_hp: int) -> void:
	var key := _unit_key(unit_id, unit_index)
	var prev: int = _last_hp.get(key, new_hp)
	if new_hp < prev:
		play_sfx("hit")
	elif new_hp > prev:
		play_sfx("heal")
	_last_hp[key] = new_hp

func _on_battle_ended(victory: bool) -> void:
	play_sfx("victory" if victory else "defeat")

func get_current_bgm_id() -> String:
	return _current_bgm_id

func get_last_played_sfx_id() -> String:
	return _last_played_sfx_id

## #23 설정 -- linear 0..1, same maxf(0.0001) floor as _apply_equal_power_gain
## (linear_to_db(0.0) is -inf, which AudioServer clamps oddly).
func set_sfx_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(_SFX_BUS), linear_to_db(maxf(linear, 0.0001)))

func set_bgm_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(_BGM_BUS), linear_to_db(maxf(linear, 0.0001)))
