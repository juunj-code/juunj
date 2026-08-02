# 프로토타입: 상태이상 아이콘 렌더 스모크 체크 (throwaway)

**상태**: 부분 완료 — 헤드리스로 확인 가능한 만큼만 PASS. 실제 화면 스크린샷 확인은
사람이 에디터에서 F6으로 직접 봐야 함 (아래 "왜 헤드리스로 스크린샷이 안 되는가" 참조).

## 프로토타입 브리프

```
QUESTION:     StatusEffect.icon_id + battle_screen.gd의 TextureRect 배선
              (design/art/art-bible.md Section 5)이 에러 없이 동작하는가?
CORE VERB:    RunManager를 실제 씬 전환 없이 스텁으로 세팅, BattleScreen을
              poison+stun+defense_up 3종 활성 상태로 단독 구동
THROWAWAY?:   yes — prototypes/status-icon-smoke/, src/에서 임포트 안 함
KEEP IF:      에러 없이 _ready() 끝까지 도달 — load()/TextureRect 배선 자체는 정상
KILL IF:      load() 실패나 null 텍스처 에러 — icon_id 경로/에셋 문제
```

## 왜 헤드리스로 스크린샷이 안 되는가

`--headless`는 dummy 렌더링 드라이버를 쓰기 때문에 `get_viewport().get_texture()`가
항상 null — 실제 픽셀을 볼 방법이 없다. `prototypes/touch-input-smoke/`가 이미
발견한 것과 같은 계열의 한계(그쪽은 입력 디스패치, 이쪽은 렌더 출력)라서 스크린샷
검증은 처음부터 포기하고, 대신 "코드가 에러 없이 끝까지 도는가"만 헤드리스로 확인했다.

## 실행 방법 (헤드리스 — 배선 에러 유무만 확인)

```
godot --headless --path . res://prototypes/status-icon-smoke/StatusIconSmoke.tscn
```

콘솔에 `status icon smoke: reached end of _ready() without error -- PASS`가 뜨면
`load(effect.icon_id)` + `TextureRect` 배선 자체는 정상.

## 실제 확인이 필요하면 (사람이 눈으로)

1. `StatusIconSmoke.tscn`을 Godot 에디터에서 연다.
2. F6으로 실행한다.
3. 파티 쪽 유닛 줄에 poison(빨강 해골)/stun(빨강 소용돌이)/defense_up(초록 방패+화살표)
   아이콘 3개 + 잔여 턴수 숫자가 나란히 보이는지 확인.

**추가 (2026-08-02)**: `enemy_tank_01`에 `sprite_id`가 채워진 뒤로 이 스모크가
`battle_screen.gd`의 적 스프라이트 `load()`/`TextureRect` 배선도 같이 검증한다
(같은 씬을 재사용, 별도 스크립트 안 만듦).

## 추가 프로토타입: `save_bridge_debug.gd`/`SaveBridgeDebug.tscn` (2026-08-02)

ADR-0001 2단계(`SaveManager`의 `FS.syncfs()` 확인) 구현 직후, 실제 웹 빌드에서
전체 던전을 수동으로 클릭해 런을 끝까지 진행하지 않고도 `SaveManager.save()`를
직접 호출해 진짜 IndexedDB 왕복을 볼 수 있게 만든 디버그 씬. 사용법:
`project.godot`의 `run/main_scene`을 잠깐 이 씬으로 바꾸고 익스포트 → 확인 →
`Boot.tscn`으로 원복(둘 다 이 세션에서 이미 처리, `.git diff`로 원복 확인됨).

**결과 (2026-08-02, 실제 웹 빌드, 로컬 서빙)**:
- `SAVE_BRIDGE_DEBUG: calling save() -- OS.has_feature(web)=true` — 웹 분기 진입 확인
- `SAVE_BRIDGE_DEBUG: save() returned true` — 1단계(가상 FS 쓰기) 정상
- 브라우저 콘솔에 Emscripten 자체 경고 발생: **`warning: 2 FS.syncfs operations in flight at once, probably just doing extra work`** — `FS.syncfs`가 실제로 존재하고 호출된다는 확실한 증거. 동시에 "2개가 동시 진행 중"이라는 건 **Godot 엔진 자신도 `user://` 쓰기 시 내부적으로 `FS.syncfs()`를 자동 호출한다**는 뜻으로 보임 — ADR-0001의 Verification Required 항목 (a)("FileAccess.close()가 IndexedDB 자동 동기화를 트리거하는지")가 사실상 YES로 실측된 것.
- **그런데 `GodotSaveBridge.onSyncDone` 콜백도, 5초 타임아웃 폴백(`_on_sync_timeout`)도 20초 넘게 기다려도 전혀 발화하지 않음.** 콜백 자체가 아예 안 오는 건지, SceneTreeTimer가 이 씬 구성에서 안 도는 건지 이번 세션에선 원인 특정까지 못함.

**판정 (1차)**: PARTIAL — 위 결론은 콘솔 캡처 도구가 이 세션에서 신뢰도 낮은 것으로 드러나 아래 2~4차로 뒤집힘.

### 2~4차: 진짜 근본 원인 확정 (같은 날, 콘솔 대신 화면 Label + DOM 오버레이로 직접 확인)

콘솔 메시지 캡처가 초반 로그를 자꾸 누락하는 걸 발견해서(같은 페이지를 다시 읽어도 이전 항목이 그대로 나오거나 중간 로그가 빠짐), `read_console_messages` 대신 **결과를 Godot `Label`과 `document.body`에 꽂은 `<div>`에 직접 써서 스크린샷으로 읽는 방식**으로 바꿔 재검증:

- **핵심 원인**: `typeof FS` → `undefined`, `typeof Module` → `undefined`, `typeof Module.FS` → `undefined`. `JavaScriptBridge.eval()`로 주입한 코드는 페이지 전역(`window`) 스코프에서 실행되는데, **이 Godot 4.7.1 웹 익스포트의 Emscripten `Module`/`FS`는 전역에 노출되지 않는 클로저 내부 값**이라 외부에서 절대 못 건드림. `FS.syncfs(...)`를 부르면 즉시 `ReferenceError: FS is not defined`로 던져짐(1차에서 본 "2 FS.syncfs operations in flight" 경고는 이 세션 중 빠르게 반복한 여러 탭/리로드가 겹쳐 생긴 다른 현상으로 추정 — 실제로는 우리 호출이 성공한 적이 한 번도 없었음).
- **결론**: `ADR-0001`의 Key Interfaces에 적힌 구현(`_js_bridge.eval("FS.syncfs(false, ...)")`)은 **이 Godot 버전에서 원천적으로 동작 불가능** — `save_manager.gd`의 콜백이 영원히 안 오는 게 당연했음(예외가 나되 GDScript 쪽에 전파 안 되고 조용히 삼켜짐). 지금 구현된 5초 타임아웃 폴백조차 발화 안 하는 것도 확인됐는데(부가 발견, 아래), 그거와 무관하게 어차피 이 경로 자체가 막혀 있었음.
- **부가 발견 (원인 미해결, 별도 이슈로 분리)**: 이 최소 디버그 씬에서는 `_process()`도, `get_tree().create_timer()`도 전혀 발화하지 않음(10초+ 대기해도 프레임 카운터가 0에서 안 움직임) — 반면 이번 세션 앞부분에서 실제 게임 화면(메인메뉴 Tween 페이드, 전투 등)은 정상적으로 시간 기반 동작을 했음. 즉 일반 게임 진행 중엔 문제 없고, 이 특정 "거의 빈 Control 하나뿐인" 디버그 씬에서만 재현됨 — 원인 미상, 프로덕션 영향 여부 불명확이라 더 안 팜.

**결정 (2026-08-02, 사용자 선택)**: 대안 3(웹 영속화를 `localStorage`로 완전 재설계)으로 진행. `localStorage`/`window`/`document`는 이번 진단에서 `eval()`로 실제 접근 가능함이 이미 확인된 상태였고(`FS`와 달리 브라우저 표준 전역 API), `localStorage.setItem()/getItem()`이 동기식이라 애초에 ADR-0001이 필요로 했던 "완료 확인 콜백" 자체가 불필요해짐(호출이 안 던지면 이미 쓰기가 끝난 것).

**구현 완료**: `save_manager.gd` 전면 재설계 — 웹 분기에서 `user://`+`FileAccess`+`FS.syncfs()` 대신 `JavaScriptBridge.eval()`로 `localStorage.setItem/getItem`을 직접 호출(payload는 Base64로 감싸서 JS 문자열 리터럴 이스케이핑 문제 원천 차단). 비동기 콜백/타임아웃 관련 코드(`_confirm_durable_write`, `_on_indexeddb_sync_done`, `_on_sync_timeout`, `_sync_timeout_timer`, `_ready()`의 `GodotSaveBridge` 등록) 전부 삭제 — 더 이상 필요 없음. 데스크톱 경로는 완전히 그대로. 테스트도 새 흐름에 맞게 재작성(`save_manager_test.gd`), 182/182 GUT 통과.

**실브라우저 최종 검증 (`save_bridge_debug.gd` 최종본, round 6)**: 실제 웹 빌드에서 `SaveManager.save()` → 메모리 초기화 → `SaveManager.load_from_disk()` 전체 왕복 성공 확인 — `save() returned true`, `reloaded section: { "ts": 1390.0, "value": 42.0 }`, `PASS`. **ADR-0001의 실질적 목표(웹에서 저장이 실제로 됐는지 확인 가능)가 이번에 진짜로 달성됨.**

## 결과 (2026-08-02, Godot 4.7.1, 헤드리스만)

| 확인 항목 | 결과 |
|---|---|
| `load(effect.icon_id)` + `TextureRect` 배선이 에러 없이 실행 | PASS (헤드리스 콘솔 출력 확인) |
| 실제 아이콘이 화면에 올바르게 보이는지 (스크린샷/육안) | **미확인** — 헤드리스 렌더 한계, 에디터 F6 필요 |

**판정**: 코드 배선은 신뢰할 수 있는 수준으로 확인됨(에러 없음 + 아이콘 PNG 3개는
생성 직후 개별적으로 육안 확인 완료, `design/art/status-icon-prompts.md` 참조).
화면 배치/크기감 같은 최종 비주얼 승인만 사람 확인 대기 — ADVISORY, 게이트 아님
(`.claude/docs/coding-standards.md` Test Evidence 표의 "Visual/Feel" 분류).
