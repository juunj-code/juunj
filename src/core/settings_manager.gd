extends Node
## Autoload (SettingsManager). #23 설정 -- SFX/BGM 볼륨을 #17 로컬 세이브로
## 영속화. See systems-index.md #23 (Alpha, Not Started -> 착수).
##
## 스코프: 볼륨만. 언어 설정은 스킵(ponytail) -- 이 게임은 모든 GDD/UI 텍스트가
## 한국어 단일이고 i18n 인프라(TranslationServer 카탈로그 등) 자체가 없어서,
## 지금 노출하면 존재하지 않는 기능을 흉내내는 스위치가 됨. 실제 다국어 콘텐츠가
## 생기면 그때 추가.

signal volume_changed(bus: String, value: float)

var sfx_volume: float = 1.0
var bgm_volume: float = 1.0

func _ready() -> void:
	_load_from_save()

func _load_from_save() -> void:
	var saved: Variant = SaveManager.get_section("settings")
	if saved != null:
		sfx_volume = clampf(saved.get("sfx_volume", 1.0), 0.0, 1.0)
		bgm_volume = clampf(saved.get("bgm_volume", 1.0), 0.0, 1.0)
	AudioManager.set_sfx_volume(sfx_volume)
	AudioManager.set_bgm_volume(bgm_volume)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	AudioManager.set_sfx_volume(sfx_volume)
	_persist()
	volume_changed.emit("sfx", sfx_volume)

func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	AudioManager.set_bgm_volume(bgm_volume)
	_persist()
	volume_changed.emit("bgm", bgm_volume)

func _persist() -> void:
	SaveManager.save_section("settings", {"sfx_volume": sfx_volume, "bgm_volume": bgm_volume})
	SaveManager.save()
