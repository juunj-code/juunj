# ADR-0010: GDScript await/코루틴 패턴 표준화

## Status

Proposed

## Date

2026-07-26

## Last Verified

2026-07-26

## Decision Makers

technical-director, godot-gdscript-specialist (architecture.md Required ADR #10 담당 지정)

## Summary

`#1 턴제 전투`의 플레이어 턴 입력 대기와 `#3 동료 해금`의 발견 팝업 확인 대기는 둘 다 "무기한, 타임아웃 없이 플레이어 탭을 기다리는" 동일한 형태의 코루틴 일시정지가 필요하다. 이 ADR은 `await custom_signal`을 프로젝트 전체에서 플레이어 입력을 기다리는 유일한 승인된 패턴으로 표준화하고, 폴링 루프·`yield()`(구식 메커니즘)·"만약을 위한" 타임아웃 래핑을 명시적으로 금지하며, await 재개 직후 노드 생존을 확인하는 방어 가드를 필수 관용구로 못박는다.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Scripting |
| **Knowledge Risk** | LOW — in training data |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` (크로스컷팅 Deprecated API 워치리스트: `yield()` → `await`), `architecture.md` "크로스컷팅 Deprecated API 워치리스트" |
| **Post-Cutoff APIs Used** | None — `signal.connect(callable)` 문법과 커스텀 시그널에 대한 `await`는 GDScript 2.0(Godot 4.0)부터 안정적으로 존재하는 기능이며, 이 프로젝트가 참조하는 4.4~4.6 post-cutoff 변경 이력(`breaking-changes.md`) 어디에도 `await`/시그널 연결 문법 자체의 변경 사항이 없다 |
| **Verification Required** | None — 유일한 잠재 리스크는 구식 `yield()` 메커니즘과의 혼동이며, 이 프로젝트의 GDD(`턴제-전투.md`, `동료-해금.md`)는 이미 `await` 문법만 사용하고 있어 실측 검증 대상 자체가 없다 |

> **Note**: Knowledge Risk가 LOW이므로 엔진 버전 업그레이드 시 재검증 우선순위는 낮다. 다만 GDScript 언어 문법 변경(예: 코루틴 관련 신규 데코레이터)이 향후 버전에서 발생하면 재확인 필요.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | 없음 — 이 ADR 자체가 다른 ADR의 전제조건이 되지는 않는다. 다만 `.claude/docs/technical-preferences.md`의 "Forbidden Patterns" 섹션에 "폴링 루프로 입력 대기 구현 금지"를 채워 넣는 근거 문서 역할을 한다. |
| **Blocks** | None — Feature/UI 레이어 ADR로 해당 시스템(`#1`, `#3`) 구현 직전이면 충분(architecture.md "Feature/UI 레이어" 분류 참조), 코딩 시작 전체를 막는 Foundation 레이어 ADR이 아니다. |
| **Ordering Note** | `#1 턴제 전투`와 `#3 동료 해금` 구현 착수 전에 Accepted 상태여야 한다. `#20 UI/HUD`가 `emit_signal()`로 신호를 발신하는 쪽이므로, `#20` 구현자도 이 ADR의 신호 명명 규칙을 따라야 한다. |

## Context

### Problem Statement

턴제 게임은 본질적으로 "플레이어가 답할 때까지 기다린다"는 대기가 반복적으로 발생한다. `턴제-전투.md`의 턴 루프는 `await action_selected`, `await target_selected`를, `동료-해금.md`의 발견 흐름은 `await popup_confirmed`를 요구하며, 두 GDD 모두 "타임아웃 없음(Core Rule 1 / 무기한 대기)"을 명시적 요구사항으로 못박고 있다. 이 대기를 매 프레임 bool 플래그를 확인하는 `_process()` 폴링으로 구현하면 불필요한 CPU 사이클을 소모하고 코드 구조가 산만해지며, `동료-해금.md` Core Rule 3이 직접 지적하듯 "수동 토글 bool" 방식은 예외/조기 반환 경로에서 플래그가 되돌아가지 않아 입력이 영구히 잠기는 버그 클래스를 만든다. 이 패턴이 시스템마다 다르게(어떤 곳은 폴링, 어떤 곳은 시그널) 구현되면 유지보수 시 코드베이스 전체에서 "이 대기는 어떻게 풀리는가"를 매번 다시 추적해야 한다.

### Current State

구현이 아직 존재하지 않는다(src/ 비어있음). GDD 레벨에서는 이미 `await custom_signal` 문법이 채택되어 있으나(`턴제-전투.md`의 "구현 패턴" 리비전, `동료-해금.md` Core Rule 3), 이것이 프로젝트 전역 아키텍처 규칙으로 격상되지 않아 향후 다른 시스템(예: `#20`이 직접 관여하는 다른 확인 다이얼로그) 구현자가 매번 새로 이 결정을 내려야 하는 상태다.

### Constraints

- GDScript 2.0(Godot 4.0+)의 `await signal_name` 문법만 사용 가능 — 구식 `yield(self, "signal_name")`은 4.x에서 완전히 제거됨.
- 턴제 장르 요구사항상 플레이어 입력 대기에 타임아웃을 걸 수 없다(광고 SDK 콜백 같은 "외부 시스템이 응답하지 않을 수도 있는" 경우와 근본적으로 다른 성격).
- `#3 동료 해금`이 이미 지적한 대로, await 도중 씬 전환/노드 제거가 레이스될 가능성을 코드 레벨에서 방어해야 한다.

### Requirements

- 플레이어 입력을 기다리는 모든 코루틴은 동일한 문법·명명 관용구를 따라야 한다.
- await 재개 직후 노드가 여전히 씬 트리에 있는지 확인하는 가드가 모든 사용처에 일관되게 적용되어야 한다.
- 코드 리뷰 체크리스트가 이 패턴 위반(폴링, `yield()`, 불필요한 타임아웃)을 기계적으로 걸러낼 수 있을 만큼 규칙이 구체적이어야 한다.

## Decision

프로젝트 전역에서 게임 로직이 플레이어 입력을 기다려야 할 때는 **`await custom_signal` 패턴만** 사용한다. 다음을 명시적으로 금지한다:

1. **폴링 루프**: `_process(delta)`에서 매 프레임 bool 플래그(`is_action_selected` 등)를 확인하는 방식.
2. **`yield()`**: Godot 3.x의 구식 코루틴 메커니즘 — 4.x에서 존재하지 않으며, 문서/주석에서도 언급 금지(신규 개발자 혼동 방지).
3. **수동 bool 토글로 확인 상태 추적**: `동료-해금.md` Core Rule 3이 지적한 그대로 — 예외/조기 반환 경로에서 리셋되지 않아 입력이 영구히 잠기는 버그 클래스를 만든다.

표준 관용구:

- 대기 대상이 되는 노드/Autoload에 `signal action_selected(action_data: Dictionary)` 같은 시그널을 선언한다.
- 코루틴 함수는 `var result: Dictionary = await action_selected`로 일시정지한다.
- 입력을 발생시키는 UI 레이어(`#20`)는 플레이어가 탭한 시점에 `emit_signal("action_selected", data)`(또는 4.x 문법 `action_selected.emit(data)`)를 호출한다.
- await가 재개된 직후, 노드 상태를 건드리기 전에 **반드시** `if not is_inside_tree(): return`(또는 동등한 가드)을 확인한다 — 씬 전환이 대기 도중 발생했을 경우 해제된 노드에 접근하는 null-reference 크래시를 방지하기 위한 표준 방어 패턴이다.

### Architecture

```
[코루틴 소유 시스템 (#1 / #3)]              [UI 레이어 (#20)]
        |                                          |
        | signal action_selected(data)             |
        | (선언, 대기 시작)                          |
        |                                          |
        |--- await action_selected --------------->| (플레이어 탭 대기, 논블로킹)
        |     (실행 일시정지, 타임아웃 없음)          |
        |                                          |
        |                              플레이어 탭
        |                                          |
        |<----- action_selected.emit(data) --------|
        |                                          |
  [재개 직후 가드]
  if not is_inside_tree(): return
        |
  [정상 로직 계속]
```

### Key Interfaces

```gdscript
# #1 턴제 전투 — 턴 루프 코루틴 (의사코드)
signal action_selected(action_data: Dictionary)
signal target_selected(target_id: String)

func _process_player_turn(unit: CompanionRunState) -> void:
    player_input_requested.emit(unit.id)
    var action_data: Dictionary = await action_selected
    if not is_inside_tree():
        return  # 씬 전환이 대기 중 발생 — 이후 로직 실행 금지
    var target_id: String = await target_selected
    if not is_inside_tree():
        return
    _execute_action(unit, action_data, target_id)

# #20 UI/HUD — 액션 버튼 탭 핸들러
func _on_skill_button_pressed(skill_data: Dictionary) -> void:
    combat_controller.action_selected.emit(skill_data)
```

```gdscript
# #3 동료 해금 — 팝업 확인 대기 (의사코드)
signal popup_confirmed

func _on_companion_discovered(companion_id: String) -> void:
    # ... #10 조회, discovered_companions 추가 ...
    companion_unlocked_this_run.emit(id, name, description, portrait_path, color_accent)
    await popup_confirmed
    if not is_inside_tree():
        return
    # 던전 탐색 재개 로직
```

### Implementation Guidelines

- 시그널 이름은 프로젝트 명명 규칙(snake_case 과거형, `.claude/docs/technical-preferences.md`)을 따른다: `action_selected`, `target_selected`, `popup_confirmed`.
- `await` 대상 시그널은 코루틴을 소유하는 시스템(Autoload 또는 해당 노드)이 선언하고, UI 레이어는 오직 `emit()`만 호출한다 — 역방향(UI가 시그널을 선언하고 게임 로직이 구독)은 다른 문제(ADR-0012의 신호 구독 컨벤션)이며 이 ADR의 범위가 아니다.
- `is_inside_tree()` 가드는 await 직후 첫 줄에 위치해야 한다 — 재개된 콜백 안에서 다른 노드 상태를 읽거나 쓰기 전에 항상 먼저 확인.
- 코드 리뷰 체크리스트 항목(신규): "`_process()`/`_physics_process()` 안에 입력 대기용 bool 플래그 확인 코드가 있는가? → 있다면 `await custom_signal`로 리팩터링 요구", "`yield(` 문자열이 grep에 걸리는가? → 즉시 차단."

## Alternatives Considered

### Alternative 1: `SignalAwaiter` 스타일 헬퍼 클래스

- **Description**: 시그널 대기를 감싸는 별도 유틸리티 클래스(`SignalAwaiter.wait_for(node, "signal_name")` 같은 형태)를 만들어 재사용.
- **Pros**: 이론적으로 대기 로직을 한 곳에 집중.
- **Cons**: Godot 4.0부터 `await signal_name`이 이미 네이티브로 동일한 일을 하므로 래퍼가 추가하는 가치가 없다 — 오히려 간접 계층 하나를 더 얹어 디버깅(스택 트레이스 추적)을 어렵게 만든다.
- **Estimated Effort**: 낮음 (그러나 불필요)
- **Rejection Reason**: YAGNI — 네이티브 기능이 이미 요구사항을 충족하므로 래퍼 클래스는 순수 오버엔지니어링이다.

### Alternative 2: 모든 `await`에 "만약을 위한" 타임아웃 래핑

- **Description**: `#18 광고 통합`의 콜백 타임아웃 패턴을 그대로 가져와 모든 입력 대기에도 `SceneTreeTimer` 기반 타임아웃을 건다.
- **Pros**: "영원히 멈추는" 상황을 이론적으로 방지.
- **Cons**: 턴제 장르의 핵심 요구사항("입력 없이 진행 없음", `턴제-전투.md` Core Rule 1)과 정면으로 모순된다. `#18`의 타임아웃은 외부 JS SDK가 응답하지 않을 수도 있다는 신뢰할 수 없는 외부 시스템에 대한 방어이지, 플레이어 입력에 대한 방어가 아니다 — 플레이어 입력은 정의상 "플레이어가 응답할 때까지"이며 응답 자체가 실패 조건이 아니다.
- **Estimated Effort**: 낮음
- **Rejection Reason**: 장르 요구사항 위반. `#18`과 이 ADR의 대기는 근본적으로 다른 종류의 불확실성(외부 SDK 신뢰성 vs. 플레이어 의사결정 시간)을 다루므로 같은 해법을 적용할 수 없다.

## Consequences

### Positive

- 프로젝트 전체에서 "입력 대기"가 단 하나의 패턴으로 통일되어, 코드 리뷰어가 편차를 즉시 발견할 수 있다.
- `is_inside_tree()` 가드를 표준 관용구로 못박음으로써 `#3`이 이미 예견한 씬 전환 레이스 버그 클래스를 사전에 차단한다.
- 폴링 제거로 불필요한 `_process()` 오버헤드가 없다(다만 턴제 게임 규모상 성능 임팩트 자체는 미미할 것으로 예상 — Performance Implications 참조).

### Negative

- `await` 코루틴은 콜스택이 여러 프레임에 걸쳐 있어, 디버거에서 실행 흐름을 추적하기가 동기 코드보다 약간 더 어렵다(GDScript 자체의 일반적 트레이드오프이며 이 ADR이 만드는 문제는 아니다).

### Neutral

- 이 패턴은 이미 GDD 레벨(`턴제-전투.md`, `동료-해금.md`)에서 사실상 결정돼 있었다 — 이 ADR은 그 결정을 프로젝트 전역 아키텍처 규칙으로 격상시키고 코드 리뷰 체크리스트에 반영하는 것이 실질 변화다.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| 구현자가 습관적으로 `yield()` 예제를 참고(구버전 Godot 3.x 튜토리얼 등)해 잘못된 문법 사용 | Low | Medium (컴파일 에러로 즉시 발견되므로 실제 런타임 리스크는 낮음) | 코드 리뷰 체크리스트에 `yield(` grep 확인 항목 추가 |
| `is_inside_tree()` 가드 누락으로 씬 전환 레이스 시 null-reference 크래시 | Medium | High (플레이어 대면 크래시) | 모든 `await custom_signal` 사용처에 가드를 표준 관용구로 강제, 코드 리뷰에서 확인 |
| 새 시스템(#20의 다른 확인 다이얼로그 등)이 이 ADR을 모르고 폴링으로 재발명 | Low | Medium | `.claude/docs/technical-preferences.md` Forbidden Patterns 섹션에 이 ADR을 링크해 발견 가능성 확보 |

## Performance Implications

N/A — 구현 코드가 존재하지 않아 측정할 대상이 없다. 다만 정성적으로: `await` 기반 대기는 폴링 대비 CPU 사이클을 소모하지 않으므로 성능 저하 우려는 없다.

## Migration Plan

N/A — 마이그레이션 대상이 되는 기존 시스템이 없다(첫 구현).

## Validation Criteria

- [ ] `#1`, `#3` 구현 코드에 `yield(` 문자열이 존재하지 않는다(grep으로 확인 가능).
- [ ] `#1`, `#3`의 입력 대기 코루틴 중 `_process()`/`_physics_process()` 안에서 bool 플래그를 확인하는 코드가 없다.
- [ ] `await custom_signal` 사용처마다 재개 직후 `is_inside_tree()` 가드가 존재한다(GUT 테스트로 씬 전환 중 await 재개 시나리오를 시뮬레이션해 크래시 없음을 확인).

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/턴제-전투.md` (Core Rule 1, "구현 패턴" 리비전) | #1 턴제 전투 | "입력 없이 진행 없음... 타임아웃 없음(턴제)" + "'입력 대기' 단계는... 실제 터치 입력까지 무기한 대기해야 하므로, 커스텀 시그널(`await action_selected`, `await target_selected`)에 대한 `await`로 구현" | `await custom_signal`을 프로젝트 표준으로 확정하고, 타임아웃을 명시적으로 금지되는 안티패턴으로 못박음 |
| `design/gdd/동료-해금.md` (Core Rule 3) | #3 동료 해금 | "이 시스템의 발견 흐름은 `await popup_confirmed` 형태로 플레이어 탭 시그널을 기다린다 — 수동 토글 bool이 아니라 시그널 `await`로 구현해야 예외/조기 반환 경로에서 입력 잠금이 풀리지 않는 버그를 피한다" | 수동 bool 토글을 명시적 금지 패턴으로 확정하고, `is_inside_tree()` 가드를 씬 전환 레이스 방어책으로 표준화 |

## Related

- ADR-0012 (`docs/architecture/adr-0012-ui-signal-subscription-convention.md`) — 이 ADR은 "게임 로직이 UI 입력을 기다리는 방향"을, ADR-0012는 "UI가 게임 로직 상태 변화를 구독하는 반대 방향"을 다룬다. 두 ADR 모두 시그널 우선·폴링 금지라는 동일 원칙(`architecture.md` Architecture Principles #2)의 서로 다른 절반이다.
- `design/gdd/턴제-전투.md` — "구현 패턴" 리비전, Core Rule 1
- `design/gdd/동료-해금.md` — 발견 흐름, Core Rule 3
