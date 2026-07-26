# 바람의 탑 (Wind Tower) — Master Architecture

## Document Status
- Version: 1.0
- Last Updated: 2026-07-26
- Engine: Godot 4.6 (web export, HTML5)
- GDDs Covered: 전체 18개 MVP GDD (`design/gdd/systems-index.md` 참조), 23개 시스템 전체 레이어 배치
- ADRs Referenced: 없음 — 12개 Required ADR 식별, 아직 미작성 (아래 Required ADRs 참조)
- Technical Director Sign-Off (TD-ARCHITECTURE): 2026-07-26 — **APPROVED WITH CONDITIONS** (아래 TD 자체 검토 참조)
- Lead Programmer Feasibility (LP-FEASIBILITY): skipped — Lean mode (`production/review-mode.txt`)

### Technical Director 자체 검토 (TD-ARCHITECTURE)

`.claude/docs/director-gates.md`의 TD-ARCHITECTURE 4개 기준 적용:

1. **모든 TR이 아키텍처 결정으로 커버되는가?** — 60개 TR 전부가 12개 Required ADR 중 하나로 매핑됨(Phase 5/6). 단, 이 ADR들은 아직 **작성되지 않았고 Accepted 상태가 아님** — "계획은 완전하나 실행은 아직" 상태.
2. **모든 HIGH RISK 엔진 도메인이 명시적으로 다뤄지는가?** — ✅ 4개 HIGH RISK(IndexedDB 동기화/JS 브릿지/COOP-COEP/듀얼 포커스) 전부 Required ADR #1,#3,#4,#11로 명시적 매핑됨.
3. **API 경계가 깔끔하고 구현 가능한가?** — ✅ 6개 핵심 경계 정의, `#18`의 Callable 결합도 문제도 Phase 4에서 명확화됨.
4. **Foundation 레이어 ADR 갭이 구현 전에 해소되는가?** — ❌ **아직 미해소** — Foundation 레이어 Required ADR 7개(#1,#2,#3,#4,#5,#6,#7) 중 작성/Accepted된 것이 0개. `docs/CLAUDE.md`의 ADR 라이프사이클 규칙("Proposed 상태의 ADR을 참조하는 스토리는 자동 블록")에 따라, 코딩 시작 전 이 7개는 반드시 작성→Accepted 상태여야 함.

**결론**: 아키텍처 청사진 자체는 기술적으로 견고하나(1-3 통과), 4번 조건이 아직 열려 있어 **APPROVED WITH CONDITIONS** — 조건: 아래 "Run These ADRs Next"의 Foundation 레이어 ADR이 Accepted 상태가 되기 전까지 구현 착수 금지.

## Engine Knowledge Gap Summary

**Engine**: Godot 4.6 (Jan 2026) · **LLM 학습 데이터 커버리지**: ~4.3까지 신뢰 가능 · **Post-cutoff**: 4.4(MEDIUM), 4.5(HIGH), 4.6(HIGH)

### HIGH RISK — 아래 항목은 구현 전 반드시 엔진 문서 재확인 + ADR 필요

| 도메인/시스템 | 위험 내용 |
|---|---|
| Input/UI (#20 UI/HUD) | 4.6의 듀얼 포커스 시스템 — 마우스/터치 포커스와 키보드/게임패드 포커스가 분리됨. 터치 우선 + 커스텀 Control 기반 HUD라 직접 영향권 |
| #18 광고 통합 | `JavaScriptBridge.create_callback()`/`.eval()`/`.get_interface("window")` — 4.4~4.6 사이 API 변경 여부 미검증 |
| #17 로컬 세이브 | HTML5 `user://` → IndexedDB 동기화 — `FileAccess.close()`가 4.6에서 실제로 durable flush를 보장하는지 미검증 |
| #19 씬 관리 | 스레드 백그라운드 로딩 — Threads 익스포트 변형은 호스트(itch.io)의 COOP/COEP 헤더 필요, 미해결 |

### MEDIUM RISK — 주요 API만 확인
- Animation: 4.6 IK 전면 개편 — 이 프로젝트는 3D 스켈레톤 없음, 영향 낮음
- Rendering: D3D12 기본값(Windows), glow 재정렬 — 에디터/개발머신 이슈, 2D 웹 게임플레이엔 비영향

### LOW RISK — 학습 데이터 신뢰 가능
Audio, Physics(2D 전용이라 Jolt 3D 기본값 변경 무관), Navigation, Networking — 18개 GDD 어디에서도 이 도메인들의 post-cutoff 변경에 영향받는 사용 패턴 없음

### 크로스컷팅 Deprecated API 워치리스트
`connect(sig, obj, "method")` → `signal.connect(callable)` / `yield()` → `await` / 얕은 `duplicate()` → 중첩 리소스는 `duplicate_deep()`(4.5+) 필요 여부 검증 / `instance()` → `instantiate()` / `Array.sort()`/`sort_custom()` 불안정 정렬 (이미 `#6`/`#7`에서 실제로 발견되어 수정된 이력 있음)

## System Layer Map

표준 5-레이어 스택(`PRESENTATION → FEATURE → CORE → FOUNDATION → PLATFORM`)에 23개 시스템 배치. **주의**: `systems-index.md`의 자체 레이어 라벨(Foundation/Core/Feature/Presentation/Polish)은 "설계 의존성 순서" 축이고, 아래는 "엔진 통합 깊이" 축 — 이름은 같지만 다른 분류다.

```
┌─────────────────────────────────────────────────────────────┐
│ PRESENTATION  #20 UI/HUD · #21 오디오 · #22 동료 내러티브    │
├─────────────────────────────────────────────────────────────┤
│ FEATURE       #1 턴제 전투 · #2 랜덤 던전 · #3 동료 해금 ·   │
│               #4 장비 · #7 적 AI · #8 시너지 ·               │
│               #9 히든 트리거 · #15 파티 구성 · #16 런 결과   │
├─────────────────────────────────────────────────────────────┤
│ CORE          #6 전투 공식 · #12 상태이상                    │
├─────────────────────────────────────────────────────────────┤
│ FOUNDATION    #10 동료 데이터 · #11 적 데이터 · #13 런 상태  │
│               관리 · #14 영구 진행 · #17 로컬 세이브 ·       │
│               #19 씬 관리 · #5 클라우드 세이브(예정)         │
├─────────────────────────────────────────────────────────────┤
│ PLATFORM      #18 광고 통합                                  │
└─────────────────────────────────────────────────────────────┘
```

`#23 설정`(미설계)은 데이터/영속성 부분이 FOUNDATION, 설정 화면은 PRESENTATION(`#20` 소관)으로 갈릴 가능성 — GDD 작성 시 확정.

### GDD 레이어 vs 아키텍처 레이어 — 갈라지는 4곳

| 시스템 | GDD 레이어 | 아키텍처 레이어 | 이유 |
|---|---|---|---|
| #13 런 상태 관리 | Core | **Foundation** | Autoload 싱글톤 + 5개 시그널로 9개 이상 시스템에 이벤트 버스 역할 — FOUNDATION 정의("engine integration, event bus")에 부합 |
| #14 영구 진행 | Core | **Foundation** | 전투/입력 로직이 아니라 `#17` 위에 얹힌 순수 저장 오케스트레이션 |
| #7 적 AI | Core | **Feature** | 순수 의사결정 로직(gameplay AI) — 전투 수식 자체가 아니라 `#6`의 소비자 |
| #18 광고 통합 | Polish | **Platform** | 게임플레이 시스템이 아니라 브라우저 JS SDK와의 직접 경계 — 프로젝트에서 가장 "플랫폼 표면"에 가까운 코드 |

**엔진 인지 체크 (Core/Foundation)**: `#19 씬 관리`(스레드 로딩, COOP/COEP 미해결)와 `#17 로컬 세이브`(IndexedDB 동기화 미검증)가 이 두 레이어에서 유일한 HIGH RISK 시스템. `#13`/`#14`/`#10`/`#11`은 순수 GDScript 상태/데이터 컨테이너라 엔진 리스크 없음. `#6`/`#12`는 순수 수식/로직이라 마찬가지로 엔진 리스크 없음.

## Module Ownership

### FOUNDATION

| 시스템 | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| #10 동료 데이터 | CompanionData/SkillData 스키마, 레지스트리 | `get(id)`, `get_all_ids()`, 공유 정렬/로드 유틸 | (없음 — 진짜 최하단) | `ResourceLoader`, `DirAccess`(오름차순 정렬), `Resource` |
| #11 적 데이터 | EnemyData 스키마, 레지스트리 | `get(id)`, 동일 공유 유틸 재사용 | #10의 공유 로드 유틸 | 동일 |
| #17 로컬 세이브 | 저장 파일 스키마, 원자적 쓰기 상태머신, 재시도/백오프 | `save_section()`, `load_section()` | (없음) | `FileAccess`(bool 리턴), `user://`(⚠️HIGH — IndexedDB 동기화 미검증) |
| #19 씬 관리 | 전환 상태머신, PackedScene 프리로드 캐시, Fade/Flash | `go_to(scene_id, transition, [color])` | (없음) | `ResourceLoader.load_threaded_*`, `Tween`, `_process` 델타 누적(⚠️HIGH — COOP/COEP) |
| #13 런 상태 관리 | state/층/방/파티/적 런타임 전체 | `start_run()`,`end_run()`,`advance_floor()`,`advance_room()`, 프로퍼티 게터, 5개 시그널 | #19(전환), #10(초기 스탯), #6(승패 판정 결과) | Autoload, property getter 문법, typed Array |
| #14 영구 진행 | 해금 동료 목록, 최고 층수 | `commit_run_end()`,`get_unlocked_companions()`, 3개 시그널 | #17(저장 2회/커밋), #10(id 검증) | Autoload |
| #5 클라우드 세이브(예정) | — | — | #17 | 미설계 |

### CORE

| 시스템 | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| #6 전투 공식 | (없음 — 순수 함수) | 5개 공식(기본뎀·스킬뎀·턴순서·SP·승패) | 호출자가 넘긴 스탯 값만 | `floori()`+엡실론, `sort_custom` 미사용(2차 정렬키로 대체) |
| #12 상태이상 | StatusEffect 스키마 | `apply_effect()`,`tick_dot()` | #6(DOT 후 승패 재판정 트리거), #13(active_effects 기록) | `Resource.duplicate()`(앨리어싱 버그 방지) |

### FEATURE

| 시스템 | Owns | Exposes | Consumes |
|---|---|---|---|
| #1 턴제 전투 | 턴 루프, targeted_this_turn | 5개 UI용 시그널, end_run() 트리거 | #6,#7,#12,#13,#15 |
| #2 랜덤 던전 | 방 생성 알고리즘 | `generate_floor()` | #13,#11,#9 |
| #3 동료 해금 | 발견 흐름 오케스트레이션 | `companion_unlocked_this_run` 시그널 | #9,#10,#13,#19 |
| #4 장비 | EquipmentData, 6종 고정 아이템 | `get_effective_atk/def()`,`roll_drop()` | #10,#13 |
| #7 적 AI | (없음 — 순수 함수) | `decide_action()` | #11,#6,#13(targeted_this_turn 읽기 전용) |
| #9 히든 트리거 | 히든 동료 배정 풀 | `get_next_companion_id()`,`evaluate()` | #14,#10,#4 |
| #15 파티 구성 | 화면 로컬 선택 상태만 | `start_run()` 호출 | #14,#4,#10,#13 |
| #16 런 결과 | (없음 — 순수 전달) | (없음, 리프 노드) | #13,#18 |
| #8 시너지(예정) | — | — | 미설계 |

### PRESENTATION

| 시스템 | Owns | Consumes |
|---|---|---|
| #20 UI/HUD | (없음, 명시적 무상태) | #1,#3,#4,#9,#13,#14,#15,#16 (전부 시그널 구독) — ⚠️HIGH: 4.6 듀얼 포커스 |
| #21 오디오/#22 내러티브(예정) | — | 미설계 |

### PLATFORM

| 시스템 | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| #18 광고 통합 | 타이머/콜백 상태, JS 브릿지 등록 | `show_interstitial(on_complete)` | 없음 직접 — `on_complete`는 호출자(#16)가 만든 불투명 Callable을 받을 뿐, `#18`이 `SceneManager`를 직접 참조하지 않음 | `JavaScriptBridge.*`(⚠️HIGH), `SceneTreeTimer` |

### API 경계 메모 (Phase 4에서 정식화)

`#18`의 GDD는 `#19 씬 관리`를 Hard Upstream으로 표기하지만, 실제로는 `#18`이 `SceneManager`를 직접 호출하지 않는다 — `#16`이 만든 콜백을 그냥 실행할 뿐이다. GDD 버그는 아님(문서화 정밀도 차이) — Phase 4에서 "`#18`은 `Callable`만 소비하지 특정 시스템에 결합되지 않는다"로 명확히 한다.

## Data Flow

### 1. 입력 → 상태 → 렌더링 경로 (턴제라 "프레임" 대신 "입력 처리 사이클")

```
플레이어 탭(액션 버튼)
  → #20이 이벤트를 #1이 대기 중인 시그널로 발신 (action_selected)   [signal]
  → #1의 턴 루프 코루틴 재개 (await 해제)
  → #1이 #6.skill_damage()/basic_damage() 호출                      [동기 호출, 순수 함수]
  → #1이 결과를 #13의 CompanionRunState/EnemyRunState에 직접 기록    [공유 상태 쓰기 — #13 Core Rule이 명시적으로 허용]
  → #1이 unit_hp_changed(unit_id, new_hp) 발신                      [signal]
  → #20 구독 → HP 바 갱신 (폴링 없음)
```
스레드 경계 없음 — Godot 시그널은 기본 동기(같은 프레임 내 처리).

### 2. 시그널/이벤트 경로

| 시그널 | 발신자 | 확인된 구독자 | 비고 |
|---|---|---|---|
| `floor_changed`,`combat_entered`,`combat_exited`,`run_ended`,`state_changed` | #13 | (문서상 명시적 구독자 미기재) | ⚠️ 실제 구독자 목록이 GDD 레벨에 완전히 명세되지 않음 — Required ADR 후보 |
| `progress_committed` | #14 | #13(await 후 전환) | 저장 성공 여부와 무관하게 항상 발신 |
| `companion_unlocked_this_run` | #3 | #20 | 5-인자(description/color_accent 포함) |
| `companion_discovered` / `hidden_room_already_cleared` | #9 | #3 / #20 | |
| `equipment_dropped` | #4 | #20 | |
| `unit_hp_changed` 등 5개 | #1 | #20 | |

`#13`의 5개 시그널은 "9개 이상 시스템이 구독"이라고 서술만 되어 있고 실제 구독자가 시스템별로 명세되지 않음 — Phase 6 Required ADR로 이관("RunManager 시그널 카탈로그 및 구독 등록 패턴").

### 3. 저장/로드 경로

```
런 종료: #14.commit_run_end() → #17.save_section() 정확히 2회 → progress_committed 발신 (성공/실패 무관)
부팅 시: #14._ready() → #17.load_section()으로 unlocked_companions/highest_floor 복원 → #10 대조 검증
```
직렬화 소유자: `#17`(파일 I/O, schema_version, 원자적 쓰기, 손상 감지 전부 소유) — `#14`는 orchestration만. ⚠️HIGH: `FileAccess` 동기 호출이 리턴해도 웹에서 IndexedDB 실제 durable flush 여부는 미검증 — `#17`의 ADR에서 반드시 확정.

### 4. 초기화 순서

Godot Autoload는 `project.godot`에 나열된 순서로 부팅(알파벳 순 아님) — 실제 결정 필요:

```
제안 순서: SceneManager → CompanionRegistry → EnemyRegistry → SaveManager → ProgressManager → RunManager → AdManager
```

`ProgressManager`는 `_ready()`에서 `SaveManager.load_section()`을 호출하므로 **`SaveManager`보다 반드시 나중**이어야 함 — 순서를 강제하는 유일한 제약. 나머지는 상호 `_ready()`-시점 호출이 없어 순서 자유. 이 순서를 Foundation 레이어 Required ADR로 기록.

## API Boundaries

핵심 경계 6개 (23개 시스템 전체가 아니라 하중이 가장 큰 계약 위주).

### `RunManager` (#13)

```gdscript
func start_run(party_config: Array[Dictionary]) -> void
func end_run(success: bool) -> void
func advance_floor() -> void
func advance_room() -> void
func add_discovered_companion(id: String) -> void
var party: Array[CompanionRunState]         # get-only 프로퍼티, 상태 게이트
var current_enemies: Array[EnemyRunState]   # 동일
signal floor_changed(new_floor: int)
signal state_changed(old_state: String, new_state: String)
# + combat_entered, combat_exited, run_ended
```
- 호출자 불변조건: `party`/`current_enemies`의 **배열 구조**(추가/삭제)는 이 시스템만 변경 — 다른 시스템은 기존 `CompanionRunState`/`EnemyRunState` **필드**만 직접 수정 가능(단일 진실 공급원 원칙이 명시적으로 허용). `state != "EXPLORING"`일 때 `advance_floor()`/`advance_room()` 호출 금지.
- 보장: `state`가 IDLE/RUN_ENDED일 때 게터는 크래시 대신 `[]`+`push_error` 반환. `end_run()`은 멱등.

### `SaveManager` (#17)

```gdscript
func save_section(name: String, data: Variant) -> SaveResult  # await 가능, .success: bool
func load_section(name: String) -> Variant
```
- 불변조건: 호출자는 섹션 내용의 스키마를 스스로 책임진다 — `SaveManager`는 검증하지 않고 그대로 저장/반환.
- 보장: 원자적 쓰기(임시파일+swap), 최대 16.5초 내 성공/실패 확정, 큐 드롭 시에도 최신 상태 재조회로 데이터 유실 없음. ⚠️HIGH: "성공" 신호가 실제 IndexedDB durable flush를 의미하는지는 미검증 — 이 계약의 신뢰도 자체가 ADR 대상.

### `ProgressManager` (#14)

```gdscript
func commit_run_end(discovered_ids: Array[String], floor: int) -> void
signal progress_committed(newly_unlocked: Array[String], save_success: bool)
```
- 불변조건: `#13`은 `progress_committed` 수신 전까지 RunResultScreen 전환 금지.
- 보장: `discovered_ids`에 몇 개가 담기든 `save_section()` 호출은 항상 정확히 2회. 저장 성공/실패와 무관하게 신호는 반드시 발신(무한 대기 방지).

### `SceneManager` (#19)

```gdscript
func go_to(scene_id: String, transition: String, color: Color = Color.WHITE) -> void
```
- 보장: `Loading`/`Transitioning` 중 재호출은 무시(이중 전환 방지). ⚠️HIGH: 실제 백그라운드 스레드 로딩 여부는 COOP/COEP 헤더 활성화에 달림 — 계약은 "논블로킹으로 보인다"이지 "진짜 스레드"를 보장하지 않음.

### `CombatFormula` (#6) — 상태 없는 순수 함수

```gdscript
static func skill_damage(atk: int, multiplier: float, def: int) -> int  # floori(atk*mult+0.0001)-def, min 1
static func turn_order(units: Array) -> Array  # 2차 정렬키(파티 인덱스) 필수 — sort_custom 불안정
```
- 보장: 부작용 없음, 같은 입력 → 항상 같은 출력(테스트 결정성의 기반).

### `AdManager` (#18) — Callable 경계

```gdscript
func show_interstitial(on_complete: Callable) -> void
```
- 명확화: `#18`은 `on_complete`가 무엇을 하는지 모른다(현재는 `#16`이 `SceneManager.go_to()`를 담은 Callable을 넘김) — `#18`을 `#19 씬 관리`에 직접 결합된 것으로 취급하면 안 됨. 실제 계약은 "5초 내 `on_complete`를 정확히 1회 호출한다"뿐.

## ADR Audit

**(2026-07-26 갱신)** `/architecture-decision` 워크플로우로 12개 ADR(ADR-0001~0012) 전부 작성 완료 — 각 파일 `docs/architecture/adr-NNNN-*.md`. 전부 `Status: Proposed` (프로젝트 컨벤션상 신규 ADR은 항상 Proposed로 시작 — Accepted 전환은 별도 검토 세션 필요, `docs/CLAUDE.md`의 ADR 라이프사이클 규칙 참조).

### Traceability Coverage Check

Phase 0b에서 추출한 ~60개 기술 요구사항(TR)이 12개 ADR로 전부 매핑됨 — **60/60 addressed by a Proposed ADR, 0/60 Accepted.** 구현 착수 전 Foundation 7개(ADR-0001~0007)가 최소한 Accepted 상태여야 함(TD 자체 검토 조건 참조, 위 Document Status).

## Required ADRs

60개 개별 TR을 그대로 나열하지 않고, 하나의 결정으로 묶이는 주제 12개로 통합.

### Foundation 레이어 (코딩 시작 전 필수)

1. **HTML5 웹 익스포트 로컬 저장 동기화 검증** → covers: TR-local-save-001,005,006,007 — ⚠️HIGH, `#17` 자체가 "구현 전 필수"로 못박은 항목
2. **Autoload 초기화 순서 및 RunManager 시그널 카탈로그** → covers: TR-run-state-004 — Phase 3의 부팅 순서 제약(SaveManager→ProgressManager) + 실제 구독자 미명세 갭
3. **JavaScriptBridge 광고 콜백 브릿지 검증** → covers: TR-ad-integration-001,002,003,004,005 — ⚠️HIGH
4. **씬 관리 스레드 로딩 & COOP/COEP 헤더 전략** → covers: TR-scene-management-002,004,005,008 — ⚠️HIGH, itch.io 호스팅 제약 확인 필요
5. **RNG 주입 패턴 표준화** → covers: TR-random-dungeon-001, TR-equipment-003, TR-hidden-trigger-001
6. **데이터 레지스트리 공유 유틸리티(Companion/Enemy Registry)** → covers: TR-companion-data-003,004,005, TR-enemy-data-002
7. **Resource 데이터 스키마 & 빌드타임 검증 도구** → covers: TR-companion-data-001,002,006, TR-enemy-data-001,003, TR-status-effects-001

### Core 레이어

8. **전투 공식 부동소수점/정렬 안정성 정책** → covers: TR-combat-formula-001~005, TR-enemy-ai-002 — 이미 5번 반복 발견된 버그 클래스를 아키텍처 규칙으로 고정
9. **Resource 인스턴스 복제 정책(aliasing 방지)** → covers: TR-status-effects-002

### Feature/UI 레이어 (해당 시스템 구현 직전이면 충분)

10. **GDScript await/코루틴 패턴 표준화** → covers: TR-turn-based-combat-001, TR-companion-unlock-002
11. **Godot 4.6 듀얼 포커스 UI 대응 전략** → covers: TR-ui-hud-005 — ⚠️HIGH
12. **UI 시그널 구독 컨벤션(폴링 금지 공식화)** → covers: TR-ui-hud-001

### 보류 가능 (구현 시점에 결정)

나머지 개별 TR(저장 파일 크기 상수 튜닝, 팝업 큐 세부 등)은 이미 GDD에 충분히 명세되어 있어 별도 ADR 불필요 — 스토리 작성 시 GDD를 직접 참조.

## Architecture Principles

1. **단일 진실 공급원 (Single Source of Truth)** — 런타임 게임 상태는 항상 정확히 한 곳(`RunManager`)에만 존재. 다른 시스템은 캐시하지 않고 매번 읽는다. (`#13` GDD의 명시적 Core Rule, 여러 리뷰에서 재확인됨)
2. **시그널 우선, 폴링 금지** — 시스템 간 통신은 Godot 시그널로 한다. 매 프레임 상태를 폴링하는 코드는 금지.
3. **공식은 순수 함수로 분리** — 데미지/전투 공식(`#6`)은 상태 없는 순수 함수. 결정적이라 유닛 테스트가 항상 같은 결과를 내야 한다.
4. **테스트 가능성을 위한 의존성 주입** — RNG, 타이머/clock, JS 브릿지 등 비결정적/외부 자원은 전부 주입 가능해야 한다(`.claude/docs/coding-standards.md`의 요구사항이기도 함).
5. **`""` sentinel, null 금지** — GDScript typed String이 null을 가질 수 없다는 제약 때문에 프로젝트 전역 컨벤션으로 확정(`#4`/`#13`/`#15` 등에서 반복 확인됨).

## Open Questions

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| QQ-01 | HTML5 저장소 durable sync 실제 동작 미검증 | High | Required ADR #1 |
| QQ-02 | COOP/COEP 헤더 itch.io 활성화 가능 여부 | High | Required ADR #4 |
| QQ-03 | JavaScriptBridge 4.4→4.6 API 변경 여부 | High | Required ADR #3 |
| QQ-04 | 광고 SDK 구체 선택(AdSense/AdMob Web/파트너) | Medium | `#18` GDD Open Question — Required ADR #3에서 함께 결정 |
| QQ-05 | RunManager 5개 시그널의 전체 구독자 목록 미명세 | Medium | Required ADR #2 |
| QQ-06 | `#23 설정` 미설계 — 레이어 배치(Foundation vs Presentation) 미확정 | Low | `#23` GDD 작성 시 |
| QQ-07 | 전투 공식 실제 빌드 검증(`/prototype`) 미실행 — 종이 검증만 완료 | High | `/prototype roguelite-core` 실행 권장 (아키텍처 완료 직후) |
