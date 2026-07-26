# Systems Index: 바람의 탑 (Wind Tower)

> **Status**: Approved
> **Created**: 2026-07-22
> **Last Updated**: 2026-07-22
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

바람의 탑은 브라우저 기반 턴제 로그라이트 JRPG다. 플레이어는 매 런 랜덤 생성 던전을 탐험하며 히든 동료를 발견하고, 발견한 동료는 영구적으로 해금되어 다음 런에도 사용 가능하다. 핵심 필라는 "발견의 기쁨 / 성장은 영원하다 / 솔로도 최강 / 전략 단순+조합 깊게" 네 가지이며, 시스템 설계의 모든 결정은 이 필라를 기준으로 판단한다. 총 23개 시스템이 Foundation → Core → Feature → Presentation → Polish 5개 레이어로 계층화되며, 의존성 순서대로 설계한다. 광고 수익 모델이 수익화의 핵심이므로 광고 통합은 MVP 범위에 포함된다.

---

## Systems Enumeration

| # | 시스템명 | 카테고리 | 우선순위 | 상태 | 설계 문서 | 의존 시스템 |
|---|----------|----------|----------|------|-----------|-------------|
| 1 | 턴제 전투 | Gameplay | MVP | Designed | design/gdd/턴제-전투.md | #6, #7, #12, #13, #10, #11, #15 |
| 2 | 랜덤 던전 | Gameplay | MVP | Designed | design/gdd/랜덤-던전.md | #13, #19, #11 |
| 3 | 동료 해금 | Progression | MVP | Designed | design/gdd/동료-해금.md | #10, #13, #14, #9 |
| 4 | 장비 | Economy | MVP | Designed | design/gdd/장비.md | #10, #13 |
| 5 | 클라우드 세이브 (inferred) | Persistence | Full Vision | Not Started | — | #17 |
| 6 | 전투 공식 | Core | MVP | Approved | design/gdd/전투-공식.md | #10, #11 |
| 7 | 적 AI | Gameplay | MVP | Designed | design/gdd/적-AI.md | #11, #6 |
| 8 | 시너지 | Gameplay | Vertical Slice | Not Started | — | #10, #6 |
| 9 | 히든 트리거 | Gameplay | MVP | Designed | design/gdd/히든-트리거.md | #13, #10 |
| 10 | 동료 데이터 | Core | MVP | Approved | design/gdd/동료-데이터.md | (없음) |
| 11 | 적 데이터 | Core | MVP | Approved | design/gdd/적-데이터.md | (없음) |
| 12 | 상태이상 | Gameplay | MVP | Designed | design/gdd/상태이상.md | #6 |
| 13 | 런 상태 관리 | Core | MVP | Designed | design/gdd/런-상태-관리.md | #19 |
| 14 | 영구 진행 | Progression | MVP | Designed | design/gdd/영구-진행.md | #13, #17, #10 |
| 15 | 파티 구성 | Gameplay | MVP | Designed | design/gdd/파티-구성.md | #10, #13 |
| 16 | 런 결과 | Progression | MVP | Designed | design/gdd/런-결과.md | #13, #14 |
| 17 | 로컬 세이브 | Persistence | MVP | Approved | design/gdd/로컬-세이브.md | (없음) |
| 18 | 광고 통합 (inferred) | Meta | MVP | Designed | design/gdd/광고-통합.md | #19 |
| 19 | 씬 관리 | Core | MVP | Approved | design/gdd/씬-관리.md | (없음) |
| 20 | UI/HUD | UI | MVP | Designed | design/gdd/UI-HUD.md | #1, #13, #14, #15 |
| 21 | 오디오 | Audio | Vertical Slice | Not Started | — | #19 |
| 22 | 동료 내러티브 (inferred) | Narrative | Alpha | Not Started | — | #10, #3 |
| 23 | 설정 (inferred) | Meta | Alpha | Not Started | — | #17, #19 |

---

## Categories

| 카테고리 | 설명 | 해당 시스템 |
|----------|------|-------------|
| **Core** | 모든 것이 의존하는 기반 시스템 | #10 동료 데이터, #11 적 데이터, #13 런 상태 관리, #19 씬 관리, #6 전투 공식 |
| **Gameplay** | 게임을 재미있게 만드는 시스템 | #1 턴제 전투, #2 랜덤 던전, #7 적 AI, #8 시너지, #9 히든 트리거, #12 상태이상, #15 파티 구성 |
| **Progression** | 플레이어 성장과 진행 | #3 동료 해금, #14 영구 진행, #16 런 결과 |
| **Economy** | 자원 획득과 소비 | #4 장비 |
| **Persistence** | 저장과 연속성 | #17 로컬 세이브, #5 클라우드 세이브 |
| **UI** | 플레이어 정보 표시 | #20 UI/HUD |
| **Audio** | 사운드와 음악 | #21 오디오 |
| **Narrative** | 스토리와 대화 | #22 동료 내러티브 |
| **Meta** | 게임 루프 외부 시스템 | #18 광고 통합, #23 설정 |

---

## Priority Tiers

| 티어 | 정의 | 목표 마일스톤 | 설계 우선도 |
|------|------|---------------|-------------|
| **MVP** | 핵심 루프가 동작하는 데 필수. 없으면 "재미있는가?" 검증 불가 | 브라우저 초기 론치 | 최우선 설계 |
| **Vertical Slice** | 완전하고 폴리시된 한 영역의 경험. 전체 게임 느낌 시연 가능 | 시연 빌드 | 두 번째 설계 |
| **Alpha** | 모든 기능 러프하게 완성. 완전한 기계적 스코프, 콘텐츠 미완성 OK | Alpha 마일스톤 | 세 번째 설계 |
| **Full Vision** | 폴리시, 엣지 케이스, 있으면 좋은 기능 | Beta / 릴리스 | 필요 시 설계 |

---

## Dependency Map

### Foundation Layer (의존성 없음)

1. **#10 동료 데이터** — 동료의 스탯·스킬·해금 조건 데이터 구조. 9개 이상 시스템의 기반
2. **#11 적 데이터** — 적의 스탯·AI 행동·보상 데이터 구조. 전투 밸런스의 기준점
3. **#17 로컬 세이브** — 파일 저장/불러오기 기반 레이어. 영구 진행의 전제 조건
4. **#19 씬 관리** — 던전·전투·메인메뉴 씬 전환 및 웹 내보내기 기반

### Core Layer (Foundation에 의존)

1. **#6 전투 공식** — 데미지·방어·스킬 효과 수식 → #10 동료 데이터, #11 적 데이터
2. **#7 적 AI** — 적 행동 패턴·우선순위 결정 → #11 적 데이터, #6 전투 공식
3. **#12 상태이상** — 기절·독·버프/디버프 효과 → #6 전투 공식
4. **#13 런 상태 관리** — 현재 런의 생명주기 추적 → #19 씬 관리
5. **#14 영구 진행** — 런 간 해금 상태 영속화 → #13 런 상태 관리, #17 로컬 세이브, #10 동료 데이터

### Feature Layer (Core에 의존)

1. **#1 턴제 전투** — 턴 순서·공격·스킬·도망 로직 → #6, #7, #12, #13, #10, #11, #15
2. **#2 랜덤 던전** — 절차적 던전 레이아웃 생성 → #13 런 상태 관리, #19 씬 관리, #11 적 데이터 (방 유형별 적 스폰)
3. **#3 동료 해금** — 히든 동료 발견 및 영구 등록 → #10, #13, #14, #9
4. **#4 장비** — 장비 슬롯·능력치 보정·드롭 → #10 동료 데이터, #13 런 상태 관리
5. **#8 시너지** — 동료 조합 보너스 계산 → #10 동료 데이터, #6 전투 공식
6. **#9 히든 트리거** — 히든방·히든동료 발생 조건 평가 → #13 런 상태 관리, #10 동료 데이터
7. **#15 파티 구성** — 동료 선택·파티 편성 UI → #10 동료 데이터, #13 런 상태 관리
8. **#16 런 결과** — 런 종료 화면·해금 기록 → #13 런 상태 관리, #14 영구 진행

### Presentation Layer (Feature에 의존)

1. **#20 UI/HUD** — 전투 HUD·던전 탐색 UI·터치 인터페이스 → #1, #13, #14, #15
2. **#21 오디오** — 전투 SFX·BGM·환경음 → #19 씬 관리
3. **#22 동료 내러티브** — 동료 배경스토리·만남 대사 → #10 동료 데이터, #3 동료 해금

### Polish Layer (전체에 의존)

1. **#18 광고 통합** — 웹 광고 SDK 연동·노출 타이밍 → #19 씬 관리
2. **#5 클라우드 세이브** — Firebase 동기화·크로스 플랫폼 저장 → #17 로컬 세이브
3. **#23 설정** — 볼륨·언어 등 사용자 환경설정 → #17 로컬 세이브, #19 씬 관리

---

## Recommended Design Order

| 순서 | 시스템 | 우선순위 | 레이어 | 에이전트 | 예상 노력 |
|------|--------|----------|--------|----------|-----------|
| 1 | #10 동료 데이터 | MVP | Foundation | game-designer + systems-designer | M |
| 2 | #11 적 데이터 | MVP | Foundation | game-designer + systems-designer | S |
| 3 | #17 로컬 세이브 | MVP | Foundation | game-designer + technical-director | S |
| 4 | #19 씬 관리 | MVP | Foundation | game-designer + godot-specialist | S |
| 5 | #6 전투 공식 | MVP | Core | systems-designer | M |
| 6 | #7 적 AI | MVP | Core | game-designer + ai-programmer | M |
| 7 | #12 상태이상 | MVP | Core | systems-designer | S |
| 8 | #13 런 상태 관리 | MVP | Core | game-designer + systems-designer | S |
| 9 | #14 영구 진행 | MVP | Core | game-designer | S |
| 10 | #1 턴제 전투 | MVP | Feature | game-designer + systems-designer | L |
| 11 | #2 랜덤 던전 | MVP | Feature | game-designer + godot-specialist | M |
| 12 | #3 동료 해금 | MVP | Feature | game-designer | M |
| 13 | #4 장비 | MVP | Feature | economy-designer | S |
| 14 | #9 히든 트리거 | MVP | Feature | game-designer | S |
| 15 | #15 파티 구성 | MVP | Feature | game-designer + ux-designer | S |
| 16 | #16 런 결과 | MVP | Feature | game-designer | S |
| 17 | #20 UI/HUD | MVP | Presentation | ux-designer + game-designer | M |
| 18 | #18 광고 통합 | MVP | Polish | technical-director | S |
| 19 | #8 시너지 | Vertical Slice | Feature | systems-designer | M |
| 20 | #21 오디오 | Vertical Slice | Presentation | audio-director | M |
| 21 | #22 동료 내러티브 | Alpha | Presentation | narrative-director + writer | L |
| 22 | #23 설정 | Alpha | Polish | ux-designer | S |
| 23 | #5 클라우드 세이브 | Full Vision | Polish | technical-director | M |

> 노력 예상: S = 1세션, M = 2~3세션, L = 4세션+

---

## Circular Dependencies

- **없음** — 모든 의존성이 단방향(Foundation → Core → Feature → Presentation → Polish) 흐름을 따름

---

## High-Risk Systems

| 시스템 | 위험 유형 | 위험 설명 | 완화 방안 |
|--------|-----------|-----------|-----------|
| #10 동료 데이터 | Design + Scope | 9개 이상 시스템이 의존하는 병목. 데이터 구조 변경 시 연쇄 수정 발생 | 첫 번째 GDD 설계 대상. /prototype 전에 데이터 스키마 확정 |
| #13 런 상태 관리 | Technical | 5개 이상 시스템이 동시 참조. 레이스 컨디션·상태 불일치 위험 | GDScript 싱글톤 패턴 vs 씬 기반 상태 중 구조적 결정 필요 |
| #6 전투 공식 | Design | 밸런스 기준점. 공식이 잘못되면 모든 전투 콘텐츠 재작업 | /prototype 에서 공식 MVP 버전 조기 검증 필수 |
| #14 영구 진행 | Technical | 웹 브라우저 환경의 로컬 저장 제한(IndexedDB/LocalStorage 크기). 브라우저 캐시 초기화 시 데이터 소실 위험 | 로컬 세이브 시스템과 함께 웹 환경 저장 한계 설계 시 명시 |

---

## Progress Tracker

| 지표 | 수치 |
|------|------|
| 총 식별 시스템 수 | 23 |
| 설계 문서 시작됨 | 18 |
| 설계 문서 검토 완료 | 5 |
| 설계 문서 승인됨 | 5 |
| MVP 시스템 설계 완료 | 18 / 18 |
| Vertical Slice 시스템 설계 완료 | 0 / 2 |

---

## Next Steps

- [x] 시스템 목록 검토 및 승인
- [x] 의존성 순서 확정
- [x] 우선순위 티어 배정
- [ ] `/design-system 동료-데이터` — 첫 번째 GDD 설계 시작 (설계 순서 #1)
- [ ] `/design-review` — 각 GDD 완성 후 검토
- [ ] `/prototype roguelite-core` — 전투 공식·동료 해금 핵심 루프 조기 검증
- [ ] `/gate-check pre-production` — MVP GDD 전체 완성 후 다음 단계 진입
