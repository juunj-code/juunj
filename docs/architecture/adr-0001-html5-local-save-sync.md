# ADR-0001: HTML5 웹 익스포트 로컬 세이브 IndexedDB Durability 검증 전략

## Status

Proposed

## Date

2026-07-26

## Last Verified

2026-07-26

## Decision Makers

technical-director, godot-specialist (architecture.md Required ADR #1 담당 지정)

## Summary

`#17 로컬 세이브`(`SaveManager`)가 Godot HTML5 웹 익스포트에서 "저장 성공" 신호를 발신할 때, 그 신호가 실제로 브라우저 IndexedDB에 durable하게 반영되었음을 의미하는지 현재 검증되지 않았다. 이 ADR은 `JavaScriptBridge.eval()`로 Emscripten의 `FS.syncfs(false, callback)`을 직접 호출하고 콜백을 `JavaScriptBridge.create_callback()`으로 GDScript에 브리지하는 방식을 "저장 완료" 신호의 근거로 채택할 것을 제안하며, 실제 구현 전에 3가지 항목의 실측 검증이 반드시 선행되어야 함을 명시한다.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 (HTML5 web export) |
| **Domain** | Core / Persistence |
| **Knowledge Risk** | HIGH — post-cutoff, must verify |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/current-best-practices.md` (grep 결과 `JavaScriptBridge`/`threaded`/`HTML5`/`web export` 키워드 매치 없음 — 아래 Verification Required 참조) |
| **Post-Cutoff APIs Used** | `FileAccess.store_*()` (Godot 4.4+에서 `void` → `bool` 반환으로 변경, `breaking-changes.md` "4.3 → 4.4" 확인됨), `JavaScriptBridge.eval()` / `JavaScriptBridge.create_callback()` / `JavaScriptBridge.get_interface()` (버전 변경 이력이 엔진 레퍼런스 라이브러리에 문서화되어 있지 않음 — ADR-0003 참조) |
| **Verification Required** | (a) Godot 4.6에서 `FileAccess.close()`가 `user://` 가상 FS 쓰기 완료 시점에 IndexedDB `FS.syncfs()` 자동 호출을 트리거하는지 실측 확인. (b) `JavaScriptBridge.eval()`로 `FS.syncfs(false, callback)`을 직접 호출하고 `JavaScriptBridge.create_callback()`으로 콜백을 GDScript에 바인딩하는 방식이 실제 브라우저(모바일 Safari, 모바일 Chrome, 데스크톱 Chrome)에서 신뢰 가능한 "반영 완료" 신호를 주는지 실측 확인. (c) `SAVE_WRITE_TIMEOUT_MS=5000`이 실측 근거 없는 placeholder임 — 위 브라우저 조합에서 실제 IndexedDB flush 지연 분포를 측정해 재조정. |

> **Note**: Knowledge Risk가 HIGH이므로 엔진 버전 업그레이드 시 이 ADR은 반드시 재검증되어야 한다.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (blocking 의존은 아님). 단, 구현 세부사항은 ADR-0003("JavaScriptBridge 광고 콜백 브릿지 검증")이 확립하는 JS↔GDScript 콜백 브릿지 표준 패턴(`JavaScriptBridge.create_callback()` + `get_interface("window")` + `_ready()` 사전 등록 + DI 시임)을 그대로 재사용한다 — 동일 패턴을 두 번 다르게 발명하지 않기 위함. |
| **Enables** | 이 ADR 자체가 다른 ADR을 여는 것은 아님. (역방향: ADR-0003이 이 ADR을 enable — ADR-0003 참조) |
| **Blocks** | `#17 로컬 세이브` 구현 착수 전체, 그리고 `#14 영구 진행`(저장 신호에 의존)의 신뢰도 있는 구현 |
| **Ordering Note** | ADR-0003과 병렬로 작성되었으나(번호 충돌 방지를 위한 사전 배정), 실제 코드 작성 순서상 ADR-0003의 JS 브릿지 표준 패턴을 먼저 확정한 뒤 이 ADR의 `FS.syncfs()` 콜백 구현에 그 패턴을 적용하는 것을 권장한다. |

## Context

### Problem Statement

`바람의 탑`의 필라 2("성장은 영원하다")는 런에 실패해도 발견한 동료 해금은 영구히 남는다는 약속이다. 이 약속의 유일한 기술적 근거는 `#17 로컬 세이브`가 발신하는 "저장 성공" 신호다. 그런데 Godot HTML5 익스포트에서 `user://`는 Emscripten MEMFS(가상 파일시스템)에 매핑되고, 그 내용이 실제 브라우저 IndexedDB에 영속화되는 것은 별도의 비동기 `FS.syncfs()` 단계다. `FileAccess.store_*()`(Godot 4.4+ `bool` 반환)가 성공을 리턴해도 그것은 가상 FS 내 쓰기 성공만 확인할 뿐, IndexedDB 반영 여부는 확인하지 않는다. 즉 "저장 완료" UI가 표시된 직후 플레이어가 브라우저를 강제 종료하면, 표시된 성공과 무관하게 실제로는 유실이 발생할 수 있다 — 이 프로젝트에서 가장 player-trust-critical한 리스크다.

### Current State

`#17` GDD는 원자적 쓰기(`_write_temp()` + `_swap()`), 5000ms 타임아웃, 지수 백오프 2회 재시도(최악 16500ms)를 설계했지만, 이 전체 상태머신은 "가상 FS 내 쓰기 성공"을 판정 기준으로 삼고 있다 — IndexedDB 실제 durability는 GDD 자신이 Open Question #2로 명시적으로 미해결 처리했다.

### Constraints

- Godot 4.6 웹 익스포트, Emscripten 기반 MEMFS + IndexedDB 백엔드라는 플랫폼 제약은 변경 불가.
- LLM 학습 데이터 커버리지가 ~4.3까지이며 `JavaScriptBridge` API가 4.4~4.6 사이 변경되었는지 이 프로젝트의 엔진 레퍼런스 라이브러리 자체에 문서화되어 있지 않다(grep 결과 무매치).
- 실제 타겟 브라우저(모바일 Safari/Chrome)에서의 실측 데이터가 아직 없다 — 종이 설계 단계.

### Requirements

- "저장 성공" 신호는 실제 durable 반영을 최대한 신뢰성 있게 근사해야 한다.
- 구현은 `.claude/docs/coding-standards.md`의 DI 요구사항(비결정적 외부 자원은 주입 가능해야 함)을 따라야 하며, GUT 헤드리스 테스트 환경에서 실제 브라우저 JS 실행 없이도 계약을 검증할 수 있어야 한다(ADR-0003의 `_js_bridge` 시임 패턴과 동일한 접근).
- `SAVE_WRITE_TIMEOUT_MS` 등 타이밍 상수는 실측 후 확정되어야 하며, 실측 전까지는 "unverified placeholder"로 명시적으로 취급되어야 한다.

## Decision

`SaveManager`의 저장 완료 확인을 2단계로 분리한다:

1. **1단계 (가상 FS 쓰기)**: `_write_temp()` → `FileAccess.store_*()` bool 리턴 확인 → `_swap()`. 기존 GDD 설계 그대로 유지.
2. **2단계 (durable 반영 확인, 이 ADR이 신규 추가)**: `_swap()` 완료 직후, 웹 빌드에서는 `JavaScriptBridge.eval()`로 `FS.syncfs(false, <callback>)`을 호출하고, 그 콜백을 ADR-0003이 확립한 패턴과 동일하게 `_ready()`에서 사전 등록된 `JavaScriptBridge.create_callback()`을 통해 GDScript로 되돌린다. 이 콜백이 (에러 없이) 호출된 시점에만 `SaveManager`는 최종 "Save Complete" 시그널을 발신한다. 콜백이 없거나 에러를 리턴하면 기존 재시도/타임아웃 상태머신(`Retrying` → `Save Failed`)으로 진입한다.

비웹(에디터/데스크톱) 환경에서는 2단계를 스킵하고 1단계 성공만으로 즉시 "Save Complete"를 발신한다 — `FileAccess`가 실제 디스크에 쓰므로 durability 이슈가 없다.

### Architecture

```
[소비 시스템] --save_section()--> [SaveManager]
                                      |
                                      v
                              1) _write_temp()
                                      v
                              2) FileAccess bool 확인
                                      v
                              3) _swap()
                                      v
                     (web only) 4) JavaScriptBridge.eval(
                                     "FS.syncfs(false, GodotSaveBridge.onSyncDone)")
                                      v
                     JS FS.syncfs 콜백 --------------------+
                                      |                    |
                                      v                    v
                        성공: create_callback 발화   에러/타임아웃(SAVE_WRITE_TIMEOUT_MS)
                                      v                    v
                              Save Complete 시그널   Retrying → Save Failed
```

### Key Interfaces

```gdscript
# SaveManager (Autoload) — durability 확인 시임 추가
var _js_bridge = JavaScriptBridge  # 테스트에서 mock 주입 (ADR-0003과 동일 DI 패턴)

func _ready() -> void:
    if OS.has_feature("web"):
        _js_bridge.eval("window.GodotSaveBridge = {};", true)
        var bridge = _js_bridge.get_interface("window").GodotSaveBridge
        bridge.onSyncDone = _js_bridge.create_callback(_on_indexeddb_sync_done)

func _confirm_durable_write() -> void:
    if not OS.has_feature("web"):
        _on_indexeddb_sync_done(null)  # 비웹은 즉시 durable로 취급
        return
    _js_bridge.eval("FS.syncfs(false, function(err) { GodotSaveBridge.onSyncDone(err); });")

func _on_indexeddb_sync_done(err) -> void:
    if err:
        _enter_retry_state()
    else:
        _emit_save_complete()
```

### Implementation Guidelines

- `_write_temp()`와 `_swap()`은 GDD가 이미 요구한 대로 개별 테스트 가능 단계로 노출 — 이 ADR의 2단계 확인은 그 뒤에 이어붙이는 것이지 대체하는 것이 아니다.
- `_on_indexeddb_sync_done`의 등록은 반드시 `_ready()`에서, `_confirm_durable_write()`가 처음 호출되기 전에 완료되어야 한다(ADR-0003의 등록 순서 규칙과 동일한 이유 — 등록 누락 시 `#18`에서 실제로 발생했던 것과 같은 `ReferenceError` 클래스의 버그가 재발한다).
- `SAVE_WRITE_TIMEOUT_MS`(현재 5000ms)는 1단계+2단계 전체를 포괄하는 타임아웃으로 재해석한다 — 2단계가 추가되는 만큼 실측 후 값 조정이 필요할 수 있다(Verification Required 참조).
- GUT 테스트는 `_js_bridge`를 mock으로 교체해 `FS.syncfs` 호출 여부와 콜백 성공/실패 분기만 검증한다 — 실제 브라우저 IndexedDB 동작 자체는 자동화 테스트 대상이 아니다(수동/실브라우저 검증 필요, Verification Required 참조).

## Alternatives Considered

### Alternative 1: `FileAccess.close()` 단독 신뢰

- **Description**: `FileAccess.close()`가 리턴하면 그것만으로 "저장 완료"로 취급하고, IndexedDB 동기화는 Godot 엔진이 내부적으로 처리한다고 가정한다.
- **Pros**: 구현이 가장 단순하다 — 추가 JS 브릿지 코드가 필요 없다.
- **Cons**: GDD의 Open Question #2가 이미 명시한 대로 미검증 가정이다. `close()`가 자동 `syncfs()`를 트리거하는지, 트리거한다면 동기인지 비동기인지가 4.6 기준으로 문서화되어 있지 않다. 이 가정이 틀릴 경우 필라 2 전체의 신뢰가 조용히 깨진다 — 실패 모드가 사용자에게 보이지 않는다는 점이 가장 위험하다.
- **Estimated Effort**: 낮음 (거의 0)
- **Rejection Reason**: GDD 자신이 "insufficiently verified"로 이미 플래그한 접근이며, 실패 시 감지조차 안 되는 silent failure 클래스라 이 프로젝트의 가장 치명적인 리스크 항목에 적용하기엔 근거가 너무 약하다.

### Alternative 2: 저장마다 페이지 unload 이벤트에 의존(beforeunload sync flush)

- **Description**: 브라우저의 `beforeunload`/`visibilitychange` 이벤트에서 동기적으로 flush를 강제 시도.
- **Pros**: 사용자가 실제로 떠나려는 시점에 한 번 더 안전망을 제공.
- **Cons**: 대부분의 모던 브라우저가 `beforeunload` 내 비동기 작업이나 긴 동기 작업을 신뢰성 있게 완료 보장하지 않는다(특히 모바일 Safari) — 이것 자체가 미검증 가정을 하나 더 얹는 것이며 근본 문제(저장 시점의 durable 확인)를 해결하지 않는다.
- **Estimated Effort**: 중간
- **Rejection Reason**: 근본 해결책이 아니라 보조 안전망 수준 — `FS.syncfs()` 명시적 확인이 우선이며, 이 대안은 향후 추가 보강으로 남겨둔다(YAGNI, 현재 범위 아님).

## Consequences

### Positive

- "Save Complete" 신호가 최소한 브라우저에게 durable flush를 명시적으로 요청하고 그 결과를 확인한 뒤에만 발신되므로, 현재의 silent-failure 리스크가 명확히 관측 가능한 실패(재시도/최종 실패 UI)로 전환된다.
- ADR-0003과 동일한 JS 브릿지 DI 패턴을 재사용하므로 두 시스템의 테스트 전략과 구현 관용구가 일관된다 — 유지보수 시 두 가지 다른 브릿지 패턴을 익힐 필요가 없다.

### Negative

- 저장 경로에 브라우저 왕복(JS eval + 콜백)이 하나 더 추가되어 저장 완료까지의 지연이 늘어난다 — 정확한 지연폭은 실측 전까지 알 수 없다(Verification Required).
- `SAVE_WRITE_TIMEOUT_MS=5000`이 이 추가 단계를 포함하기에 충분한지 재검증이 필요하며, 그 전까지는 값 자체가 placeholder다.

### Neutral

- 비웹(에디터/데스크톱) 경로는 변경 없음 — 이 ADR의 영향은 웹 빌드에 국한된다.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `FS.syncfs()` 콜백이 실제로는 durable을 보장하지 않는(브라우저별 구현 차이) | Medium | Critical (필라 2 신뢰 붕괴) | 구현 전 실측 검증(Verification Required 항목 a, b)을 반드시 선행 — 이 ADR은 검증 계획이지 최종 보증이 아님을 명시 |
| `SAVE_WRITE_TIMEOUT_MS`가 실제 모바일 flush 지연보다 짧아 정상 저장을 실패로 오판 | Medium | High (플레이어가 실제로는 성공한 저장을 실패로 오인) | 실제 타겟 브라우저에서 flush 지연 분포 실측 후 값 재조정(Verification Required 항목 c) |
| `JavaScriptBridge` API가 4.4~4.6 사이 변경되어 `create_callback()`/`get_interface()` 시그니처가 다름 | Unknown (엔진 레퍼런스에 미문서화) | High (컴파일/런타임 에러) | ADR-0003의 Verification Required와 동일 항목 — 실제 4.6 빌드에서 최소 재현 테스트 선행 |

## Performance Implications

N/A — 구현 코드가 존재하지 않아 측정할 대상이 없다. 실측 항목은 위 Verification Required 및 Risks에 기록.

## Migration Plan

N/A — 마이그레이션 대상이 되는 기존 시스템이 없다(첫 구현).

## Validation Criteria

- [ ] 실제 모바일 Safari/Chrome에서 저장 요청 → `FS.syncfs()` 콜백 수신까지의 지연을 최소 20회 이상 실측하고 분포(p50/p95/max)를 기록한다.
- [ ] 탭 강제 종료(devtools로 시뮬레이션 가능한 범위 내) 직후 재시작 시, "성공" 신호를 받은 저장이 실제로 남아있는지 최소 10회 반복 확인한다.
- [ ] `SAVE_WRITE_TIMEOUT_MS`가 실측 p95 지연을 여유 있게 포괄하는지 확인하고 필요 시 값을 갱신한다.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/로컬-세이브.md` (Core Rule 6, Open Question #2) | #17 로컬 세이브 | "저장 요청은 성공/실패를 명확히 반환... 소비 시스템이 '저장됐다'고 UI에 표시하기 전에 이 확인을 기다려야 한다" + "(a) FileAccess.close()가 IndexedDB 자동 동기화를 수행하는지, (b) FS.syncfs() 직접 호출 방식의 신뢰성, (c) SAVE_WRITE_TIMEOUT_MS 실측 근거" | `FS.syncfs()` 명시적 콜백 확인을 저장 완료 신호의 필수 2단계로 채택하고, 세 항목 모두 구현 전 실측 검증 항목으로 명시 |
| `design/gdd/로컬-세이브.md` (Acceptance Criteria 6) | #17 로컬 세이브 | "UI는... 시스템으로부터 명시적 성공 신호를 수신한 시점에만 표시한다" | 2단계(durable 확인) 완료 후에만 Save Complete 시그널 발신하도록 설계해 이 AC의 신뢰도를 강화 |

## Related

- ADR-0003 (`docs/architecture/adr-0003-js-ad-bridge.md`) — 이 ADR의 JS↔GDScript 콜백 브릿지 구현은 ADR-0003이 확립한 표준 패턴을 재사용한다.
- `design/gdd/로컬-세이브.md` — Core Rule 6, Open Question #2
- `docs/architecture/architecture.md` — Data Flow 3번(저장/로드 경로), Required ADRs #1
