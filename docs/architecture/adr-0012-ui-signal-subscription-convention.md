# ADR-0012: UI 시그널 구독 컨벤션 (폴링 금지 공식화)

## Status

Proposed

## Date

2026-07-26

## Last Verified

2026-07-26

## Decision Makers

technical-director, godot-gdscript-specialist (architecture.md Required ADR #12 담당 지정)

## Summary

`UI-HUD.md`의 Core Rule 1("UI는 데이터를 소유하지 않는다: 신호 수신 시 즉시 갱신. 상태 캐시 없음")은 이미 GDD 레벨에서 강한 컨벤션이지만, 무엇이 구체적으로 금지되고 코드 리뷰가 무엇을 걸러야 하는지 아키텍처 규칙으로 격상된 적이 없다. 이 ADR은 "폴링 금지, 시그널로만 구독, Presentation 레이어 노드는 다른 시스템 소유 데이터의 로컬 캐시를 갖지 않는다"를 프로젝트 전역 금지 패턴으로 공식화하고, `#20`의 팝업 큐(자기 소유 데이터)가 이 규칙의 예외가 아니라 애초에 규칙이 다루는 대상이 아님을 명확히 한다.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | UI |
| **Knowledge Risk** | LOW — in training data |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` (LOW RISK 도메인 목록 — 시그널/노드 통신 자체는 4.3까지의 학습 데이터로 충분히 커버됨), `architecture.md` Architecture Principles #1·#2 |
| **Post-Cutoff APIs Used** | None — `Node.signal.connect(callable)` 문법(Godot 4.0+)만 사용, 이 프로젝트가 참조하는 4.4~4.6 변경 이력 어디에도 시그널 연결/구독 문법 자체의 변경이 없다 |
| **Verification Required** | None |

> **Note**: Knowledge Risk가 LOW이므로 재검증 우선순위는 낮다.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | `.claude/docs/technical-preferences.md`의 현재 비어있는 "Forbidden Patterns" 섹션을 채우는 근거 문서 — 이 ADR이 그 섹션에 옮겨 적힐 최초 항목이 되어야 한다. |
| **Blocks** | None |
| **Ordering Note** | 없음 — `#20` 구현 직전이면 충분(Feature/UI 레이어, architecture.md "구현 직전이면 충분" 분류). |

## Context

### Problem Statement

`UI-HUD.md`는 이미 "UI는 데이터를 소유하지 않는다"를 Core Rule 1로 선언하고, 자신이 구독하는 8개 시스템(`#1`,`#3`,`#4`,`#9`,`#13`,`#14`,`#15`,`#16`)의 신호 목록까지 표로 정리해두었다. 그러나 이것은 GDD의 서술적 규칙일 뿐, "정확히 어떤 코드 형태가 금지되는가"를 코드 리뷰가 기계적으로 판별할 수 있는 형태로 명세하지 않았다. 규칙이 모호하면 구현자가 "이 정도 캐시는 괜찮겠지"라는 판단을 각자 내리게 되고, 그 판단이 시스템마다 달라지면 `단일 진실 공급원`(architecture.md Architecture Principle #1)이 조용히 깨지는 지점이 여러 곳에서 생긴다.

### Current State

구현이 아직 존재하지 않는다(src/ 비어있음). `.claude/docs/technical-preferences.md`의 "Forbidden Patterns" 섹션은 현재 "[None configured yet — add as architectural decisions are made]"로 비어있다 — 이 ADR이 그것을 채우는 첫 항목이 되어야 한다.

### Constraints

- `#20`이 구독해야 하는 신호가 8개 시스템에 걸쳐 최소 9개 이상 존재한다(`UI-HUD.md` "신호 구독 목록" 참조) — 규칙이 단순하고 기계적으로 검증 가능해야 이 규모에서 일관되게 지켜진다.
- `#20`은 자신의 팝업 큐(Core Rule 3)라는 로컬 상태를 이미 합법적으로 갖고 있다 — "상태 캐시 없음" 규칙이 이 정당한 로컬 상태까지 금지하는 것으로 오독되면 안 된다.

### Requirements

- 코드 리뷰가 "이 코드가 Core Rule 1을 위반하는가"를 기계적으로(구체적인 안티패턴 코드 형태 매칭으로) 판별할 수 있어야 한다.
- 정당한 예외(팝업 큐)와 금지 대상(다른 시스템 데이터의 로컬 사본)의 경계가 명확히 문서화되어야 한다.

## Decision

**"폴링 금지, 시그널로만 구독, Presentation 레이어 노드는 다른 시스템이 소유한 데이터의 로컬 캐시를 갖지 않는다"**를 프로젝트 전역 FORBIDDEN PATTERN으로 공식화한다. 이 결정은 `.claude/docs/technical-preferences.md`의 "Forbidden Patterns" 섹션을 채우는 최초 항목이 된다.

**금지되는 구체적 코드 형태 (negative example)**:

```gdscript
# 금지 — _process()에서 다른 시스템 소유 데이터를 매 프레임 비교
var last_known_hp: int = -1

func _process(delta: float) -> void:
    if RunManager.party[0].current_hp != last_known_hp:
        last_known_hp = RunManager.party[0].current_hp
        update_hp_bar()
```

이 형태가 금지되는 이유는 두 가지다: (1) 매 프레임 다른 시스템의 데이터를 읽어 폴링하는 것 자체가 Architecture Principle #2("시그널 우선, 폴링 금지") 위반이고, (2) `last_known_hp`라는 변수가 `RunManager`가 이미 소유한 `current_hp`의 **로컬 사본**이며, 이 사본과 원본이 어긋날 수 있는 창(update 타이밍 차이)이 생겨 단일 진실 공급원 원칙(Architecture Principle #1)을 깬다.

**올바른 패턴 (positive example)**:

```gdscript
# 올바른 패턴 — _ready()에서 시그널 구독, 신호 수신 시에만 갱신, 캐시 없음
func _ready() -> void:
    RunManager.unit_hp_changed.connect(_on_unit_hp_changed)

func _on_unit_hp_changed(unit_id: String, new_hp: int) -> void:
    if unit_id != displayed_unit_id:
        return
    hp_bar.value = new_hp  # 비교 없이 즉시 반영, 이전 값을 저장하지 않음
```

**"상태 캐시 없음"의 정확한 범위**: 이 규칙이 금지하는 것은 **다른 시스템이 소유한 데이터의 캐시된 사본**이다. `#20`이 소유하는 팝업 큐(Core Rule 3, "한 번에 팝업 하나... 큐에 순서대로 저장 후 순차 표시")는 이 규칙의 예외가 아니라 **애초에 이 규칙이 다루는 대상이 아니다** — 팝업 큐는 다른 시스템(`#1`,`#3`,`#4`,`#9` 등)이 발신한 신호 데이터를 받아 "표시 순서"라는 `#20` 자신의 프레젠테이션 상태로 관리하는 것이지, 다른 시스템 소유 데이터의 사본이 아니다. 즉 "UI 컴포넌트는 자신만의 일시적 프레젠테이션 상태를 절대 가질 수 없다"는 뜻이 아니라, "다른 시스템이 이미 소유한 데이터를 UI가 별도로 복제해 들고 있으면 안 된다"는 뜻이다.

### Architecture

```
[다른 시스템 (#1/#3/#4/#9/#13/#14/#15/#16)]  ← 데이터 소유
        |
        | signal (예: unit_hp_changed, companion_unlocked_this_run)
        v
[#20 UI/HUD 노드]
        |
        |-- _ready(): connect(signal, handler)  ← 최초 1회만
        |
        |-- handler(data): 즉시 렌더링, 로컬 비교/캐시 없음
        |
        +-- (예외 아님, 별개 영역) 팝업 큐: #20 자신의 "표시 순서" 상태
                — 다른 시스템 데이터의 사본이 아니라 #20 고유 프레젠테이션 로직
```

### Key Interfaces

```gdscript
# #20 UI/HUD — 신호 구독 컨벤션의 표준 형태
extends Control

func _ready() -> void:
    RunManager.unit_hp_changed.connect(_on_unit_hp_changed)
    RunManager.unit_sp_changed.connect(_on_unit_sp_changed)
    CompanionUnlockController.companion_unlocked_this_run.connect(_on_companion_unlocked)
    # ... UI-HUD.md "신호 구독 목록"의 나머지 신호도 동일 패턴

func _on_unit_hp_changed(unit_id: String, new_hp: int) -> void:
    _find_hp_bar(unit_id).value = new_hp

# 팝업 큐 — #20 고유 상태 (이 ADR의 금지 대상이 아님)
var _popup_queue: Array[Dictionary] = []

func _on_companion_unlocked(id: String, name: String, description: String, portrait_path: String, color_accent: Color) -> void:
    _popup_queue.append({"type": "companion", "id": id, "name": name, "description": description, "portrait_path": portrait_path, "color_accent": color_accent})
    _try_show_next_popup()
```

### Implementation Guidelines

- `#20`의 모든 신호 구독은 `_ready()`에서 완료한다 — 런타임 중간에 조건부로 구독/해지하는 패턴은 이 ADR 범위 밖(필요 시 별도 판단).
- 코드 리뷰 체크리스트(신규): "`#20` 내부에 `_process()`/`_physics_process()`에서 다른 Autoload/시스템의 프로퍼티를 읽고 이전 값과 비교하는 코드가 있는가? → 있다면 시그널 구독으로 리팩터링 요구." / "`#20`이 다른 시스템 데이터를 그대로 복제해 저장하는 멤버 변수가 있는가(단, 화면에 표시할 최신값 그 자체를 담는 것은 허용 — '비교용 이전 값'이 문제)?"
- 팝업 큐처럼 `#20` 자신의 프레젠테이션 상태(어떤 팝업이 다음 차례인지, 현재 어떤 화면 상태인지)는 이 ADR이 금지하는 대상이 전혀 아니다 — 리뷰어가 이를 혼동해 정당한 UI 로컬 상태까지 차단하지 않도록 이 구분을 리뷰 체크리스트에 함께 기재한다.

## Alternatives Considered

### Alternative 1: 신호 구독과 폴링 혼용 허용(신호가 늦거나 놓칠 경우 대비 폴백)

- **Description**: 기본은 시그널 구독이되, `_process()`에서 주기적으로(예: 1초마다) 값을 재확인해 신호 누락을 보정.
- **Pros**: 신호 연결 버그가 있어도 UI가 결국 올바른 값으로 수렴한다는 안전망 제공.
- **Cons**: Godot 시그널은 기본 동기이며(architecture.md Data Flow "스레드 경계 없음 — Godot 시그널은 기본 동기") 같은 프레임 내 처리되므로 "신호 누락"이 발생할 시나리오 자체가 이 프로젝트 아키텍처에서 설계상 존재하지 않는다 — 존재하지 않는 문제에 대한 방어 코드는 순수 오버엔지니어링이며, 오히려 "폴링과 시그널 중 어느 쪽이 진실인지" 혼란만 추가한다.
- **Estimated Effort**: 낮음
- **Rejection Reason**: YAGNI — 이 프로젝트의 동기 시그널 아키텍처에서 폴백 폴링이 해결하는 실제 문제가 없다.

### Alternative 2: 캐시를 허용하되 "매 프레임 신호 소스와 대조 검증"만 금지

- **Description**: UI가 로컬 사본을 유지하되, 그 사본을 매 프레임 비교하는 것만 금지하고 사본 자체는 허용.
- **Pros**: 일부 최적화(예: 값이 실제로 바뀌었을 때만 다시 그리기)에 유용해 보일 수 있음.
- **Cons**: "사본은 있어도 되지만 비교는 안 된다"는 규칙은 실질적으로 무의미하다 — 사본이 존재하는 순간 그것이 최신 상태와 어긋날 잠재적 창이 생기고, 결국 어떤 형태로든 비교/동기화 로직이 재도입될 유인이 생긴다. 규칙 자체가 모호해 코드 리뷰가 판별하기 어렵다.
- **Estimated Effort**: 낮음
- **Rejection Reason**: 규칙의 명확성과 기계적 검증 가능성을 해친다 — "신호 수신 시 즉시 갱신, 캐시 없음"이라는 단순한 규칙이 리뷰 체크리스트로서 더 실용적이다.

## Consequences

### Positive

- 코드 리뷰가 "이 코드가 이 ADR을 위반하는가"를 negative example 형태와 직접 대조해 기계적으로 판별 가능해진다.
- `.claude/docs/technical-preferences.md`의 비어있는 "Forbidden Patterns" 섹션에 첫 항목이 채워져, 향후 다른 시스템도 참조할 수 있는 선례가 생긴다.
- 팝업 큐 예외의 경계를 명시함으로써, 향후 리뷰어가 정당한 UI 로컬 상태(예: 다른 화면 전환 애니메이션 상태)까지 잘못 차단하는 과잉 적용을 방지한다.

### Negative

- 없음으로 판단 — 이 ADR은 이미 GDD 레벨에서 사실상 결정된 컨벤션을 공식화하는 것일 뿐, 새로운 제약을 추가하지 않는다.

### Neutral

- 이 규칙은 `#20`에 국한되지 않고 향후 `#21 오디오`, `#22 내러티브` 등 다른 Presentation 레이어 시스템에도 동일하게 적용될 것으로 예상된다(architecture.md System Layer Map 참조) — 그 시점에 이 ADR을 참조로 재사용 가능.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| 구현자가 "성능 최적화" 명목으로 폴링+비교 패턴을 재도입 | Low | Medium (단일 진실 공급원 위반, 디버깅 난이도 증가) | 코드 리뷰 체크리스트에 negative example과 직접 대조하는 항목 추가 |
| 팝업 큐 예외를 오독해 정당한 UI 로컬 상태(화면 전환 상태 등)까지 과도하게 금지 | Low | Low (개발 마찰, 기능 결함 아님) | 이 ADR의 "정확한 범위" 절을 코드 리뷰 체크리스트/온보딩 문서에 함께 링크 |

## Performance Implications

N/A — 구현 코드가 존재하지 않아 측정할 대상이 없다.

## Migration Plan

N/A — 마이그레이션 대상이 되는 기존 시스템이 없다(첫 구현).

## Validation Criteria

- [ ] `#20` 구현 코드 전체에서 다른 시스템 소유 데이터를 대상으로 한 `_process()`/`_physics_process()` 폴링 비교 코드가 없다(grep/코드 리뷰로 확인).
- [ ] `#20`의 모든 신호 구독이 `_ready()`에서 1회 완료된다.
- [ ] 팝업 큐 외에 다른 시스템 데이터의 "이전 값 비교용" 사본 변수가 존재하지 않는다.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/UI-HUD.md` (Core Rule 1) | #20 UI/HUD | "UI는 데이터를 소유하지 않는다: 신호 수신 시 즉시 갱신. 상태 캐시 없음" | negative/positive 코드 예시로 이 규칙을 기계적으로 검증 가능한 형태로 구체화 |
| `design/gdd/UI-HUD.md` (Core Rule 3) | #20 UI/HUD | "한 번에 팝업 하나... 팝업이 이미 표시된 상태에서 다른 팝업 트리거가 오면 큐에 순서대로 저장 후 순차 표시" | 팝업 큐가 "상태 캐시 없음" 규칙의 예외가 아니라 규칙이 다루는 대상 자체가 아님을 명시해, 두 Core Rule 사이의 잠재적 오해를 해소 |
| `design/gdd/UI-HUD.md` ("신호 구독 목록") | #20 UI/HUD | #1,#3,#4,#9,#13,#14,#15,#16으로부터 총 9개 이상 신호 구독 목록 | 이 모든 구독이 `_ready()`에서 1회 연결되는 표준 관용구를 확립 |

## Related

- ADR-0010 (`docs/architecture/adr-0010-await-coroutine-pattern.md`) — 이 ADR은 "UI가 게임 로직 상태 변화를 구독하는 방향"을, ADR-0010은 "게임 로직이 UI 입력을 기다리는 반대 방향"을 다룬다. 두 ADR 모두 시그널 우선·폴링 금지라는 동일 원칙(architecture.md Architecture Principle #2)의 서로 다른 절반이다.
- `.claude/docs/technical-preferences.md` — "Forbidden Patterns" 섹션(현재 비어있음, 이 ADR이 최초 채움 대상)
- `design/gdd/UI-HUD.md` — Core Rule 1, 3, "신호 구독 목록"
