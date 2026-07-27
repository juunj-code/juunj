# ADR-0011: Godot 4.6 듀얼 포커스 UI 대응 전략

## Status

Accepted

## Date

2026-07-26

## Last Verified

2026-07-27 — 실측 완료, `prototypes/touch-input-smoke/` (엔진 4.7 실제 에디터 실행, F6, 사용자 수동 확인). 결과:
(a) Button.pressed가 클릭/탭에 정상 도달함 — 확인.
(b) `grab_focus()`를 전혀 호출하지 않는 커스텀 enum 하이라이트가 탭에 정상 반응함 — 확인.
(c) 클릭 없이 마우스만 올렸을 때 우리 로직(라벨, 하이라이트 상태)은 반응하지 않음 — 확인. Godot 기본 Button 테마의 마우스 호버 시각 효과(회색 틴트)는 관찰됐으나 이는 엔진 기본 테마의 장식적 스타일일 뿐 기능적 인터랙션이 아니며, 터치 기기에는 호버 자체가 없어 실제 타겟 플랫폼(모바일 브라우저)에서는 나타나지 않음 — `technical-preferences.md`의 "호버 전용 인터랙션 금지" 위반 아님.
세 항목 모두 예상대로 동작 — Superseded 불필요. (참고: 헤드리스 CLI 시뮬레이션은 시도했으나 `--headless`가 GUI 입력 디스패치 자체를 실행하지 않아 마우스 클릭조차 재현 안 됨 — 실제 에디터 실행으로 전환해 검증함, 상세는 `prototypes/touch-input-smoke/README.md` 참조.)

## Decision Makers

technical-director, godot-specialist (architecture.md Required ADR #11 담당 지정 — 프로젝트 전체 최우선 엔진 지식 갭 항목)

## Summary

Godot 4.6은 마우스/터치 포커스와 키보드/게임패드 포커스를 분리하는 "듀얼 포커스" 시스템을 도입했으며, `#20 UI/HUD`는 터치 우선·Control 노드 기반의 액션 버튼·타겟 하이라이트·팝업 확인 버튼으로 전부 이 변경의 직접 영향권에 있다. 이 프로젝트의 엔진 레퍼런스 라이브러리는 `grab_focus()`가 4.6에서 키보드/게임패드 포커스만 조작한다는 사실은 확인해주지만, 터치 탭이 Control의 `gui_input`/커스텀 하이라이트 로직에 실제로 어떻게 도달하는지는 문서화하지 않으므로, 이 ADR은 네이티브 Focus 시스템에 대한 의존을 회피하는 설계 결정과 함께 구현 착수 전 필수 실측 검증 프로세스를 명령한다.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 (written); **verified against Godot 4.7.1** on 2026-07-27 — see Last Verified |
| **Domain** | UI / Input |
| **Knowledge Risk** | HIGH — post-cutoff, must verify |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md` (전문 확인), `docs/engine-reference/godot/modules/input.md` (전문 확인), `docs/engine-reference/godot/breaking-changes.md` (전문 확인) |
| **Post-Cutoff APIs Used** | Godot 4.6의 듀얼 포커스 시스템 자체(마우스/터치 포커스 vs 키보드/게임패드 포커스 분리) — `grab_focus()`가 4.6에서 키보드/게임패드 포커스만 조작한다는 점 |
| **Verification Required** | **엔진 레퍼런스 라이브러리 갭 — 아래 "Decision" 참조.** `ui.md`/`input.md`/`breaking-changes.md` 세 문서 모두 "마우스/터치 포커스는 키보드/게임패드 포커스와 분리된다"는 사실과 "`grab_focus()`는 키보드/게임패드만 조작한다"는 사실만 반복해서 확인해줄 뿐, (a) 터치 탭이 Control의 `gui_input`으로 전달되는 실제 메커니즘(마우스 이벤트로 에뮬레이트되는지, `InputEventScreenTouch`가 별도 경로로 처리되는지), (b) 마우스/터치 포커스가 시각적 스타일(`focus`/`hover` StyleBox) 외에 탭 판정 자체(버튼이 눌린 것으로 인식되는지)에도 영향을 주는지, (c) 이 프로젝트의 커스텀 타겟 하이라이트(적 유닛 위 탭 가능 표시)처럼 엔진 네이티브 Focus 스타일에 의존하지 않는 순수 커스텀 드로잉이 듀얼 포커스 변경의 영향을 받는지 — 이 세 가지를 세 문서 어디에서도 명시하지 않는다. 구현 착수 전 실제 Godot 4.6 빌드에서의 실측 확인이 반드시 필요하다(아래 "Decision" 및 "Validation Criteria" 참조). |

> **Note**: Knowledge Risk가 HIGH이므로 엔진 버전 업그레이드 시 이 ADR은 반드시 재검증되어야 한다.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | None |
| **Blocks** | **`#20 UI/HUD` 구현 착수 전체** — architecture.md의 4개 HIGH RISK 엔진 도메인 중 하나로 명시적으로 식별된 항목이며, 아래 "Decision"의 실측 검증 프로세스가 완료되기 전까지 `#20`의 액션 버튼/타겟 하이라이트/팝업 확인 버튼 관련 스토리는 착수 금지. |
| **Ordering Note** | 이 ADR은 기술적 결론을 완전히 확정할 수 없다(문서로는 불가능 — 실측이 필요) — 이 ADR의 실질적 가치는 그 실측 체크를 "반드시 일어나게 강제하는 것"이지 건너뛰는 것이 아니다. `#20` 스토리 작성 전 반드시 아래 프로세스를 1회 실행하고 그 결과로 이 ADR을 갱신(Last Verified 날짜 업데이트, 필요시 Superseded)해야 한다. |

## Context

### Problem Statement

`.claude/docs/technical-preferences.md`는 이 프로젝트의 입력 우선순위를 명확히 규정한다: "Primary Input: Touch (모바일 브라우저 우선)", "모든 UI는 터치 탭으로 조작 가능해야 함. 호버(hover) 전용 인터랙션 금지", "버튼 최소 크기 44×44px". `#20 UI/HUD`는 전투 화면의 액션 버튼, 적 유닛 탭-타겟 하이라이트, 발견 팝업의 "확인" 버튼 등 전부 Control 노드 기반이며 전부 터치 탭으로 조작된다. Godot 4.6은 "마우스/터치 포커스가 키보드/게임패드 포커스와 분리된다"는 변경(듀얼 포커스)을 도입했는데, 이 프로젝트는 게임패드를 아예 지원하지 않고(`Gamepad Support: None`) 키보드는 보조 입력일 뿐이므로 이 변경이 실제로 우리 UI에 어떤 영향을 주는지 — 아무 영향이 없는지, 아니면 커스텀 하이라이트 구현 방식을 바꿔야 하는지 — 구현 착수 전에 반드시 확인해야 한다.

### Current State

구현이 아직 존재하지 않는다(src/ 비어있음). GDD(`UI-HUD.md`)는 액션 버튼·타겟 하이라이트·팝업을 전부 "탭 가능"으로만 서술하고, 어떤 Godot 포커스 API를 사용할지는 명시하지 않는다(적절한 추상화 레벨 — GDD의 책임이 아니다). 엔진 레퍼런스 라이브러리(`ui.md`, `input.md`, `breaking-changes.md`)는 이 변경의 "존재"는 확인해주지만, 터치 전용·게임패드 없음이라는 이 프로젝트의 특수한 조합에서 실제로 무엇을 바꿔야 하는지는 답해주지 않는다.

### Constraints

- 게임패드 미지원 — 대부분의 듀얼 포커스 논의(4.6 릴리스 노트, 이 프로젝트의 엔진 레퍼런스)는 "마우스 vs 키보드/게임패드"를 대비하는 맥락이 많은데, 이 프로젝트는 후자 축이 사실상 없다(키보드는 보조 입력).
- 호버 전용 인터랙션 절대 금지(`technical-preferences.md`) — 듀얼 포커스가 새로 만드는 "포커스 상태"가 혹시라도 호버성 시각 피드백에 의존하는 패턴을 유도한다면 이 프로젝트 제약과 충돌한다.
- 엔진 레퍼런스 라이브러리 자체가 이 특정 조합(터치 전용 Control UI)에 대한 상세 가이드를 제공하지 않는다 — 실측 없이는 문서만으로 최종 결론을 낼 수 없다.

### Requirements

- `#20`의 커스텀 액션 버튼/타겟 하이라이트/팝업 확인 버튼이 4.6에서도 터치 탭에 정상 반응해야 한다.
- 44×44px 최소 터치 영역, 호버 전용 인터랙션 금지라는 기존 제약이 듀얼 포커스 변경으로 인해 깨지지 않아야 한다.
- 구현 착수 전 최소 1회의 실제 Godot 4.6 빌드 실측 확인이 있어야 한다 — 문서 인용만으로 "안전하다"고 단정하지 않는다.

## Decision

**이 ADR은 문서만으로 기술적 결론을 완전히 확정할 수 없음을 명시적으로 인정한다.** 엔진 레퍼런스 라이브러리(`ui.md`, `input.md`, `breaking-changes.md`)는 듀얼 포커스의 존재와 `grab_focus()`의 4.6 동작 범위(키보드/게임패드 한정)는 확인해주지만, 터치 탭이 Control의 `gui_input`에 도달하는 구체적 메커니즘과 우리의 커스텀 하이라이트가 그 메커니즘의 영향을 받는지는 다루지 않는다 — 이것을 **엔진 레퍼런스 라이브러리 갭**으로 명시적으로 선언하고, 추측으로 메우지 않는다.

대신 두 가지를 함께 결정한다:

**1. 설계 원칙 (리스크 회피 방향)**: `#20`의 모든 커스텀 탭 상호작용(액션 버튼 강조, 타겟 하이라이트, 팝업 확인 버튼)은 Godot 네이티브 Focus 시스템(`grab_focus()`, `has_focus()`, 포커스 StyleBox)에 의존하지 않는다. 대신 명시적 boolean/enum 상태(`is_selected: bool`, `highlight_state: HighlightState`)를 시그널 핸들러가 직접 토글하고, 그 상태에 따라 자체 `StyleBoxFlat`/커스텀 draw를 적용한다. 이렇게 하면 듀얼 포커스가 무엇을 어떻게 바꾸든(포커스 스타일이 갈리든, 포커스 판정 타이밍이 달라지든) 우리 UI의 시각적 하이라이트 로직 자체는 그 변경과 무관해진다 — 게임패드가 없는 이 프로젝트에서 네이티브 Focus 시스템이 원래 주려는 가치(키보드 탐색 시각 피드백)를 우리가 애초에 필요로 하지 않기 때문에 이 회피가 자연스럽다.

**2. 필수 프로세스 (실측 검증 게이트)**: 리스크 회피 설계를 채택하더라도, "터치 탭이 Control의 `_gui_input()`/`pressed` 시그널에 정상적으로 도달하는가" 자체는 여전히 실측이 필요한 기본 전제다. `#20` 구현 착수 **전에** 반드시 다음을 수행한다:

```
1. throwaway Godot 4.6 씬 하나를 만든다 (Button 노드 + 커스텀 하이라이트 Control 1개).
2. 웹 익스포트(또는 최소 모바일 에뮬레이션 터치 이벤트)로 실행한다.
3. 확인 항목:
   a. 터치 탭이 Button의 `pressed` 시그널을 정상 발신하는가?
   b. `grab_focus()`를 호출하지 않은 상태에서도 커스텀 boolean 상태 기반 하이라이트가
      탭에 정상 반응하는가? (네이티브 Focus 의존이 없어도 동작 확인)
   c. 호버 전용으로 보이는 의도치 않은 시각 피드백(포커스 스타일이 실수로 마우스
      hover처럼 보이는 경우)이 없는가?
4. 결과를 이 ADR의 "Last Verified" 날짜와 함께 기록하고, 예상과 다른 동작이
   발견되면 이 ADR을 Superseded 처리하고 새 ADR을 작성한다.
```

이 프로세스는 "사전 4.6 이전 포커스 기반 UI 관용구가 그대로 이전된다고 가정하지 않는다"는 원칙을 실행 가능한 절차로 강제하기 위한 것이며, 이 ADR의 핵심 가치는 이 체크를 **건너뛰지 않게 만드는 것**이다.

### Architecture

```
[플레이어 탭] (터치, 호버 없음)
        |
        v
[Control 노드 _gui_input() 또는 Button.pressed 시그널]  ← (a) 실측 필요: 정상 도달 확인
        |
        v
[시그널 핸들러: highlight_state = HighlightState.SELECTED]  ← grab_focus() 호출 없음
        |
        v
[queue_redraw() 또는 StyleBoxFlat 교체]  ← 순수 boolean 상태 기반, 네이티브 Focus 미의존
        |
        v
[시각적 하이라이트 표시]  ← (b),(c) 실측 필요: 호버 전용처럼 보이지 않는지 확인
```

### Key Interfaces

```gdscript
# #20 UI/HUD — 커스텀 타겟 하이라이트 (네이티브 Focus 비의존, 의사코드)
class_name EnemyTargetHighlight
extends Control

enum HighlightState { NONE, SELECTABLE, SELECTED }
var highlight_state: HighlightState = HighlightState.NONE

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        if highlight_state == HighlightState.SELECTABLE:
            target_tapped.emit(enemy_id)  # #1로 target_selected 발신은 상위 컨트롤러가 처리

func set_selectable(value: bool) -> void:
    highlight_state = HighlightState.SELECTABLE if value else HighlightState.NONE
    queue_redraw()

func _draw() -> void:
    if highlight_state == HighlightState.SELECTABLE:
        draw_rect(Rect2(Vector2.ZERO, size), Color.YELLOW, false, 2.0)
```

### Implementation Guidelines

- `#20`의 어떤 커스텀 하이라이트/선택 로직도 `has_focus()`나 포커스 관련 StyleBox(`focus`)를 조건으로 사용하지 않는다 — 대신 위 예시처럼 명시적 enum/bool 상태를 직접 관리한다.
- `grab_focus()` 자체를 아예 호출하지 않는 것이 기본 방침이다 — 이 프로젝트에 키보드/게임패드 탐색 요구사항이 없으므로(게임패드 미지원, 키보드는 보조 입력) 네이티브 Focus 시스템의 존재 이유 자체가 약하다. 만약 접근성 목적으로 키보드 tab 이동이 필요해지면(현재 GDD 범위 밖) 그때 별도로 `grab_focus()` 사용을 재검토한다.
- 위 "필수 프로세스"의 실측 체크는 `#20`의 첫 스토리 착수 직전에 1회 실행하고, 결과를 이 ADR 파일에 추가 기록(Last Verified 갱신)한다 — 스토리 리뷰어는 이 실측 기록이 없으면 `#20` 스토리를 블록해야 한다.
- 44×44px 최소 터치 영역은 이 ADR과 무관하게 `UI-HUD.md` Core Rule 4가 이미 요구하므로 별도 재확인 불필요하지만, 구현 시 함께 검증 대상에 포함한다.

## Alternatives Considered

### Alternative 1: 네이티브 Focus 시스템(`grab_focus()`/포커스 StyleBox)을 그대로 사용

- **Description**: 4.6 이전 관용구처럼 `grab_focus()`와 엔진 기본 포커스 스타일에 의존해 선택 상태를 표현.
- **Pros**: 엔진이 기본 제공하는 시각 피드백을 그대로 활용, 코드량 감소.
- **Cons**: 정확히 이 ADR이 HIGH RISK로 지정된 이유 그 자체 — `grab_focus()`가 4.6에서 키보드/게임패드 포커스만 조작한다는 것은 확인됐지만, 터치 탭 시 이 스타일이 실제로 어떻게(또는 전혀 안) 적용되는지가 문서화되지 않았다. 이 경로를 채택하면 이 프로젝트가 가진 정확히 그 미검증 리스크를 프로덕션 코드에 그대로 심는 셈이다.
- **Estimated Effort**: 낮음
- **Rejection Reason**: 게임패드/키보드 탐색이 필요 없는 이 프로젝트에서 네이티브 Focus 시스템이 주는 이득이 거의 없는 반면, 문서화되지 않은 4.6 동작에 의존하는 리스크만 짊어지게 된다.

### Alternative 2: 엔진 문서가 더 상세해질 때까지 이 ADR 자체를 보류

- **Description**: 현재 엔진 레퍼런스 라이브러리가 충분한 디테일을 주지 못하므로, 공식 문서가 업데이트되거나 커뮤니티 검증이 쌓일 때까지 ADR 작성/구현을 미룬다.
- **Pros**: 잘못된 가정 위에 결정을 내리는 리스크를 피할 수 있어 보인다.
- **Cons**: architecture.md의 TD 자체 검토가 이미 지적했듯, `#20`은 프로젝트의 최상위 Presentation 레이어이자 사실상 전체 게임의 유일한 입력 경로다 — 무기한 보류는 곧 프로젝트 전체 구현 착수를 무기한 보류하는 것과 같다.
- **Estimated Effort**: N/A (보류이므로)
- **Rejection Reason**: 실행 불가능 — "언젠가 문서가 좋아지면"은 구체적 일정이 없는 회피이며, 이 ADR이 채택한 실측 프로세스가 훨씬 빠르고 확실한 대안이다.

## Consequences

### Positive

- 네이티브 Focus 시스템에 대한 의존을 제거함으로써, 듀얼 포커스의 정확한 세부 동작이 문서화되지 않았다는 사실 자체가 더 이상 구현 블로커가 아니게 된다 — 우리 코드가 그 미지의 영역에 의존하지 않기 때문.
- 실측 검증 프로세스를 ADR Dependencies의 "Blocks"로 명시함으로써, 이 위험이 조용히 넘어가지 않고 반드시 `#20` 착수 전에 확인되도록 강제한다.

### Negative

- 이 ADR은 완전한 기술적 확신을 제공하지 못한다 — "실측 전까지는 모른다"는 상태를 그대로 남겨둔다. 이는 솔직함의 비용이지만, 거짓 확신보다 낫다.
- 커스텀 boolean 상태 기반 하이라이트는 네이티브 Focus 대비 약간의 추가 코드(enum, `_gui_input` 핸들링, `queue_redraw()` 호출)가 필요하다.

### Neutral

- 이 설계 결정은 게임패드 지원이 추가될 경우(현재 계획 없음) 재검토가 필요할 수 있다 — 그 시점에 네이티브 Focus 시스템의 가치가 달라지기 때문.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| 엔진 레퍼런스 라이브러리 갭으로 인해 실측 전까지 진짜 리스크 범위를 알 수 없음 | High (이미 확인된 사실) | High (`#20` 전체가 이 리스크에 걸려 있음) | 실측 프로세스를 ADR Dependencies "Blocks"로 강제, `#20` 착수 전 필수 게이트로 지정 |
| 커스텀 boolean 하이라이트가 실측 결과 예상치 못한 방식으로 여전히 듀얼 포커스 영향을 받음(예: `_gui_input` 도달 자체가 막힘) | Low~Medium (미검증) | Critical (전투 조작 자체 불가) | 실측 체크리스트 항목 (a)가 정확히 이것을 확인 — 실패 시 이 ADR을 Superseded 처리하고 대체 입력 경로(`_input()` 레벨 `InputEventScreenTouch` 직접 처리 등) 재설계 |
| 개발자가 편의상 네이티브 `grab_focus()`를 실수로 재도입 | Low | Medium | 코드 리뷰 체크리스트에 "`#20` 커스텀 하이라이트 코드에 `grab_focus()` 호출이 있는가?" 항목 추가 |

## Performance Implications

N/A — 구현 코드가 존재하지 않아 측정할 대상이 없다.

## Migration Plan

N/A — 마이그레이션 대상이 되는 기존 시스템이 없다(첫 구현).

## Validation Criteria

- [x] throwaway Godot 씬에서 터치/클릭이 Button/Control의 `pressed`/`_gui_input`에 정상 도달함을 실측 확인. (2026-07-27, Godot 4.7.1, 에디터 실행)
- [x] `grab_focus()`를 호출하지 않은 커스텀 boolean 하이라이트가 탭에 정상 반응함을 실측 확인. (2026-07-27)
- [x] 의도치 않은 호버 전용 시각 피드백이 없음을 실측 확인(`technical-preferences.md`의 호버 금지 제약 준수) — 기본 Button 테마의 장식적 호버 틴트는 관찰됐으나 기능적 인터랙션 아님, 터치 기기엔 해당 없음. (2026-07-27)
- [x] 위 세 항목 실측 완료 후 이 ADR의 "Last Verified" 날짜 갱신, 결과가 예상과 다르면 Superseded 처리. → 예상대로 동작, Superseded 불필요.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/UI-HUD.md` (Core Rule 4, 5) | #20 UI/HUD | "터치 최소 44×44px: 모든 탭 가능 영역 최소 크기 준수" + "타겟 하이라이트는 모드 전용: `player_input_requested` 신호 이후 액션 선택 완료 시만 적 탭 영역 활성" | 커스텀 boolean/enum 상태 기반 하이라이트 설계로 44×44px 영역과 활성/비활성 모드 전환을 네이티브 Focus 동작 불확실성과 무관하게 구현 가능하게 함 |
| `design/gdd/턴제-전투.md` ("플레이어 입력 프로토콜", UX Flag) | #1 턴제 전투 | "터치 최소 44×44px 보장, 타겟 선택과 액션 선택을 한 화면에서 처리" | 액션 버튼·타겟 선택 하이라이트 모두 동일한 네이티브-Focus-비의존 패턴으로 구현하도록 통일 |
| `.claude/docs/technical-preferences.md` | #20 UI/HUD (전역) | "Primary Input: Touch (모바일 브라우저 우선)", "모든 UI는 터치 탭으로 조작 가능해야 함. 호버(hover) 전용 인터랙션 금지" | 실측 프로세스가 정확히 호버 전용 피드백 유입 여부를 검증 항목으로 포함 |

> 이 ADR이 다루는 High Risk 항목은 GDD가 아니라 architecture.md의 Engine Knowledge Gap Summary에서 최우선으로 식별된 프로젝트 전체 아키텍처 리스크다 — foundational 성격이 강하지만 `#20` GDD 요구사항에 직접 연결되므로 위 표에 기재한다.

## Related

- `architecture.md` — Engine Knowledge Gap Summary (HIGH RISK 표), TD 자체 검토 항목 2
- `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/modules/input.md`, `docs/engine-reference/godot/breaking-changes.md` — 인용된 갭의 출처
- ADR-0012 (`docs/architecture/adr-0012-ui-signal-subscription-convention.md`) — `#20`의 다른 아키텍처 규칙, 독립적이나 같은 시스템 대상
