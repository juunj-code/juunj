extends GutTest
## #18 광고 통합. See design/gdd/광고-통합.md Acceptance Criteria, ADR-0003.
## Tests the real AdManager autoload directly (same convention as
## companion_unlock_test.gd) -- no class_name here, since Godot rejects a
## script that both declares class_name and is registered under the same
## autoload name ("hides an autoload singleton"). `_web_override`/`_js_bridge`
## are reset in after_each() so no state leaks into other test files.
##
## AC5(게임플레이 중 미호출)는 AdManager 자체엔 자율 트리거 코드가 아예 없어
## (호출부는 전부 외부 시스템 소관) 테스트로 검증할 로직이 없음 -- YAGNI.

func after_each() -> void:
	AdManager._web_override = null
	AdManager._js_bridge = JavaScriptBridge
	AdManager._pending_callback = Callable()
	AdManager._timeout_timer = null

func test_non_web_calls_on_complete_immediately() -> void: # AC2
	var called := [false] # boxed -- GDScript lambdas capture locals by value, not by reference

	AdManager.show_interstitial(func(): called[0] = true)

	assert_true(called[0])

func test_web_show_interstitial_evals_showInterstitial_exactly_once() -> void: # AC1
	var mock := MockJsBridge.new()
	mock.eval_return_value = true # SDK present
	AdManager._web_override = true
	AdManager._js_bridge = mock

	AdManager.show_interstitial(func(): pass)

	var dispatch_calls: Array = mock.eval_calls.filter(func(s): return s.contains("showInterstitial()"))
	assert_eq(dispatch_calls.size(), 1)

func test_ad_completed_fires_on_complete() -> void: # AC3
	var mock := MockJsBridge.new()
	mock.eval_return_value = true # SDK present
	AdManager._web_override = true
	AdManager._js_bridge = mock
	var called := [false]

	AdManager.show_interstitial(func(): called[0] = true)
	AdManager._on_ad_completed() # simulate JS calling back

	assert_true(called[0])

func test_timeout_fires_callback_when_ad_never_responds() -> void: # AC4
	var mock := MockJsBridge.new()
	mock.eval_return_value = true # SDK present
	AdManager._web_override = true
	AdManager._js_bridge = mock
	var called := [false]

	AdManager.show_interstitial(func(): called[0] = true)
	AdManager._on_ad_timeout() # simulate the 5s failsafe firing

	assert_true(called[0])

## AC6, revised 2026-08-02: real browser verification found create_callback()'s
## JS->GDScript relay never fires in this Godot 4.7.1 web export (manual
## window.GodotAdBridge.adCompleted() calls and the 5s timeout both silently
## no-op -- see prototypes/ad-callback-smoke/README.md). The no-SDK case (100%
## of the current MVP, since no ad SDK is integrated yet) now bypasses that
## broken relay entirely via eval()'s synchronous return value instead of
## routing through a JS-side if/else + GodotAdBridge.adCompleted() callback.
func test_sdk_missing_completes_synchronously_without_dispatch() -> void: # AC6
	var mock := MockJsBridge.new()
	mock.eval_return_value = false # no SDK
	AdManager._web_override = true
	AdManager._js_bridge = mock
	var called := [false]

	AdManager.show_interstitial(func(): called[0] = true)

	assert_true(called[0])
	var dispatch_calls: Array = mock.eval_calls.filter(func(s): return s.contains("showInterstitial()"))
	assert_eq(dispatch_calls.size(), 0) # never reached the broken async relay

func test_reentrant_call_ignored_while_pending() -> void: # AC7
	var mock := MockJsBridge.new()
	mock.eval_return_value = true # SDK present -- only reachable once pending
	AdManager._web_override = true
	AdManager._js_bridge = mock
	var first_called := [false]
	var second_called := [false]

	AdManager.show_interstitial(func(): first_called[0] = true)
	AdManager.show_interstitial(func(): second_called[0] = true) # ignored -- already pending
	AdManager._on_ad_completed()

	assert_true(first_called[0])
	assert_false(second_called[0])
	var dispatch_calls: Array = mock.eval_calls.filter(func(s): return s.contains("showInterstitial()"))
	assert_eq(dispatch_calls.size(), 1) # second call didn't re-dispatch

class MockJsBridge:
	var eval_calls: Array[String] = []
	var eval_return_value = null # configurable per test -- the SDK-presence check is synchronous

	func eval(code: String, _use_strict_mode: bool = false):
		eval_calls.append(code)
		return eval_return_value

	func get_interface(_name: String):
		return null

	func create_callback(method: Callable) -> Callable:
		return method
