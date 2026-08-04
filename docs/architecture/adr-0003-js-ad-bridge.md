# ADR-0003: JavaScriptBridge 광고 콜백 브릿지 — 표준 JS↔GDScript 콜백 패턴

## Status

Accepted (2026-08-04 — 실제 Ad SDK 연동 및 실브라우저 검증으로 Validation Criteria 전부 확인, 위 "Last Verified" 참조)

## Date

2026-07-26

## Last Verified

2026-08-04 — 실제 Ad SDK(Google AdSense H5 Games Ads / Ad Placement API) 연동 완료, 실브라우저 검증. `AdManager.show_interstitial()`을 `window.adManager.showInterstitial()` 플레이스홀더에서 실제 `adBreak({type:'next', name:..., adBreakDone: ...})` 호출로 교체(`adBreakDone`은 공식 문서상 광고 표시/스킵/에러/차단과 무관하게 정확히 1회 보장되는 유일한 콜백이라 이걸로 `window.GodotAdBridge.adCompleted()`를 호출). `export_presets.cfg`의 `html/head_include`에 AdSense 스크립트 태그 + `adBreak`/`adConfig` 폴리필 주입.

**중요 발견 — 2026-08-02의 "create_callback() 릴레이가 안 됨" 진단이 이 경로에는 적용되지 않음**: `prototypes/ad-callback-smoke/`를 로컬 서버로 재구동해 실측한 결과, `show_interstitial()` 호출 후 ~3초 내(5초 타임아웃보다 훨씬 전) "CALLBACK FIRED"가 표시됨 — 타임아웃 폴백이 아니라 실제 `adBreakDone → window.GodotAdBridge.adCompleted() → _on_ad_completed()` 릴레이가 정상 작동했다는 뜻. 네트워크 탭에서 `ep1.adtrafficquality.google/pagead/sodar` 요청(204)도 확인돼 SDK 자체가 실제로 로드·실행되고 있음도 함께 확인. 2026-08-02 당시엔 브라우저 DevTools 콘솔에서 수동으로 `window.GodotAdBridge.adCompleted()`를 호출해 릴레이 실패를 재현했었는데, 이번엔 진짜 비동기 SDK 콜백 경로로 도달했을 때 정상 동작함 — 두 경로의 차이(콘솔 수동 호출 vs SDK 내부 콜백)가 왜 다른 결과를 내는지는 이번 세션에서 추가로 조사하지 않음(원인 불명, 결과만 재확인). itch.io(`juunj/wind-tower:html`, v0.2.0)에 실제 배포 완료.

## Decision Makers

technical-director, godot-specialist (architecture.md Required ADR #3 담당 지정)

## Summary

`#18 광고 통합`(`AdManager`)의 GDD 리비전 과정에서 `window.GodotAdBridge`가 실제로 생성/바인딩되지 않아 두 JS 분기 모두 `ReferenceError`로 죽는 실제 버그가 발견되어 수정되었다. 이 ADR은 그 수정된 형태(`_ready()`에서 `JavaScriptBridge.create_callback()` 사전 등록 + 재진입 가드 + `_js_bridge` DI 시임)를 이 프로젝트에서 JS↔GDScript 비동기 콜백이 필요한 모든 곳에 적용할 표준 패턴으로 공식화한다.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 (HTML5 web export) |
| **Domain** | UI / Scripting |
| **Knowledge Risk** | HIGH — post-cutoff, must verify |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/modules/networking.md` — grep으로 `JavaScriptBridge`/`create_callback`/`get_interface` 키워드를 전체 `docs/engine-reference/godot/` 트리에서 검색했으나 **일치하는 파일이 0개**였다. |
| **Post-Cutoff APIs Used** | `JavaScriptBridge.eval()`, `JavaScriptBridge.create_callback()`, `JavaScriptBridge.get_interface()` |
| **Verification Required** | `JavaScriptBridge.create_callback()`와 `get_interface("window")`의 시그니처가 LLM 학습 데이터 커버리지(~4.3) 이후 4.4~4.6 사이 변경되었는지 확인 필요. **엔진 레퍼런스 라이브러리 자체의 갭으로 명시적으로 플래그**: 현재 `docs/engine-reference/godot/`에는 `JavaScriptBridge` 전용 문서(예: `modules/web.md` 또는 `modules/javascript-bridge.md`)가 존재하지 않는다 — 이 프로젝트가 HTML5 단일 타겟이고 `#17`/`#18` 양쪽 모두 이 API에 의존하는 점을 고려하면 이는 이 ADR 하나로 메울 수 있는 갭이 아니라 엔진 레퍼런스 라이브러리 자체에 전용 문서를 추가할 가치가 있는 항목이다(아래 Risks 참조). 실제 4.6 빌드에서 이 ADR의 Key Interfaces 코드가 컴파일/실행되는지 최소 재현 테스트로 확인해야 한다. |

> **Note**: Knowledge Risk가 HIGH이므로 엔진 버전 업그레이드 시 이 ADR은 반드시 재검증되어야 한다.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0001("HTML5 웹 익스포트 로컬 저장 동기화 검증")의 durability-confirmation 접근법 — ADR-0001은 이 ADR이 확립하는 `_ready()` 사전 등록 + `create_callback()` + DI 시임 패턴을 `FS.syncfs()` 콜백 브릿지에 그대로 재사용한다. |
| **Blocks** | `#18 광고 통합` 구현 착수 |
| **Ordering Note** | ADR-0001과 병렬로 작성되었으나(번호 사전 배정), 이 ADR이 정의하는 패턴이 ADR-0001의 구현 세부사항에 선행 참조된다 — 코드 작성 순서상 이 ADR의 패턴을 먼저 확정하는 것을 권장. |

## Context

### Problem Statement

Godot 웹 익스포트에서 브라우저 JS가 비동기로 완료한 이벤트(광고 종료, IndexedDB 동기화 등)를 GDScript 쪽으로 신뢰성 있게 되돌리는 방법이 필요하다. `#18` GDD의 초기 설계 리뷰에서, JS eval 문자열이 `GodotAdBridge.adCompleted()`를 호출하도록 작성되어 있었지만 **그 객체와 메서드를 실제로 만들거나 바인딩하는 코드가 어디에도 없어서** 실행 시 두 JS 분기(정상 완료·SDK 미로드) 모두 `ReferenceError`로 죽고, 오직 5초 타임아웃 페일세이프 경로만 우연히 동작하는 상태였다. 이 버그 클래스(등록 없이 콜백을 호출)는 JS 브릿지가 필요한 다른 시스템(`#17`의 durability 확인 등)에서도 동일하게 재발할 수 있는 구조적 리스크다.

### Current State

`#18` GDD는 리뷰를 거쳐 이미 수정된 코드를 담고 있다: `_ready()`에서 `JavaScriptBridge.eval("window.GodotAdBridge = {};", true)` 후 `get_interface("window").GodotAdBridge.adCompleted = JavaScriptBridge.create_callback(_on_ad_completed)`로 실제 바인딩을 생성한다. 또한 재진입 가드(`if _pending_callback: return`)와 `_js_bridge` 필드(기본값은 실제 `JavaScriptBridge` 싱글톤, 테스트에서 mock으로 교체 가능)가 추가되었다. 이 ADR은 이 이미 검증된 설계를 아키텍처 표준으로 승격하는 것이다.

### Constraints

- Godot HTML5 익스포트만 대상 — 데스크톱/에디터는 `OS.has_feature("web") == false`로 이 경로 자체를 우회한다.
- `JavaScriptBridge` API의 4.4→4.6 변경 여부가 엔진 레퍼런스 라이브러리에 문서화되어 있지 않다(Verification Required 참조) — 학습 데이터로 API 존재를 가정할 수는 있으나 정확한 시그니처는 실제 4.6 빌드에서 재확인이 필요하다.
- GUT은 헤드리스 테스트 환경이라 실제 브라우저 JS를 실행할 수 없다 — DI 시임 없이는 이 경로가 전혀 테스트 불가능하다.

### Requirements

- 콜백 등록은 반드시 `eval()` 호출이 그 콜백을 참조하기 전에 완료되어야 한다.
- 타임아웃 페일세이프와 async 콜백이 동시에 존재하는 모든 곳에서, 두 경로가 경쟁할 때 정확히 한 번만 발화해야 한다(race 해결).
- 헤드리스 테스트 환경에서 실제 브라우저 실행 없이 계약(eval 호출 여부, 콜백 처리 로직)을 검증할 수 있어야 한다.

## Decision

이 프로젝트에서 JS↔GDScript 비동기 콜백이 필요한 모든 Autoload(현재 `AdManager`, 향후 `SaveManager`의 durability 확인 등)는 다음 표준 패턴을 따른다:

1. **사전 등록 필수**: 브릿지 객체와 콜백 바인딩은 반드시 `_ready()`에서, 그 콜백을 참조할 수 있는 어떤 `eval()` 호출보다도 먼저 수행한다.
2. **DI 시임 필수**: `JavaScriptBridge`를 직접 참조하지 않고 `_js_bridge` 필드(기본값 실제 싱글톤)를 통해 접근한다 — GUT 테스트가 mock으로 교체할 수 있도록.
3. **재진입 가드 필수**: 타임아웃 기반 폴백과 async 콜백 경로가 공존하는 경우, 진행 중인 요청이 있으면 새 요청을 무시하는 가드를 둔다 — 두 경로 중 먼저 도착한 쪽만 발화하고 이후 경로는 무시.

### Architecture

```
[GDScript _ready()]
    │
    ├─ JavaScriptBridge.eval("window.<Bridge> = {};", true)
    ├─ get_interface("window").<Bridge>.<method> = create_callback(_on_callback)
    │
[GDScript 요청 시점]
    │
    ├─ 재진입 가드 확인 (_pending_callback 등 이미 있으면 즉시 return)
    ├─ 타이머 시작 (페일세이프)
    ├─ JavaScriptBridge.eval("<브라우저 SDK 호출 또는 <Bridge>.<method>() 즉시 호출>")
    │
    ├─(JS async 완료)──→ <Bridge>.<method>() 호출 ──→ create_callback 발화 ──→ _on_callback()
    │                                                                              │
    └─(타이머 만료)────────────────────────────────────────────────────→ _on_timeout()
                                                                                   │
                                                              (둘 중 먼저 온 쪽만) _fire_callback()
```

### Key Interfaces

```gdscript
# 표준 패턴 — 어떤 JS 브릿지 Autoload든 이 골격을 따른다
extends Node

var _js_bridge = JavaScriptBridge  # DI 시임 — 테스트에서 mock 주입
var _pending_callback: Callable

func _ready() -> void:
    if OS.has_feature("web"):
        _js_bridge.eval("window.<BridgeName> = {};", true)
        var bridge = _js_bridge.get_interface("window").<BridgeName>
        bridge.<method_name> = _js_bridge.create_callback(_on_js_callback)

func request(on_complete: Callable) -> void:
    if not OS.has_feature("web"):
        on_complete.call()
        return
    if _pending_callback:  # 재진입 가드
        return
    _pending_callback = on_complete
    # 타이머 페일세이프 설정 + eval() 호출

func _on_js_callback() -> void:
    _fire_callback()

func _fire_callback() -> void:
    if _pending_callback:
        _pending_callback.call()
        _pending_callback = Callable()
```

### Implementation Guidelines

- `<BridgeName>`/`<method_name>` 네이밍은 시스템별로 자유롭되(`GodotAdBridge`, `GodotSaveBridge` 등), 등록·가드·시임 구조는 반드시 동일하게 유지한다.
- 재진입 가드는 타임아웃 페일세이프가 있는 경로에서만 필수다 — 페일세이프가 없는 단순 1회성 콜백이라면 가드 없이도 안전할 수 있으나, 이 프로젝트의 두 현재 사례(`#18`, ADR-0001의 `#17`)는 모두 타임아웃을 갖고 있으므로 둘 다 가드 필수.
- GUT 테스트는 `_js_bridge`에 mock을 주입해 `eval()` 호출 인자 문자열과 `_on_js_callback()` 직접 호출을 통한 콜백 시뮬레이션만 검증한다 — 실제 브라우저 JS 실행 자체는 자동화 테스트 범위 밖(수동 실브라우저 검증 필요, Verification Required 참조).

## Alternatives Considered

### Alternative 1: JS 폴링 루프

- **Description**: GDScript가 `_process()`에서 주기적으로 `JavaScriptBridge.eval()`을 호출해 JS 쪽 상태 변수(예: `window.adCompleted`)를 확인.
- **Pros**: 콜백 등록이 필요 없어 `ReferenceError` 클래스의 버그 자체가 발생하지 않는다.
- **Cons**: 매 프레임 eval 호출은 오버헤드가 있고, 이 프로젝트의 원칙 2("시그널 우선, 폴링 금지")를 정면으로 위반한다. 응답 지연도 폴링 주기에 종속된다.
- **Estimated Effort**: 낮음
- **Rejection Reason**: 아키텍처 원칙 위반(폴링 금지) + 불필요한 오버헤드. 콜백 등록 누락 버그는 이 ADR의 표준 패턴(사전 등록 강제)으로 이미 해결 가능하므로 폴링으로 우회할 필요가 없다.

### Alternative 2: `window.adManager`의 자체 Promise API에 직접 의존(중간 브릿지 객체 생략)

- **Description**: `GodotAdBridge` 같은 중간 객체 없이, `window.adManager.showInterstitial()`이 반환하는 Promise를 어떻게든 GDScript로 직접 연결.
- **Pros**: 중간 계층 하나를 줄일 수 있어 보임.
- **Cons**: `JavaScriptBridge.create_callback()`은 애초에 "JS에서 호출 가능한 GDScript 함수 참조"를 만드는 메커니즘이지 Promise를 직접 소비하지 않는다 — 결국 JS 쪽에서 Promise를 `.then()`으로 받아 그 안에서 등록된 콜백을 호출하는 중개 코드가 필요하며, 이는 `GodotAdBridge`와 본질적으로 동일한 중간 객체를 다른 이름으로 다시 만드는 것에 불과하다.
- **Estimated Effort**: 동일하거나 더 높음(Promise 체이닝 관리 추가)
- **Rejection Reason**: 중간 브릿지 객체는 선택적 오버헤드가 아니라 `JavaScriptBridge.create_callback()`의 등록 방식 자체가 요구하는 필수 구조다 — 생략이 불가능하므로 대안이 되지 못한다.

## Consequences

### Positive

- `#18`에서 실제로 발생했던 "등록 없이 호출" 버그 클래스가 아키텍처 표준으로 재발 방지된다 — 앞으로 JS 브릿지가 필요한 모든 시스템(ADR-0001의 `#17` 포함)이 동일한 검증된 골격을 그대로 재사용한다.
- DI 시임 표준화로 모든 JS 브릿지 Autoload가 GUT 헤드리스 환경에서 테스트 가능해진다.

### Negative

- 모든 JS 브릿지 코드에 등록 단계(`_ready()`)와 가드 로직이라는 고정 보일러플레이트가 추가된다 — 아주 단순한 1회성 호출에도 동일한 골격을 요구하면 과할 수 있으나, 이 프로젝트의 두 사례 모두 타임아웃 페일세이프를 갖고 있어 가드가 실제로 필요하다.

### Neutral

- 네이밍(`<BridgeName>`)은 시스템별로 자유 — 표준화 대상은 구조이지 이름이 아니다.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `JavaScriptBridge.create_callback()`/`get_interface()` 시그니처가 4.4~4.6 사이 변경되어 이 ADR의 Key Interfaces 코드가 그대로 동작하지 않음 | Unknown (엔진 레퍼런스 라이브러리에 문서화 자체가 없음) | High (컴파일/런타임 에러, `#18`/`#17` 양쪽 모두 영향) | 실제 4.6 빌드에서 최소 재현 스니펫을 먼저 실행해 시그니처 확인 — 구현 착수 전 필수. 또한 `docs/engine-reference/godot/`에 `JavaScriptBridge` 전용 레퍼런스 문서를 추가하는 것을 별도 작업으로 권장(이 ADR의 범위 밖이지만 엔진 레퍼런스 라이브러리 자체의 갭으로 기록) |
| 재진입 가드가 없는 새 JS 브릿지 시스템이 향후 추가될 때 이 표준을 따르지 않아 `#18`과 동일한 타이머 누수 버그가 재발 | Medium | Medium | 코드 리뷰 체크리스트에 "JS 브릿지 Autoload는 ADR-0003 패턴을 따르는가"를 포함 |

## Performance Implications

N/A — 구현 코드가 존재하지 않아 측정할 대상이 없다.

## Migration Plan

N/A — 마이그레이션 대상이 되는 기존 시스템이 없다(첫 구현). 단, 향후 `#17`(ADR-0001)이 이 패턴을 재사용할 때는 신규 코드 작성이지 기존 코드 변경이 아니다.

## Validation Criteria

- [x] 실제 Godot 4.7.1 웹 빌드에서 `JavaScriptBridge.create_callback()` + `get_interface("window")` 최소 재현 스니펫이 에러 없이 동작함을 확인. — 2026-08-04, 실제 AdSense SDK 콜백 경로로 확인(위 "Last Verified" 참조). 단, DevTools 콘솔에서의 수동 호출은 여전히 실패 재현됨(2026-08-02) — 이 차이의 원인은 미규명.
- [x] `AdManager`의 GUT 테스트(mock `_js_bridge` 사용)가 `#18` GDD의 Acceptance Criteria 1,3,6,7을 모두 통과. — 182/182 GUT 통과 유지(2026-08-04).
- [x] 재진입 가드가 실제로 타이머 누수(이전 리비전에서 발견된 버그)를 재발하지 않음을 확인. — `test_reentrant_call_ignored_while_pending` (AC7) 통과 유지.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/광고-통합.md` (구현 구조, 2026-07-26 리비전) | #18 광고 통합 | "구 버전은 GodotAdBridge.adCompleted()를 호출만 했지 window.GodotAdBridge를 만들거나 _on_ad_completed에 바인딩하는 코드가 전혀 없었다... _ready()에서 JavaScriptBridge.create_callback()으로 실제 콜백을 등록하도록 수정" | 이 ADR이 정확히 이 수정된 패턴(`_ready()` 사전 등록)을 프로젝트 표준으로 공식화 |
| `design/gdd/광고-통합.md` (Core Rules, `_pending_callback` 가드) | #18 광고 통합 | "재진입 시 타이머 누수... `_pending_callback`이 이미 있으면 재호출을 무시하는 가드" | 재진입 가드를 "타임아웃 페일세이프가 있는 모든 JS 브릿지"의 필수 요구사항으로 일반화 |
| `design/gdd/광고-통합.md` (Acceptance Criteria 1,3,6,7) | #18 광고 통합 | `_js_bridge` mock 주입을 통한 GUT 헤드리스 검증 요구 | DI 시임을 표준 패턴의 필수 요소로 명시 |

## Related

- ADR-0001 (`docs/architecture/adr-0001-html5-local-save-sync.md`) — `#17`의 `FS.syncfs()` durability 확인 콜백이 이 ADR의 패턴을 재사용.
- `design/gdd/광고-통합.md` — 구현 구조, Core Rules, Acceptance Criteria 1/3/6/7
- `docs/architecture/architecture.md` — Module Ownership(#18 PLATFORM), Required ADRs #3
