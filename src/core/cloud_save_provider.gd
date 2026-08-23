class_name CloudSaveProvider
extends RefCounted
## #5 클라우드 세이브 (Full Vision, Not Started) — extension point only.
##
## Real Firebase 연동은 Firebase 프로젝트 생성/API 키 발급(사용자 계정 작업)이
## 선행돼야 하고, 아직 MVP도 런칭 전이라 실사용자/실기기가 없어 지금 당장의
## 가치가 낮음(ponytail — YAGNI). 이 인터페이스 + SaveManager.cloud_provider
## 훅만 미리 만들어둬서, 실제 Firebase 자격증명이 생기면 서브클래스 하나만
## 추가하고 SaveManager.cloud_provider에 주입하면 바로 연결되게 함.
##
## 기본값은 NullCloudSaveProvider(null_cloud_save_provider.gd) — 아무 것도
## 하지 않는 완전한 no-op.

## sections 전체(SaveManager._sections와 동일 shape)를 클라우드에 업로드.
## 실패해도 로컬 세이브를 막지 않음(SaveManager.save()는 이 결과를 기다리지
## 않고 fire-and-forget으로 호출) — 클라우드는 항상 로컬의 보조 백업일 뿐.
func save_async(_sections: Dictionary) -> bool:
	return false

## 클라우드에 저장된 sections를 가져옴. 없거나 미구현이면 null.
func load_async() -> Variant:
	return null
