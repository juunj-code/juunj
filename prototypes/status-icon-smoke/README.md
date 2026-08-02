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

## 결과 (2026-08-02, Godot 4.7.1, 헤드리스만)

| 확인 항목 | 결과 |
|---|---|
| `load(effect.icon_id)` + `TextureRect` 배선이 에러 없이 실행 | PASS (헤드리스 콘솔 출력 확인) |
| 실제 아이콘이 화면에 올바르게 보이는지 (스크린샷/육안) | **미확인** — 헤드리스 렌더 한계, 에디터 F6 필요 |

**판정**: 코드 배선은 신뢰할 수 있는 수준으로 확인됨(에러 없음 + 아이콘 PNG 3개는
생성 직후 개별적으로 육안 확인 완료, `design/art/status-icon-prompts.md` 참조).
화면 배치/크기감 같은 최종 비주얼 승인만 사람 확인 대기 — ADVISORY, 게이트 아님
(`.claude/docs/coding-standards.md` Test Evidence 표의 "Visual/Feel" 분류).
