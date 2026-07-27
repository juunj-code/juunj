# Session State — 바람의 탑 (Wind Tower)

**Last Updated**: 2026-07-27
**Stage**: Architecture review 완료, ADR 5/12 Accepted → Godot 프로젝트 생성됨, 코드 착수 준비 중

## Current Task

`/architecture-review` 완료(Verdict: CONCERNS, 블로킹 없음) → ADR 5개 Accepted(0002/0005/0006/0007/0011) → Godot 4.7.1 프로젝트 생성 및 스캐폴딩 완료 → ADR-0011 터치 스모크 테스트 PASS. 남은 것: ADR-0001/0003/0004(Foundation) 실브라우저 검증, `/test-setup`, `/ux-design`.

## Progress Checklist

- [x] /start 온보딩 완료 (review-mode: lean)
- [x] /brainstorm 완료 → design/gdd/game-concept.md
- [x] /setup-engine 완료 → Godot 4.6 / GDScript
- [x] /map-systems 완료 → design/gdd/systems-index.md (23개 시스템)
- [x] MVP 18개 GDD 작성 완료
- [x] MVP 18개 GDD design-review 완료 및 승인 (systems-index.md 18/18 Approved)
- [x] /create-architecture 완료 → docs/architecture/architecture.md v1.0 (TD APPROVED WITH CONDITIONS)
- [x] /prototype-fast 완료 → prototypes/combat-core/ (throwaway) — 공식/턴루프 KEEP, 보스 스탯 밸런스 REFACTOR 신호 발견(솔로 보스전 500/0 패배)
- [x] ADR-0001~0012 전부 작성 완료 (전부 Status: Proposed) — 아래 "Required ADRs" 참조
- [x] `/architecture-review` 완료 (2026-07-27, 새 세션) — Verdict: CONCERNS, 리포트: `docs/architecture/architecture-review-2026-07-27.md`
- [x] ADR Accepted 전환 4/7 완료 (2026-07-27): **0002, 0005, 0006, 0007 → Accepted** (검증 이슈 없음). **0001, 0003, 0004는 Proposed로 보류** — 실브라우저/실기기 검증 전까지 (ADR 자체가 명시). ADR-0011(#20 UI/HUD 터치)도 동일 사유로 Proposed 보류.
- [x] 폴더 스캐폴딩 완료 (2026-07-27): `assets/{art,audio,vfx,shaders,data/{companions,enemies,skills,status_effects}}`, `tests/{unit,integration,performance,playtest}`, `tools/` — 전부 `.gitkeep`만 있는 빈 디렉토리
- [x] `project.godot` 생성 완료 (2026-07-27) — 사용자가 New Project 마법사로 생성, Renderer=Compatibility(GL Compatibility) 확인됨. 프로젝트가 `바람의탑/` 하위 폴더에 생성돼 루트로 이동 처리(`project.godot`, `icon.svg`, `.godot/` 등 → 저장소 루트). 빈 `바람의탑/` 폴더는 Godot 에디터가 잠그고 있어 삭제 실패 — 에디터를 새 경로(`C:\Users\junjj\projects\juunj`)로 재오픈하면 삭제 가능.
- [x] **엔진 버전 변경: 4.6 → 4.7** (2026-07-27) — 사용자가 실제 설치한 게 4.7이었음. 공식 4.6→4.7 마이그레이션 가이드 확인 결과, 이 프로젝트의 기존 ADR들이 의존하는 영역(JavaScriptBridge, 듀얼 포커스 UI, RNG, 정렬 안정성, floor/floori, duplicate())엔 문서화된 변경 없음 — ADR 재작업 불필요. 진짜 breaking change 3개는 `docs/engine-reference/godot/VERSION.md`에 기록(타입 리턴 상속, packed array setter, input device ID 상수). `CLAUDE.md`/`technical-preferences.md`의 Engine 필드도 4.7로 갱신.
- [ ] /test-setup (gate-check 전 필수)
- [ ] /ux-design (gate-check 전 필수)
- [ ] /review-all-gdds (선택 — 18개 전체 holistic 교차 일관성 패스)
- [ ] art-bible 섹션 5-9 작성 (섹션 1-4만 완료)
- [ ] 보스 스탯 밸런스 재검토 (prototype에서 발견 — 솔로 보스전 승률 0%, 장비 보정 미포함 기준)

## 전체 개발 진행률 스냅샷 (2026-07-26, 사용자 질의 응답 기록)

기획(GDD)은 MVP 기준 사실상 완료, 아키텍처 청사진도 완료. 하지만 전체 게임 개발 대비로는 **약 8~12%** 수준 — 실제 코드/에셋/테스트/엔진 프로젝트 자체가 전무한 상태(기획+아키텍처는 보통 전체 공수의 10~20%). 이 비율은 다음 마일스톤 진행에 따라 계속 갱신할 것.

## Key Decisions

- Engine: Godot 4.7 (원래 4.6으로 스코핑, 실제 설치판이 4.7이라 핀 변경 — 영향 없음 확인됨) / GDScript (vibe coding 최적화)
- Platform: 브라우저 (PC + 모바일) → iOS/Android 앱 (Phase 2)
- Monetization: 웹 광고 (매우중요) → AdMob 등 후보, SDK 확정은 /create-architecture
- Review Mode: lean (디렉터는 /gate-check에서만) — 단, 이번 GDD 리뷰는 사용자 지시로 매 문서 풀 스페셜리스트 강도 유지
- Save: 로컬 세이브 (MVP) → Firebase 클라우드 (Full Vision)
- Visual Identity: "어두운 세계 안에서, 동료만이 빛을 가진다"
- 적 스탯은 동료 스탯보다 개체당 약체 (그룹전 리듬), 보스는 동료 상한 초과 (격 체감)
- MVP 던전 구조: 3층 고정, 층당 방 선형 진행(분기 없음), 히든방 런당 최소 1개 보장
- MVP 동료 풀: 기본 1 + 히든 3 = 총 4명
- 전투 스킬 배율: 동료 최대 2.0배, 적 최대 1.4배 (인스타킬 방지를 위해 리뷰 중 분리)

## GDD 리뷰 파이프라인 회고 (2026-07-26 완료)

18개 문서 전부 review-design 스킬 프로세스(의존성 그래프 검증 → 완결성 체크 → 스페셜리스트 병렬 리뷰 → creative-director synthesis)로 검토, 발견 즉시 수정 후 커밋. 반복적으로 발견된 이슈 패턴 (향후 설계 작업 시 재확인 권장):
- **소유권 경계 위반**: Acceptance Criteria가 자신이 소유하지 않은 다른 시스템의 렌더링/로직을 검증 대상으로 삼는 경우 — 전체 리뷰에서 가장 빈번한 발견.
- **낡은 예시 공식**: 기본 공격 공식(atk-def)으로 스킬 데미지 위협을 서술 — 실제로는 스킬 공식(floor(atk*mult)-def) 사용해야 함. `.claude/docs/coding-standards.md`에 영구 규칙으로 등록됨.
- **팬텀 API/필드 참조**: 문서가 실제로 존재하지 않는 다른 시스템의 메서드나 필드를 인용 (예: #20의 `room_index`가 #13에 없었음, #18의 JS 콜백 배선 누락).
- **양방향 의존성 누락**: A가 B에 의존한다고 썼는데 B의 Downstream Dependents에는 A가 빠진 경우 — 여러 문서에서 반복 발견, 발견 즉시 양쪽 다 수정.

## Files in Progress

| 파일 | 상태 | 메모 |
|------|------|------|
| design/gdd/systems-index.md | 완료 | 18/18 MVP GDD Approved |
| design/gdd/*.md (18개) | 완료 (Approved) | 전부 design-review 완료, 발견 이슈 수정 반영 |
| docs/architecture/architecture.md | **완료 v1.0** | Phase 0~8 전체, TD APPROVED WITH CONDITIONS |
| docs/architecture/adr-0001~0012-*.md | **완료, 5/12 Accepted** | 0002/0005/0006/0007/0011 Accepted, 나머지 Proposed (아래 참조) |
| prototypes/combat-core/ | 완료 (throwaway) | 전투 공식 페이싱 검증 — README.md에 판정 기록 |
| design/gdd/런-상태-관리.md | 추가 갱신 | ADR-0005 반영 — `_run_rng` 필드 추가, `reset()`/`start_run()`/AC8b 동기화 |
| design/art/art-bible.md | 섹션 1-4 완료 | 섹션 5-9 미완 |
| .claude/docs/coding-standards.md | 갱신됨 | 스킬 데미지 공식 규칙 추가 |

## ADR 목록 (전부 작성 완료, 5/12 Accepted — 0002/0005/0006/0007/0011)

**Foundation (Accepted 전환 최우선, 구현 시작 전 필수):**
1. `adr-0001-html5-local-save-sync.md` — IndexedDB durable sync를 `FS.syncfs()`+JS 콜백 브릿지로 확인하는 방식 채택 (⚠️HIGH, 실제 4.6 빌드 검증 필요)
2. `adr-0002-autoload-init-order-signal-catalog.md` — Autoload 부팅 순서 확정 + RunManager 시그널 카탈로그(대부분 "미확정 구독자"로 정직하게 표시됨)
3. `adr-0003-js-ad-bridge.md` — JS↔GDScript 콜백 브릿지 패턴 표준화 (⚠️HIGH, 엔진 레퍼런스에 JavaScriptBridge 문서 자체가 없다는 갭 발견)
4. `adr-0004-scene-threaded-loading-coop-coep.md` — Regular(비스레드) 익스포트를 안전한 기본값으로 채택, Threads+COOP/COEP는 itch.io 검증 후 재검토 (⚠️HIGH)
5. `adr-0005-rng-injection-pattern.md` — `RunManager._run_rng` 하나를 런 전체에 주입하는 패턴 (GDD에도 반영 완료)
6. `adr-0006-data-registry-shared-utility.md` — `DataRegistryLoader` 공유 유틸 + 별도 빌드타임 검증 도구
7. `adr-0007-resource-schema-buildtime-validation.md` — Resource 스키마 컨벤션 + 빌드타임 검증 도구 상세 (ADR-0006 의존)

**Core:** 8. `adr-0008-combat-formula-float-sort-stability.md` — floori+엡실론, 안정 정렬 이슈를 프로젝트 전역 규칙으로 고정 · 9. `adr-0009-resource-duplication-policy.md` — StatusEffect는 얕은 `duplicate()`로 충분함을 근거와 함께 결론

**Feature/UI:** 10. `adr-0010-await-coroutine-pattern.md` — `await` 패턴 표준화 + `is_inside_tree()` 가드 · 11. `adr-0011-dual-focus-ui-strategy.md` — 듀얼 포커스 대응, 엔진 레퍼런스에 상세 미기재를 정직하게 갭으로 표시하고 구현 전 실측 프로세스를 의무화 (⚠️HIGH, `#20` 구현을 블록함) · 12. `adr-0012-ui-signal-subscription-convention.md` — 폴링 금지 컨벤션 공식화

`docs/CLAUDE.md`의 ADR 라이프사이클 규칙상 Foundation 7개(1~7)가 Accepted 되기 전에는 구현 착수 금지 — 현재 4/7 Accepted(0002/0005/0006/0007), 0001/0003/0004는 실브라우저 검증 전까지 Proposed 보류.

## Open Questions

- ADR-0001/0003/0004 (전부 ⚠️HIGH) — 문서상 결정은 내려졌으나 실제 브라우저/기기로 검증된 적 없음. 각 ADR의 "Verification Required" 항목이 실제 구현 전 필수 체크리스트. (ADR-0011은 2026-07-27 실측 완료, Accepted로 전환됨 — 더 이상 미해결 아님.)
- 광고 SDK 구체 선택 (AdSense/AdMob Web/파트너) — ADR-0003에서 패턴은 정했지만 SDK 자체는 미선택.
- 런-결과: 메인메뉴 전환 광고 게이트 배치가 "실패해도 남는 것" 판타지와 다소 긴장 관계 — 재도전 기능 설계 시 재검토.
- 파티 구성: 이전 파티 선택 유지 여부 (MVP: 초기화, Full Vision: 편의성 개선).
- **보스 스탯 밸런스** (prototype에서 신규 발견) — 장비 보정 없이 순수 스탯만으로는 솔로 보스전 승률 0% (500회 시뮬레이션). GDD를 재승인할 정도의 버그는 아니나 실제 구현 전 밸런스 담당자 재검토 필요.

## Session Extract — ADR-0011 터치 스모크 테스트 (2026-07-27)

- Godot 4.7.1 설치 확인 (`D:\claude\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe` — zip 압축 해제가 exe 이름과 동일한 폴더를 한 겹 더 만들어서 실제 실행파일은 그 안에 있음, 주의)
- `prototypes/touch-input-smoke/` 생성 — 헤드리스 CLI 시도(`Input.parse_input_event()`, `viewport.push_input()`)는 마우스 클릭조차 `gui_input`에 도달 못 함(터치 특정 문제 아니라 `--headless`가 GUI 입력 디스패치를 안 돌리는 한계) → 실제 에디터 F6 실행으로 전환, 사용자가 직접 탭/클릭 확인
- **결과: PASS 3/3** (Button.pressed 도달, grab_focus() 미사용 커스텀 하이라이트 정상 반응, 호버 전용 반응 없음 — 기본 테마 호버 틴트는 장식적 효과일 뿐)
- **ADR-0011 → Accepted 전환 완료** — `#20 UI/HUD` 스토리 착수 가능해짐

## Next Session Entry Point

남은 Foundation 3개(ADR-0001/0003/0004)는 실브라우저 검증(웹 export 후 실제 모바일 Safari/Chrome에서 저장 durability/광고 콜백 확인) 필요 — 이건 웹 export 설정 + 실기기/브라우저가 있어야 함. 그 다음 `/test-setup`, `/ux-design`.

## Session Extract — /architecture-review 2026-07-27

- Verdict: CONCERNS
- Requirements: 38 TR-ID citations found across 12 ADRs — 24 covered, 14 partial (self-flagged pending real-device/browser verification); 0 gaps at Foundation/Core layer
- New TR-IDs registered: 36 (see `docs/architecture/tr-registry.yaml`)
- GDD revision flags: UI-HUD.md (신호 vs 프로퍼티 읽기 모호), 로컬-세이브.md (2단계 durability AC 누락) — 아직 GDD 자체는 수정 안 함
- Top ADR gaps: 없음 (신규 ADR 불필요)
- **버그 발견 및 즉시 수정**: ADR-0006 ↔ ADR-0007 의존성 방향 모순 — ADR-0007 "Depends On"을 None으로, ADR-0006을 "depends on ADR-0007"로 수정
- `docs/registry/architecture.yaml`, `docs/architecture/tr-registry.yaml` 최초 소급 채우기 완료 (둘 다 이전엔 빈 템플릿이었음)
- Report: `docs/architecture/architecture-review-2026-07-27.md`
