# 프로토타입: ADR-0011 터치 입력 스모크 테스트 (throwaway)

**상태**: 완료 — PASS. throwaway, `src/`로 승격 안 됨. 삭제해도 무방 (ADR-0011에 결과 기록 완료).

## 프로토타입 브리프

```
QUESTION:     Godot 4.7(듀얼 포커스 시스템)에서 (a) 탭/클릭이 Button.pressed에
              정상 도달하는가, (b) grab_focus()를 전혀 쓰지 않는 커스텀
              enum 기반 하이라이트가 탭에 정상 반응하는가?
CORE VERB:    버튼 하나 + 커스텀 하이라이트 박스 하나, 탭하면 라벨에 결과 표시
THROWAWAY?:   yes — prototypes/touch-input-smoke/, src/에서 임포트 안 함
KEEP IF:      둘 다 YES — ADR-0011의 리스크 회피 설계(네이티브 Focus 비의존)가
              실제로 동작함이 확인됨, ADR을 Accepted로 전환 가능
KILL IF:      아무 반응 없음 — ADR-0011의 대안 설계(Alternatives 참고) 재검토 필요
```

## 왜 헤드리스가 아니라 에디터 실행인가

처음엔 `godot --headless --script`로 `Input.parse_input_event()`/`viewport.push_input()`
둘 다 시도했지만, **마우스 클릭조차 Button의 `gui_input`에 전혀 도달하지 않았다**
(터치 전용 문제가 아니라 `--headless` 자체가 실제 DisplayServer 윈도우 없이 GUI 입력
디스패치 파이프라인을 돌리지 않는 것으로 보임). 이건 ADR-0011이 실제로 알고 싶어하는
"실제 빌드/실제 입력에서 되는가"를 헤드리스로는 답할 수 없다는 뜻 — 그래서 실제
에디터 실행(F6)으로 사람이 눈으로 확인하는 방식으로 전환했다.

## 실행 방법

1. `TouchSmokeTest.tscn`을 Godot 에디터에서 연다.
2. F6 (Run Current Scene)으로 실행한다.
3. "TAP ME (Button)" 버튼을 클릭/탭한다 → 화면 하단 라벨의 "a)"가 YES로 바뀌는지 확인.
4. 회색 테두리 박스를 클릭/탭한다 → 테두리가 노란색으로 바뀌고 "b)"가 YES로 바뀌는지 확인.
5. 마우스를 올리기만 하고 클릭하지 않았을 때 아무 것도 안 변하는지 확인 (호버 전용 피드백 없음 재확인).
6. 결과를 Claude에게 보고 (PASS / FAIL + 무엇이 안 됐는지).

## 결과 (2026-07-27, Godot 4.7.1, 에디터 실행)

| 확인 항목 | 결과 |
|---|---|
| a) Button.pressed가 클릭/탭에 도달 | PASS |
| b) `grab_focus()` 미사용 커스텀 하이라이트가 탭에 반응 | PASS |
| c) 클릭 없이 호버만으로는 반응 없음 | PASS (Button 기본 테마의 회색 호버 틴트는 관찰됐으나 장식적 효과일 뿐 우리 로직/라벨엔 영향 없음, 터치 기기엔 호버 자체가 없어 무관) |

**판정: PASS.** ADR-0011의 리스크 회피 설계(네이티브 Focus 시스템 비의존, 커스텀 enum 상태 기반 하이라이트)가 실제 Godot 4.7 빌드에서 예상대로 동작함을 확인. ADR-0011 Accepted로 전환됨 — `#20 UI/HUD` 스토리 착수 가능.
