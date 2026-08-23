extends Control
## S-07 SettingsScreen. #23 설정 -- SFX/BGM 볼륨 슬라이더. See
## src/core/settings_manager.gd.

@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _bgm_slider: HSlider = %BgmSlider
@onready var _back_button: Button = %BackButton

func _ready() -> void:
	_sfx_slider.value = SettingsManager.sfx_volume
	_bgm_slider.value = SettingsManager.bgm_volume
	_sfx_slider.value_changed.connect(SettingsManager.set_sfx_volume)
	_bgm_slider.value_changed.connect(SettingsManager.set_bgm_volume)
	_back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	SceneManager.go_to("S-02", SceneTransitionRules.TRANSITION_FADE)
