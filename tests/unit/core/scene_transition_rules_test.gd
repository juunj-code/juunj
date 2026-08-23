extends GutTest
## Covers design/gdd/씬-관리.md AC4, 5, 5b, 5c, 6, 7 (list only), 11.
## AC1/2/3/8/9/10 need a real SceneManager Node + actual scene files -- not
## covered here, see the ponytail note in scene_transition_rules.gd.

func test_fade_durations() -> void: # AC4
	var d := SceneTransitionRules.transition_durations(SceneTransitionRules.TRANSITION_FADE)
	assert_eq(d["in_ms"], 300)
	assert_eq(d["out_ms"], 300)

func test_flash_durations() -> void: # AC5
	var d := SceneTransitionRules.transition_durations(SceneTransitionRules.TRANSITION_FLASH)
	assert_eq(d["in_ms"], 150)
	assert_eq(d["out_ms"], 150)

func test_flash_color_uses_given_color() -> void: # AC5b
	var c := SceneTransitionRules.resolve_flash_color(Color(0.9, 0.55, 0.2, 1))
	assert_eq(c, Color(0.9, 0.55, 0.2, 1))
	assert_ne(c, SceneTransitionRules.DEFAULT_FLASH_COLOR)

func test_flash_color_defaults_to_white_when_omitted() -> void: # AC5c
	var c := SceneTransitionRules.resolve_flash_color(null)
	assert_eq(c, Color.WHITE)

func test_load_timeout_arithmetic() -> void: # AC6
	assert_false(SceneTransitionRules.has_load_timed_out(9999))
	assert_false(SceneTransitionRules.has_load_timed_out(10000))
	assert_true(SceneTransitionRules.has_load_timed_out(10001))

func test_loading_indicator_threshold() -> void:
	assert_false(SceneTransitionRules.should_show_loading_indicator(2500))
	assert_true(SceneTransitionRules.should_show_loading_indicator(2501))

func test_boot_preload_timeout_arithmetic() -> void:
	assert_false(SceneTransitionRules.has_boot_preload_timed_out(8000))
	assert_true(SceneTransitionRules.has_boot_preload_timed_out(8001))

func test_boot_preload_scene_list_matches_gdd() -> void: # AC7 (list only, not real caching)
	assert_eq(SceneTransitionRules.BOOT_PRELOAD_SCENE_IDS, ["S-02", "S-03", "S-05"])

func test_declared_edge_recognized() -> void: # AC11
	assert_true(SceneTransitionRules.is_declared_edge("S-04", "S-05")) # Dungeon -> Battle

func test_battle_defeat_edge_recognized() -> void: # AC11 -- RunManager.end_run() fires this mid-battle on a party wipe
	assert_true(SceneTransitionRules.is_declared_edge("S-05", "S-06")) # Battle -> RunResult

func test_undeclared_edge_not_recognized_but_not_blocked() -> void: # AC11
	# BattleScreen -> MainMenu isn't in the graph -- caller decides to warn,
	# this rule set just reports it's off-graph, it doesn't refuse.
	assert_false(SceneTransitionRules.is_declared_edge("S-05", "S-02"))

func test_settings_screen_edges_recognized() -> void: # AC11 -- #23 설정 (S-07)
	assert_true(SceneTransitionRules.is_declared_edge("S-02", "S-07"))
	assert_true(SceneTransitionRules.is_declared_edge("S-07", "S-02"))
