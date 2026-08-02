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

**판정**: PARTIAL. `FS.syncfs` 호출 자체는 실증됐고 Godot의 자동 동기화 존재도 확인됐지만(ADR-0001 항목 a 실측 완료), 우리 콜백이 왕복하는지(항목 b)는 여전히 미확인 — 오히려 "Godot 자체 자동 동기화와 우리 명시적 호출이 경합해서 콜백이 죽는다"는 새로운 가설이 생김. 다음 세션 조사 방향: (1) 5초 타임아웃 자체가 왜 안 도는지부터 확인(SceneTreeTimer 단독 재현), (2) Godot의 자동 syncfs를 믿고 우리 쪽 명시적 `FS.syncfs()` 호출을 아예 빼는 대안(ADR-0001의 "Alternative 1" 재검토 근거가 될 수 있음 — 콜백 없이 신뢰하는 게 아니라, 최소한 자동 호출이 실재한다는 걸 알았으니).

## 결과 (2026-08-02, Godot 4.7.1, 헤드리스만)

| 확인 항목 | 결과 |
|---|---|
| `load(effect.icon_id)` + `TextureRect` 배선이 에러 없이 실행 | PASS (헤드리스 콘솔 출력 확인) |
| 실제 아이콘이 화면에 올바르게 보이는지 (스크린샷/육안) | **미확인** — 헤드리스 렌더 한계, 에디터 F6 필요 |

**판정**: 코드 배선은 신뢰할 수 있는 수준으로 확인됨(에러 없음 + 아이콘 PNG 3개는
생성 직후 개별적으로 육안 확인 완료, `design/art/status-icon-prompts.md` 참조).
화면 배치/크기감 같은 최종 비주얼 승인만 사람 확인 대기 — ADVISORY, 게이트 아님
(`.claude/docs/coding-standards.md` Test Evidence 표의 "Visual/Feel" 분류).
