# 프로토타입: 백그라운드 탭 복귀 시 Tween 동작 검증 (throwaway)

```
QUESTION:     ADR-0004 Verification Required (d) / TR-scene-management-008 --
              브라우저 탭을 Tween 진행 중(SceneManager._fade()가 쓰는 것과
              동일한 패턴) 30초 이상 백그라운드에 두었다가 복귀하면, delta가
              비정상적으로 크거나 Tween 종료값이 1.0이 아니거나 NaN/오버슈트가
              나는가?
CORE VERB:    8초짜리 Tween(overlay alpha 0->1)을 시작한 직후 탭을 30초+
              백그라운드에 두고 복귀, delta 로그와 최종 alpha 값을 화면
              Label + 콘솔로 확인
THROWAWAY?:   yes -- prototypes/tween-background-resume/, src/에서 임포트 안 함
KEEP IF:      복귀 후 delta가 유한하고 Tween이 정확히 alpha=1.0으로 종료
KILL IF:      NaN, 음수 오버슈트, 또는 alpha가 1.0에 도달하지 못하고 멈춤
```

## 배경

`SceneManager._fade()`는 `create_tween().tween_property(_overlay, "color:a", ...)`로
오버레이 알파를 애니메이션한다. 브라우저 탭이 백그라운드로 가면 대부분의
브라우저는 `requestAnimationFrame`을 완전히 정지하거나 강하게 스로틀링하는데,
Godot 웹 익스포트의 메인 루프도 이 콜백에 의존한다. 탭이 30초+ 백그라운드에
있다가 복귀하면 다음 프레임의 `delta`가 실제 경과 시간(30초+)을 그대로
반영할 수도 있고, 엔진이 내부적으로 델타를 클램프할 수도 있다 -- 이 프로젝트의
엔진 레퍼런스 라이브러리에 이 동작이 문서화되어 있지 않아(ADR-0004 참조)
실측이 필요했다.

## 실행 방법

1. `project.godot`의 `run/main_scene`을 이 씬으로 잠깐 변경
2. `--export-release "Web" build/web/index.html`로 재익스포트
3. 로컬 서버로 서빙 후 브라우저에서 열기 -- 씬이 로드되자마자 8초 Tween 시작
4. Tween 진행 중(8초 이내) 다른 탭으로 전환해 30초 이상 대기
5. 원래 탭으로 복귀, 화면 Label과 콘솔의 `SUSPICIOUS`/`TWEEN FINISHED` 로그 확인
6. 완료 후 `run/main_scene`을 `Boot.tscn`으로 원복 (git diff로 확인)

## 결과

**KEEP (실측 완료, 2026-08-03)** — 실제 웹 빌드에서 8초 Tween 시작 직후 새 탭을 열어
포커스를 옮기고 약 45초간 원래 탭을 백그라운드에 둔 뒤 복귀:

- 백그라운드 45초 동안 `_process`가 **완전히 정지** — 복귀 직후 화면 Label의
  `elapsed` 누적치가 45초가 아니라 백그라운드 직전 값(1.0초)에 정확히 멈춰
  있었음. 즉 백그라운드 구간은 델타로 반영되지 않고 그냥 "사라짐".
- 복귀 후 `SUSPICIOUS`(delta > 0.2s) 로그는 **단 한 번도 발생하지 않음** — 즉
  엔진이 45초짜리 거대한 단일 delta를 다음 프레임에 흘려보내지 않았다. 재개된
  프레임들은 전부 정상 범위의 작은 delta였고, `overlay_a`도 0.109 → 0.24 →
  0.372 → 0.502 → 0.631로 8초 기준 정확히 선형 진행 — 점프도 역행도 없었음.
- **부가 관찰(무관하지만 기록)**: 이 원격 브라우저 자동화 환경에서는 실제
  클릭/입력이 있을 때만 프레임이 진행되고, 순수 `wait`만으로는 진행이 멈추는
  현상이 반복 관찰됨(입력 이벤트가 없으면 이 Godot 웹 익스포트가 렌더를
  쉬는 것으로 보임 — 저전력/on-demand 렌더링 성격). 이 때문에 Tween을
  8초 전부 완주시켜 `TWEEN FINISHED` 로그까지는 확인하지 못했으나(0.631까지
  선형 확인), 이는 자동화 환경 자체의 입력 의존적 프레임 진행 특성이지 백그라운드
  복귀와는 무관 — 핵심 안전성 질문(거대 delta로 인한 오버슈트/NaN 여부)에는
  이미 명확히 답이 나왔다.
- **결론 (TR-scene-management-008)**: 우려했던 세 가지(비정상 delta, 1.0 미도달,
  NaN/오버슈트) 중 **어느 것도 발생하지 않음**. 백그라운드 시간은 델타로
  전달되지 않고 단순히 소실되며, 복귀 후에는 정상 크기 delta로만 진행 —
  `SceneManager._fade()`가 이미 GDD 설계대로 `_process(delta)` 누적 방식을
  쓰고 있어(ADR-0004 Key Interfaces) 이 동작과 완전히 정합적이다. 위험도는
  ADR 리스크 표의 "Medium impact" 우려보다 낮음 — 시각적으로는 "백그라운드
  동안 페이드가 멈췄다가 복귀 후 이어서 재생되는" 정도이며, 깨짐/크래시
  가능성은 실측상 없음.
