# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Godot Rendering Server (Forward+ / Compatibility — TBD at project creation)
- **Physics**: Jolt Physics (Godot 4.6 default)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: 브라우저 (PC + 모바일 브라우저) → iOS/Android 앱 (2단계)
- **Input Methods**: Touch (primary), Keyboard/Mouse (secondary)
- **Primary Input**: Touch (모바일 브라우저 우선)
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: 모든 UI는 터치 탭으로 조작 가능해야 함. 호버(hover) 전용 인터랙션 금지. 버튼 최소 크기 44×44px (모바일 접근성 기준). 웹 내보내기 로딩 시간 최적화 필수.

## Naming Conventions

- **Classes**: PascalCase (예: `PlayerController`, `CompanionData`)
- **Variables/Functions**: snake_case (예: `move_speed`, `take_damage()`)
- **Signals**: snake_case 과거형 (예: `health_changed`, `companion_unlocked`, `run_ended`)
- **Files**: snake_case, 클래스와 일치 (예: `player_controller.gd`, `companion_data.gd`)
- **Scenes**: PascalCase, 루트 노드와 일치 (예: `PlayerController.tscn`, `BattleScreen.tscn`)
- **Constants**: UPPER_SNAKE_CASE (예: `MAX_HEALTH`, `BASE_DAMAGE`)

## Performance Budgets

- **Target Framerate**: 60fps
- **Frame Budget**: 16.6ms
- **Draw Calls**: 100 이하 (모바일 브라우저 기준)
- **Memory Ceiling**: 256MB (모바일 브라우저 환경 고려)

## Testing

- **Framework**: GUT (Godot Unit Testing) — `addons/gut/`
- **Minimum Coverage**: 핵심 게임플레이 시스템 (전투 공식, 동료 해금 로직, 던전 생성)
- **Required Tests**: 전투 데미지 공식, 동료 영구 해금 상태 관리, 랜덤 던전 방 생성 유효성

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
<!-- Only add when actively integrating — do NOT add speculatively -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (모든 .gd 파일)
- **Shader Specialist**: godot-shader-specialist (.gdshader 파일, VisualShader 리소스)
- **UI Specialist**: godot-specialist (전용 UI 스페셜리스트 없음 — Primary가 담당)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / 네이티브 C++ 바인딩 전용)
- **Routing Notes**: 아키텍처 결정, ADR 검증, 교차 코드 리뷰는 Primary 사용. 코드 품질, 시그널 아키텍처, 정적 타입 강제, GDScript 관용구는 GDScript 스페셜리스트 사용. 머티리얼/셰이더는 Shader 스페셜리스트. GDExtension은 네이티브 확장이 필요할 때만.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
