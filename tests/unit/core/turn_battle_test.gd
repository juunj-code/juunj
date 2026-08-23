extends GutTest
## Covers design/gdd/턴제-전투.md's logic-testable core: turn order, player
## input (incl. SP-insufficient skill fallback), damage/heal execution,
## DOT+skip interaction, and victory/defeat -> RunManager handoff.
## UI-side ACs (button state, target highlight) are #20's, not this system's.
##
## Player-turn coroutine driving pattern: call battle.run_battle() WITHOUT
## await (it runs synchronously up to the first `await action_selected` and
## returns control here). battle.submit_action()/submit_target() are plain
## synchronous calls that emit the awaited signal, which resumes the
## suspended coroutine *synchronously* within that emit -- so by the time
## submit_target() returns, the whole round (every unit's turn, since only
## companions await) has already resolved, unless the battle ended first.

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

func _make_battle() -> TurnBattle:
	var battle := TurnBattle.new()
	add_child_autofree(battle)
	return battle

func test_turn_order_sorts_by_speed() -> void:
	# companion_balance_01 spd=6, enemy_speed_01 spd=8 -- enemy goes first
	var battle := _make_battle()
	battle.setup([_make_companion("companion_balance_01")], [_make_enemy("enemy_speed_01")])

	var order := battle._compute_turn_order()

	assert_false(order[0]["is_companion"])
	assert_true(order[1]["is_companion"])

func test_setup_wires_synergy_bonus_into_companion_base_atk() -> void: # 시너지.md AC12 (integration)
	# tank(12)+dealer(28)+support(14) -> team synergy_bonus=11 (4+2+5).
	# dealer's own base_atk=28 is uncapped (11 <= floori(28*0.5)=14); tank's
	# base_atk=12 is capped to floori(12*0.5)=6. No weapon equipped, so
	# base_atk should equal registry base_atk + applied synergy exactly.
	var battle := _make_battle()
	battle.setup(
		[_make_companion("companion_tank_01"), _make_companion("companion_dealer_01"), _make_companion("companion_support_01")],
		[_make_enemy("enemy_tank_01")]
	)

	var dealer_unit: Dictionary = battle.party_units.filter(func(u): return u["id"] == "companion_dealer_01")[0]
	var tank_unit: Dictionary = battle.party_units.filter(func(u): return u["id"] == "companion_tank_01")[0]

	assert_eq(dealer_unit["base_atk"], 28 + 11) # uncapped
	assert_eq(tank_unit["base_atk"], 12 + 6) # capped

## 시너지.md AC8. synergy_test.gd's header claims this is covered here, but
## no such test previously existed (2026-08-23 audit) -- the claim happened
## to be true by construction (synergy_bonus is baked into base_atk once at
## setup() and nothing ever recomputes it), but the guarantee had no
## regression test, so a future refactor could silently break it unnoticed.
func test_synergy_bonus_unchanged_after_party_member_incapacitated() -> void:
	var battle := _make_battle()
	battle.setup(
		[_make_companion("companion_tank_01"), _make_companion("companion_dealer_01"), _make_companion("companion_support_01")],
		[_make_enemy("enemy_tank_01")]
	)
	var dealer_unit: Dictionary = battle.party_units.filter(func(u): return u["id"] == "companion_dealer_01")[0]
	var tank_unit: Dictionary = battle.party_units.filter(func(u): return u["id"] == "companion_tank_01")[0]
	var base_atk_before_ko: int = dealer_unit["base_atk"]

	tank_unit["current_hp"] = 0 # simulate tank being incapacitated mid-battle

	assert_eq(dealer_unit["base_atk"], base_atk_before_ko)

func test_player_basic_attack_damages_enemy_and_enemy_counters() -> void:
	# companion_balance_01 (atk18/def12/spd6) acts before enemy_tank_01 (atk10/def12/spd2)
	var battle := _make_battle()
	battle.setup([_make_companion("companion_balance_01")], [_make_enemy("enemy_tank_01")])

	battle.run_battle()
	battle.submit_action("basic_attack")
	battle.submit_target(battle.enemy_units[0])

	# companion: max(1, 18-12) = 6 dmg -> 65-6=59
	assert_eq(battle.enemy_units[0]["current_hp"], 59)
	# enemy always affords its 0-cost skill (crush, mult 0.8): max(1, floor(10*0.8)-12) = 1 dmg -> 100-1=99
	assert_eq(battle.party_units[0]["current_hp"], 99)

func test_skill_without_enough_sp_falls_back_to_basic_attack() -> void:
	var battle := _make_battle()
	battle.setup([_make_companion("companion_balance_01")], [_make_enemy("enemy_tank_01")]) # current_sp=0

	battle.run_battle()
	battle.submit_action("skill") # skill_slash costs 2 SP, companion has 0
	battle.submit_target(battle.enemy_units[0])

	assert_eq(battle.enemy_units[0]["current_hp"], 59) # same as a basic attack, not the skill's 1.5x
	assert_push_warning("falling back to basic_attack")

func test_heal_skill_restores_missing_hp() -> void:
	var support := _make_companion("companion_support_01") # heal_multiplier=0.3, cost_sp=2, spd=9
	support.current_hp = 40 # base_hp=80
	support.current_sp = 2
	var battle := _make_battle()
	battle.setup([support], [_make_enemy("enemy_tank_01")]) # enemy spd=2, acts after support

	battle.run_battle()
	battle.submit_action("skill")
	battle.submit_target(battle.party_units[0]) # self-target

	# heal: min(missing=40, floor(80*0.3)=24) = 24 -> 40+24=64
	# then enemy's turn lands its 1-dmg skill on the only companion -> 64-1=63
	assert_eq(battle.party_units[0]["current_hp"], 63)

func test_dot_ticks_and_skip_turn_together() -> void:
	var companion := _make_companion("companion_balance_01")
	var poison: StatusEffect = StatusEffectRegistry.get_by_id("poison").duplicate()
	var stun: StatusEffect = StatusEffectRegistry.get_by_id("stun").duplicate()
	companion.active_effects = [poison, stun]
	var battle := _make_battle()
	# tank enemy (spd 2) so it can't out-speed and end the round before we inspect it;
	# companion's turn (spd 6) comes first and is skipped round 1 (stunned, no await).
	# Stun lasts exactly 1 turn (GDD 턴제-전투.md: "기절은 1턴 -- 다음 라운드 정상 행동"),
	# so the coroutine does NOT suspend after round 1 -- it keeps running through the
	# enemy's round-1 turn and into round 2, where the now-unstunned companion finally
	# hits `await action_selected` and suspends. So poison ticks twice before we can inspect.
	battle.setup([companion], [_make_enemy("enemy_tank_01")])

	battle.run_battle() # no submit_action call needed -- suspends at round 2's player-input await

	# r1: poison 5 dmg (100->95), stun skips companion's action; enemy hits for 1 (95->94)
	# r2: poison ticks again, 5 dmg (94->89); stun already expired, so companion awaits input here
	assert_eq(battle.party_units[0]["current_hp"], 89)
	assert_eq(battle.party_units[0]["active_effects"].size(), 1) # stun expired after r1, poison remains
	assert_eq(battle.party_units[0]["active_effects"][0].id, "poison")
	assert_eq(battle.party_units[0]["active_effects"][0].duration, 1) # 3 -> 2 (r1) -> 1 (r2)

func test_player_turn_emits_turn_started_and_player_input_requested() -> void: # #20 UI-HUD.md signal contract
	var battle := _make_battle()
	battle.setup([_make_companion("companion_balance_01")], [_make_enemy("enemy_tank_01")])
	var turn_started_ids: Array = []
	var input_requested_ids: Array = []
	battle.turn_started.connect(func(id): turn_started_ids.append(id))
	battle.player_input_requested.connect(func(id): input_requested_ids.append(id))

	battle.run_battle()

	assert_eq(turn_started_ids, ["companion_balance_01"])
	assert_eq(input_requested_ids, ["companion_balance_01"])

func test_turn_order_changed_emits_full_round_order() -> void: # turn queue UI
	var battle := _make_battle()
	battle.setup([_make_companion("companion_balance_01")], [_make_enemy("enemy_speed_01")])
	var orders: Array = []
	battle.turn_order_changed.connect(func(order): orders.append(order))

	battle.run_battle()

	assert_eq(orders.size(), 1) # one round computed before suspending on player input
	assert_eq(orders[0][0]["id"], "enemy_speed_01") # spd 8 beats companion's spd 6
	assert_eq(orders[0][1]["id"], "companion_balance_01")

func test_action_executed_emits_actor_and_target() -> void: # lunge-animation hook
	var battle := _make_battle()
	battle.setup([_make_companion("companion_balance_01")], [_make_enemy("enemy_tank_01")])
	var events: Array = []
	battle.action_executed.connect(func(actor_id, actor_index, target_id, target_index, action):
		events.append([actor_id, actor_index, target_id, target_index, action]))

	battle.run_battle()
	battle.submit_action("basic_attack")
	battle.submit_target(battle.enemy_units[0])

	assert_eq(events[0], ["companion_balance_01", 0, "enemy_tank_01", 0, "basic_attack"])
	assert_eq(events[1], ["enemy_tank_01", 0, "companion_balance_01", 0, "skill"]) # enemy's 0-cost skill counter

func test_basic_attack_emits_hp_changed_reflecting_final_values() -> void: # #20 UI-HUD.md signal contract
	# _sync() emits on every processing step (tick/SP-recover included), not
	# only on actual change -- so assert latest-seen value per id, not an
	# exact call sequence (see test_player_basic_attack_damages_enemy_and_
	# enemy_counters for why 59/99 is the expected end-of-round state).
	var battle := _make_battle()
	battle.setup([_make_companion("companion_balance_01")], [_make_enemy("enemy_tank_01")])
	var last_hp: Dictionary = {}
	battle.unit_hp_changed.connect(func(id, _index, hp): last_hp[id] = hp)

	battle.run_battle()
	battle.submit_action("basic_attack")
	battle.submit_target(battle.enemy_units[0])

	assert_eq(last_hp["enemy_tank_01"], 59)
	assert_eq(last_hp["companion_balance_01"], 99)

func test_victory_ends_battle_and_calls_run_manager_exit_combat() -> void:
	RunManager.reset()
	RunManager.start_run([{"companion_id": "companion_balance_01", "weapon_slot": "", "armor_slot": ""}])
	RunManager.enter_combat(["enemy_tank_01"])
	RunManager.current_enemies[0].current_hp = 1 # companion's first hit will kill it

	var battle := _make_battle()
	battle.setup(RunManager.party, RunManager.current_enemies)
	var fired := [false]
	battle.battle_ended.connect(func(v): fired[0] = v)

	battle.run_battle()
	battle.submit_action("basic_attack")
	battle.submit_target(battle.enemy_units[0])

	assert_true(battle.ended)
	assert_true(fired[0])
	assert_eq(RunManager.state, "EXPLORING") # exit_combat_victory() transitioned it

func test_defeat_ends_battle_and_calls_run_manager_end_run() -> void:
	RunManager.reset()
	RunManager.start_run([{"companion_id": "companion_balance_01", "weapon_slot": "", "armor_slot": ""}])
	RunManager.enter_combat(["enemy_tank_01"])
	RunManager.party[0].current_hp = 1 # enemy's counter will finish them off

	var battle := _make_battle()
	battle.setup(RunManager.party, RunManager.current_enemies)

	battle.run_battle()
	battle.submit_action("basic_attack")
	battle.submit_target(battle.enemy_units[0])

	assert_true(battle.ended)
	assert_false(battle.victory)
	assert_eq(RunManager.state, "RUN_ENDED")
	assert_false(RunManager.is_success)
