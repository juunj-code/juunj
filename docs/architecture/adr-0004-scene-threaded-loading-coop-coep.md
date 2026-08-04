# ADR-0004: 씬 관리 스레드 로딩 익스포트 변형 & COOP/COEP 헤더 전략

## Status

Proposed

## Date

2026-07-26

## Last Verified

2026-08-04 — Verification Required 항목 (b) 실측 완료. itch.io Edit game 페이지의 "SharedArrayBuffer support (Experimental)" 임베드 옵션(폼 필드명 `embed[cdn_type]`)이 정확히 이 ADR이 찾던 COOP/COEP 스위치임을 발견. 실제로 켜고 저장한 뒤 배포된 게임 페이지(`juunj.itch.io/wind-tower`)에서 `window.crossOriginIsolated`가 `true`, `typeof SharedArrayBuffer !== 'undefined'`가 `true`로 실측 확인 — **itch.io는 COOP/COEP 헤더를 프로젝트별 옵트인으로 실제 지원한다.** (참고: 정적 에셋 CDN URL(`html-classic.itch.zone/html/.../index.html`)을 직접 `curl`/`Invoke-WebRequest`로 조회하면 이 헤더가 안 보임 — 헤더는 CDN 에셋 레벨이 아니라 itch.io가 서빙하는 게임 페이지/프레임 컨텍스트에서만 적용되는 것으로 보임, 실제 크로스오리진 격리 여부는 반드시 브라우저의 `crossOriginIsolated`로 확인해야 함.) 검증 목적 확인 후 해당 옵션은 다시 꺼서(`crossOriginIsolated: false` 재확인) 저장 — 지금 배포된 빌드는 여전히 Regular(비스레드) 변형이라 이 실험적 옵션이 불필요하고, itch.io 자신이 "페이지나 프로젝트가 깨질 수 있음"이라 경고하는 기능이라 실사용 없이 켜둘 이유가 없음. **결론**: itch.io 지원이 확인됐으므로 Ordering Note에 따라 Threads 변형 전환은 이 ADR을 수정하지 않고 별도 신규 ADR("Superseded by")로 다룰 것 — 이 세션에서는 검증만 완료, 실제 전환은 하지 않음.

2026-08-03 — Verification Required 항목 (c)/(d) 실측 완료 (항목 (b) itch.io COOP/COEP 헤더 지원은 실제 itch.io 배포가 필요해 여전히 미검증, Status는 Proposed 유지).

**(c) Regular 변형 프레임 예산 실측** — 실제 프로덕션 웹 빌드에서 `Time.get_ticks_usec()`로 `change_scene_to_file()` 호출 자체를 정밀 계측(자동화 환경의 `_process` delta 노이즈를 우회한 직접 측정). 결과: S-02(MainMenu) 6.40ms, S-03(PartySelect) 17.10ms, **S-04(DungeonExploration) 27.60ms, S-05(BattleScreen, 적 스프라이트 2장+초상화 로드) 48.70ms** — 16.6ms 예산을 확실히 초과. 단, 이건 지속적 프레임 드랍이 아니라 씬 전환 순간 단발성 히치(hitch)임 — 매 프레임 반복되는 병목이 아니라 로드 시점 1프레임만 영향. 리스크 표가 예견한 "무거운 씬 전환 시 눈에 띄는 프레임 드랍"이 실측으로 확인됨(Medium probability → Confirmed). Threads 전환 검토를 앞당길 근거가 됨(원 문서의 "초과 시 재검토" 조건 충족) — 단, 즉시 시각적으로 문제인지는 실사용자 체감 테스트가 별도로 필요.

**(d) 탭 백그라운드 30초+ 복귀 시 Tween 동작** — `prototypes/tween-background-resume/`(8초 Tween 격리 씬)로 검증. 45초 백그라운드 후 복귀: `_process`가 백그라운드 동안 완전히 정지(경과 시간이 delta로 반영되지 않고 소실), 복귀 후 거대한 단일 delta(SUSPICIOUS >0.2s) 발생 **0건**, `overlay_a`가 0.109→0.24→0.372→0.502→0.631로 8초 기준 정확히 선형 진행(점프/역행 없음). TR-scene-management-008이 우려한 비정상 delta·1.0 미도달·NaN/오버슈트 중 어느 것도 관찰되지 않음 — 리스크 표의 Medium impact 우려보다 실제 위험도가 낮음(시각적으로는 "백그라운드 중 페이드가 멈췄다가 재개"뿐, 깨짐 없음). 상세: `prototypes/tween-background-resume/README.md`.

## Decision Makers

technical-director, godot-specialist (architecture.md Required ADR #4 담당 지정)

## Summary

`#19 씬 관리`(`SceneManager`)의 백그라운드 로딩(`ResourceLoader.load_threaded_request()`)이 실제 OS 스레드로 동작하려면 Godot 웹 익스포트의 "Threads" 변형과, 타겟 호스트(itch.io)의 COOP/COEP 크로스오리진 격리 헤더가 필요하다 — 이 헤더 지원 여부가 미검증이다. 이 ADR은 hosting-platform 의존 리스크를 피하기 위해 **Regular(비-스레드) 익스포트 변형을 기본값으로 채택**하고, itch.io의 COOP/COEP 지원이 실측 확인된 이후에 Threads 변형 전환을 재검토할 것을 결정한다.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 (HTML5 web export) |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | HIGH — post-cutoff, must verify |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/deprecated-apis.md` — grep으로 `threaded`/`COOP`/`COEP`/`SharedArrayBuffer`/`web export`/`HTML5` 키워드를 전체 `docs/engine-reference/godot/` 트리에서 검색했으나 **일치하는 파일이 0개**였다(이 프로젝트의 엔진 레퍼런스 라이브러리에 웹 익스포트 스레딩/COOP-COEP 전용 문서가 아직 없음). |
| **Post-Cutoff APIs Used** | `ResourceLoader.load_threaded_request()` / `load_threaded_get()` / `load_threaded_get_status()`, `get_tree().change_scene_to_packed()` |
| **Verification Required** | (a) Threads vs Regular 익스포트 변형 최종 결정(이 ADR에서 Regular로 결정, 아래 참조). (b) Threads 변형을 향후 채택할 경우 itch.io 프로젝트 설정에서 COOP/COEP 헤더 활성화가 실제로 가능한지 확인(itch.io 문서 또는 실제 업로드 테스트). (c) Regular 변형 채택 시 스레드 로딩 API가 메인 스레드 프레임 예산(16.6ms, `technical-preferences.md`)에 미치는 실측 영향 — FADE 트윈 프레임 드랍 여부 측정. (d) TR-scene-management-008: 탭 30초 이상 백그라운드 후 재개 시 Tween delta 로그, 종료값이 정확히 1.0인지, NaN/오버슈트 없는지 확인. |

> **Note**: Knowledge Risk가 HIGH이므로 엔진 버전 업그레이드 시 이 ADR은 반드시 재검증되어야 한다.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | None (다른 ADR을 직접 열지 않음) |
| **Blocks** | `#19 씬 관리` 구현 착수, 그리고 이를 Hard Upstream으로 삼는 `#2 랜덤 던전`, `#13 런 상태 관리`, `#18 광고 통합`의 씬 전환 관련 구현 |
| **Ordering Note** | itch.io COOP/COEP 지원이 확인되면(Verification Required 항목 b) 이 ADR은 "Superseded by ADR-XXXX"로 개정하고 Threads 변형으로 전환하는 별도 ADR을 새로 작성한다 — 이 ADR 자체를 수정하지 않는다(ADR은 불변 기록이라는 프로젝트 관례). |

## Context

### Problem Statement

`#19` GDD는 `ResourceLoader.load_threaded_request()` → `load_threaded_get()` → `change_scene_to_packed()`로 씬 전환을 논블로킹하게 만들도록 설계했다. 그러나 Godot 웹 익스포트에서 이 "스레드 로딩"이 진짜 OS 스레드 병렬성으로 동작하는지는 익스포트 변형(Threads vs Regular)에 달려 있고, Threads 변형은 `SharedArrayBuffer`를 위해 호스트 서버가 COOP/COEP 크로스오리진 격리 헤더를 응답에 포함해야만 정상 로드된다. 타겟 배포처인 itch.io가 프로젝트별 커스텀 헤더 설정을 지원하는지 확인되지 않은 상태에서 Threads 변형을 기본값으로 삼으면, 배포 시점에 게임 자체가 로드되지 않는 치명적 실패로 이어질 수 있다.

### Current State

GDD는 두 변형의 트레이드오프를 Open Question #4로 명시적으로 남겨두었다: Threads 미지원 시 (i) Threads 빌드는 로드 자체가 실패하거나, (ii) Regular 변형에서는 "스레드 로딩" API가 실제로는 메인 스레드 프레임 예산과 경쟁하는 협조적 멀티태스킹에 불과하다. GDD는 이미 타이밍 예산을 `_process(delta)` 누적(wall-clock 아님)으로 설계해 두어, 브라우저 탭이 백그라운드일 때 타임아웃이 부당하게 앞당겨지지 않도록 방어했다 — 이는 진짜 스레드가 아닐 가능성을 GDD 스스로 이미 어느 정도 예견하고 설계한 것이다.

### Constraints

- 타겟 호스트는 itch.io로 확정(`production/session-state/active.md` Key Decisions: "Platform: 브라우저 (PC + 모바일) → iOS/Android 앱 (Phase 2)", 및 architecture.md의 QQ-02가 itch.io를 COOP/COEP 검증 대상으로 명시).
- itch.io는 프로젝트별로 명시적 헤더 설정이 필요하며, 그 설정 자체가 가능한지(플랫폼이 커스텀 응답 헤더를 지원하는지)가 미확인이다.
- 성능 예산: 60fps, 16.6ms 프레임 버짓(`technical-preferences.md`), 모바일 브라우저 우선(터치 primary).
- 아직 코드가 없다 — 이 ADR 시점에 실측 데이터가 전혀 없다(종이 결정).

### Requirements

- 씬 전환은 GDD의 타이밍 예산(`SCENE_LOAD_TIMEOUT_MS=10000`, `LOADING_INDICATOR_THRESHOLD_MS=2500`, `BOOT_PRELOAD_TIMEOUT_MS=8000`)을 만족해야 한다.
- 배포 플랫폼(itch.io) 의존 리스크가 있는 경로를 기본값으로 삼지 않아야 한다 — 확인되지 않은 외부 조건에 게임 로드 자체가 실패하는 경로는 허용 불가.
- 백그라운드 탭에서 Tween/타임아웃이 부당하게 동작하지 않아야 한다(GDD가 이미 요구한 `_process` delta 누적 방식 유지).

## Decision

**Regular(비-스레드) 익스포트 변형을 기본값으로 채택**하고, Threads 변형 + COOP/COEP 헤더 활성화는 itch.io 지원이 실측 확인된 이후의 후속 결정으로 미룬다.

이유:
1. Regular 변형은 호스팅 플랫폼의 커스텀 헤더 지원 여부라는 외부 미확인 조건에 게임 로드 자체를 걸지 않는다 — 확인 안 된 전제 위에 배포를 걸지 않는다는 원칙.
2. Regular 변형이 "진짜 스레드"가 아니더라도 GDD의 타임아웃 설계(frame-accumulated, wall-clock 아님)가 이미 이 상황을 어느 정도 흡수하도록 만들어져 있다 — 설계와 결정이 서로 정합적이다.
3. Regular 변형에서 메인 스레드 프레임 예산 잠식이 실제로 문제가 된다면(Verification Required 항목 c), 그 시점에 Threads 전환을 별도 후속 ADR로 재검토하면 된다 — 지금 당장 검증 안 된 헤더 지원에 배팅할 필요가 없다.

### Architecture

```
[SceneManager.go_to(scene_id, transition)]
        │
        ▼
  ResourceLoader.load_threaded_request(path)   # Regular 익스포트: 메인 스레드 프레임 예산과
        │                                       # 협조적으로 경쟁(진짜 OS 스레드 아님)
        ▼
  매 _process(delta): load_threaded_get_status() 폴링
        │  t_load_elapsed += delta   (wall-clock 아님 — 탭 백그라운드 시 자동 정지)
        │
        ├─ t_load_elapsed > LOADING_INDICATOR_THRESHOLD_MS(2500) → 소프트 인디케이터 표시
        ├─ 로드 완료 → load_threaded_get() → change_scene_to_packed()
        └─ t_load_elapsed > SCENE_LOAD_TIMEOUT_MS(10000) → 실패 처리, 이전 씬 유지
```

### Key Interfaces

```gdscript
# SceneManager — Regular 변형 기준 로딩 루프
var _t_load_elapsed_ms: float = 0.0

func _process(delta: float) -> void:
    if state != State.LOADING:
        return
    _t_load_elapsed_ms += delta * 1000.0  # wall-clock 아님 — 탭 백그라운드 시 _process 자체가 정지되어 자동 흡수

    var status := ResourceLoader.load_threaded_get_status(_current_load_path)
    if status == ResourceLoader.THREAD_LOAD_LOADED:
        var packed := ResourceLoader.load_threaded_get(_current_load_path)
        get_tree().change_scene_to_packed(packed)
        _enter_displaying()
        return

    if _t_load_elapsed_ms > LOADING_INDICATOR_THRESHOLD_MS:
        _show_soft_loading_indicator()
    if _t_load_elapsed_ms > SCENE_LOAD_TIMEOUT_MS:
        _fail_load_and_restore_previous_scene()
```

### Implementation Guidelines

- 익스포트 프리셋(`export_presets.cfg`)은 Regular(비-스레드) HTML5 변형으로 설정 — Threads 옵션을 활성화하지 않는다.
- `_process(delta)` 누적 방식은 GDD가 이미 요구한 그대로 유지 — wall-clock(`Time.get_ticks_msec()` 등)으로 바꾸지 않는다. 이것이 탭 백그라운드 시 타임아웃을 부당하게 앞당기지 않는 유일한 방어선이다.
- Regular 변형 채택 후, 첫 프로토타입 빌드에서 씬 로드 중 프레임 드랍(특히 `BattleScreen.tscn` 같은 무거운 씬 전환 시)을 실측하고 `technical-preferences.md`의 16.6ms 예산 대비 초과 여부를 기록한다(Verification Required 항목 c) — 초과가 확인되면 Threads 전환 검토를 앞당길 근거가 된다.
- Threads 변형으로 전환을 검토할 때는 itch.io가 실제로 응답 헤더에 `Cross-Origin-Opener-Policy: same-origin` / `Cross-Origin-Embedder-Policy: require-corp`를 설정할 수 있는지부터 실제 업로드로 확인한다(문서만으로 결론 내리지 않는다) — 이 ADR의 범위 밖, 후속 ADR 대상.

## Alternatives Considered

### Alternative A: Threads 익스포트 변형 + itch.io COOP/COEP 헤더 설정

- **Description**: Threads 빌드 변형을 채택하고 itch.io 프로젝트 설정에서 커스텀 응답 헤더를 활성화해 `SharedArrayBuffer`를 사용 가능하게 만든다.
- **Pros**: 진짜 OS 스레드 병렬 로딩으로 최고 성능 — 메인 스레드 프레임 예산과 전혀 경쟁하지 않는다.
- **Cons**: itch.io의 커스텀 헤더 지원 여부 자체가 미확인이다. 지원하지 않으면 Threads 빌드는 배포 즉시 로드 실패라는 최악의 실패 모드로 이어진다 — 개발 완료 후에야 발견될 위험이 있는 외부 플랫폼 의존.
- **Estimated Effort**: 낮음(익스포트 설정 자체는 간단) — 단, itch.io 헤더 지원 확인 및 실패 시 폴백 계획 수립까지 포함하면 불확실성 비용이 높음.
- **Rejection Reason**: 확인되지 않은 호스팅 플랫폼 능력에 프로젝트 전체의 로드 가능 여부를 거는 것은 이 시점에서 받아들일 수 없는 리스크. itch.io 지원이 실측 확인되면 후속 ADR로 재검토(Ordering Note 참조).

### Alternative B: Regular(비-스레드) 익스포트 변형 (채택)

- **Description**: 위 Decision 참조.
- **Pros**: 호스팅 플랫폼 의존 리스크 없음. GDD의 frame-accumulated 타임아웃 설계와 정합적. 성능 저하 시에도 크래시가 아니라 우아한 저하(graceful degradation).
- **Cons**: "백그라운드 로딩"이 진짜 병렬이 아니라 메인 스레드와 협조적으로 경쟁 — 무거운 씬에서 프레임 드랍 가능성이 있다(실측 필요).
- **Estimated Effort**: 낮음(GDD가 이미 이 가정 하에 타임아웃을 설계해 두었다).
- **Rejection Reason**: 채택됨(위 Decision 참조).

## Consequences

### Positive

- 배포 시점에 itch.io 호스팅 제약으로 게임이 아예 로드되지 않는 최악의 실패 모드를 원천 차단한다.
- GDD의 기존 타이밍 설계(frame-accumulated 타임아웃, 소프트 인디케이터 임계값)를 그대로 활용할 수 있어 추가 설계 변경이 필요 없다.

### Negative

- Regular 변형에서 스레드 로딩 API가 메인 스레드 프레임 예산을 잠식할 가능성이 있으며, 그 정도는 실측 전까지 알 수 없다 — 최악의 경우 무거운 씬 전환 시 눈에 띄는 프레임 드랍이 발생할 수 있다.
- Threads 변형의 성능 이점을 당장 누리지 못한다 — itch.io 지원이 확인되어도 후속 ADR과 재작업이 필요하다.

### Neutral

- 이 결정은 itch.io라는 특정 호스팅 플랫폼에 종속적이다 — 향후 호스팅 플랫폼이 바뀌면(예: 자체 서버로 이전) 이 ADR은 재검토 대상이 된다.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Regular 변형의 로딩 API가 무거운 씬(`BattleScreen.tscn`) 전환 시 실제로 눈에 띄는 프레임 드랍을 유발 | Medium | Medium (게임 필 저하, 크래시는 아님) | 첫 프로토타입 빌드에서 실측(Verification Required 항목 c), 초과 시 프리로드 범위 확대나 씬 분할 등 완화책 검토 |
| itch.io가 실제로는 COOP/COEP 헤더를 지원함에도 이를 확인하지 않아 Threads 변형의 성능 이점을 불필요하게 포기 | Low-Medium | Low (기회비용, 안전성 문제는 아님) | itch.io 헤더 지원 여부를 프로토타입 단계에서 조기에 확인하고 지원 확인 시 즉시 후속 ADR 작성 |
| TR-scene-management-008: 탭 30초+ 백그라운드 후 재개 시 Tween이 정확히 1.0에 도달하지 않거나 NaN/오버슈트 발생 | Unknown (미실측) | Medium (전환 연출 깨짐, 씬 표시 자체는 진행되나 시각적 결함) | 구현 후 수동 테스트: 탭을 Tween 진행 중 30초 이상 백그라운드에 두고 재개 프레임의 delta 로그 및 Tween 종료값 확인(Verification Required 항목 d) |

## Performance Implications

N/A — 구현 코드가 존재하지 않아 측정할 대상이 없다. 실측 계획은 Verification Required 및 Risks 표에 기록.

## Migration Plan

N/A — 마이그레이션 대상이 되는 기존 시스템이 없다(첫 구현). itch.io COOP/COEP 지원이 향후 확인되어 Threads 변형으로 전환할 경우, 이 ADR은 "Superseded"로 표시하고 별도 신규 ADR을 작성한다(Ordering Note 참조) — 이 문서 자체를 수정하지 않는다.

## Validation Criteria

- [x] 첫 프로토타입 빌드(`/prototype roguelite-core` 또는 이후 실제 빌드)에서 Regular 변형으로 `DungeonExploration → BattleScreen` 전환 시 프레임 타임을 실측하고 16.6ms 예산 대비 기록. — 2026-08-03, 48.70ms 실측(예산 초과 확인), 위 "Last Verified" 참조.
- [x] 탭을 Tween 진행 중(FADE 또는 FLASH) 30초 이상 백그라운드에 두었다가 재개했을 때, 재개 프레임의 delta 값과 Tween 종료값(정확히 1.0인지, NaN/오버슈트 없는지)을 로그로 확인. — 2026-08-03, `prototypes/tween-background-resume/`로 검증, 위 "Last Verified" 참조.
- [x] itch.io 실제 프로젝트 페이지에서 커스텀 응답 헤더(COOP/COEP) 설정 가능 여부를 문서 또는 실제 업로드 테스트로 확인하고 결과를 이 ADR의 후속 노트 또는 별도 ADR에 기록. — 2026-08-04, "SharedArrayBuffer support" 임베드 옵션으로 지원 확인(`crossOriginIsolated: true` 실측), 위 "Last Verified" 참조. 이 ADR의 Verification Required (a)~(d) 전부 완료됨 — 단, Status는 여전히 Proposed 유지(Threads 변형으로의 실제 전환은 별도 신규 ADR 대상, Ordering Note 참조).

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/씬-관리.md` (Core Rule 1, Formula ②) | #19 씬 관리 | "`ResourceLoader.load_threaded_get()` → `change_scene_to_packed()` 사용... `change_scene_to_file()`(동기/블로킹) 내부적으로도 사용 금지" | Regular 변형 채택 시에도 동일한 스레드 로딩 API 골격을 유지하며 블로킹 호출을 사용하지 않음을 Key Interfaces에 명시 |
| `design/gdd/씬-관리.md` (Formula ② "웹 익스포트 스레드 로딩 리스크", Open Question #4) | #19 씬 관리 | "Threads 빌드 변형 + 호스트의 COOP/COEP 헤더 필요... itch.io는 프로젝트별로 명시적으로 켜야만 제공... 구현 전 ADR 필수" | 이 ADR이 정확히 그 결정을 내림 — Regular를 기본값으로, Threads는 itch.io 지원 확인 후 후속 ADR로 |
| `design/gdd/씬-관리.md` (탭 백그라운드 Edge Case, `_process` delta 누적) | #19 씬 관리 | "`t_load_elapsed`는... `_process(delta)` 누적치로 측정... 브라우저가 백그라운드 탭에서 `_process` 호출 자체를 멈추므로... 타임아웃 판정이 부당하게 앞당겨지지 않는다" | Key Interfaces에서 동일하게 delta 누적 방식을 유지하도록 명시 |
| `design/gdd/씬-관리.md` (Open Question #2, TR-scene-management-008) | #19 씬 관리 | "탭을 Tween 진행 중 30초 이상 백그라운드에 둔 뒤 재개 프레임의 delta 로그, Tween 종료값이 정확히 1.0인지 확인" | Verification Required 항목 d 및 Validation Criteria에 동일 항목으로 포함 |

## Related

- ADR-0001 (`docs/architecture/adr-0001-html5-local-save-sync.md`) — 동일하게 웹 익스포트 플랫폼 제약을 다루는 Foundation 레이어 ADR(직접 의존관계는 없음).
- `design/gdd/씬-관리.md` — Core Rule 1, Formula ②, Open Questions #2/#4
- `docs/architecture/architecture.md` — Module Ownership(#19 FOUNDATION), Required ADRs #4
- `.claude/docs/technical-preferences.md` — Performance Budgets(60fps, 16.6ms 프레임 버짓)
