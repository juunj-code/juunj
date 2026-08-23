# Session State — 바람의 탑 (Wind Tower)

**Last Updated**: 2026-08-23
**Stage**: 코딩 착수 (design/architecture 문서는 참고자료, 게이트 아님 — [[project_juunj-scope-pivot]] 참조). 사용자가 커밋/다음 시스템 선택 등 코딩 단계 전반에 자율 진행 승인 ([[project_juunj-review-autonomy]] 참조, 2026-07-29 확장, 2026-08-17 "나한테 뭐 물어보지말고, 스스로 검증하고" 재확인).

## Current Task

**보스 전용 BGM 분기 (2026-08-21)** — 새 세션에서 "이어서 작업" 요청, 지난 세션 "다음" 목록(보스 BGM 분기/스킬 아이콘/기타 피드백 공백) 중 크레딧 불필요한 항목부터 자율 진행.

- `AudioManager.bind_battle(battle)`이 `battle.enemy_units`를 직접 순회해 `is_boss` 필드로 `combat`/`combat_boss` BGM을 분기(`TurnBattle._build_enemy_units()`가 이미 `is_boss`를 유닛 딕셔너리에 풀어놔서 `EnemyRegistry` 재조회 불필요 — 오디오.md 원안이 가정한 것보다 단순하게 구현 가능했음, GDD에 구현 노트로 기록). 새 트랙 1개(`AudioSynth.sequence`, 사각파, 기존 `combat`보다 저음역+느린 템포로 긴장감 표현) — 새 에셋 없음.
- 신규 GUT 테스트 1개(보스 유닛 포함 파티 vs `enemy_boss_01` 바인딩 시 `combat_boss` 확인), 208/208 통과. 커밋 `73c4a70`.

**스킬 아이콘 (같은 세션, 2026-08-21)** — 크레딧 지출 확인(AskUserQuestion) 후 승인받아 진행.

- Higgsfield `nano_banana_pro`로 4개 컴패니언 스킬(방패 강타/강타/가벼운 치유/베기) 아이콘 생성 — 상태이상 아이콘과 동일한 flat pictogram + 2px 테두리 규칙(art-bible Section 5), 색상은 힐만 기존 회복-초록 채널 재사용하고 나머지 3개는 각 컴패니언의 `color_accent`. `SkillData.icon_id` 필드 신규, `battle_screen.gd`의 `_skill_button.icon`에 배선.
- **버그 잡음**: 원본이 2048×2048이라 `Button.icon`에 자동 축소가 없어 처음 배선 시 아이콘이 화면 전체를 뒤덮음(창모드 스크린샷으로 발견) — `icon_max_width=24`(기존 상태이상 아이콘/로스터 아이콘과 동일 컨벤션)로 해결, 원본 리사이즈는 안 함.
- **검증**: 신규 창모드 검증 스크립트(`prototypes/skill-icon-verify/`, RunManager 상태를 직접 세팅 + BattleScreen 수동 인스턴스화 — `RunManager.start_run()`/`enter_combat()`의 SceneManager 트랜지션 락과 얽혀 두 번 실패한 뒤 우회) — 스크린샷으로 "강타 (SP 3)" 옆 아이콘이 정상 크기로 렌더링 확인, 검증 후 삭제(기존 관례와 동일). 208/208 GUT 통과(로직 변경 없음, 순수 시각).
- 커밋 `13b34ec`.

**런 결과 화면 동료 발견 카드 (같은 세션, 2026-08-21)** — "다음 ㄱㄱ" 요청으로 자체 진단 계속. GDD vs 실제 구현 대조로 찾음.

- `런-결과.md` UI Requirement #3이 "이번 런 신규 해금 동료 — 동료 카드 (초상화 + 이름)"를 명시하는데, 실제 `run_result_screen.gd`는 이름만 쉼표로 이어붙인 plain text였음(초상화 없음) — GDD의 AC 범위 축소 노트("실제 렌더링 검증은 #20 소관")에 가려져 있던 진짜 구현 갭. `RunResult.build_display_data()`(데이터 계층, AC로 커버됨)는 안 건드리고 렌더링만 수정 — `CompanionData.portrait_id`/`color_accent` 재사용, 배틀/히든발견 팝업과 동일한 카드 스타일(색상 테두리 PanelContainer + 초상화 + 이름), 새 에셋 없음.
- **검증**: 창모드 스크린샷(동료 2명 해금 상태로 세팅)으로 색상 테두리 카드 2개가 정상 렌더링 확인. 208/208 GUT 그대로(로직 미변경, 순수 렌더링). 커밋 `008cdae`.

**히든방 발견 팝업에 동료 초상화 추가 (같은 세션, 2026-08-21)** — 같은 GDD-대조 방식으로 이어서 찾음, 이번엔 더 뼈아픈 케이스.

- `UI-HUD.md` AC4가 "동료 초상화·이름·설명" 팝업 표시를 명시하는데, `dungeon_exploration_screen.gd`의 `_on_companion_unlocked()`가 신호로 받은 `portrait_id`/`color_accent`를 `_portrait_id`/`_color_accent`로 언더스코어 처리해 그냥 버리고 있었음 — 텍스트(제목+설명)만 표시, "새 동료 발견!"이라는 이 게임의 가장 큰 감정적 순간에 이미지가 아예 없던 실제 AC 위반. `_build_popup_portrait()`로 TextureRect를 1회 생성(배틀 카드/런결과 카드와 동일 패턴), `_render_popup()`에서 팝업 타입이 "companion"일 때만 표시(장비/이미해금 팝업은 UI-HUD.md 스펙에 초상화 요구 없음 — 스코프 유지). `PopupPanel` 고정 오프셋을 초상화 들어갈 공간만큼 확대.
- **검증**: 창모드 스크린샷(`CompanionUnlock.companion_unlocked_this_run` 직접 발신)으로 발견금 테두리 팝업 안에 초상화가 제목/설명 위에 정상 렌더링 확인. 208/208 GUT 그대로. 커밋 `15458be`.

**파티 구성 화면 스탯 미리보기 (같은 세션, 2026-08-22)** — "다음 ㄱㄱ"로 이어서 진행, 같은 GDD-대조 방식(UI Requirements vs 실제 구현)을 다른 화면에도 적용해서 찾음.

- `파티-구성.md` UI Requirement #5(2026-07-26 리비전으로 "장비 교체 시 변화량도 함께 표시"가 명시적으로 강조됨 — "절대 수치만으로는 이 장비가 뭘 바꿨는지 안 보임")인데, `party_select_screen.gd`엔 애초에 ATK/DEF 스탯 표시 자체가 전혀 없었음(장비 픽커만 있고 결과 수치는 안 보임). `Equipment.get_effective_atk/def()`를 그대로 재사용(공식 재구현 없음)해 로스터 행마다 Label 1개 추가, 델타는 `effective - base`.
- **검증**: 창모드 스크린샷(도른에게 체인 메일 장착)으로 "DEF 25 (+5)" 정상 표시 확인 — AC6c 예시값과 정확히 일치. 208/208 GUT 그대로. 커밋 `ee05f15`.

**셀프 피드백 + 방패 아이콘 재생성 (같은 세션, 2026-08-22)** — "스스로 셀프 피드백 해봐" 요청에 6개 항목 자체 지적(아이콘 가독성 미검증/검증 스크립트 삽질/팝업 고정크기 오버플로 위험/델타 "(0)" 표기/화면별 독립검증만 함/미푸시). 사용자가 1번(방패 아이콘)부터 재작업 지시.

- **문제**: `skill_guard_bash.png`(2026-08-21 생성분)가 프롬프트에 "round shield"라고만 썼더니 실제로는 톱니 모양 동전/메달에 균열선 — 방패 실루엣이 전혀 없었음. 1차 검증 때 "존재하고 크기/색 맞다"만 확인하고 "실제로 방패로 읽히는가"는 확인 안 한 게 원인.
- **재생성**: 프롬프트에 heater-shield 실루엣(평평한 윗변, 아래로 갈수록 좁아져 한 점으로 뾰족) 명시 + "circle/coin/medallion 아님" 명시적 배제 → 1회 재생성으로 명확한 방패 실루엣 확보.
- **검증 방식 자체도 개선**: 이전엔 풀해상도(2048px)만 봤음 — 이번엔 실제 배틀 스크린 스킬 버튼(24px 렌더)에 꽂아서 창모드 스크린샷으로 실물 크기 가독성까지 확인.
- 208/208 GUT 그대로(텍스처 교체만, 로직 무변경). 커밋 `66aa40d`.
**남은 셀프 피드백 3건 처리 (같은 세션, 2026-08-22)** — "다음 ㄱㄱ"로 이어서 진행.

- **팝업 오버플로 위험 해결**: `PopupPanel`을 고정 픽셀 오프셋(320×300) 대신 `CenterContainer`로 감싸고 `custom_minimum_size=(320,0)`만 지정(너비 고정, 높이는 내용에 맞춰 자동 확장). 합성한 긴(4줄) 설명 텍스트로 스트레스 테스트해 패널이 깔끔하게 늘어나는 것 확인(이전 고정 크기였다면 잘렸을 케이스).
- **델타 "(0)" 표기 수정**: `_delta_text()`가 이제 변화 없음도 "+0"으로 표시(기존엔 "0"이라 "수치 자체가 0"과 헷갈릴 여지 있었음).
- 커밋 `3939a8a` (두 수정 함께).
- **통합 플레이스루 검증**: 이전 검증들은 전부 RunManager 상태를 직접 주입하고 화면을 수동 인스턴스화했음(진짜 버튼 클릭/SceneManager 전환 경로를 안 탐) — 이번엔 실제 Boot 흐름 그대로(MainMenu "게임 시작" 클릭 → PartySelect 동료 선택+"출발" 클릭 → Dungeon 진입 → 1번 방이 전투방이라 자동으로 S-05까지) 재현. 전체 체인이 실제 버튼 이벤트로 정상 작동 확인, 재생성한 방패 아이콘도 실전 배틀 화면에서 정상 렌더링 재확인. 버그 없음 — 코드 변경 없이 검증만 완료(임시 스크립트 삭제).
- **다음**: 사용자 지시 대기.

**push 완료 (2026-08-22)** — 사용자 "push ㄱㄱ" 승인, `origin/main`이 로컬 46개 커밋 반영해 동기화됨.

**GDD Open Questions 2건 정리 (같은 세션, 2026-08-22)** — "다음 작업 ㄱㄱ"로 이어서, 각 GDD의 미해결 Open Questions 중 "즉시 해결 필요"로 표시된 것과 실측 가능한 것을 골라 정리.

- **`적-AI.md` OQ#2("상태이상 적용 시 AI 타겟 재계산", 2026-07-26부터 "즉시 해결" 태그)**: 코드 감사로 확인 — `turn_battle.gd`가 이미 장비+시너지 반영된 `base_atk`를 `EnemyAI`에 넘기고 있고, 현재 상태이상 데이터엔 ATK를 만지는 `STAT_MODIFY`가 하나도 없음(`defense_up`만 DEF). 즉 지금은 실제로 발현되는 갭이 없어 YAGNI로 종결, `enemy_ai.gd`에 향후 ATK 버프 상태이상 추가 시 고칠 지점을 가리키는 `ponytail:` 주석만 남김. 커밋 `df20432`.
- **`시너지.md` OQ#3("보스 DEF와 파티 규모의 상호작용", 2026-08-08 systems-designer 발견, 미해결)**: 실제 `TurnBattle`로 3인 만원 파티(전 class_type, 최대 시너지) vs `enemy_boss_01`을 끝까지 구동 — **8라운드 승리, 파티 총HP 91% 잔존, 유닛 2/3 무피해**. 솔로전(기존 `boss_balance_test.gd`, 최적 플레이 필요한 박빙)과 뚜렷한 난이도 절벽 확인. AskUserQuestion으로 확인 → **"의도된 커브로 확정" 선택, 데이터/코드 변경 없이 종결**. 커밋 `9b0af22`, `03b688b`.
- **검증**: 두 건 다 문서/주석만, 로직 변경 없음(두 번째 건은 확인용 임시 GUT 테스트 작성→실행→삭제, 커밋 안 됨). 208/208 GUT 그대로.

**GDD Open Questions 대량 정리 + 실버그 1건 수정 (같은 세션, 2026-08-22)** — 사용자 "계속 이어나가... 자러갈거니까 계속 작업하셈" — 자율로 전체 GDD Open Questions 스윕.

- **실제 버그 발견+수정**: `UI-HUD.md` OQ1("전투 애니메이션 중 입력 블록")을 조사하다가 발견 — 액션 버튼은 제출 즉시 비활성화되지만 **타겟 버튼은 클릭해도 다음 턴 셋업 때까지 안 사라짐**(재클릭 시 리스너 없는 신호로 버려지긴 해도 "입력 차단" 의도와 안 맞음). `battle_screen.gd`에 `_on_target_pressed()` 추가해 클릭 즉시 `_clear_targets()`. 창모드로 targets_before=1→targets_after_click=0(같은 프레임) 확인. 커밋 `06b279a`.
- **Open Questions 8건 종결** (전부 "이미 코드/문서상 답이 나와 있었는데 태그만 안 갱신됨" 패턴, 실측/코드감사로 확인 후 닫음, 스탯/로직 변경 없음):
  - `전투-공식.md` OQ3(동속도 순서 UI 노출) — 2026-08-17 턴 순서 대기열 UI가 이미 충족.
  - `턴제-전투.md` OQ1(애니메이션 입력 블록, `UI-HUD.md`와 동일 건 교차참조) / OQ2(도망 옵션 없음) — 전자는 위 버그 수정으로 해결, 후자는 이미 "의도된 트레이드오프"로 결론 나 있던 텍스트에 태그만 정리.
  - `동료-데이터.md` OQ1(스킬 레벨업 없음, 코드 확인) / OQ3(기본 동료 파티 제외 가능, `party_composition.gd`에 잠금 로직 없음 확인).
  - `영구-진행.md` OQ2(`BASE_COMPANION_ID` 최종값 확정, 이미 `companion_balance_01`로 박혀있었음).
  - 커밋 `af1c8bd`, `0310dc0`, `a8fc4d8`.
  - **닫지 않고 남긴 것**: 실측/플레이테스트 데이터가 실제로 필요한 항목(전투 페이싱 "중앙값 턴 ≤30초", SP 초기값 밸런스, 씬-관리의 웹 익스포트 COOP/COEP·백그라운드탭 ADR 항목 등)은 근거 없이 억지로 안 닫음 — Full Vision 스코프인 것들(장비 영속, 클라우드 세이브 등)도 그대로 둠.
- 208/208 GUT 그대로. push 완료(`412458a`).

**시도했다가 되돌린 항목 — 방법론 교훈 (같은 세션, 2026-08-22)**: 타겟 버튼 수정과 같은 패턴으로 "다음 방으로" 버튼도 연타 시 방을 건너뛸 수 있다고 판단해 `_on_advance_pressed()` 진입 즉시 비활성화하는 수정을 추가했는데, 검증 스크립트가 `button.pressed.emit()`을 `disabled` 상태 무시하고 강제로 두 번 호출하는 방식이라 거짓 양성이었음 — Godot의 `Button.disabled`는 실제 입력 이벤트 처리 시점에 체크되는 것이지 `.emit()` 직접 호출은 그 게이트를 우회함. `disabled`를 존중하는 올바른 이중클릭 시뮬레이션(각 클릭 전 `if not disabled`로 가드)으로 원본 코드를 재검증한 결과 **원본이 이미 안전했음**(히든방 팝업 캐스케이드가 같은 동기 호출 스택 안에서 이미 버튼을 비활성화함, 이 게임의 방 타입엔 "평범한 방"이 아예 없어 combat/boss/hidden 전부 어떤 경로로든 즉시 비활성화됨) — 수정을 되돌림(커밋 안 됨, 스태시만 됐다가 drop). 타겟 버튼 쪽은 재검토해도 여전히 실제 갭(전투 여러 턴에 걸쳐 버튼이 안 사라진 채로 남아있는 게 사실이라 다름) — 그쪽 수정(`06b279a`)은 유효.
- **다음**: 사용자 지시 대기 (기상 후).

**아이콘 에셋 리사이즈 (같은 세션, 2026-08-22)** — 기상 후 "지금 이제 수정할만한게 뭐가있지?" 질문에 자체 점검하다 발견. 크레딧 확인 후 진행하듯 리사이즈도 AskUserQuestion으로 확인 받고 진행.

- 스킬 아이콘 4개(2026-08-21 신규, 각 2~4MB) + 상태이상 아이콘 3개(기존, 각 ~800KB) 전부 24px 렌더용인데 2048px/1024px 원본 그대로 커밋돼 있었음 — 합계 ~12MB, `assets/art/` 전체(32MB)의 1/3. 2026-08-06에 "에셋 적어서 보류"됐던 리사이즈 판단의 트리거 조건("에셋 늘어나면")이 실제로 충족됨.
- `Image.resize(128,128, LANCZOS)`로 7개 일괄 리사이즈 — 128px면 24px 렌더 대비 5배 여유(2x DPI까지 안전), 화질 손실 없음(창모드 스크린샷 확인). 파일당 2~4MB → ~12KB. `assets/art/` 32MB → 19MB.
- art-bible에 정책 확정 기록: 이후 24px급 아이콘은 생성 직후 리사이즈를 기본 절차로.
- 208/208 GUT 그대로(에셋 교체만). 커밋 `e2eab85`, push 완료.

**웹 빌드 재익스포트 + 실브라우저 검증 (같은 세션, 2026-08-22)** — `build/web/`이 2026-08-09 스냅샷이라 그 이후 전부(오디오~오늘 리사이즈까지) 미반영 확인, 사용자 승인 받고 재익스포트.

- `godot --headless --export-release "Web" build/web/index.html`로 재생성(21.5MB pck + 39.5MB wasm). `build/`는 gitignore 대상이라 커밋 대상 아님, 로컬 아티팩트로만 존재.
- **Claude in Chrome으로 실제 브라우저 검증**: 로컬 서버(`python3 -m http.server 8765`) 띄우고 메인메뉴→"시작"→파티선택(어제 만든 스탯 미리보기 "ATK 18 (+0) DEF 12 (+0)" 실제 렌더 확인)→"출발"→던전 자동 전투 진입→베기 스킬 사용→타겟 클릭→데미지 넘버 "-6" 팝업까지 실클릭으로 전체 체인 확인. 콘솔 에러/경고 0건.
- 검증 후 탭 닫고 로컬 서버 종료.
- **다음**: 사용자 지시 대기.

**#22 동료 내러티브 (2026-08-23)** — "다음 해야할 작업은 뭐야" 질문에 남은 후보 5개(동료 내러티브/설정/클라우드 세이브/실측 미해결 항목/자체 진단) 제시, 사용자 "1부터 5까지 차례대로 진행하자" 승인 — 1번부터 착수.

- `CompanionData`에 `backstory`(2~3문장 배경 서사)/`meeting_line`(1인칭 만남 대사) 필드 신규, 4개 컴패니언 `.tres`에 채움(기존 `description`은 "어디서 발견되는지" 짧은 플레이버 텍스트라 역할 안 겹침). 새 GDD 없이 기존 #10/#3 스키마 확장만(코딩 우선 관행 유지).
- **배경 서사** — `party_select_screen.gd` 로스터에 이름 버튼 아래 회색 Label로 상시 노출(선택 여부 무관, 고르기 전에 누군지 알 수 있어야 하므로).
- **만남 대사** — `dungeon_exploration_screen.gd`의 `_on_companion_unlocked()`가 `_id`를 버리던 걸 실제로 사용(`CompanionRegistry.get_by_id(id).meeting_line`), 해금 팝업 본문 맨 위에 인용구로 추가.
- **검증**: 208/208 GUT 그대로(순수 데이터+렌더링, 로직 미변경). 창모드 스크린샷 2장(`prototypes/narrative-verify/`, 검증 후 삭제) — 파티 선택 화면 4개 로스터 행 전부 배경 서사 정상 렌더링, 해금 팝업에 "내 뒤에 있으면 다치지 않아." 인용구가 초상화/제목 아래 정상 표시 확인.
- **다음**: 2번(#23 설정 화면)으로 진행.

이전 항목:

**턴 순서 대기열 UI + #21 오디오 구현 (2026-08-17)** — 새 세션에서 "이어서 작업" 요청. 지난 세션 "다음" 항목(턴 순서 대기열 UI/유휴 모션/스킬 아이콘) 중 하나를 자율 선택해 진행, 이어서 사용자가 "더 재미있는 게임, 게임다운 게임" 요청 → 자체 진단으로 우선순위 결정.

- **턴 순서 대기열 UI**: `TurnBattle`에 `turn_order_changed(turn_order: Array)` 시그널 신규(라운드 계산될 때마다 발신, `_compute_turn_order()` 재사용). `BattleScreen`에 `TurnQueueRow`(작은 초상화 칩, 현재 턴만 밝게·나머지 dim) 추가 — 기존 카드 빌드 로직(`_portrait_path`/`_accent_color`) 재사용, 새 에셋 없음. 196/196 GUT(+1), 창모드 스크린샷으로 확인(칩 순서·하이라이트 정상). 커밋 `77c2059`.
- **자체 진단 (오디오 완전 부재 발견)**: "게임다운 게임" 요청에 응해 재점검 → `#21 오디오` GDD가 2026-08-08에 Approved되고 다른 시스템(#1/#9/#13)이 이미 구독을 약속해뒀는데, 실제 `src/`에 오디오 코드/에셋이 0건이었음(무음 게임). 시각 폴리시보다 임팩트가 크다고 판단해 우선 착수.
- **AudioManager 구현**: 외부 에셋 생성(Higgsfield 크레딧) 대신 `AudioSynth`(신규, `class_name`, square/triangle/sine 파형을 `AudioStreamWAV` PCM으로 런타임 합성)로 GDD의 "미니멀 8비트" 요구를 코드만으로 충족 — 새 크레딧/파일 불필요. `AudioManager` 오토로드: SFX/BGM 버스(런타임 `AudioServer.add_bus`), SFX 5종(hit/heal/victory/defeat/discovery — 전투는 사각파, 히든 발견은 사인파로 GDD의 파형 구분 그대로), BGM 3종(lobby/exploration/combat) 등파워(sin/cos) 크로스페이드(GDD 리뷰가 지적한 "선형 dB lerp가 중간 지점에서 음량 훅 꺼짐" 버그를 애초에 회피). `SceneManager.scene_ready`/`CompanionUnlock.companion_unlocked_this_run`(둘 다 오토로드) 직접 구독, `BattleScreen`은 `AudioManager.bind_battle(_battle)` 1회 호출(TurnBattle은 오토로드가 아니라 전투마다 바인딩 필요).
- **의도적 스코프 컷**: 보스 전용 BGM 분기는 스킵(ponytail — MVP는 전투 루프 1개, 필요해지면 트랙 추가+`is_boss` 체크). GDD의 UI 탭 사운드도 기존 결정대로 계속 스코프 제외.
- **검증**: `AudioSynth`/`AudioManager` 신규 GUT 테스트 10개(hit/heal 판별, victory/defeat, BGM 전환, 파형 프레임 수/루프 설정) — 헤드리스 첫 실행에서 `class_name AudioSynth`가 전역 클래스 캐시에 안 잡혀 파싱 실패(기존에도 겪은 패턴) → `--headless --editor --quit`로 캐시 갱신 후 재실행, 206/206 통과. 헤드리스는 더미 오디오 드라이버라 실제 재생 검증이 안 돼, 별도로 창모드(실제 오디오 디바이스)에서 버스 생성+SFX 5종+BGM 크로스페이드를 실행해 에러 없음 확인(임시 스크립트, 삭제 완료). 커밋 `f85b730`.
- **다음**: 캐릭터 유휴 모션, 스킬 아이콘, 보스 전용 BGM(스킵한 항목) 중 우선순위 판단 필요 — 사용자에게 묻지 않고 계속 자율 진행 예정.

**스킬 정보 표시 + 공격 린지 모션 (같은 세션, 2026-08-17)** — "나한테 뭐 물어보지말고, 스스로 검증하고, 더 재미있는 게임, 게임다운 게임이 되도록" 요청으로 자율 계속 진행. 위 "다음" 목록에서 순수 폴리시(유휴 모션/아이콘)보다 실제 플레이 정보/피드백 공백을 우선.

- **스킬 버튼 정보 공백 해결**: `_skill_button`이 스킬 이름/코스트/효과 전혀 안 보여주고 "스킬"이라고만 표시 — 플레이어가 뭘 쓰는지 모르고 누르는 상태였음(실제 "재미" 저해 — 전략적 선택엔 정보가 필요). `SkillData.name`/`cost_sp`/`description`을 버튼 텍스트+툴팁에 배선(새 UI 요소 없음). 창모드 스크린샷으로 "강타 (SP 3)" 정상 표시 확인.
- **공격자 린지 모션 신규**: `TurnBattle`에 `action_executed(actor_id, actor_index, target_id, target_index, action)` 시그널 추가(`_execute_action()` 시작 지점에서 발신 — `unit_hp_changed`만으로는 누가 누굴 때렸는지 알 수 없었음). `BattleScreen`이 이를 받아 공격자 카드를 타겟 방향으로 짧게 밀었다 되돌리는 튠(0.09s 아웃/0.15s 인) 추가 — 지난 히트피드백 세션에서 "공격 모션/린지가 전혀 없어 멈출 움직임 자체가 없다"며 히트스톱을 스킵했던 그 공백을 메움. **다음에 히트스톱 재검토 여지 생김**(사용자 확인 불필요, 필요시 판단해서 진행).
- **검증**: 신규 GUT 테스트 1개(action_executed의 actor/target/action 페이로드), 207/207 통과. 창모드 스크린샷 2장(공격 전/린지 중)으로 카드가 실제로 타겟 쪽으로 이동하며 데미지 넘버가 같은 프레임에 뜨는 것 확인.
- **다음**: 캐릭터 유휴 모션, 스킬 아이콘(그래픽), 히트스톱 재검토, 보스 전용 BGM 중 우선순위 판단 필요 — 계속 자율 진행.

**히트스톱 + 유휴 모션 (같은 세션, 2026-08-17)** — "/auto-mode-setup" + "계속 자율로 진행해" 요청으로 이어서 진행, 위 "다음" 목록 순서대로 처리.

- **히트스톱(freeze frame) 신규**: `game-feel` 스킬의 표준 레시피(`Engine.time_scale` 순간적으로 낮췄다가 `ignore_time_scale` 타이머로 실제시간 복원) 적용. 데미지에만 발동(힐/스태거된 멀티히트 넘버는 제외), 카드 팝/데미지 넘버 튠은 의도적으로 시간축 스케일 영향을 그대로 받게 둬(엔진 기본 idle 프로세스) 프리즈 순간에 같이 멈춰야 "정지"로 읽힘. `_exit_tree()`에 `time_scale=1.0` 복원 안전장치 추가(전투 중 씬 전환 도중 얼어붙는 사고 방지). 창모드로 `time_scale`이 히트 직후 0.05 → 0.5초 뒤 1.0으로 정상 복귀하는지 직접 확인(가장 위험한 실패 모드).
- **유휴 모션(idle bob) 신규**: 카드가 턴 사이 완전 정지해 있어 "일시정지된 스크린샷"처럼 보이던 문제. 초상화 노드(카드 자체 아님 — `card.position`은 린지 튠이 소유)에 유닛별 위상 오프셋을 준 느린 상하 bob(3px, ~1.6초 주기) 추가, 쓰러진 유닛은 정지. 새 에셋 없음. 창모드 스크린샷 2장(0.8초 간격)으로 위치 변화 확인.
- **검증**: 두 기능 다 207/207 GUT 그대로(순수 시각 변화, 로직 미변경). 커밋 `1ff2148`(히트스톱), `de43956`(유휴 모션).
- **스킬 아이콘(그래픽)은 보류**: 이번 세션의 다른 항목(오디오, 스킬 정보 텍스트, 린지, 히트스톱, 유휴 모션)은 전부 새 에셋/크레딧 없이 코드만으로 해결했는데, 아이콘 그래픽은 실제 이미지 생성(Higgsfield 크레딧, 실비용)이 필요함 — 이 프로젝트의 기존 컨벤션(2026-08-15 던전 배경 아트 때도 크레딧 사용은 자율 진행 승인과 별개로 AskUserQuestion 확인 후 진행)에 따라 크레딧 지출은 계속 확인받고 진행. 코드 준비(SkillData에 icon_id 필드 추가 등)는 언제든 크레딧 승인 이후 빠르게 이어갈 수 있음.
- **다음**: 보스 전용 BGM 분기, 스킬 아이콘(크레딧 확인 필요), 그 외 발견되는 게임성/피드백 공백 — 계속 자율 진행.

이전 항목:

**입체감 폴리시 — 카드 그림자 + 초상화 확대 + 던전 배경 아트 (2026-08-15)** — 사용자가 전투 화면 마주보기 구도를 보고 "한결 낫다"면서 "입체감있게 좀 만들어줘"라고 추가 요청.

- **카드 그림자**: `battle_screen.gd`/`dungeon_exploration_screen.gd`의 유닛/HP 카드 StyleBoxFlat에 `shadow_color`/`shadow_size`/`shadow_offset` 추가(Godot 네이티브 기능, 새 에셋 없음) — 카드가 바닥 위에 떠 있는 느낌.
- **초상화 96→150px**: 사용자가 "캐릭터 이미지를 새로 만들어야 하는 거 아니냐"고 질문 → 원본 아트 확인해보니 이미 전신 일러스트였음(96px 박스에 욱여넣혀 아이콘처럼 보였을 뿐). 새 에셋 없이 `_PORTRAIT_SIZE`만 키움. art-bible Section 3-1(96×96 명시)과 어긋나므로 코드에 정정 필요 노트 남김 — **다음 세션에 art-bible 갱신 필요**.
- **art-bible 3-3 상충 발견, 미해결**: Section 3-3 "UI 셰이프 문법"이 "3D bevel 금지", "모서리 순수 직각(1px 라운드도 금지)"을 명시하는데, 기존 카드(corner_radius 6, 컬러 보더)부터 이미 이 규칙과 어긋나 있었고 이번 그림자 추가로 더 벌어짐. 사용자가 결과를 보고 긍정적으로 반응해 진행은 했지만 문서 자체를 갱신할지, UI를 문서에 맞춰 되돌릴지는 **판단 필요 — 다음 세션에 결정**.
- **던전 배경 아트 추가**: 던전 탐색 화면이 배경 없이 완전 검은 화면이던 게 훨씬 눈에 띄는 문제라 발견 → 사용자에게 크레딧 사용 확인(AskUserQuestion) 후 승인받아 Higgsfield `nano_banana_pro`로 `dungeon_room_01.png` 생성(art-bible Section 2 "던전 탐색" 무드: Cool 무방향광, 전투보다 저대비 — battle_arena_01과 의도적으로 다르게). `DungeonExplorationScreen.tscn`에 BattleScreen과 동일한 패턴(풀렉트 TextureRect, STRETCH_KEEP_ASPECT_COVERED)으로 배선.
- **동료 초상화 아트 스타일 불일치 발견, 미해결**: 4개 동료 원본 파일을 열어보다가 발견 — 도른(탱커)은 배경 없는 순수 전신 일러스트, 리사(딜러)는 액자 프레임이 그림 안에 이미 그려진 반신, 유이(서포터)는 순수 상반신 흉상컷. 지금은 카드 테두리에 가려 티가 덜 나지만 통일감 있게 다시 생성할지 **다음 세션 판단 필요** (사용자에게 "지금 급한 건 아니니 넘어가고 나중에 손볼 목록에 적어둔다"고 전달, 확인 응답 없음).
- **검증**: 헤드리스 스크린샷(창 모드 GL 렌더링 — 이 Godot 빌드는 `--headless`가 dummy 렌더러라 실제 픽셀이 안 나옴, 창 모드로 전환해서 캡처) 2회(전투/던전), 195/195 GUT 통과. 커밋 `8658eb6`(카드 그림자+초상화 확대), `73fd957`(던전 배경).
- **다음**: 위 3개 미해결 항목(art-bible 초상화 크기 갱신, 3-3 셰이프 문법 상충 정리, 동료 초상화 스타일 통일 여부) 중 어느 걸 먼저 다룰지 사용자 확인 필요. 그 외엔 메인메뉴/파티선택/런결과 화면도 배경 아트 확장할지 결정 대기.

**위 3개 항목 전부 해결 (같은 세션, 2026-08-15)** — 사용자가 "1 2 3 ㄱㄱ"으로 일괄 승인.
1. art-bible Section 3-3에 카드 초상화 표시 크기(150px) 신규 문서화.
2. art-bible Section 3-3에 "예외: 게임플레이 카드 UI" 절 추가 — 라운드 코너/컬러 보더/드롭섀도우를 승인된 예외로 명문화(UI를 문서에 맞춰 되돌리지 않고, 문서를 실제 출시된 UI에 맞춤).
3. **동료 초상화 통일**: `portrait-prompts.md` 원본 스펙(흉상, chest-up, 평면 배경, 프레임 없음)을 다시 읽어보니 애초에 전신/액자프레임은 스펙 위반이었음 — 도른(탱커)·유이(서포터)가 아니라 **도른(탱커, 전신)·리사(딜러, 액자프레임)** 쪽이 비표준이었다는 걸 재확인. `companion_tank_01`/`companion_dealer_01` 둘 다 같은 프롬프트로 재생성(딜러는 프레임이 또 나와서 "flat solid background, no frame/vignette" 강조해 2차 재시도 후 성공). `companion_balance_01`/`companion_support_01`은 이미 스펙 준수라 안 건드림. 195/195 GUT 통과, 스크린샷으로 4장 통일된 흉상 구도 확인. 커밋 `5f6a9d2`.
- **다음**: 메인메뉴/파티선택/런결과 화면 배경 아트 확장 여부 결정 대기.

**나머지 3화면 배경 확장 완료 (같은 세션, 2026-08-15)** — "계속하자" 승인으로 진행. art-bible이 메인메뉴/파티선택/런결과를 전부 "메인 메뉴 / 로비" 무드 하나로 묶어놓은 걸 근거로, `tower_lobby_01.png` 1장만 생성해 세 화면에 공용으로 배선(크레딧 절약 + 일관성). 6개 화면(S-02~S-06 전부 + Boot) 모두 배경 아트 확보 완료. 헤드리스 스크린샷 3장 확인(메인메뉴/파티선택 정상, 런결과는 첫 시도에서 스크립트 버그로 크래시 — `root.get_children()`로 화면 전환하며 지우다가 RunManager 등 오토로드까지 같이 free해버림, 별도 스크립트로 재시도해 해결. 실제 게임 코드엔 영향 없음, 임시 검증 스크립트 한정 버그). 195/195 GUT 통과. 커밋 `d90275c`.
- **다음**: 없음 — 이번 "입체감 폴리시" 작업 완료. 사용자 다음 지시 대기.

**히트 피드백 추가 (같은 세션, 2026-08-15)** — 사용자가 "너 스스로 부족한 점 생각해봐, 레퍼런스 조사해보고"로 자체 점검 요청.

- **자체 진단**: 지금까지 폴리시가 전부 정지 이미지 개선(그림자/배경/초상화)뿐이었고, 진짜 "게임 같지 않다"의 핵심은 애니메이션/피드백이 전무하다는 것 — 공격해도 카드 반응 없음, 데미지가 숫자로 안 뜸.
- **레퍼런스 조사**(WebSearch): Wildfrost/Darkest Dungeon류 포지셔닝 전략, 데미지 넘버는 통통 튀며 축소·페이드되는 쪽이 타격감 좋음, 멀티히트는 시차 스태거 필요("Damage Numbers in RPGs" 아티클).
- **구현 1**: `battle_screen.gd`에 데미지/힐 넘버 팝업(Label+Tween, 위로 뜨며 페이드) + 맞은 카드 squash-pop(TRANS_BACK). `unit_hp_changed`엔 델타가 없어서 HP바 이전값과 diff(시그널 계약 안 건드림). 커밋 `34566ac`.
- **구현 2**: `all_allies` 스킬(전체 힐 등)이 `_sync()`를 같은 프레임에 유닛별로 동기 호출하는 걸 발견 — 넘버/pop이 전부 동시에 터져서 "뭉텅이"로 보이던 문제. 프레임당 히트 배치 인덱스 추적해 0.08초씩 스태거. 단일 히트(흔한 경로)는 stagger=0으로 회귀 없음, 스크린샷으로 확인. 커밋 `587e975`.
- **히트스톱은 스킵**: 지금은 공격 모션/린지(lunge)가 전혀 없는 메뉴 기반 전투라 "멈출 움직임" 자체가 없음 — 실제 타격 모션이 생기면 그때 Engine.time_scale 기반으로 재검토.
- 195/195 GUT 통과 (2회 검증).
- **다음**: 턴 순서 대기열 UI, 캐릭터 유휴 모션, 스킬 아이콘 중 어느 걸 다룰지 사용자 확인 필요.

이전 항목:

**전투 화면 대형 재구성 — 마주보고 서기 (2026-08-13, 배경 아트 직후)** — 배경 아트를 본 사용자가 여전히 "너무 구리다" — "캐릭터를 마주보고 서있으면 좋겠다"는 구체적 피드백. 문제: 유닛 카드가 풀와이드 VBox라 배경이 생겨도 여전히 "세로로 쌓인 목록"처럼 보였음(파티/적 카드가 각각 화면 절반 폭 전체로 늘어남).

- `PartyContainer`/`EnemyContainer`를 VBoxContainer → HBoxContainer로 교체(유닛이 같은 편끼리 가로로 나란히 서도록) + 각각 `CenterContainer`로 감싸 방 중앙에서 수직/수평 중앙정렬되도록 배치. `UnitsRow`에 `size_flags_vertical=3`을 줘서 카드 영역이 세로로 확장되며 버튼 행을 화면 하단으로 밀어냄 — 결과적으로 유닛들이 방 중간에 "서 있고" 버튼은 바닥에 깔림.
- 카드 자체도 HBoxContainer 부모 아래에서는 내용물 크기로 줄어듦(더 이상 풀와이드 바가 아님) — 초상화 96×96로 키우고, 적 초상화는 `flip_h=true`로 좌우 반전해 파티 쪽(화면 왼쪽)을 바라보게 함.
- `battle_screen.gd`의 `@onready` 타입/`_build_rows()` 파라미터 타입을 VBoxContainer→HBoxContainer로 동기화(타입 불일치로 처음엔 런타임 에러 — 잡아서 수정).
- **검증**: 2인 파티 vs 보스, 3인 파티(MAX_PARTY_SIZE) vs 적 2마리 두 케이스 모두 헤드리스 스크린샷으로 확인 — 좌우로 갈라져 마주보는 구도, 960px 폭에서 오버플로 없음. 195/195 GUT 통과.
- **다음**: 사용자 확인 대기. 이 정도면 "게임 같다"는 반응 나오는지 확인 후, 다른 화면(던전 탐색 등)에도 배경+실제 배치 확장할지 결정.

이전 항목:

**전투 화면 배경 아트 1건 (2026-08-13, 2차 폴리시 직후)** — 2차 폴리시 결과 스크린샷을 본 사용자 피드백: "뭔가 게임같지가않다..." — 진단: 던전/전투 어느 화면에도 실제 배경 아트가 없어(art-bible Section 6이 처음부터 환경 아트를 보류해둔 상태) 카드+버튼만 쌓인 웹폼처럼 보였음. 범위를 물어봐서(AskUserQuestion) "전투 화면부터"로 좁게 승인받음.

- Higgsfield `nano_banana_pro`로 전투 배경 1장 생성(2크레딧, 사용자 승인) — 직사각형 석실, 순수 직각 벽, 반복 타일 바닥, Neutral-Cool 방향광+비네트(art-bible Section 2 "전투" 무드 + Section 3-2 환경 지오메트리를 그대로 적용, 새 규칙 없음). `assets/art/backgrounds/battle_arena_01.png`, 프롬프트는 `design/art/background-prompts.md`에 기록(기존 portrait/enemy-sprite-prompts.md와 동일 컨벤션).
- `scenes/BattleScreen.tscn`에 풀렉트 `TextureRect`(`STRETCH_KEEP_ASPECT_COVERED`)로 배경 배선 — 기존 좌(파티)/우(적) 카드 레이아웃은 그대로 두고 그 뒤에 깔기만 함(레이아웃 변경 없음, 방 비율이 기존 2분할 카드와 자연스럽게 맞아떨어짐).
- 새 에셋이라 `godot --headless --editor --quit`로 임포트 트리거 필요했음(`.png.import` 사이드카 생성, 기존 세션에서도 나온 패턴).
- **검증**: 헤드리스 스크린샷으로 전/후 비교, "카드만 떠있던" 화면이 실제 석실 안에서 전투하는 것처럼 보이도록 개선 확인. 195/195 GUT 통과.
- **다음**: 사용자가 이 결과 보고 던전 탐색(S-04)/메인메뉴 등 나머지 화면도 배경 아트를 확장할지 결정 대기.

이전 항목:

**비주얼 폴리시 2차 — 나머지 5개 화면 + 전역 배경/버튼 테마 (2026-08-13)** — 1차(BattleScreen 카드화)에 이어 "비주얼 작업 이어가야지" 요청으로 나머지 화면 처리.

- **전역 배경**: 지금까지 어떤 화면도 배경색을 지정하지 않아 Godot 기본 클리어 컬러(회색)가 그대로 노출되고 있었음(메인메뉴 "회색 배경" 불만의 실제 원인) — `project.godot`에 `rendering/environment/defaults/default_clear_color`를 art-bible 던전 흑(Abyss `#0D0F14`)으로 1줄 설정, 화면별 수정 없이 6개 화면 전부 한 번에 적용.
- **부작용 발견+수정**: Abyss 배경 위에서 Godot 기본 Button/OptionButton 스타일(회색 배경 대비용으로 설계됨)이 다크-온-다크로 거의 안 보이게 됨 — `assets/theme/default_theme.tres` 신규 작성(Button/OptionButton/PopupMenu normal·hover·pressed·disabled 스타일박스, 냉석/안개 팔레트 기반 테두리+배경, Life White 텍스트), `project.godot`의 `gui/theme/custom`으로 프로젝트 전역 적용. 새 에셋 없음, StyleBoxFlat만 사용.
- **MainMenuScreen**: 타이틀 48px + Life White 색상, 버튼과 간격 확보.
- **PartySelectScreen/RunResultScreen**: 타이틀 28px + Life White (배틀스크린 카드 폴리시와 톤 통일). RunResultScreen의 신기록 뱃지는 발견금(Discovery gold `#E8C84A`)로 강조.
- **DungeonExplorationScreen**: 팝업 패널이 스타일 지정 없이 기본 회색 박스였던 것을 발견금 골드 테두리 카드로 교체(히든/보상 발견이라는 의미와 일치, art-bible 4-2 시맨틱 규칙 그대로 적용). 파티 HP도 평문 라벨 → BattleScreen과 동일한 `color_accent` 테두리 카드 + ProgressBar로 교체(같은 패턴 재사용, 새 코드 최소).
- **검증**: 헤드리스 SceneTree 스크립트로 RunManager 상태를 직접 세팅해(SceneManager fade 우회) 6개 화면(S-02~S-06, 팝업 상태 포함) 전부 실제 렌더 스크린샷 확인 — 대비 문제 확인 후 수정, 재확인 완료. 스크립트는 확인용 1회성이라 커밋 전 삭제. 195/195 GUT 통과(변경 전후 2회 확인).
- **다음**: 없음 — 6개 화면 전부 폴리시 완료. 추가로 손댈 곳 있으면 사용자 확인 후 진행.

이전 항목:

**전투 화면(BattleScreen) 비주얼 폴리시 1차 (2026-08-09)** — 사용자가 실제로 플레이해보려다 "비주얼이 꽝이라 몰입이 안 됨" 피드백. Claude in Chrome 확장이 연결 안 돼 있어서 실제 게임 화면을 헤드리스 인게임 스크린샷(`get_viewport().get_texture().get_image().save_png()`, RunManager 상태를 스크립트로 직접 세팅)으로 직접 확인 → 문제 실측 확인.

- **발견**: 메인메뉴는 회색 배경+기본 버튼뿐. 전투 화면은 동료가 `companion_tank_01` 같은 원본 ID 텍스트로만 표시(초상화 에셋 있는데 전투 화면엔 연결 안 돼 있었음, PartySelectScreen에만 연결됨), HP는 텍스트만, 적 스프라이트는 `EXPAND_FIT_WIDTH_PROPORTIONAL`이 VBoxContainer 전체 폭으로 늘려버려 이상하게 찌그러져 보임.
- **수정**: `scenes/battle_screen.gd` — 유닛별 카드(PanelContainer, `CompanionData.color_accent`로 테두리 색 구분 — #3 히든 발견 플래시가 이미 쓰는 필드 재사용, 새 에셋 없음), 초상화/스프라이트를 CenterContainer+SHRINK로 고정(스트레치 버그 수정), 실제 `ProgressBar` HP바 추가, 원본 ID 대신 `CompanionData`/`EnemyData.name` 표시명 사용(전투 화면 라벨/타겟 버튼/턴 표시 전부).
- 195/195 GUT 통과. 커밋 `419cb65`.
- **부산물**: 웹 익스포트(`build/web/`) + 로컬 서버(`localhost:8765`, 여전히 켜져 있음) 준비 완료 — 사용자가 직접 브라우저로 플레이 가능.
- **다음**: 다른 화면(MainMenu/PartySelect/Dungeon/RunResult) 비주얼 폴리시는 아직 손 안 댐 — 사용자 확인 후 진행 여부 결정.

이전 항목:

**#21 오디오 GDD 독립 /design-review 완료 + 리비전 완료 (2026-08-08)** — 이 harness가 프로젝트 로컬 스킬을 슬래시커맨드로 인식 못 해서, 이 대화와 전혀 무관한 새 백그라운드 서브에이전트에 `.claude/skills/design-review/SKILL.md`를 그대로 따라 독립 리뷰를 위임(진짜 독립성 확보 — 페르소나 주입 서브에이전트까지 포함).

- **Verdict: NEEDS REVISION**, blocking 6건. 가장 뼈아픈 발견: `unit_hp_changed` 등 3개 시그널이 오늘 TD-001 수정으로 3-인자(`unit_index` 추가)가 됐는데 오디오.md는 갱신을 놓쳐 2-인자로 남아있었음(제 실수). 나머지: 보스 BGM 판별이 `EnemyRunState`에 없는 `is_boss` 필드를 읽으려 함(실제론 `EnemyRegistry` 조회 필요) · 크로스페이드 공식이 선형 dB lerp라 중간 지점에서 실제 음량이 훅 꺼짐(등파워 크로스페이드로 교체, `sin`/`cos` 기반) · 히든 발견 사운드가 "특별한 사운드"로만 뭉뚱그려짐(파형 계열 자체를 다르게 지정 — 전투 SFX는 사각파, 히든 발견은 삼각파/사인파 벨음으로 분리) · AC 11개 전부 재생 여부를 검증할 방법이 없었음(`get_current_bgm_id()`/`get_last_played_sfx_id()` 조회 함수 추가로 해결) · UI 탭 사운드(`play_ui_tap()`)가 `UI-HUD.md` 어디서도 호출을 약속 안 한 고아 기능(이번 리비전에서 스코프 제외, `#20`/`#23` 쪽에서 필요 시 다시 끌어오는 걸로 미룸).
- **부수 발견**: `적-데이터.md`의 Downstream Dependents에 `#21`이 누락돼 있던 것도 리뷰가 잡아냄 — 추가.
- **트래킹 갱신**: `systems-index.md` #21 Designed(review pending) → Approved, Vertical Slice 진행률 2/2 둘 다 Approved.
- **커밋 대기 중**.

이전 항목:

**#19 씬 생명주기 신호 구현 + 헤드리스 감지 버그 발견/수정 (2026-08-08)** — 사용자가 "더 할 일 없냐"고 재차 확인 요청, 재검토해서 찾은 작업.

- `씬-관리.md`(Approved)가 저작 시점부터 `scene_loading_started`/`scene_ready`/`scene_exited` 신호를 약속(#18/#21/#23이 구독 예정)했지만 실제 `scene_manager.gd` 코드엔 없었음 — `#21 오디오` 저작 중 발견한 갭을 실제로 구현.
- **부수 발견 (진짜 버그)**: 신호 테스트 작성 중, `go_to()`의 "헤드리스면 동기 처리" 분기가 `OS.has_feature("headless")`로 판별하고 있었는데, 이 feature 태그는 **헤드리스로 컴파일된 익스포트 템플릿**만 감지하고 `--headless` 런타임 플래그는 감지 못 함 — 실측 확인(`DisplayServer.get_name()=headless` vs `OS.has_feature("headless")=false`, 별도 진단 스크립트로 검증). 즉 **이전까지 모든 GUT 실행이 실제로는 동기 경로를 한 번도 못 타고 매번 진짜 Tween/스레드 로드를 기다리고 있었음** — 그동안 무해하다고 넘겼던 "transition already in progress" 경고들이 사실 이 버그의 증상이었음. `OS.has_feature("headless")` → `DisplayServer.get_name() == "headless"`로 수정, 전수 재실행 후 해당 경고 완전히 사라짐 확인.
- 195/195 GUT 통과. 커밋 `1e14051`.
- `design/gdd/오디오.md` Open Questions #1 해결로 갱신.

이전 항목:

**TD-001 해결 (2026-08-08)** — 백로그의 유일한 미차단 항목(리뷰 세션/GUI 확인 불필요). `unit_hp_changed`/`unit_sp_changed`/`status_effects_changed`에 `unit_index` 인자 추가해 같은 `enemy_id`를 공유하는 두 적 인스턴스의 HP/SP/상태이상 라벨이 같이 갱신되던 버그 수정. `battle_screen.gd`의 라벨 딕셔너리도 `"id#index"` 키로 단순화(배열 제거). `UI-HUD.md` 신호 계약 갱신. 194/194 GUT 통과, 커밋 `fb9ad21`. `docs/tech-debt-register.md` 남은 항목 TD-002(의도적 YAGNI 보류) 1건뿐.

이전 항목:

**#21 오디오 GDD 신규 작성 완료 (2026-08-08)** — Vertical Slice 마지막 미착수 시스템. 사용자와 톤(차분하고 신비로운 칩튠 BGM, 미니멀 8비트 SFX + 히든 발견만 특별한 사운드)만 빠르게 정하고 8개 섹션 전부 초안 작성 → 승인. 파일: `design/gdd/오디오.md`.

- **오너십 원칙**: 순수 신호-구독 출력 레이어, 게임 상태 미소유, 재생 실패해도 게임 진행 차단 안 함(Graceful Degradation).
- **의존성 재구성**: systems-index엔 `#19`만 있었지만, 실제로 `#1`(전투 SFX, `unit_hp_changed` 부호 판별)·`#9`(히든 발견 스팅어)·`#13`(승패 스팅어+보스 BGM 분기)·`#11`(is_boss만 간접 참조)도 이미 다른 GDD들(동료-해금/런-결과/UI-HUD/전투-공식)이 "#21 구독" 형태로 예고해뒀던 걸 발견해 정식 의존성으로 편입. `턴제-전투.md`/`히든-트리거.md`/`런-상태-관리.md`에 `#21` 양방향 Downstream 항목 추가.
- **부수 발견**: `씬-관리.md`(Approved)가 이미 `scene_ready`/`scene_exited` 신호를 `#21`에 약속했지만, 실제 `scene_manager.gd` 코드엔 그 신호가 없음(구현 안 됨) — Open Questions에 기록, `#21` 코드 착수 시 `#19` 코드에도 같이 추가해야 함.
- **제작 범위**: 이번 세션은 GDD(스펙)까지만, 실제 BGM/SFX 에셋 생성은 사용자 결정으로 별도 세션.
- **트래킹 갱신**: `systems-index.md` #21 Not Started → Designed(review pending), Vertical Slice 설계 진행률 2/2. `entities.yaml`에 `crossfade_volume_db` 포뮬러 신규 등록.
- **다음 세션 필수**: `/design-review design/gdd/오디오.md`는 반드시 새 세션에서(저작 세션과 분리 — #8과 동일 컨벤션).
- **커밋 대기 중**.

이전 항목:

**#8 시너지 GDD 독립 /design-review 완료 + 리비전 완료 (2026-08-08)** — 이전 세션이 남긴 "다음 세션 필수" 항목을 새 세션에서 실행. 4개 전문 서브에이전트(game-designer/systems-designer/qa-lead 병렬 어드버서리얼 리뷰 → creative-director 시니어 종합) 실행.

- **Verdict: NEEDS REVISION** (major 아님). Blocking 4건: (1) 팀 단위 flat `synergy_bonus`를 파티원 전원에게 동일 가산하는 원안이 MVP 실제 스탯(tank base_atk=12)으로 이미 +91.7~110% 상대 증가율을 재현함(원래 "로스터 확장 시 미래 위험"으로만 다뤘던 문제가 사실 지금 당장의 문제였음 — systems-designer 발견), (2) `#1`이 실제로 시너지 함수를 올바르게 호출하는지 검증하는 AC 부재, (3) `SynergyTable` 순서-쌍 대칭성 회귀 가드 부재, (4) "노골적으로 안 보여준다" 결정의 검증 경로가 트리거 없는 순환 참조(Open Question)로만 남아있었음.
- **리비전 내용**: 개인별 50% 상한(`applied_bonus = min(synergy_bonus, floori(base_atk*0.5))`) 도입 — 팀 단위 전략성은 유지하면서 저스탯 파티원의 극단적 스윙만 완화. AC 3건 추가(AC11 상한 경계값, AC12 통합 계약 spy 검증, AC13 테이블 대칭성 가드), AC5/AC6에 AC9와 동일한 "MVP는 합성 입력 테스트 대상" 캐비어트 추가. 개발자 전용 디버그 로그 + 셀프 플레이테스트 체크리스트 항목 추가(사용자 결정 — 무언 발견 철학은 유지, 검증 트리거만 확보). "6쌍뿐이라 조합이 사실상 풀린다"는 지적은 사용자 결정으로 MVP 스코프 한계로 인정·문서화(로스터 10명 확장 시 재검토, 지금 안티시너지 규칙 추가는 기각).
- **부수 발견+수정**: `턴제-전투.md`의 절차적 흐름도(Detailed Rules)가 Dependencies 표에는 있는 `#8` 호출 지점을 실제 흐름 단계로는 전혀 보여주지 않고 있었음 — 구현 시 시너지 배선이 누락될 위험이 있는 크로스 문서 갭이라 이번에 함께 수정(흐름도에 "파티 시너지 반영" 단계 추가).
- **미해결로 기록만**: 보스 DEF=8(솔로 전용 튜닝)이 파티 전투(시너지 포함 최대 3인)와 어떻게 상호작용해야 하는지는 `#8` 범위 밖 — Open Questions에 발견 사실만 기록, `#6`/`#11` 재검토 시 처리.
- **트래킹 갱신**: `systems-index.md` #8 상태 Designed(review pending) → **Approved**, Vertical Slice 진행률 0/2 → 1/2. `entities.yaml`의 `synergy_bonus` 항목에 상한 로직 반영. 재검토(2차 `/design-review`)는 스킵 — 자율 진행 방침([[project_juunj-review-autonomy]])에 따라 리비전 후 바로 승인 처리.
- **커밋 완료** (`349cf5a` 문서 리비전). 이어서 같은 세션에서 **코드 구현까지 완료**: `src/core/synergy.gd`(`calculate_party_synergy_bonus`/`get_applied_synergy_bonus`, 50% 상한 포함) + `turn_battle.gd._build_companion_units()`에 배선(장비 위에 가산, 전투 시작 시 1회) + 테스트 13개 신규(`synergy_test.gd` 12개 + `turn_battle_test.gd` 통합 테스트 1개, AC12가 요구한 "#1이 실제로 호출하는지" 검증). GUT 194/194 통과. 커밋 `6d497b3`.

이전 항목:

**#8 시너지 GDD 설계 완료 (2026-08-06)** — `/design-system 시너지`로 8개 필수 섹션 + Visual/Audio + UI + Open Questions 전부 작성. 파일: `design/gdd/시너지.md`.

- **핵심 설계**: 파티 내 서로 다른 `class_type` 쌍(unordered pair)마다 flat ATK 보너스, 전투 시작 시 1회 계산 후 고정(재계산 없음), 파티 전원에게 동일 가산. `#6 전투-공식.md`이 미리 예고해둔 "공식① 수정된 atk 입력" 인터페이스 그대로 사용(범위 확장 안 함 — ATK만).
- **MVP 6쌍 값** (systems-designer 페르소나 검토, 최댓값 시나리오까지 검증): tank-dealer +4, tank-balance +2, tank-support +2, dealer-balance +3, dealer-support +5, balance-support +3. 최대 스택 11(3인 파티, 서로 다른 3타입). 솔로 전투(2026-08-02 보스 밸런스 튜닝 대상)엔 전혀 영향 없음 확인.
- **N명 확장 대비**: 사용자가 "동료 4명뿐인데 의미 있나" 지적 → 규칙 자체는 class_type 태그(4종 고정) 기반이라 로스터가 10명(Vertical Slice 계획값)으로 늘어도 구조 변경 없이 확장됨. 실제 동료 콘텐츠 추가(이름/사연/스탯/스킬/아트)는 오늘 다루지 않고 별도 작업으로 분리 — 사용자 명시적 결정.
- **Acceptance Criteria**: qa-lead 페르소나 검토로 3건 보완(관측 방법 구체화, balance 커버리지 누락, 순서 무관성 미검증) — 최종 10개 GIVEN-WHEN-THEN.
- **양방향 일관성 보정**: `턴제-전투.md`(이미 Approved)의 Upstream Dependencies에 `#8 시너지` 항목 추가(#4 장비가 추가됐던 것과 동일 패턴) — #8이 설계되기 전에는 없었던 의존성.
- **레지스트리 반영**: `design/registry/entities.yaml`에 `synergy_bonus` formula 항목 추가(6쌍 값·재검증 트리거 포함).
- **systems-index 갱신**: #8 상태 Not Started → Designed (review pending), 의존 시스템에 `#13`(런 상태 관리, 설계 중 발견된 Soft 의존) 추가.
- **Creative Director 리뷰**: lean 모드라 스킵(헤더에 명시).
- **다음 세션 필수**: `/design-review design/gdd/시너지.md`는 **반드시 새 세션에서** 실행(같은 세션에서 실행 금지 — 저자 컨텍스트가 섞여 독립 검토가 안 됨).

이전 항목 (판단 필요 3건 해결):
- 접근성 최소 텍스트 크기/대비 검증 시점 → **다음 모바일 플레이테스트 때 같이** (이미 `accessibility-requirements.md`에 그렇게 적혀있었음, 변경 없음).
- 상태이상 아이콘 스펙(32×32) vs 실제(24×24) 불일치 → **스펙을 실제값(24×24)에 맞춰 정정**. `design/art/art-bible.md` Section 5-1과 "발견된 갭" 노트 갱신.
- 초상화 원본 리사이즈/압축 정책 → **지금은 계속 보류** (에셋 11개뿐, 영향 없음). `art-bible.md`에 판단 완료로 기록.
- 로컬 6개 미푸시 커밋(itch.io 배포, ADR-0003 Accepted 등) → **push 완료**, origin/main 동기화됨.

이전 항목들 (2026-08-04, 접근성 확인 + art-bible 6-9 작성): 사용자가 "판단 필요하면 다음 세션에서 물어봐"라고 하고 자리를 비운 상태에서 진행. 코드 변경 없음(전부 문서 작업), 커밋 2개(`7294224`, `78d1b1a`).

- **접근성 Basic tier**: `accessibility-requirements.md`를 실제 구현 대비 재검증 — 9개 항목 중 5개가 "Not Started"에서 실제 코드 인용(`grep` 검증)으로 Satisfied 전환(상태이상 아이콘+텍스트 병행, 색맹 안전 스프라이트, 전체 버튼 44px 터치타겟, 1회성 300ms 플래시). Basic tier 자체도 proposed → confirmed.
- **art-bible 섹션 6-9**: 7(UI/HUD)·8(Asset Standards)·9(Reference)는 실제 코드/파일을 근거로 역문서화, 6(Environment)은 환경 아트 프로덕션이 아직 0건이라 텍스처 철학·무드 매트릭스 교차참조만 채우고 나머지(건축양식/프롭밀도/환경서사)는 명시적으로 보류(추측성 규정을 미리 만들지 않음).

**보스 스탯 밸런스 재검토 착수 → 보류, 판단 필요 (2026-08-01)**: 백로그의 "보스 스탯 밸런스 재검토"(prototype 발견 — 솔로 보스전 승률 0%)를 조사만 하고 데이터는 건드리지 않음. 조사 결과:
1. **별개 발견**: 4개 적 스킬(`skill_boss_gale` 포함) 전부 `cost_sp=0`으로, 매 턴 스킬만 사용(기본 공격을 쓸 일이 없음). `design/gdd/적-AI.md`(38행)는 "결과적으로 SP 시스템이 적 스킬 주기를 자연스럽게 결정한다 (cost_sp=3 → 3턴마다 강 스킬)"이라고 명시적으로 SP 게이팅을 전제하는데, 실제 데이터는 그 전제와 안 맞음. **다만** `turn_battle_test.gd`가 이 0-cost 동작을 "enemy always affords its 0-cost skill"이라고 명시적으로 주석 달아 여러 곳(정확한 데미지 수치까지)에서 테스트로 고정해뒀음 — 즉 이전 세션이 의도적으로 이렇게 결정했을 가능성이 있어, 단순 GDD 불일치로 단정하고 고칠 사안이 아니라고 판단해 보류함.
2. **솔로 보스전 재계산**: cost_sp를 GDD 예시대로 3으로 고쳐도(수동 계산, 아이라 vs 보스 1:1) 승산 없음 — 아이라 평균 6.5dmg/round vs 보스 220HP(34라운드 필요), 보스 평균 10.67dmg/round vs 아이라 100HP(약 9~10라운드面 사망). cost_sp 수정만으론 프로토타입이 지적한 문제가 안 풀림 — 진짜 원인은 보스 base_hp/atk/def 자체가 솔로 상대로 과함.
3. **Pillar 3 재확인**: "솔로도 최강이 될 수 있다"는 실제로 "멀티플레이 없이도 게임 전체를 공략 가능"이라는 뜻(1인 플레이 완결성)이지, "동료 1명이 보스를 이길 수 있어야 한다"는 뜻이 아님 — prototype 브리프가 이 필라 이름을 빌려 stress-test 시나리오 이름을 붙인 것일 뿐, 문서상 파티는 최대 3명(`MAX_PARTY_SIZE`)까지 구성 가능.
4. **그런데 첫 런은 구조상 강제 솔로임**: `PartyComposition._init()`이 "언락된 동료가 1명뿐이면 자동 선택"하고, `RunManager.discovered_companions`(런 중 발견)는 `RunManager.party`(전투 파티, 런 시작 시 1회 고정)에 즉시 합류하지 않음 — 히든방에서 찾은 동료는 **다음 런부터** 선택 가능. 즉 모든 플레이어의 첫 런은 보스방까지 필연적으로 솔로 전투이고, 전투가 완전 결정론적(크리티컬/회피 없음)이라 현재 스탯대로면 첫 보스 조우가 100% 패배로 고정됨. 단, 패배해도 발견한 동료는 영속 해금되므로(로그라이트식 "실패해도 성장") 이게 의도된 난이도 벽인지 버그성 불균형인지는 밸런스 철학 판단.

**결론**: 데이터 변경 없이 보류. 위 4번(첫 런 필연적 솔로 패배)이 실제로 문제인지 아닌지는 사용자 판단 필요 — 확인되면 보스 스탯(base_hp 150~300, base_atk 20~30 안전범위 내) 또는 적 스킬 SP 게이팅 재도입 중 하나로 조정.

**보스 스탯 완화로 해결 (2026-08-02)**: 사용자가 문제로 확인, 보스 스탯 완화 경로 선택. 실제 데미지 공식(`CombatFormula`)·SP 메커니즘(`current_sp` 시작값 0, 매턴+1, 아이라 skill_slash cost_sp=2/mult1.5, 보스 skill_boss_gale cost_sp=0이라 매턴 무조건 스킬)을 그대로 파이썬으로 재현해 전수탐색한 결과, **GDD가 문서화한 보스 스탯 범위(HP150~300/ATK15~25/DEF10~20) 안에는 솔로 승리 가능 조합이 0개**임을 확인(DEF 하한 10이 근본 원인 — 10 이상이면 최적 플레이로도 패배). DEF 하한을 8로 낮춰야(GDD 스펙 자체를 수정) HP150/ATK15/DEF8 조합에서 11라운드·10HP 차이로 승리 가능 — 사용자 승인 후 이 값으로 확정. `enemy_boss_01.tres` 갱신(220/20/16 → 150/15/8), `design/gdd/적-데이터.md`의 보스 DEF 범위·예시 배분·Tuning Knobs·AC7을 8~20으로 동기화, `enemy_registry_test.gd`의 boss DEF 단언도 10→8로 갱신. **회귀 테스트 신규 작성**: `tests/unit/core/boss_balance_test.gd` — 실제 `TurnBattle`로 아이라 솔로 vs 보스를 "항상 skill 요청(SP 부족 시 자동 basic_attack 폴백)" 정책으로 끝까지 구동해 `battle.victory`를 단언, 향후 스탯/공식 변경이 이 승리 가능성을 조용히 깨는 걸 방지. 176/176 GUT 통과(헤드리스 재실행 확인, 신규 테스트 포함).

**장비 슬롯 선택 UI 완료 (2026-08-01)**: `PartySelectScreen`에 동료별 무기/방어구 `OptionButton` 픽커 추가 — `PartyComposition.equip()`(이미 순수 로직 테스트됨)을 호출하고, "슬롯 교체 중 인벤토리 반환"(장비.md Edge Case) 규칙은 화면이 `RunManager.inventory`에 직접 append/erase하는 방식으로 구현(코어 로직은 RunManager 비의존 유지, HudRules/BattleScreen과 동일한 계층 분리 유지). 동료 선택 해제 시에도 장착 중이던 아이템을 인벤토리로 반환하도록 처리(누락 시 아이템 증발 버그였음). 픽커는 인벤토리 변화마다 전원 리빌드 — 한 동료가 집으면 다른 동료 드롭다운에서 즉시 사라짐. 독립 디버그 하네스로 시각 확인(철검 장착 → 다른 동료 드롭다운에서 소멸 확인). 175/175 GUT 통과(코어 로직 미변경). 커밋 `c72ab0a`.

**SP/상태이상 HUD 폴리시 완료 (2026-08-01)**: `BattleScreen`이 `TurnBattle.unit_sp_changed`/`status_effects_changed` 신호를 구독하지 않고 있던 걸 배선(#20 UI-HUD AC7/AC8) — 유닛별 SP 점(`HudRules.sp_dots()` 재사용)과 상태이상 "이름(잔여턴)" 텍스트 라벨 추가. 상태이상 아이콘 그래픽 에셋은 아직 없음(art-bible 5-9 미작성)이라 `StatusEffect.name` 필드를 텍스트로 그대로 사용 — 실제 아이콘 에셋 생기면 텍스트를 아이콘+숫자로 교체. `RunManager._scene_navigator_override` 테스트 시임으로 실제 씬 전환 없이 `BattleScreen`을 단독 구동해 SP=2/5·poison(3) 상태로 스크린샷 확인. 175/175 GUT 통과. 커밋 `07c78d4`.

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
- [x] 보스 스탯 밸런스 재검토 완료 (2026-08-02) — `enemy_boss_01` 150/15/8로 조정, GDD 동기화, `boss_balance_test.gd` 회귀 테스트 추가
- [x] art-bible Section 5(상태이상 아이콘 시스템) 작성 완료 (2026-08-02) — 프레임/색상/픽토그램 규칙 정의. Section 6-9는 계속 보류(게이트 아님)
- [x] 상태이상 아이콘 에셋 생성 + 배선 완료 (2026-08-02) — 사용자 승인으로 Higgsfield `nano_banana_pro` 사용(6 크레딧). poison(빨강 해골)/stun(빨강 소용돌이)/defense_up(초록 방패+화살표) 3종을 `assets/art/icons/`에 저장, `StatusEffect.icon_id` 채움, `battle_screen.gd`의 상태이상 표시를 텍스트(`이름(턴)`)에서 아이콘+턴수 인라인 표시로 교체(`#20 UI/HUD` AC8 완성). 헤드리스 스모크 체크(`prototypes/status-icon-smoke/`)로 배선 자체가 에러 없이 도는 것 확인 + 아이콘 PNG 3개 생성 직후 개별 육안 확인 완료. **단, 실제 화면 배치/크기감 최종 확인은 에디터 F6 사람 확인 대기**(ADVISORY, 게이트 아님 — 스모크 체크가 헤드리스 렌더 한계로 스크린샷을 못 찍음, 근거는 프로토타입 README 참조). 176/176 GUT 통과.
- [x] 적 스프라이트 4종 생성 + 배선 완료 (2026-08-02) — 사용자 승인, Higgsfield `nano_banana_pro`(8 크레딧). 고블린 정찰병(소형, 삼각 돌출 2개)/떠도는 병사(중형, 비대칭 어깨)/돌 수문장(비대칭 거대 주먹+균열 노치)/바람의 수호자(보스, 내부 네거티브 스페이스 링 형태) — 전부 art-bible 3-1 실루엣 규칙 충족 확인(육안). 몸 전체는 냉석/안개 청회색, 위협홍은 눈/균열 포인트로만(art-bible 4-2에 이 규칙 명문화, 기존 rim-light 색 서술 모호함도 같이 정리). `EnemyData.sprite_id` 채움, `TurnBattle._build_enemy_units()`에 `sprite_id` 전달 추가, `battle_screen.gd`가 적 유닛 줄 상단에 64×64 스프라이트 렌더. 헤드리스 스모크(`prototypes/status-icon-smoke/`, enemy_tank_01 재사용)로 배선 에러 없음 확인. 176/176 GUT 통과. 최종 화면 배치는 상태이상 아이콘과 동일하게 에디터 F6 확인 대기(ADVISORY).

- [x] **첫 실제 웹 빌드 익스포트 + 실브라우저 검증, 치명적 버그 2건 발견·수정** (2026-08-02) — ADR-0001/0004 실브라우저 검증을 시도하다가 이 프로젝트 역사상 처음으로 실제 Godot Web(HTML5) 익스포트를 만들어 데스크톱 Chrome(claude-in-chrome)으로 로컬 서빙해 직접 플레이 테스트함. **이전까지 모든 검증은 GUT 헤드리스(느슨한 소스 파일시스템) 또는 에디터 F6 실행뿐이었고, 패킹된(PCK) 익스포트로 실행해본 적이 전혀 없었음** — 그래서 아래 두 버그는 지금까지 한 번도 발견된 적이 없었음.
  - **버그 1 (치명적, 수정 완료)**: `DataRegistryLoader.load_all()`이 웹 익스포트에서 **모든 데이터 레지스트리(동료/적/상태이상/스킬/장비 5개 전부)를 완전히 빈 상태로 로드**하고 있었음 — 원인은 패킹된 PCK 안에서 `DirAccess` 디렉토리 목록이 파일명에 `.remap`을 붙여 반환하는데(`companion_balance_01.tres` → `companion_balance_01.tres.remap`), 기존 `filename.ends_with(".tres")` 필터가 이를 전부 걸러냈기 때문. 실제로 파티 선택 화면에서 동료 이름이 `<null>`로 표시되는 걸 보고 역추적 발견. `src/core/data_registry_loader.gd`에서 `.remap` 접미사를 먼저 제거한 뒤 확장자 체크하도록 수정, 회귀 테스트(`tests/fixtures/companions_remap/`, `companion_registry_test.gd`의 `test_remap_suffixed_filename_is_still_discovered`) 추가. 177/177 GUT 통과.
  - **버그 2 (치명적, 수정 완료)**: 한글 텍스트가 전부 두부(□) 글자로 깨져 나옴 — Godot 기본 폰트가 CJK 글리프를 포함하지 않고, 데스크톱은 OS 폰트로 폴백하지만 웹 익스포트는 브라우저 샌드박스 때문에 OS 폰트에 접근 불가. Noto Sans KR(OFL 라이선스, `assets/fonts/NotoSansKR-Regular.ttf`)을 프로젝트에 추가하고 `project.godot`의 `[gui] theme/custom_font`로 지정해 해결.
  - **전체 플레이 검증 완료**: MainMenu(한글 렌더) → PartySelect(동료 초상화+한글 이름 표시) → Dungeon → Battle(적 스프라이트 렌더, HP/SP 표시, 기본 공격으로 실제 데미지 적용까지) 전 구간을 실제 웹 빌드에서 클릭으로 직접 확인, JS 콘솔 에러 0건.
  - **ADR-0004 (Regular/비스레드 익스포트)**: 실제로 이 값으로 익스포트했고 Emscripten 빌드 로그가 "single-threaded"를 확인 — 결정 자체는 실증됨. 단 Verification Required (c)(프레임 예산 실측)/(d)(백그라운드 탭 복귀 Tween 동작)는 이번 세션에서 계측하지 않음 — 여전히 Proposed.
  - **ADR-0001 (로컬 세이브 durability)**: 여전히 Proposed. 이 ADR이 요구하는 `FS.syncfs()` JS 브릿지 자체가 아직 코드로 구현 안 됨(데스크톱 동기 코어만 존재), 그리고 Validation Criteria가 명시적으로 실제 모바일 Safari/Chrome 20회+ 실측을 요구 — 이번 세션 도구로는 불가능, 손 못 댐.
  - **환경 메모**: Godot 4.7.1 export templates(~1.28GB)를 로컬 `%APPDATA%/Godot/export_templates/4.7.1.stable/`에 설치함(레포에는 없음, 다른 머신에서 웹 익스포트 재현하려면 재설치 필요). `export_presets.cfg`는 이 프로젝트 기존 `.gitignore`가 이미 제외 설정되어 있어(일반적으론 커밋 권장이지만 기존 컨벤션 존중해 그대로 둠) 커밋하지 않음 — 필요 시 이 파일 내용을 세션 로그에서 복원 가능.

- [x] **ADR-0001 2단계(로컬세이브 IndexedDB durability 확인) 구현** (2026-08-02) — `save_manager.gd`에 ADR-0003과 동일한 JS 브릿지 DI 패턴(`_js_bridge`/`_web_override` 시임, `_ready()`에서 `GodotSaveBridge.onSyncDone` 콜백 사전 등록) 적용. 웹에서는 `_swap()` 성공 후 `FS.syncfs()` 콜백을 기다린 뒤에만 `save_succeeded`/`save_failed` 시그널 발신, 비웹은 즉시 발신(기존과 동일). **의도적 스코프 분리**: `save()`의 bool 리턴값은 여전히 1단계(가상 FS 쓰기)만 의미 — `ProgressManager.commit_run_end()`가 이 리턴값을 동기적으로 쓰고 있어서 그걸 깨지 않으려고 리턴값과 시그널의 의미를 의도적으로 분리함(현재 이 시그널을 구독하는 곳이 실제로 없어서 아무 캐러도 마이그레이션 불필요, 주석에 명시). 재시도/지수백오프/큐 상태머신(ADR이 언급하는)은 여전히 구현 안 함 — 타이밍 상수가 ADR 자신도 "실측 전 placeholder"로 표시한 값들이라 지금 만드는 건 추측성 코드(YAGNI). 대신 `AdManager`와 동일한 단일 타임아웃 실패 안전장치(`SAVE_SYNC_TIMEOUT_MS`)만 추가.
  - **테스트**: `ad_manager_test.gd`의 mock 브릿지 패턴을 그대로 재사용해 `save_manager_test.gd`에 4개 추가(웹 성공/에러/타임아웃/비웹 즉시확인). 181/181 GUT 통과.
  - **실브라우저 검증 1차**: 웹 빌드 재익스포트 후 부팅 시 `_ready()`의 `window.GodotSaveBridge = {}` 등록 + `create_callback()`이 콘솔 에러 없이 실행됨을 확인. 이후 실제 전투를 여러 판 진행하며(적 처치 포함) 콘솔 에러 0건 유지 확인. 던전 3층을 수동 클릭으로 다 돌아 진짜 런 종료를 보기엔 시간이 오래 걸려 중단.
  - **실브라우저 검증 2차 (`prototypes/status-icon-smoke/save_bridge_debug.gd` 디버그 하네스, `run/main_scene`을 일시적으로 이 씬으로 바꿔 익스포트 → 확인 → 원복)**: `SaveManager.save()`를 직접 호출해 던전 진행 없이 저장 경로만 트리거. **핵심 발견**: 브라우저 콘솔에 Emscripten 자체 경고 `"warning: 2 FS.syncfs operations in flight at once"`가 뜸 — `FS.syncfs`가 실제로 존재/호출된다는 확실한 증거이자, **Godot 엔진이 `user://` 쓰기 시 자체적으로도 `FS.syncfs()`를 자동 호출한다**는 뜻(ADR-0001 Verification Required 항목 (a)가 사실상 YES로 실측됨). **그런데 우리 콜백(`GodotSaveBridge.onSyncDone`)도, 5초 타임아웃 폴백도 20초 넘게 전혀 발화 안 함** — 원인 미특정(Godot 자체 자동 sync와 우리 명시적 호출이 경합해서 콜백이 죽는 것인지, 아니면 SceneTreeTimer/콜백 배선 자체 버그인지 이번 세션엔 못 밝힘). 상세: `prototypes/status-icon-smoke/README.md`.
  - **근본 원인 확정 (2026-08-02, 콘솔 캡처 대신 화면 Label+DOM 오버레이로 직접 재검증)**: 콘솔 메시지 캡처 도구가 이 세션에서 로그를 누락하는 걸 발견해 위 1차 결론("2 FS.syncfs operations in flight")은 오판으로 정정. 실제로는 **`FS`가 이 Godot 4.7.1 웹 익스포트에서 전역(`window`)에 전혀 노출되지 않음**(`typeof FS`→`undefined`, `typeof Module`→`undefined`) — `JavaScriptBridge.eval()`은 페이지 전역 스코프에서 도는데 Emscripten의 `Module`/`FS`는 Godot 내부 클로저에 갇혀 있어 외부에서 절대 접근 불가. `_confirm_durable_write()`의 `FS.syncfs(...)` 호출은 매번 `ReferenceError`를 던지고 조용히 삼켜짐 — 그래서 콜백도 5초 타임아웃도 영원히 안 왔던 것. **ADR-0001 Key Interfaces에 적힌 구현 방식 자체가 이 엔진 버전에서 원천적으로 불가능**하다는 뜻 — 패치가 아니라 재설계가 필요. `save_manager.gd` 상단에 이 사실을 명시하는 주석 추가(웹에서 현재 항상 깨진다는 걸 다음에 코드만 보고도 알 수 있게). 대안 방향 3가지를 `prototypes/status-icon-smoke/README.md`에 정리해둠(Godot 자체 내부 자동 동기화 신뢰/다른 공식 API 탐색/영속화 방식 자체 재설계). **부가 발견(미해결)**: 이 진단용 최소 씬에서는 `_process()`/`SceneTreeTimer`도 전혀 안 도는 현상 발견 — 단, 실제 게임 화면(메인메뉴 Tween 등)은 정상 동작해서 이 특정 디버그 씬 한정 문제로 보이며 더 조사 안 함.
  - **여전히 남음**: ADR-0001 Validation Criteria가 요구하는 모바일 Safari/Chrome 20회+ 실측, 탭 강제종료 후 재시작 데이터 보존 확인 — 이번 세션 도구로는 불가능. ADR은 계속 Proposed 유지(ADR 불변 기록 컨벤션에 따라 본문 수정 안 함).
  - **재설계 완료 (2026-08-02, 사용자 결정)**: `FS`가 전역에 없다는 근본 원인이 확정되자 사용자가 "웹 저장 경로를 `localStorage`로 완전 교체"를 선택. `save_manager.gd` 전면 재작성 — 웹 분기는 `user://`+`FS.syncfs()` 대신 `JavaScriptBridge.eval()`로 `localStorage.setItem/getItem`을 Base64로 감싸 직접 호출(동기식이라 콜백/타임아웃 로직 자체가 불필요해져 관련 코드 전부 삭제, 데스크톱 경로는 무변경). 테스트 재작성, 182/182 GUT 통과. **실제 웹 빌드에서 `save()` → 메모리 초기화 → `load_from_disk()` 전체 왕복 성공 확인**(`PASS`, 값 정확히 복원) — ADR-0001의 실질 목표(웹에서 저장 확인 가능)가 실제로 달성됨. 남은 건 여전히 모바일 실기기 검증뿐(ADR Proposed 유지). 상세: `prototypes/status-icon-smoke/README.md`.

**ADR-0004 Verification Required (c)/(d) 실측 완료 (2026-08-03)** — 유저 요청으로 남은 검증 항목 중 배포 계정 없이 가능한 것부터 착수. **(c) 프레임 예산**: `change_scene_to_file()`을 `Time.get_ticks_usec()`로 직접 계측(자동화 환경의 rAF 노이즈 우회) — S-02 6.4ms, S-03 17.1ms, **S-04 27.6ms, S-05(BattleScreen) 48.7ms**로 16.6ms 예산 초과 확인(단발성 히치, 지속 드랍 아님). **(d) 탭 백그라운드 30초+ 복귀**: `prototypes/tween-background-resume/`(8초 Tween 격리 씬)로 검증 — 45초 백그라운드 후 복귀해도 거대 delta 스파이크 0건, 백그라운드 시간은 그냥 소실되고 복귀 후 정상 크기 delta로 선형 재개, NaN/오버슈트 없음. 상세는 ADR-0004의 "Last Verified" 섹션 및 두 prototype README 참조. **(b) itch.io COOP/COEP 헤더 지원**은 실제 itch.io 배포 계정이 필요해 여전히 미검증 — ADR-0004 Status는 Proposed 유지. 182/182 GUT 통과, 디버그 계측 전부 원복 후 프로덕션 웹 빌드 재익스포트.

**AdManager JS→GDScript 콜백 릴레이 버그 발견+수정 (2026-08-02)** — 던전 플레이스루로 패배 흐름을 검증하던 중 `RunResultScreen`의 "메인메뉴로" 버튼이 실제 웹 빌드에서 클릭해도 반응 없는 걸 발견(3번 클릭+11초 이상 대기). 원인 추적: `AdManager.show_interstitial()`의 `create_callback()` 기반 JS→GDScript 콜백이 이 Godot 4.7.1 웹 익스포트에서 릴레이되지 않음 — 콘솔에서 `window.GodotAdBridge.adCompleted()`를 수동 호출해도 GDScript `_on_ad_completed()`가 실행되지 않고, 5초 타임아웃 폴백도 발화 안 함. 같은 세션 초반 ADR-0001에서 확인한 문제(GDScript→JS 방향, `FS` 전역 부재)와 정반대 방향의 동일 계열 버그. `prototypes/ad-callback-smoke/`(단독 씬 + 화면 Label)로 격리 재현·검증. **수정**: SDK 존재 여부를 `eval()`의 동기 반환값으로 먼저 확인 → SDK 없으면(현재 MVP 100% 케이스) 깨진 비동기 릴레이를 아예 안 타고 `on_complete.call()` 즉시 호출. SDK 있는 경로는 기존 비동기 콜백 그대로 두되 미검증(실제 SDK 붙는 시점에 재검증 필수 — Open Questions에 추가). `ad_manager.gd`/`ad_manager_test.gd` 수정, 182/182 GUT 통과. 프로토타입 씬으로 재익스포트→실브라우저 로드해 "CALLBACK FIRED" 즉시 표시 확인 후 `main_scene`을 `Boot.tscn`으로 원복, 프로덕션 웹 빌드 재익스포트 완료.

**ADR-0004 프레임 예산 초과 실제 수정 (2026-08-03, 사용자 부재 중 자율 진행)** — (c) 실측(S-04 27.6ms/S-05 48.7ms, 16.6ms 예산 초과)에 대한 실제 코드 수정 착수. `scene_manager.gd`에 남아있던 uncommitted 디버그 계측(`push_warning` 3곳, 중복 적 HP 표시 코스메틱 이슈를 데이터 레벨에서 재확인하던 조사— 데이터는 정상, 표시만 공유되는 기존 문서화된 한계로 재확인 완료)은 제거. 1차 수정(`load_threaded_request()`를 fade 앞으로 옮기고 fade 뒤에 `load_threaded_get()`)을 커밋(`ecba852`) 직후 자체 검토 중 결함 발견 — Godot의 non-thread(Regular) 웹 익스포트에서는 `load_threaded_get_status()`를 매 프레임 폴링하지 않으면 백그라운드 로드가 전혀 진행되지 않는다는 문서화된 동작을 놓쳤음(그냥 요청만 걸어두면 나중에 `get()` 호출 시 그 자리에서 전부 블로킹 — 실질적으로 아무것도 개선 안 됨). `_poll_loading()` 코루틴 추가(`await get_tree().process_frame` 루프)로 정정, 새 커밋(`ffeb44f`). 182/182 GUT 통과 유지. **미검증 항목**: 이 세션에서 Chrome 확장 연결 불가(사용자 부재) — 실제 웹 빌드에서 정확한 ms 재측정은 다음 세션으로 이월. 프로덕션 웹 빌드는 이 수정 반영해 재익스포트 완료.

**ADR-0004 프레임 예산 수정 실측 재확인 완료 (2026-08-04)** — `scene_manager.gd`의 `go_to()`에 `Time.get_ticks_usec()` 기반 임시 계측(`push_warning`)을 넣어 웹 빌드 재익스포트 → 로컬 서버 → claude-in-chrome 실브라우저로 Boot→MainMenu→PartySelect→Dungeon→Battle 실제 플레이하며 콘솔 로그로 측정. 결과: S-02 4.50ms / S-03 1.00ms / S-04 1.30ms / S-05 1.40ms — 전부 16.6ms 예산 내 (수정 전 6.4/17.1/27.6/48.7ms 대비 큰 폭 개선, `_poll_loading()` 수정이 실제로 효과 있었음 확정). 임시 계측 코드 제거하고 파일 상단 doc comment를 실측치로 갱신, 182/182 GUT 재확인, 프로덕션 웹 빌드 재익스포트 완료. ADR-0004는 여전히 (b) itch.io COOP/COEP 헤더 검증(배포 계정 필요)만 남아 Proposed 유지 — 그 외 (c)/(d)는 완전 종결.

**itch.io 최초 배포 완료 (2026-08-04)** — `https://juunj.itch.io/wind-tower` 페이지 생성(Kind=HTML, Draft, Mobile friendly 켬, 자동시작 끔 — 오디오 autoplay 정책 대응). butler CLI 설치(`broth`에서 windows-amd64 최신, `~/.local/butler/butler.exe`, PATH 등록) 및 `butler login`으로 계정 인증(이메일 인증 1회 선행 필요했음). `build/web/`을 `juunj/wind-tower:html` 채널로 push(v0.1.0, 61.61 MiB, build #1856821) — ADR-0004의 마지막 미검증 항목 (b) itch.io COOP/COEP 헤더 지원을 실측할 수 있는 실제 배포 대상이 이제 존재함(이번 세션엔 헤더 자체는 아직 확인 안 함). "playable in browser" 채널 태그를 Edit game 페이지에서 수동 적용 완료, 브라우저로 재방문해 "Run game" 버튼(임베드 플레이, 다운로드 링크 아님) 뜨는 것 확인. 이후 업데이트는 `butler push ./build/web juunj/wind-tower:html --userversion <새버전>`으로 diff만 재업로드.

**ADR-0004 (b) itch.io COOP/COEP 헤더 지원 실측 완료 (2026-08-04)** — 배포 직후 바로 이어서 검증. Edit game 페이지의 "SharedArrayBuffer support (Experimental)" 임베드 옵션(폼 필드 `embed[cdn_type]`)이 COOP/COEP 스위치임을 발견, 실제로 켜고 저장 후 게임 페이지에서 `window.crossOriginIsolated === true` / `typeof SharedArrayBuffer !== 'undefined'`로 실측 확인 — **itch.io는 COOP/COEP를 프로젝트별 옵트인으로 실제 지원**. 검증 후 옵션은 다시 꺼서 원복(`crossOriginIsolated: false` 재확인 완료) — 현재 빌드가 Regular(비스레드) 변형이라 당장 불필요하고 itch 자신이 실험적/파손 위험을 경고하는 옵션이라 실사용 없이 켜둘 이유가 없었음. ADR-0004의 Verification Required (a)~(d) 전부 완료됐으나 Status는 여전히 Proposed 유지 — Threads 변형으로의 실제 전환은 이 ADR을 수정하지 않고 별도 신규 ADR로 처리하는 게 Ordering Note 방침(지금은 검증만, 전환은 안 함). 상세는 `docs/architecture/adr-0004-scene-threaded-loading-coop-coep.md`의 "Last Verified" 섹션 참조.

**#18 광고 통합 — 실제 Ad SDK(Google AdSense H5 Games Ads) 연동 완료 (2026-08-04)** — 사용자가 이미 보유한 AdSense 계정(`ca-pub-2707110870063457`)으로 진행. 조사 결과 AdMob은 네이티브 모바일 SDK 전용이라 웹/HTML5 캔버스 게임엔 해당 없음("AdMob Web"이라는 옵션 자체가 존재하지 않음) — AdSense의 H5 Games Ads(Ad Placement API)가 이 프로젝트에 유일하게 맞는 실질적 선택지였음. itch.io는 게임 페이지 자체엔 광고 스크립트를 금지하지만 게임 파일 내부 광고는 명시적으로 금지하지 않음(다만 "광고 없는 프로젝트 선호"라 문화적으론 드묾) — 당장 막힌 건 아니라 진행.

**구현**: `AdManager.show_interstitial()`을 플레이스홀더(`window.adManager.showInterstitial()`)에서 실제 `adBreak({type:'next', name:'run-result-return', adBreakDone: ...})` 호출로 교체 -- `adBreakDone`은 공식 문서상 광고 표시/스킵/에러/차단 여부와 무관하게 정확히 1회 보장되는 유일한 콜백이라 이걸로 GDScript 콜백을 재개(afterAd 대신 사용, exactly-once 보장이 이유). SDK 존재 판정도 `typeof adBreak === 'function'`으로 교체(head_include의 폴리필이 스크립트 로드 성패 무관하게 즉시 전역 정의하므로 존재 자체보다 나중에 adBreakDone이 알아서 실패를 흡수). `export_presets.cfg`의 `html/head_include`에 AdSense `<script>` 태그 + `adBreak`/`adConfig` 폴리필 주입(퍼블리셔 ID 하드코딩, 이 프로젝트 컨벤션상 `export_presets.cfg` 자체는 기존부터 gitignore 대상).

**실브라우저 검증 + 중요 발견**: `prototypes/ad-callback-smoke/`(기존 하네스 재사용, `main_scene` 임시 교체 → 로컬 서버 → claude-in-chrome → 원복 패턴) 결과 `show_interstitial()` 호출 후 ~3초 내(5초 타임아웃보다 훨씬 전) "CALLBACK FIRED" 확인 — 타임아웃 폴백이 아니라 실제 `adBreakDone → window.GodotAdBridge.adCompleted()` 릴레이가 정상 작동. 네트워크 탭에서 `ep1.adtrafficquality.google/pagead/sodar` 요청(204)도 확인돼 SDK가 실제로 로드·실행 중임을 재확인. **2026-08-02엔 이 동일한 create_callback() 릴레이가 브라우저 DevTools 콘솔의 수동 호출로는 실패했었는데, 지금은 진짜 SDK 콜백 경로로는 성공** — 두 경로(콘솔 수동 vs SDK 내부 콜백)가 왜 다른 결과를 내는지는 미규명, 결과만 재확인. ADR-0003 Validation Criteria 전부 체크 완료, Status를 Proposed → **Accepted**로 전환(상세는 ADR-0003의 "Last Verified" 참조). 182/182 GUT 통과 유지, itch.io(`juunj/wind-tower:html`)에 v0.2.0으로 배포 완료(디버그 하네스는 로컬에서만 확인, 프로덕션 빌드는 `Boot.tscn`으로 원복한 뒤 재익스포트해 배포).

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

- ADR-0001/0003/0004 (전부 ⚠️HIGH) — 문서상 결정은 내려졌으나 실제 브라우저/기기로 검증된 적 없음. 각 ADR의 "Verification Required" 항목이 실제 구현 전 필수 체크리스트. (ADR-0011은 2026-07-27 실측 완료, Accepted로 전환됨 — 더 이상 미해결 아님. **ADR-0004는 2026-08-03 (c)/(d) 실측 완료, 같은 날 (c)가 지적한 프레임 예산 초과 코드 수정 착수(`_poll_loading()`, 커밋 `ffeb44f`), 2026-08-04 실브라우저로 재측정 완료(S-02~S-05 전부 16.6ms 예산 내), 같은 날 (b) itch.io COOP/COEP 헤더 지원도 실측 확인("SharedArrayBuffer support" 옵션, `crossOriginIsolated: true` 확인) — Verification Required (a)~(d) 전부 완료. Threads 변형으로의 실제 전환은 별도 신규 ADR 대상이라 Status는 Proposed 유지.**)
- ~~광고 SDK 구체 선택~~ — 2026-08-04 해결. AdSense H5 Games Ads(Ad Placement API)로 확정 및 연동, 실브라우저 검증 완료(위 "Current Task" 참조). **단, 실제 수익화는 별도 블로커에 막혀 있음** — AdSense "Add site"가 서브도메인(`juunj.itch.io`)이 아니라 최상위 도메인(`itch.io`) 소유권 인증을 요구, itch.io는 제3자 소유 도메인이라 인증 불가 확인(2026-08-04, 실제 시도). **결론**: itch.io + 개인 AdSense 계정은 구조적으로 안 맞음 — itch.io는 계속 무료 배포처로 유지, 광고 수익화는 사용자가 나중에 가비아 등으로 자체 도메인을 구매한 뒤 그 도메인에 웹빌드를 별도 호스팅하는 시점으로 미룸. 코드(`AdManager`/`export_presets.cfg` head_include)는 도메인 비의존적이라 그때 그대로 재사용 가능, 추가 작업 불필요.
- 런-결과: 메인메뉴 전환 광고 게이트 배치가 "실패해도 남는 것" 판타지와 다소 긴장 관계 — 재도전 기능 설계 시 재검토.
- 파티 구성: 이전 파티 선택 유지 여부 (MVP: 초기화, Full Vision: 편의성 개선).
- ~~**보스 스탯 밸런스**~~ — 2026-08-02 해결, 위 "Current Task" 참조.

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
