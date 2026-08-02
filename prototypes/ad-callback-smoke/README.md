# 프로토타입: AdManager 콜백 스모크 체크 (throwaway)

```
QUESTION:     RunResultScreen "메인메뉴로" 버튼이 실제 웹 빌드에서 클릭해도
              반응하지 않는 문제 발견 (던전 플레이스루 중) -- AdManager.
              show_interstitial()의 JS->GDScript 콜백(_js_bridge.create_callback)이
              실제로 릴레이되는가?
CORE VERB:    RunManager 없이 AdManager.show_interstitial()을 단독 호출,
              콜백이 오는지/타임아웃 폴백이 도는지 화면 Label로 확인
THROWAWAY?:   yes -- prototypes/ad-callback-smoke/, src/에서 임포트 안 함
KEEP IF:      "CALLBACK FIRED"가 즉시 또는 5초 타임아웃 후 뜸
KILL IF:      아무것도 안 뜸 -- create_callback 릴레이 자체가 깨짐
```

## 배경

던전 플레이스루로 승패 흐름을 검증하던 중, 패배 후 RunResultScreen에서
"메인메뉴로" 버튼을 3번 클릭 + 총 11초 이상 대기해도 아무 반응이 없었다.
버튼은 `RunResult.go_to_main_menu()` -> `AdManager.show_interstitial(callback)`
-> (ad 없으면) `GodotAdBridge.adCompleted()` 즉시 호출 -> `_on_ad_completed()`
-> `_fire_callback()` -> `callback.call()` -> `SceneManager.go_to("S-02", ...)`
경로를 탄다.

실브라우저 콘솔에서 `window.GodotAdBridge.adCompleted()`를 수동으로 호출해봐도
전환이 일어나지 않았다 -- JS 쪽 함수 자체는 존재하고 호출 가능한데
(`typeof window.GodotAdBridge.adCompleted === "function"`), GDScript
`_on_ad_completed()`가 실행되는 기색이 없음. `create_callback()`으로 만든
콜백이 JS에서 호출됐을 때 실제로 GDScript 쪽으로 릴레이되는지가 핵심 의문.

이 세션 초반 ADR-0001에서 발견한 문제(GDScript->JS 방향, `FS`/`Module`이
전역에 없음)와는 반대 방향(JS->GDScript)의 문제라 별도로 검증 필요.

## 실행 방법

1. `project.godot`의 `run/main_scene`을 이 씬으로 잠깐 변경
2. `--export-release "Web" build/web/index.html`로 재익스포트
3. 로컬 서버로 서빙 후 브라우저에서 열어 화면 텍스트 확인
4. 완료 후 `run/main_scene`을 `Boot.tscn`으로 원복 (git diff로 확인)

## 결과

**KEEP (근본 원인 확정, 수정 완료, 2026-08-02)** — 실제 웹 빌드에서 이 씬을 단독 구동한 결과
`CALLBACK FIRED`가 **즉시** 뜸(타임아웃 아님). 단, 이건 수정 후 검증 결과다:

- **근본 원인**: `create_callback()`으로 만든 JS→GDScript 콜백이 이 Godot 4.7.1 웹
  익스포트에서 릴레이되지 않음 — ADR-0001에서 확인된 문제(GDScript→JS 방향, `FS`가
  전역에 없음)와 반대 방향의 동일 계열 버그. `window.GodotAdBridge.adCompleted()`를
  콘솔에서 수동 호출해도 GDScript `_on_ad_completed()`가 실행되지 않았고, 5초
  타임아웃 폴백도 발화하지 않았음(수정 전 상태로 직접 재현 확인).
- **수정**: `AdManager.show_interstitial()`이 광고 SDK 존재 여부를
  `_js_bridge.eval("!!(window.adManager && ...)", true)`의 **동기 반환값**으로
  먼저 확인하도록 변경 — SDK가 없으면(현재 MVP 100% 케이스) 깨진 콜백 릴레이를
  아예 타지 않고 `on_complete.call()`을 바로 호출. SDK가 실제로 존재하는 경로만
  기존 비동기 콜백/타임아웃 배선을 그대로 사용(광고 SDK 통합 시점에 반드시 재검증
  필요 — 그 경로는 이번에 실증 못 함).
- **검증**: 수정 적용 후 이 씬으로 재익스포트 → 실브라우저 로드 →
  `booting... → web=true → calling show_interstitial()... → CALLBACK FIRED →
  show_interstitial() returned...` 전부 즉시(동기) 표시 확인. 182/182 GUT 통과.
  `src/core/ad_manager.gd`, `tests/unit/core/ad_manager_test.gd`에 반영.
- **후속**: 실제 광고 SDK를 붙이는 시점에 SDK-존재 분기(비동기 콜백 경로)를 이
  프로토타입과 같은 방식(단독 씬 + 화면 Label)으로 재검증할 것 — 이번엔 SDK가
  없어서 그 경로는 코드만 존재하고 실증되지 않았다.
