class_name NullCloudSaveProvider
extends CloudSaveProvider
## #5 클라우드 세이브 — 기본 구현. 아무 동작도 하지 않는 no-op. 실제 Firebase
## 자격증명이 없는 지금 SaveManager.cloud_provider의 유일한 provider. 부모의
## save_async()/load_async() 기본 동작(false/null)을 그대로 상속 -- 재정의할
## 것이 없음.
