extends Node
## Autoload (AdManager). #18 광고 통합. See design/gdd/광고-통합.md, ADR-0003
## (JS↔GDScript 콜백 브릿지 표준 패턴). MVP 타이밍은 딱 하나 -- RunResult
## "메인메뉴로" 탭 후 인터스티셜 1회. 게임플레이 중에는 아무 시스템도 이걸
## 호출하지 않는다(#1/#15 쪽 책임, 이 시스템은 자체적으로 트리거하지 않음).
##
## ponytail: `_web_override`는 `_js_bridge`(ADR-0003 필수 DI 시임)와 별개로
## 추가한 두 번째 테스트 시임. GUT은 데스크톱 Godot 바이너리로 돌아가므로
## `OS.has_feature("web")`이 항상 false -- 이 시임 없이는 AC1/3/4/6/7이 검증하는
## web 분기 자체에 진입할 방법이 없다. null이면 실제 OS.has_feature("web")를 쓴다.

const AD_TIMEOUT_MS := 5000

var _pending_callback: Callable
var _timeout_timer: SceneTreeTimer
var _js_bridge = JavaScriptBridge # DI 시임 -- 테스트에서 mock으로 교체 (ADR-0003)
var _web_override = null # DI 시임 -- true/false로 강제, null=실제 OS 값 사용

func _ready() -> void:
	if _is_web():
		_js_bridge.eval("window.GodotAdBridge = {};", true)
		var bridge = _js_bridge.get_interface("window").GodotAdBridge
		bridge.adCompleted = _js_bridge.create_callback(_on_ad_completed)

func _is_web() -> bool:
	if _web_override != null:
		return _web_override
	return OS.has_feature("web")

func show_interstitial(on_complete: Callable) -> void:
	if not _is_web():
		on_complete.call()
		return
	if _pending_callback: # 재진입 가드 -- AC7
		return

	# ponytail (2026-08-02): 실브라우저 검증 중 발견 -- create_callback()으로 만든
	# JS->GDScript 콜백이 이 Godot 4.7.1 웹 익스포트에서 릴레이되지 않음(직접
	# window.GodotAdBridge.adCompleted() 수동 호출해도 GDScript 쪽 미도달, 5초
	# 타임아웃 폴백도 발화 안 함 -- prototypes/ad-callback-smoke/README.md 참조).
	# ad SDK가 없는 경로는 eval()의 동기 반환값으로 우회해서 콜백 릴레이 자체를
	# 안 탄다. AdSense H5 Games Ads(Ad Placement API)를 2026-08-04 실연동 --
	# `typeof adBreak`만 확인(head_include의 폴리필이 실 스크립트 로드 성패와
	# 무관하게 항상 즉시 전역에 정의해둠). 이후 실제 광고 네트워크 요청이 막히거나
	# (adblocker, 계정 미승인 등) 실패해도 공식 문서상 adBreakDone은 여전히
	# 정확히 1회 호출되도록 보장되므로, 여기서 더 깐깐하게 확인할 필요가 없다 --
	# 실브라우저 재검증은 여전히 필요(Open Questions 참조).
	var has_ad_sdk: bool = _js_bridge.eval("typeof adBreak === 'function'", true)
	if not has_ad_sdk:
		on_complete.call()
		return

	_pending_callback = on_complete
	_timeout_timer = get_tree().create_timer(AD_TIMEOUT_MS / 1000.0)
	_timeout_timer.timeout.connect(_on_ad_timeout)
	# adBreakDone은 광고 표시/스킵/에러/차단 여부와 무관하게 정확히 1회 보장되는
	# 유일한 콜백(공식 문서 명시) -- afterAd가 아니라 이걸로 재개해야 exactly-once가
	# 보장된다. 5초 타임아웃은 스크립트 자체가 죽었을 때의 최후 방어선으로 유지.
	_js_bridge.eval("""
		adBreak({
			type: 'next',
			name: 'run-result-return',
			adBreakDone: function() { window.GodotAdBridge.adCompleted(); }
		});
	""")

func _on_ad_completed() -> void: # JS에서 GodotAdBridge.adCompleted() 호출 시
	if _timeout_timer:
		_timeout_timer.timeout.disconnect(_on_ad_timeout)
	_fire_callback()

func _on_ad_timeout() -> void:
	_fire_callback()

func _fire_callback() -> void:
	if _pending_callback:
		_pending_callback.call()
		_pending_callback = Callable()
