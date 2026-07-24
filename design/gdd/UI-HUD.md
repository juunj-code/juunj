# UI/HUD

> **Status**: In Design
> **Author**: 사용자 + Claude Code
> **Last Updated**: 2026-07-24
> **Implements Pillar**: (전체 필라 지원 — 정보 표시·입력 인터페이스)
> **Creative Director Review**: Skipped — Lean 모드

## Overview

UI/HUD 시스템은 게임 내 모든 정보 표시와 플레이어 입력 UI를 소유하는 Presentation 레이어 시스템이다. 각 씬의 CanvasLayer 또는 Control 노드로 구현되며, 하위 시스템의 신호를 구독해 상태를 실시간 갱신한다. 이 시스템은 데이터를 소유하지 않는다 — 모든 데이터는 #1 턴제 전투·#13 RunManager·#14 영구 진행·#15 파티 구성·기타 신호로부터 읽는다. 씬별로 책임 범위가 구분되며, 각 씬의 UI는 해당 씬 스크립트 또는 별도 HUD 씬으로 관리된다.

## Player Fantasy

정보가 필요할 때 항상 보이고, 입력은 탭 두 번이면 충분하다. 화면이 정보로 가득 차지 않으면서도 필요한 것은 다 있다.

## Detailed Design

### 씬별 UI 구성

#### S-04 DungeonExplorationScreen (던전 탐색)

| UI 요소 | 내용 | 데이터 소스 |
|---------|------|-------------|
| 현재 층/방 표시 | "2층 · 2번 방" | RunManager.current_floor, room_index |
| 이동 버튼 | "다음 방으로" — 방 클리어 후 활성 | RunManager.state |
| 파티 HP 요약 | 동료별 HP 바 (소형) | RunManager.party |
| 히든방 발견 팝업 | 동료 초상화 + 이름 + "동료가 되었다!" + 확인 버튼 | #3 동료 해금 신호 |
| 이미 해금 팝업 | "이미 동료가 되어 있어요" 텍스트 + 확인 버튼 | #9 히든 트리거 신호 |
| 아이템 드롭 팝업 | 아이템 이름 + 스탯 + 확인 버튼 | #4 장비 신호 |

#### S-05 BattleScreen (전투 화면)

| UI 요소 | 내용 | 데이터 소스 |
|---------|------|-------------|
| 파티 HP 바 | 동료별 HP 바 (수치 표시) | #1 턴제 전투 신호 |
| 파티 SP 표시 | SP 점 ●●○○○ (0~5) | #1 턴제 전투 신호 |
| 적 HP 바 | 적별 HP 바 | #1 턴제 전투 신호 |
| 보스 HP 바 | 별도 대형 HP 바 (is_boss=true 시) | #1 턴제 전투 신호 |
| 액션 버튼 | [기본 공격] [스킬명 (SP비용)] | #1 player_input_requested 신호 |
| 스킬 버튼 비활성 | SP < cost_sp 시 그레이아웃 + 비탭 | #1 턴제 전투 신호 |
| 타겟 하이라이트 | 적 유닛 위 선택 표시 (탭 가능) | #1 player_input_requested 신호 |
| 상태이상 아이콘 | 각 유닛 옆 아이콘 + 잔여 턴 수 | #12 상태이상 |
| 현재 턴 표시 | "○○의 턴" 텍스트 | #1 turn_started 신호 |

#### S-03 PartySelectScreen (파티 구성)

→ `#15 파티 구성` GDD의 UI Requirements 참조.

#### S-06 RunResultScreen (런 결과)

→ `#16 런 결과` GDD의 UI Requirements 참조.

### 신호 구독 목록

| 발신자 | 신호 | UI 반응 |
|--------|------|---------|
| #1 턴제 전투 | `unit_hp_changed(unit_id, new_hp)` | HP 바 즉시 갱신 |
| #1 턴제 전투 | `unit_sp_changed(unit_id, new_sp)` | SP 점 갱신 |
| #1 턴제 전투 | `player_input_requested(companion_id)` | 액션 버튼 + 타겟 하이라이트 표시 |
| #1 턴제 전투 | `turn_started(unit_id)` | "○○의 턴" 텍스트 갱신 |
| #1 턴제 전투 | `status_effects_changed(unit_id, effects)` | 상태이상 아이콘 갱신 |
| #3 동료 해금 | `companion_unlocked_this_run(id, name, portrait_path)` | 히든방 발견 팝업 표시 |
| #9 히든 트리거 | `hidden_room_already_cleared(id)` | "이미 동료" 팝업 표시 |
| #4 장비 | `equipment_dropped(item_data)` | 아이템 드롭 팝업 표시 |

### Core Rules

1. **UI는 데이터를 소유하지 않는다**: 신호 수신 시 즉시 갱신. 상태 캐시 없음.
2. **팝업은 블로킹**: 팝업 표시 중 던전 이동 버튼·전투 액션 버튼 비활성.
3. **한 번에 팝업 하나**: 팝업 중첩 없음. 팝업이 이미 표시된 상태에서 다른 팝업 트리거가 오면 큐에 순서대로 저장 후 순차 표시.
4. **터치 최소 44×44px**: 모든 탭 가능 영역 최소 크기 준수.
5. **타겟 하이라이트는 모드 전용**: `player_input_requested` 신호 이후 액션 선택 완료 시만 적 탭 영역 활성.

## Formulas

수치 공식 없음.

**SP 점 표시 계산:**
```
filled_dots = current_sp
empty_dots = SP_MAX - current_sp  # SP_MAX = 5
표시: "●" × filled_dots + "○" × empty_dots
```

## Edge Cases

- **모든 적 처치 직후 UI 갱신**: `unit_hp_changed`로 적 HP 바가 0으로 갱신 → 전투 종료 씬 전환까지 수십ms 간 액션 버튼 활성 상태일 수 있음. #1 턴제 전투가 즉시 종료 처리하여 씬 전환 → UI 문제 없음.

- **팝업 중첩 (드롭 + 동료 발견 동시)**: 같은 방에서 아이템 드롭과 동료 발견이 동시에 발생하지 않도록 #2·#9·#4 시퀀스 보장. 만약 동시에 오면 팝업 큐로 순차 처리.

- **보스방 레이아웃 분기**: `is_boss=true` 방 진입 시 BattleScreen 내 보스 HP 바 레이아웃으로 전환. 같은 S-05 씬에서 조건부 분기.

- **SP 5가 넘는 경우**: #6 전투 공식이 SP를 SP_MAX=5로 클램핑하므로 표시는 항상 0~5 범위.

## Dependencies

### Upstream Dependencies

| 시스템 | 의존 유형 | 사용 |
|--------|-----------|------|
| #1 턴제 전투 | **Hard** | 전투 상태 신호 구독 |
| #13 런 상태 관리 | **Hard** | 현재 층/방, 파티 HP 요약 |
| #14 영구 진행 | **Hard** | 런 결과 화면 해금 진행도 |
| #15 파티 구성 | **Hard** | 파티 선택 UI 렌더링 |

### Downstream Dependents

없음 (최상위 Presentation 레이어).

## Tuning Knobs

| 조정값 | 현재 설정 | 안전 범위 | 설명 |
|--------|-----------|-----------|------|
| 팝업 닫기 방식 | 플레이어 탭 확인 | — | 자동 닫기 YAGNI |
| SP 표시 방식 | 점 (●/○) | — | 숫자 텍스트로 교체 가능 |
| 전투 애니메이션 블록 | 미블록 (즉시 입력 가능) | — | 피격 애니메이션 중 입력 블록은 `/ux-design`에서 결정 |
| 보스 HP 바 크기 | 대형 (일반 2배) | — | `/ux-design`에서 확정 |

## Visual/Audio Requirements

이 시스템이 모든 게임 내 시각 UI를 소유한다. 오디오는 #21 오디오가 신호를 구독해 SFX 재생.

## UI Requirements

이 시스템 자체가 UI 소유자다. 상세 레이아웃은 `/ux-design`에서 확정:
- 터치 최소 44×44px 전체 준수
- 모바일 세로 화면 기준 (브라우저)
- CanvasLayer(오버레이)로 씬 위에 렌더링

📌 **UX Flag**: 전투 화면에서 파티(하단)·적(상단)·액션 버튼(최하단) 레이아웃 배치는 `/ux-design`에서 확정.

## Acceptance Criteria

1. (HP 바 실시간 갱신) GIVEN 전투 중 동료 HP 감소 WHEN `unit_hp_changed` 신호 수신 THEN HP 바가 즉시 갱신된다.

2. (스킬 비활성) GIVEN SP=1, cost_sp=2 WHEN 액션 버튼 표시 THEN 스킬 버튼이 그레이아웃 + 비탭 상태.

3. (타겟 하이라이트) GIVEN `player_input_requested` 수신 후 액션 선택 완료 WHEN 적 유닛 확인 THEN 살아있는 적에 선택 하이라이트 표시.

4. (동료 발견 팝업) GIVEN `companion_unlocked_this_run` 신호 수신 WHEN 처리 THEN 동료 초상화·이름·"동료가 되었다!" 팝업 표시, 던전 이동 비활성.

5. (팝업 확인 후 해제) GIVEN 팝업 표시 중 WHEN "확인" 탭 THEN 팝업 닫힘 + 던전 이동 재활성.

6. (현재 층/방 표시) GIVEN current_floor=2, room_index=1 WHEN 던전 탐색 화면 THEN "2층 · 2번 방" 표시.

7. (SP 점 표시) GIVEN current_sp=2, SP_MAX=5 WHEN 파티 HP/SP 바 표시 THEN "●●○○○" 표시.

8. (상태이상 아이콘) GIVEN 동료에 poison(2) 활성 WHEN 전투 화면 THEN 해당 동료 옆 poison 아이콘 + "2" 표시.

## Open Questions

1. **전투 애니메이션 중 입력 블록** — 피격 SFX/애니메이션 재생 중 다음 입력 블록 여부. `/ux-design`에서 결정.
   - 담당: ux-designer | 해결 시점: `/ux-design`

2. **보스방 레이아웃** — 보스 HP 바 위치 및 크기. `/ux-design`에서 확정.
   - 담당: ux-designer | 해결 시점: `/ux-design`
