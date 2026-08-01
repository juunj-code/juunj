# Session State — 바람의 탑 (Wind Tower)

**Last Updated**: 2026-08-01
**Stage**: 코딩 착수 (design/architecture 문서는 참고자료, 게이트 아님 — [[project_juunj-scope-pivot]] 참조). 사용자가 커밋/다음 시스템 선택 등 코딩 단계 전반에 자율 진행 승인 ([[project_juunj-review-autonomy]] 참조, 2026-07-29 확장).

## Current Task

**동료 초상화 아트 배선 완료 (2026-08-01)**: 이전 세션 종료 시점엔 Higgsfield 크레딧 소진 + Gemini(nanobanana) 무료 쿼터 0으로 초상화 생성이 블록된 상태였음(`design/art/portrait-prompts.md`에 프롬프트만 저장, 커밋 `29602ad`). 이후 생성이 풀려 `design/art/portrait-prompts.md`에 고정해둔 프롬프트/컬러로 4개 동료 초상화(balance/dealer/support/tank) 전부 생성 → `assets/art/portraits/`에 저장, Godot import 완료. 각 동료 `.tres`의 `portrait_id`를 실제 경로로 채우고 `PartySelectScreen._build_roster()`가 로스터 버튼 아이콘으로 렌더하도록 배선(`icon_max_width=40`). 이 작업이 커밋 안 된 채 남아있던 걸 이번 세션에서 발견 → GUT 175/175 재확인 후 커밋(`7646249`). 함께 밀려있던 Godot 에디터 생성 `.gd.uid` 사이드카 9개도 동일 커밋에 포함(기존 트래킹 컨벤션과 일치).

**MVP 18/18 시스템 전부 구현 완료 (2026-07-31)** — #6 전투 공식 → #10 동료 데이터 → #11 적 데이터 → #7 적 AI → #12 상태이상 → #19 씬 관리(순수 로직) → #13 런 상태 관리 → #15 파티 구성 → #4 장비 → #17 로컬 세이브(동기 코어) → #14 영구 진행 → #16 런 결과 → #2 랜덤 던전 → #1 턴제 전투 → #9 히든 트리거 → #3 동료 해금 → #20 UI/HUD(순수 로직) → #19 SceneManager Node + 실제 화면 6개 → **#18 광고 통합(AdManager)**. **175/175 GUT 통과, 26개 커밋.**

**#18 구현 메모**: ADR-0003 패턴(사전 등록 콜백 + `_js_bridge` DI + 재진입 가드) 그대로 구현. 실제 GUT 헤드리스 검증을 위해 `_web_override` 시임을 하나 더 추가함 — GUT은 데스크톱 바이너리로 돌아가 `OS.has_feature("web")`이 항상 false라, 이 시임 없이는 GDD AC1/3/4/6/7이 검증하는 web 분기 자체에 진입할 방법이 없었음(ADR-0003/GDD 원문엔 이 갭이 명시돼 있지 않았음, 구현 중 발견). SDK 실선택(AdSense/AdMob/파트너)과 실브라우저 JS 검증은 여전히 미해결 — ADR-0003은 Proposed 유지(0001/0004와 동일 사유).
**부수 발견+수정**: `SceneManager.go_to()`가 `--headless`에서도 실제 Tween로 비동기 대기하고 있었음 — 보이는 창이 없는 CI/테스트 환경에서 이건 "몇 프레임 뒤 엉뚱한 테스트 도중에 재개되는 suspended coroutine"을 만들어냄. 이게 이전 세션에서 잡은 TurnBattle 행(hang)의 진짜 근본 원인이었고, 이번엔 같은 뿌리에서 새 증상(모든 동료가 죽은 상태로 `run_battle()`이 시작되면 적 턴에서 EnemyAI가 타겟 후보 0개로 크래시)이 발견됨. `_fade()`가 headless에서 즉시 완료되도록 수정 + `run_battle()`이 루프 진입 전에 승패를 먼저 확인하도록 수정 + `BattleScreen`/`DungeonExplorationScreen` 양쪽에 기대 상태(`IN_COMBAT`/`EXPLORING`) 아닐 때 로드를 무시하는 방어 가드 추가로 해결.

**2026-07-31 세션 요약 (화면 배선)**: `SceneManager` 오토로드(Tween 기반 fade/flash, ADR-0004에 따라 동기 씬 스왑) 및 `project.godot`의 `run/main_scene`을 `Boot.tscn`으로 설정. `TurnBattle`/`CompanionUnlock`에 #20 UI-HUD.md 신호 계약(`unit_hp_changed`/`unit_sp_changed`/`turn_started`/`player_input_requested`/`status_effects_changed`/`popup_confirmed`) 추가 — 이전 세션에서 순수 로직만 뽑아뒀던 `HudRules`/`HudPopupQueue`를 실제 `DungeonExplorationScreen`이 소비하도록 배선 완료. `BattleScreen`(S-05)이 `TurnBattle`을 직접 소유·구동(setup → run_battle, 버튼으로 submit_action/submit_target 전달)하고 `RunResultScreen`(S-06)은 `RunResult.build_display_data()`의 순수 렌더. 6개 화면 전부 연결되어 Boot→MainMenu→PartySelect→Dungeon→Battle→RunResult 풀 루프가 처음으로 실제로 플레이 가능한 상태.
**발견+수정한 버그 2건**: (1) `run_result_test.gd`의 `SceneManagerSpy`가 이제 진짜 오토로드로 존재하는 `SceneManager`와 이름이 겹쳐 `find_child` 탐색에서 항상 밀림 — 테스트 안에서 실제 오토로드를 잠깐 트리에서 빼고 spy로 교체하는 방식으로 수정. (2) `BattleScreen.tscn`이 실존하게 되자, 다른 테스트가 남긴 미완료 비동기 `SceneManager.go_to("S-05",...)`가 엉뚱한 테스트 프레임 도중에 완료되어 `RunManager.state=IDLE`인 채로 `BattleScreen._ready()`가 실행 → `TurnBattle.setup([], [])` → `run_battle()`의 `while true`가 빈 turn_order로 영원히 도는 행(hang) 발생, GUT 전체가 멈춤. `run_battle()`에 빈 turn_order 가드 추가(즉시 종료) + `BattleScreen._ready()`에 `RunManager.state != "IN_COMBAT"` 방어 가드 추가로 해결. 부수적으로 `scene_transition_rules.gd`의 선언된 전환 그래프에 `S-05→S-06`(전투 패배 시 결과 화면 직행) 엣지가 누락돼 있던 것도 발견해 추가.
**알려진 미완 항목 (게이트 아님)**: `PartySelectScreen`은 장비 슬롯 선택 UI 없이 무기/방어구 슬롯을 항상 빈 문자열로 시작(#4 스탯 보정 미적용); `BattleScreen`은 SP 수치를 표시하지 않음(`HudRules.sp_dots()`는 있지만 아직 미배선); AC8(상태이상 아이콘)도 아직 렌더 없음. 전부 "플레이 가능"엔 지장 없는 후속 폴리시 패스.

**#3 구현 메모**: `CompanionUnlock`(src/core/companion_unlock.gd, 오토로드)는 `HiddenTrigger.companion_discovered`를 구독해 #10 조회 → `RunManager.add_discovered_companion()`(이미 #13이 dedupe/state-guard를 갖고 있었음, 재사용) → FLASH 연출(디펜시브 `find_child("SceneManager")`, #19 미존재라 현재는 no-op) → `companion_unlocked_this_run` 신호 발신까지만 담당. GDD의 `await popup_confirmed`(팝업 닫힐 때까지 블로킹)는 스킵 — #20이 없어 검증 불가능하고 구 AC6이 이미 #20 스코프로 이관됨; #20 배선 시점에 추가. **부수 발견**: `CompanionUnlock`이 실제 오토로드로 상시 리스닝하게 되면서 `hidden_trigger_test.gd`가 `RunManager.state`를 EXPLORING으로 안 맞춰놨던 게 드러남(이전엔 리스너가 없어 무해했음) — `before_each()`에 `RunManager.state = "EXPLORING"` 추가해 수정.

**#20 구현 범위 결정**: #19 SceneManager Node와 동일한 이유(`S-03/04/05/06` .tscn 실 씬 파일이 하나도 없음)로 실제 Control/CanvasLayer/터치 UI Node 구현은 스킵 — 만들어도 헤드리스로 검증 불가능한 보일러플레이트일 뿐. 대신 AC 중 순수 로직/포맷팅으로 테스트 가능한 부분만 뽑아냄: `HudRules`(src/core/hud_rules.gd, static — SP 점 표시 AC7, 층/방 텍스트 AC6, 스킬 비활성 판정 AC2, 생존 타겟 필터링 AC3)와 `HudPopupQueue`(src/core/hud_popup_queue.gd, 인스턴스 — 팝업 단일 활성+FIFO 큐, Core Rule 3/AC4/AC5). AC1(HP바 갱신)·AC8(상태이상 아이콘)은 신호→렌더 그대로 바인딩이라 로직이 없어 함수 없음. 실제 Node 배선은 #2/#3/#13이 진짜 화면을 갖게 되는 시점(#19와 동일 트리거)에 이 뽑아낸 로직을 호출하는 형태로 완성할 것.

**#9 구현 메모**: `HiddenTrigger`(src/core/hidden_trigger.gd, 오토로드)는 `RunManager.room_entered` 신호를 자체 구독(#13은 #9 존재를 모름, Core→Feature 단방향 유지). 중요 수정: GDD 원문의 `hidden_mage_02` 등 플레이스홀더 풀은 #10의 실제 데이터(companion_dealer_01/support_01/tank_01, `is_hidden=true`)와 매칭되지 않아 폐기 — 대신 `CompanionRegistry`에서 `is_hidden=true`인 동료를 동적으로 풀링하도록 구현(로스터 변경에 자동 동기화, GDD 상수 하드코딩보다 정확). `DungeonGenerator.generate_run()`이 플로어 생성 전에 `HiddenTrigger.start_new_run(rng)`를 defensive find_child로 호출해 풀을 리셋 — 던전 생성이 히든방마다 `get_next_companion_id()`를 동기 호출하므로 런 시작 시점에 시그널이 아닌 직접 리셋이 필요했음(시그널 기반으로는 타이밍이 늦음).

**#1 구현 메모**: `TurnBattle`(src/core/turn_battle.gd)은 시퀀싱/입력 대기/디스패치만 담당, 데미지·턴순서·SP는 #6/#7/#12에 위임. Unit은 duck-typed Dictionary(setup()에서 CompanionRunState/EnemyRunState + registry로 1회 빌드, "run_state" 백레퍼런스로 _sync() 동기화). `SkillRegistry` 오토로드 신규 추가(#10/#11 registry와 동일 패턴, DataRegistryLoader 래퍼).
**발견+수정한 테스트 버그**: 이전 세션(또는 이전 나)이 짠 `test_dot_ticks_and_skip_turn_together`가 "기절→해당 유닛 턴 스킵→run_battle()이 그 라운드 끝에서 멈출 것"이라고 잘못 가정했음. 실제로는 GDD(턴제-전투.md: "기절은 1턴 — 다음 라운드 정상 행동")대로 스턴은 정확히 1턴만 지속되므로, skip_turn은 그 유닛 차례만 건너뛰고 코루틴은 계속 진행 — 2라운드째에 스턴이 풀린 동료가 `await action_selected`에 걸려야 비로소 멈춤. 그 사이 poison이 두 번 틱함(1번이 아니라). 구현이 아니라 테스트 쪽 가정이 틀렸던 것으로 판단, GDD 대조 확인 후 테스트 기대값을 수정(hp 95→89, duration 2→1).
**새로 등장한 재현 패턴**: `class_name`이 새로 추가된 .gd 파일은 Godot 전역 스크립트 클래스 캐시에 바로 안 잡힘 → GUT가 "Could not find type X" 파싱 에러를 냄. 고치는 법: `godot --headless --editor --quit --path .` 로 헤드리스 에디터를 한 번 띄웠다 종료하면 캐시 갱신됨 (이전 세션 CombatFormula 때도 동일 증상, 이번 TurnBattle도 동일하게 해결).

**중요 전환**: `#17 로컬 세이브`를 "ADR-0001 검증 전까지 완전 차단"으로 잘못 판단했던 걸 정정함 — GUT 테스트는 데스크톱 Godot로 돌아가므로 `FileAccess`는 실제 동기 I/O이고, ADR-0001이 막는 건 오직 웹 익스포트의 IndexedDB durability 뿐. 그래서 섹션 API·원자적 쓰기·손상 감지·용량 상한 등 동기 코어는 지금 정상 구현+테스트했고, 재시도/타임아웃/큐(웹 비동기 전용 매커니즘)만 ADR-0001 Accepted 이후로 미룸. 이 판단 덕분에 `#14 영구 진행`도 바로 이어서 구현 가능해짐 — 앞으로 비슷한 "ADR 필수" GDD를 만나면 먼저 "데스크톱에서 테스트 가능한 부분과 실제 웹 검증이 필요한 부분"을 나눠볼 것.

**Core/Foundation 순수 로직 계층이 거의 소진됨** — 남은 항목은 실제 엔진 통합(Node/Tween/씬 파일) 또는 미검증 ADR이 필요:
- **#19 씬 관리**: `SceneTransitionRules`(순수 로직: 전환 타이밍/그래프/타임아웃 산수)만 완료. `SceneManager` 오토로드 자체(실제 Tween, CanvasLayer, `ResourceLoader.load_threaded_request/get`, 시그널)는 보류 — `Boot.tscn` 등 실제 씬 파일이 하나도 없어 지금 만들면 검증 불가능. `#2`/`#3`/`#13`이 실제 화면을 갖게 되면 이 Node 배선을 완성할 것.
- **#17 로컬 세이브**: 여전히 대기 — ADR-0001(HTML5/IndexedDB 쓰기 durability) 실브라우저 검증이 "구현 시작 전 필수"인데 Proposed 상태.
**완료된 시스템 요약**: #6 전투 공식·#10 동료 데이터·#11 적 데이터(+DataValidator)·#7 적 AI·#12 상태이상·#19 씬 관리(순수 로직)·#13 런 상태 관리(RunManager, inventory 포함)·#15 파티 구성·#4 장비·#17 로컬 세이브(동기 코어)·#14 영구 진행·#16 런 결과. **126/126 GUT 통과, 17개 커밋.** 전부 `src/core/`, 테스트는 `tests/unit/core/`.

**버그 수정 1건**: RunManager가 ProgressManager를 `commit_discovered`(존재한 적 없는 이름)로 조회하고 있어서, #14가 완성된 뒤에도 defensive guard 때문에 실제로는 연결이 안 되고 있었음 — `commit_run_end()`로 정정, `last_newly_unlocked`/`last_is_new_record` 필드를 RunManager에 추가해 #16이 읽어감. 실제 ProgressManager 대상 회귀 테스트 추가.

**다음 후보 (언블록 상태)**:
- `#2 랜덤 던전` — #13 완료, #19(Node) 미완성. #13/#15가 그랬듯 defensive seam으로 던전 생성 순수 로직(방 배치·타입 분류)부터 뽑아낼 수 있을 듯. `#9 히든 트리거`·`#3 동료 해금`이 이것에 연쇄 대기 중이라 다음 우선순위로 보임.
- `#1 턴제 전투` — 8개 hard dep 전부 존재(#6,#7,#10,#11,#12,#13,#15,#4). GDD가 "L(4세션+)"로 예상했고 실제 플레이어 입력 대기(`await action_selected`)가 핵심이라 UI 없이는 반쪽 구현 — #2 이후 큰 다음 단계로 고려.
- `#19 SceneManager Node`(실제 Tween/threaded load) — 실제 씬 파일이 있어야 의미 있음, 계속 보류.
- `#17 재시도/타임아웃/큐` — ADR-0001 Accepted + 실 웹 빌드 검증 후.

이전 완료 항목 (2026-07-28): `/review-all-gdds`(FAIL, 5개 blocking) 이슈 전부 producer 판단 완료 및 GDD 반영 완료, 이후 재검토 PASS. 상세: `design/gdd/gdd-cross-review-2026-07-28.md`.

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
- [x] /test-setup 완료 (2026-07-28) — GUT 9.7.1 설치(`addons/gut/`), `.gutconfig.json`, 첫 실제 테스트(`tests/unit/combat/combat_formula_test.gd`, ADR-0008 엡실론 가드 회귀 테스트) 작성 및 헤드리스 실행으로 2/2 통과 확인, `.github/workflows/tests.yml` CI 작성. **주의**: 여러 제네릭 스킬/에이전트 파일(`coding-standards.md`였던 것 포함, 지금 수정함)이 GdUnit4를 기본값으로 잡고 있었으나 이 프로젝트의 실제 결정(technical-preferences.md, ADR-0001/0003/0005)은 GUT — `tests/README.md`에 이 불일치 기록해둠.
- [x] /ux-design 부분 완료 (2026-07-28) — `design/ux/interaction-patterns.md`, `design/accessibility-requirements.md` 생성. **단, 사용자 부재 중 진행이라 새 디자인 판단은 안 하고 이미 결정된 것(ADR-0010/0011/0012, technical-preferences.md)만 정리함.** accessibility Target Tier=Basic은 제안일 뿐 — producer 확인 필요.
- [x] /review-all-gdds 완료 (2026-07-28) — **Verdict: FAIL**, 5개 진짜 blocking 이슈 발견. 리포트: `design/gdd/gdd-cross-review-2026-07-28.md`. **systems-index.md의 GDD 상태를 "Needs Revision"으로 자동 표시하지 않음** — 사용자 부재 중 실행이라 이 판단(어느 GDD를 언제 재작업할지)은 producer 확인 후 처리하는 게 맞다고 보고 보류함.
- [x] 5개 blocking 이슈 전부 수정 (2026-07-28) — 장비/전투-공식/턴제-전투/상태이상/히든-트리거/씬-관리/game-concept/랜덤-던전/런-상태-관리/systems-index 총 10개 파일 수정. 상세: `gdd-cross-review-2026-07-28.md`의 Resolution Log 섹션.
- [x] GDD 재검토 완료 (2026-07-28, 병렬 Consistency + Design Theory 2-pass) — **Verdict: PASS**. 재검토 중 발견된 추가 이슈 4개(랜덤-던전 잔존 오류, 영구-진행 의존성 오귀인, heal_multiplier 공식 누락, "적 강도 자동 조절" 미구현 약속)도 전부 수정 완료. 상세: `gdd-cross-review-2026-07-28.md`의 "Re-Review" 섹션. 남은 항목은 전부 non-blocking Warning(밸런스 튜닝·registry 정리 등)으로 코딩 착수를 막지 않음.
- [x] **방향 전환 결정 (2026-07-28)**: 사용자가 제작 속도 우려(1주 vs 1년 비교)를 제기 → 남은 설계 문서 다듬기·ADR 완결·art-bible 후반부를 코딩 전 게이트로 취급하지 않기로 결정. 이제부터 GDD/ADR은 참고자료, 코딩 진행하며 필요시 인라인으로 갭 메움. 상세: [[project_juunj-scope-pivot]] 메모리 참조.
- [x] **코드 착수** (2026-07-29): `src/core/combat_formula.gd` (#6, 14 tests), `src/core/{companion_data,skill_data,data_registry_loader,companion_registry}.gd` (#10, 4 tests), `src/core/{enemy_data,enemy_registry,data_validator}.gd` + `tools/validate_data.gd` (#11 + build-time skill_id/target_type/damage_multiplier validator, 9 tests). 27/27 GUT 통과. 커밋 4개 (combat formula, .uid sidecars, 동료 데이터, 적 데이터+validator).
- [x] MVP 18/18 시스템 전부 완료, 6개 화면(S-01~S-06) 전부 배선 완료 (2026-07-31) — 상세는 "Current Task" 최신 항목 참조.
- [ ] **다음**: MVP 코드는 전부 구현됨. 남은 건 (1) 광고 SDK 실선택 + 실브라우저 JS 검증(ADR-0003), (2) 실브라우저/실기기 검증 필요한 나머지 ADR(0001 로컬세이브 durability, 0004 씬 로딩 COOP/COEP), (3) 폴리시 후속(장비 슬롯 UI, SP 표시, 상태이상 아이콘) — 전부 게이트 아님, 실제 플레이/배포 준비 단계에서 처리.
- [ ] art-bible 섹션 5-9 작성 (섹션 1-4만 완료, 코딩 진행 중 필요할 때 채움 — 게이트 아님)
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

## Session Extract — /review-all-gdds 2026-07-28

- Verdict: **FAIL**
- GDDs reviewed: 18
- Flagged for revision: 턴제-전투, 장비, 히든-트리거, 동료-해금, 씬-관리, 랜덤-던전, game-concept(합류/난이도), 전투-공식, systems-index, entities.yaml, 파티-구성, 적-데이터, 상태이상
- Blocking issues (5, see report for full detail):
  1. 장비(#4)의 스탯 보정치가 실제 전투 공식에 전혀 반영 안 됨 — #4가 기능적으로 죽어있음
  2. 히든방 재방문 시 장비 드롭 여부, `히든-트리거`와 `장비`가 정반대로 서술 (AC 충돌)
  3. `동료-해금`이 `씬-관리`에 없는 3-인자 `SceneManager.go_to()` 시그니처를 호출 (color_accent 플래시 연출 미구현)
  4. game-concept.md가 약속한 "런 내 합류"가 18개 GDD 어디에도 구현 안 됨 (MVP 컷인지 미정)
  5. 히든방 진입 트리거를 실제로 누가 호출하는지 `#2`/`#9`/`#13`/`#20` 어디에도 명시 안 됨
- Recommended next: 위 5개를 producer가 결정(구현 방식/스코프 컷 여부) → 관련 GDD 수정 → `/review-all-gdds` 재실행 → PASS/CONCERNS 확인 후 architecture 영향 여부 재점검
- Report: design/gdd/gdd-cross-review-2026-07-28.md

## Next Session Entry Point

**우선순위 1 — 방향 전환**: GDD 재검토 PASS 완료(2026-07-28). 사용자가 제작 속도(1주 vs 1년 비교) 우려로 스코프 피벗 결정 — 남은 프리프로덕션 게이트(ADR-0001/0003/0004 실브라우저 검증, art-bible 5-9, `/gate-check`)를 코딩 착수 전 필수 조건으로 더 이상 취급하지 않음. **바로 `src/`에 core loop(전투+던전+동료해금) 구현 착수**. GDD/ADR은 참고자료로만 사용 — 코딩 중 갭 발견 시 인라인으로 결정하고 넘어갈 것 (전체 파이프라인 재가동 안 함, 사용자가 다시 그 수준 리고 요청하지 않는 한). 상세 근거: [[project_juunj-scope-pivot]].

**보류 (게이트 아님, 필요할 때 처리)**:
1. Foundation ADR 3개(0001/0003/0004) 실브라우저 검증 — 실제 해당 코드(로컬 세이브, 광고 브릿지, 씬 로딩) 작성 시점에 병행 검증
2. accessibility-requirements.md의 Basic tier 제안 확인/조정
3. art-bible 섹션 5-9, 보스 스탯 밸런스 재검토, `power_ring` 트레이드오프 등 — 실제 플레이 가능해진 뒤 튜닝 패스

## Session Extract — /architecture-review 2026-07-27

- Verdict: CONCERNS
- Requirements: 38 TR-ID citations found across 12 ADRs — 24 covered, 14 partial (self-flagged pending real-device/browser verification); 0 gaps at Foundation/Core layer
- New TR-IDs registered: 36 (see `docs/architecture/tr-registry.yaml`)
- GDD revision flags: UI-HUD.md (신호 vs 프로퍼티 읽기 모호), 로컬-세이브.md (2단계 durability AC 누락) — 아직 GDD 자체는 수정 안 함
- Top ADR gaps: 없음 (신규 ADR 불필요)
- **버그 발견 및 즉시 수정**: ADR-0006 ↔ ADR-0007 의존성 방향 모순 — ADR-0007 "Depends On"을 None으로, ADR-0006을 "depends on ADR-0007"로 수정
- `docs/registry/architecture.yaml`, `docs/architecture/tr-registry.yaml` 최초 소급 채우기 완료 (둘 다 이전엔 빈 템플릿이었음)
- Report: `docs/architecture/architecture-review-2026-07-27.md`
