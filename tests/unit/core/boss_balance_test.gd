extends GutTest
## Regression test for the solo-boss-fight balance investigation
## (production/session-state/active.md, 2026-08-01/02). Combat is fully
## deterministic (no crit/dodge), and the game forces every player's first run
## to fight enemy_boss_01 solo with whichever companion is unlocked by default
## -- so if that matchup isn't winnable with optimal play, it's unwinnable,
## period, not just unlucky. Locks in "winnable" as an invariant so future
## stat/formula changes can't silently reintroduce a guaranteed-loss boss.

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

func test_solo_starter_companion_can_beat_boss_with_optimal_play() -> void:
	# Arrange -- companion_balance_01 (아이라) is the only non-hidden MVP
	# companion, so she's guaranteed to be the solo fighter on a first run.
	var battle := TurnBattle.new()
	add_child_autofree(battle)
	battle.setup([_make_companion("companion_balance_01")], [_make_enemy("enemy_boss_01")])

	# Act -- always request "skill"; _get_player_action() auto-falls-back to
	# basic_attack when SP is insufficient, which is exactly the optimal policy.
	battle.run_battle()
	var rounds := 0
	while not battle.ended and rounds < 50:
		rounds += 1
		battle.submit_action("skill")
		battle.submit_target(battle.enemy_units[0])

	# Assert
	assert_true(battle.ended, "battle did not resolve within 50 rounds")
	assert_true(battle.victory, "solo starter companion must be able to beat the boss with optimal play")
