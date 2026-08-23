extends GutTest
## Covers #23 설정 (src/core/settings_manager.gd): volume clamping, persistence
## through #17 로컬 세이브, and reload-from-save. SettingsManager is an
## autoload (shared across tests), so state is reset in before_each like
## progress_manager_test.gd does for the same reason.

func before_each() -> void:
	SaveManager._sections = {}
	SettingsManager.sfx_volume = 1.0
	SettingsManager.bgm_volume = 1.0

func test_set_sfx_volume_updates_field_and_persists() -> void:
	SettingsManager.set_sfx_volume(0.4)

	assert_eq(SettingsManager.sfx_volume, 0.4)
	assert_eq(SaveManager.get_section("settings")["sfx_volume"], 0.4)

func test_set_bgm_volume_updates_field_and_persists() -> void:
	SettingsManager.set_bgm_volume(0.7)

	assert_eq(SettingsManager.bgm_volume, 0.7)
	assert_eq(SaveManager.get_section("settings")["bgm_volume"], 0.7)

func test_set_sfx_volume_clamps_above_range() -> void:
	SettingsManager.set_sfx_volume(1.5)
	assert_eq(SettingsManager.sfx_volume, 1.0)

func test_set_bgm_volume_clamps_below_range() -> void:
	SettingsManager.set_bgm_volume(-0.5)
	assert_eq(SettingsManager.bgm_volume, 0.0)

func test_set_volume_emits_volume_changed() -> void:
	var received: Array = []
	SettingsManager.volume_changed.connect(func(bus, value): received.append([bus, value]))

	SettingsManager.set_sfx_volume(0.3)

	assert_eq(received, [["sfx", 0.3]])

func test_load_from_save_defaults_when_no_section() -> void:
	SettingsManager._load_from_save()
	assert_eq(SettingsManager.sfx_volume, 1.0)
	assert_eq(SettingsManager.bgm_volume, 1.0)

func test_load_from_save_restores_persisted_values() -> void:
	SaveManager.save_section("settings", {"sfx_volume": 0.2, "bgm_volume": 0.9})
	SettingsManager._load_from_save()

	assert_eq(SettingsManager.sfx_volume, 0.2)
	assert_eq(SettingsManager.bgm_volume, 0.9)
