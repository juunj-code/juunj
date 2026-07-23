# Session State — 바람의 탑 (Wind Tower)

**Last Updated**: 2026-07-24
**Stage**: Concept → Systems Design

## Current Task

로컬-세이브 GDD 완료 (design/gdd/로컬-세이브.md) — 8개 필수 섹션 + Visual/Audio, UI Requirements, Open Questions 전부 작성됨. qa-lead 검토된 Acceptance Criteria 22개. entities.yaml에 세이브 운영 상수 6개 등록. systems-index.md 갱신 완료 (MVP 설계 완료 3/18).

## Progress Checklist

- [x] /start 온보딩 완료 (review-mode: lean)
- [x] /brainstorm 완료 → design/gdd/game-concept.md
- [x] /setup-engine 완료 → Godot 4.6 / GDScript
- [x] /art-bible 섹션 1-4 완료 → design/art/art-bible.md (섹션 5-9 미완)
- [x] /map-systems 완료 → design/gdd/systems-index.md (23개 시스템)
- [x] /design-system 동료-데이터 (설계 순서 #1) → design/gdd/동료-데이터.md (Designed)
- [x] /design-system 적-데이터 (설계 순서 #2) → design/gdd/적-데이터.md (Designed)
- [x] /design-system 로컬-세이브 (설계 순서 #3) → design/gdd/로컬-세이브.md (Designed)
- [ ] /design-system 씬-관리 (설계 순서 #4, 다음 차례)
- [ ] /prototype roguelite-core (전투 공식 조기 검증)

## Key Decisions

- Engine: Godot 4.6 / GDScript (vibe coding 최적화)
- Platform: 브라우저 (PC + 모바일) → iOS/Android 앱 (Phase 2)
- Monetization: 웹 광고 (매우중요) → AdMob (Phase 2)
- Review Mode: lean (디렉터는 /gate-check에서만)
- Save: 로컬 세이브 (MVP) → Firebase 클라우드 (Full Vision)
- Visual Identity: "어두운 세계 안에서, 동료만이 빛을 가진다"
- 적 스탯은 동료 스탯보다 개체당 약체 (그룹전 리듬), 보스는 동료 상한 초과 (격 체감)
- 로컬 세이브는 범용 섹션 키 저장 인프라(스키마 모름) — 원자적 쓰기, 5초 타임아웃, 최대 3회 시도(16.5초 상한), 256KB 하드캡
- 로컬 세이브의 HTML5 웹 익스포트 저장 동기화 동작은 미검증 리스크로 아키텍처 단계에 이월(→ ADR)

## Files in Progress

| 파일 | 상태 | 메모 |
|------|------|------|
| design/gdd/game-concept.md | 완료 | 브라우저 로그라이트 JRPG 개념 문서 |
| design/art/art-bible.md | 섹션 1-4 완료 | 섹션 5-9 (캐릭터/환경/UI/에셋 기준/레퍼런스) 미완 |
| design/gdd/systems-index.md | 완료 | 23개 시스템, 의존성 맵, 설계 순서 |
| design/gdd/동료-데이터.md | 완료 (Designed) | 8개 필수 섹션 + Acceptance Criteria + Open Questions |
| design/gdd/적-데이터.md | 완료 (Designed) | 8개 필수 섹션 + Visual/Audio + UI + Open Questions, qa-lead 검토 |
| design/gdd/로컬-세이브.md | 완료 (Designed) | 8개 필수 섹션 + Visual/Audio + UI(UX Flag) + Open Questions, qa-lead 검토 |
| design/registry/entities.yaml | 완료 | 동료 5개 + 적 9개 + 세이브 6개 = constants 20개 |
| .claude/docs/technical-preferences.md | 완료 | Godot 4.6 설정 |
| CLAUDE.md | 완료 | 엔진 스택 업데이트 |

## Open Questions

- 아트 바이블 섹션 5-9는 언제 작성? (개별 GDD 설계 전 or 후)
- /prototype을 GDD 설계 전에 먼저 실행? (전투 공식 조기 검증)
- 적-데이터 GDD Open Questions 3건 (보스 스프라이트 컨셉명, 일반 적 3종 스킬 내용, 아트 바이블 섹션 5-9 의존)
- 로컬-세이브 GDD Open Questions 4건 (schema_version 마이그레이션, HTML5 저장 동기화 미검증 리스크(→ADR 필수), 저장 실패 UX 카피, 클라우드 세이브 충돌 정책)

## Next Session Entry Point

`/design-system 씬-관리`로 설계 순서 #4 (#19 씬 관리) 진행 권장.
또는 `/consistency-check`로 로컬-세이브 registry 값 충돌 여부 확인.
또는 `/prototype roguelite-core`로 전투 루프 조기 검증 가능.

<!-- CONSISTENCY-CHECK: 2026-07-23 | GDDs checked: 2 | Conflicts found: 0 | Verdict: PASS -->
