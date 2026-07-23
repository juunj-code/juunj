# Game Concept: 바람의 탑 (Wind Tower)

*Created: 2026-07-22*
*Status: Draft*

---

## Elevator Pitch

> 매 런마다 랜덤 생성 던전에서 히든 동료를 발견하고 영구 해금하는 브라우저 기반 턴제 로그라이트 JRPG.
> 런은 끝나도 동료는 남는다 — 당신만의 최강 파티는 한 번의 런으로 완성되지 않는다.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 로그라이트 JRPG (Turn-based Roguelite RPG) |
| **Platform** | 브라우저 (PC + 모바일 브라우저) → iOS/Android 앱 (2단계) |
| **Target Audience** | 수집/성장 JRPG 팬, 포케로그·로그라이크 유저, 짧은 세션을 원하는 모바일 게이머 |
| **Player Count** | 싱글플레이어 |
| **Session Length** | 10~20분 (런 1회) |
| **Monetization** | 광고 수익 (브라우저 웹 광고 → AdMob) |
| **Estimated Scope** | Medium (3~4개월, 출시 가능 버전 기준 / 풀 비전 5~6개월, 솔로 개발) |
| **Comparable Titles** | 포케로그, Slay the Spire, 소환사의 협곡 (클래식 바람의나라 싱글버전) |

---

## Core Fantasy

나만 아는 히든 동료로 최강 파티를 꾸렸다는 자신감.
솔로로 탑의 최고층까지 올라가는 것, 그리고 아무도 찾지 못한 비밀 동료를 처음 발견했을 때의 쾌감.
매 런마다 "오늘은 어떤 동료를 만날까"라는 기대감으로 게임을 켜게 된다.

---

## Unique Hook

포케로그처럼 반복 플레이하는데, AND ALSO 발견한 동료들이 영구 해금되어 내 로스터에 추가되고 동료마다 짧은 사연이 있어 애착이 생긴다.

히든 동료를 발견하는 것이 단순한 운이 아니라 — 탐색 의지와 패턴 파악의 결과다.

---

## Visual Identity Anchor

**방향명**: 어둠 속의 바람빛 (Wind Light in Darkness)

**핵심 규칙**: 어두운 던전 배경에 따뜻하고 선명한 동료 컬러로 강한 대비를 만든다.

**시각 원칙**:
1. **히든 단서 내재화** — 모든 히든 요소는 미세한 시각적 단서를 품는다 (살짝 빛나는 벽, 색이 다른 타일). 테스트: 힌트 없이도 주의 깊은 플레이어가 10% 확률로 발견할 수 있어야 한다.
2. **동료 합류 연출** — 동료 발견 시 화면에 색감이 살아나는 연출. 테스트: "아, 새 동료 얻었다"가 화면만 봐도 느껴지는가.
3. **바람의나라 오마주** — 16비트 픽셀아트, 탑뷰. 익숙한 감성 위에 새로운 구조.

**컬러 철학**: 던전은 청록·회색 톤. 동료들은 각자 고유한 warm 컬러 포인트(붉은색, 황금색, 보라색 등)로 개성 표현.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** | 6 | 전투 효과음, 히든 방 발견 연출, 픽셀아트 애니메이션 |
| **Fantasy** | 3 | "나만의 최강 파티" 판타지, 솔로 클리어의 성취감 |
| **Narrative** | 5 | 동료마다 1~2줄 사연, 이스터에그 스토리 힌트 |
| **Challenge** | 2 | 턴제 전략, 적 패턴 파악, 파티 시너지 탐구 |
| **Fellowship** | N/A | 싱글플레이 전용 |
| **Discovery** | 1 | 히든 방, 히든 동료, 이스터에그, 비밀 층 |
| **Expression** | 7 | 파티 구성 선택, 장비 조합 |
| **Submission** | 4 | 10~20분 짧은 세션, 실패해도 동료가 남는 구조 |

### Key Dynamics (Emergent player behaviors)

- 플레이어들이 "이 동료 어떻게 찾았어?"를 커뮤니티에서 공유하게 됨
- "이 파티 조합이 개사기다"를 발견하는 시너지 탐색 행동
- 히든 방을 찾기 위해 모든 벽을 두드리는 탐색 습관
- 새 런마다 다른 동료 조합을 실험하는 반복 플레이

### Core Mechanics (Systems we build)

1. **턴제 전투 시스템** — 파티원별 행동 선택, 적 AI 패턴, 시너지 발동
2. **랜덤 던전 생성** — 방 유형 조합 (전투방 / 히든방 / 휴식방 / 보스방)
3. **동료 수집 및 영구 해금 시스템** — 런 내 합류, 런 종료 후 영구 로스터 추가
4. **장비 시스템** — 런 내 임시 장비 습득, 클리어 보너스는 영구 강화에 반영
5. **클라우드 세이브** — Google 로그인 기반 크로스 플랫폼 동기화

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | 파티 구성 선택, 던전 경로 선택, 어떤 히든 방을 먼저 탐색할지 | Core |
| **Competence** | 적 패턴 학습, 시너지 발견, 더 깊은 층 도달 | Core |
| **Relatedness** | 동료 사연, 특정 캐릭터에 대한 애착 형성 | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — 동료 도감 완성, 히든 엔딩 달성, 최고층 클리어 기록
- [x] **Explorers** — 히든 방 발견, 이스터에그 수집, 시너지 연구
- [ ] **Socializers** — 해당 없음 (싱글플레이 전용)
- [ ] **Killers/Competitors** — 해당 없음

### Flow State Design

- **Onboarding curve**: 첫 런은 무조건 쉬운 던전 3층. 기본 동료 1명으로 시작, 전투 튜토리얼 인게임 텍스트로 1회.
- **Difficulty scaling**: 해금된 동료 수에 따라 적 강도 자동 조절. 동료가 많을수록 더 강한 적 조합 등장.
- **Feedback clarity**: 전투 결과 수치 표시, 히든 방 발견 시 특수 효과음 + 화면 효과, 동료 해금 시 연출.
- **Recovery from failure**: 실패해도 발견한 동료는 영구 해금 유지. "실패 = 성장"이 항상 느껴져야 한다.

---

## Core Loop

### Moment-to-Moment (30초)

방 입장 → 적 조우 → 파티원별 행동 선택 (공격 / 스킬 / 방어) → 결과 확인 → 다음 방 이동.
시너지 발동 시 화면 강조 연출.

### Short-Term (5~15분)

현재 층 전투방 클리어 → 분기점에서 경로 선택 → 히든 방 탐색 → 동료/장비 획득 → 미니보스 → 다음 층.
"히든 방이 어딘가 있을 것 같다"는 탐색 욕구가 5분 루프를 구동한다.

### Session-Level (10~20분)

런 완료 (성공 or 실패) → 이번 런에서 발견한 동료 영구 해금 확인 → **광고 자연 배치** → 다음 런 파티 구성 선택 → 시작.
실패해도 "오늘 ○○을 해금했다"로 세션이 마무리된다.

### Long-Term Progression

동료 로스터가 점점 채워짐 → 파티 조합 전략 깊어짐 → 새 동료로 더 깊은 층 도달 → 전체 동료 수집 = 히든 엔딩 해금.
"도감 완성"이 장기 목표.

### Retention Hooks

- **Curiosity**: "아직 못 찾은 히든 동료가 몇 명 더 있을까?" — 도감의 빈칸
- **Investment**: 해금된 동료 로스터, 최고 층수 기록
- **Social**: (1단계는 없음) 향후: 친구 기록 비교
- **Mastery**: 최적 파티 조합 연구, 노데스 런 달성

---

## Game Pillars

### Pillar 1: 발견의 기쁨

모든 런에 "나만 찾을 수 있는 것"이 숨겨져 있어야 한다.

*Design test*: 히든 방 추가(A) vs 일반 방 추가(B) — 항상 A를 선택한다. 콘텐츠 양보다 발견의 밀도가 우선이다.

### Pillar 2: 성장은 영원하다

런이 끝나도 발견한 동료는 사라지지 않는다. 플레이어는 항상 뭔가를 얻고 나온다.

*Design test*: 실패 후 플레이어가 "아깝다" 대신 "그래도 ○○ 해금했다"를 느껴야 한다.

### Pillar 3: 솔로도 최강이 될 수 있다

멀티플레이 없이도 게임 전체를 완전히 공략할 수 있다.

*Design test*: 모든 콘텐츠, 모든 히든 동료, 모든 엔딩이 혼자서 접근 가능한가?

### Pillar 4: 전략은 단순하게, 조합은 깊게

개별 전투는 누구나 이해할 수 있어야 하지만, 파티 조합은 파고들수록 깊어야 한다.

*Design test*: 처음 플레이어도 첫 런을 완료할 수 있는가? 100시간 플레이어도 최적 조합을 발견하는 재미가 있는가?

### Anti-Pillars (What This Game Is NOT)

- **NOT 멀티플레이**: 경쟁/협동 모드 추가 시 "솔로 최강" 판타지가 희석되고 개발 복잡도가 폭발적으로 증가한다.
- **NOT 가챠/뽑기**: 랜덤 과금 뽑기는 직접 발견하는 쾌감을 죽이고 유저 신뢰를 잃는다.
- **NOT 복잡한 스킬트리**: 3~6개월 첫 게임 스코프에서 깊은 스킬트리는 완성 불가능한 부채다.
- **NOT 장편 스토리**: 동료당 1~2줄 사연으로 충분하다. 텍스트 대작은 YAGNI.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| 포케로그 | 로그라이크 수집 구조, 반복 플레이 중독성 | 픽셀 JRPG 전투, 동료에 사연 추가 | 동일 타겟 유저에게 이미 검증된 공식 |
| Slay the Spire | 런 기반 로그라이트, 전략적 선택 | 카드 없이 파티 기반 턴제 전투 | 로그라이트 전략 레이어의 설계 원칙 |
| 바람의나라 | 탑뷰 픽셀아트 감성, 동료 수집 | 싱글플레이, 로그라이크 구조, 브라우저 기반 | 한국 유저에게 익숙한 미적 참조점 |

**비게임 영감**: 포켓몬 도감 완성 심리, 트레이딩카드 히든 레어 카드 발견의 쾌감.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 15~35세 |
| **Gaming experience** | Mid-core (매일 플레이하지만 하드코어 MMORPG는 아님) |
| **Time availability** | 하루 10~30분, 짧은 세션 선호 |
| **Platform preference** | 모바일 브라우저, PC 브라우저 |
| **Current games they play** | 포케로그, 리그오브레전드, 모바일 수집형 RPG |
| **What they're looking for** | 간단한데 전략적인 수집형 RPG, 진행이 영원히 사라지지 않는 로그라이크 |
| **What would turn them away** | 복잡한 조작, 긴 세션 강요, 과금 압박, 광고 과다 노출 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4 — 웹 내보내기 최고 수준, 무료, 동일 프로젝트에서 iOS/Android 내보내기 가능. 첫 게임에 진입장벽 가장 낮음. |
| **Key Technical Challenges** | 랜덤 던전 생성 품질 보장, 클라우드 세이브 백엔드 (Firebase 추천), 광고 SDK 연동 (브라우저→AdMob 순서) |
| **Art Style** | 16비트 픽셀아트, 탑뷰 |
| **Art Pipeline Complexity** | Low-Medium — 픽셀아트 에셋 + 턴 기반 전투 애니메이션 |
| **Audio Needs** | Moderate — 루프 배경음악(던전 분위기), 전투 효과음, 히든 발견 시 특수 사운드 |
| **Networking** | None (싱글플레이어, 클라우드 세이브는 Firebase REST API) |
| **Content Volume** | 동료 20명, 던전 3종, 장비 30종+, 플레이타임 약 5~10시간 (전체 동료 수집 기준) |
| **Procedural Systems** | 던전 층 랜덤 생성 — 미리 제작한 방 유형(전투/히든/휴식/보스)을 조합하는 방식 (완전 절차적 생성보다 제작 부담 낮음) |

---

## Risks and Open Questions

### Design Risks

- 완전 랜덤 던전에서 특정 런에 히든 방이 전혀 없는 경우 — 발견 욕구를 자극하지 못할 수 있음
- 동료 20명의 개성 있는 스킬/사연 설계에 창의성 소진 위험

### Technical Risks

- 랜덤 던전 생성이 "공정하고 재미있게" 느껴지도록 튜닝하기 어려움
- Godot 4 웹 내보내기 초기 로딩 시간 최적화 필요 (모바일 브라우저 특히)
- 클라우드 세이브 백엔드 초기 설정 부담 (Firebase Auth + Realtime DB)

### Market Risks

- 신규 브라우저 게임은 초기 광고 수익이 매우 낮음 — 유저 유입 없이는 광고 수익 미미
- 마케팅/홍보 채널 없이 유저 확보 어려움 (커뮤니티 빌딩 필요)

### Scope Risks

- 첫 게임으로 3~6개월 내 완성을 위한 엄격한 스코프 관리 필요
- "한 기능만 더" 심리로 MVP에서 못 멈추는 패턴 위험

### Open Questions

- 랜덤 던전: 방 조합 방식 vs 타일맵 절차적 생성? → MVP 프로토타입에서 검증
- 클라우드 세이브: Firebase vs Supabase vs 자체 구현? → Firebase 우선 (초보자 친화적)
- 광고 배치: 런 종료 외 추가 배치 (부활 보상형 광고?) → 유저 경험과의 균형 테스트 필요

---

## MVP Definition

**Core hypothesis**: 10~20분 런 구조에서 히든 동료를 발견하고 영구 해금하는 경험이 충분히 재미있어서 다음 런을 시작하게 만드는가?

**Required for MVP**:
1. 턴제 전투 — 공격 + 스킬 1개, 파티원 최대 3명
2. 3층 랜덤 던전 — 전투방/히든방/보스방 조합
3. 동료 4명 — 기본 동료 1명 + 히든 동료 3명
4. 런 종료 후 동료 영구 해금 표시
5. Godot 4 웹 내보내기로 브라우저 실행 가능

**Explicitly NOT in MVP**:
- 클라우드 세이브 (로컬 저장으로 시작)
- 광고 연동 (2단계)
- 동료 사연/대화 (텍스트 1줄로 대체)
- 장비 시스템 (기본 스탯만)
- 보상형 광고, 앱 버전

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 동료 4명, 던전 1종(3층) | 코어 전투 루프, 동료 해금 | 6~8주 |
| **Vertical Slice** | 동료 10명, 던전 2종 | 코어 + 장비 + 로컬 세이브 | 10~12주 |
| **Alpha (출시 가능)** | 동료 15명, 던전 2종, 광고 1개 | 브라우저 출시, 기본 광고 | 14~16주 |
| **Full Vision** | 동료 20명, 던전 3종, 히든 엔딩 2개 | 클라우드 세이브, AdMob, 앱 버전 | 20~24주 |

---

## Next Steps

- [ ] `/setup-engine` — Godot 4 엔진 설정 및 버전별 레퍼런스 문서 구성
- [ ] `/art-bible` — 시각 정체성 사양 작성 (GDD 작성 전에 완료할 것)
- [ ] `/prototype roguelite-core` — 코어 루프 프로토타입: 랜덤 던전 + 턴제 전투 + 동료 해금이 재미있는지 먼저 검증 (1~2주 throwaway 코드)
- [ ] 프로토타입 PROCEEDS → `/map-systems` — 시스템 분해 및 의존성 매핑
- [ ] `/design-system [system-name]` — 시스템별 GDD 작성
- [ ] `/create-architecture` — 마스터 아키텍처 블루프린트 생성
- [ ] `/gate-check` — 프리프로덕션 진입 전 단계 게이트 검증
