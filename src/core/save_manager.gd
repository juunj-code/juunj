extends Node
## Autoload. Section-based local save/load. See design/gdd/로컬-세이브.md.
##
## Desktop/editor: FileAccess against user://, atomic write via separately-
## callable _write_temp()/_swap() (GDD AC4 testability note), schema_version,
## corruption detection, size budget.
##
## Web: FS.syncfs()-based durability confirmation (the original ADR-0001
## design) turned out to be unworkable -- confirmed 2026-08-02 via a real
## web-export browser test (prototypes/status-icon-smoke/README.md) that
## `FS`/`Module` are Emscripten internals never exposed on `window`, so
## JavaScriptBridge.eval("FS.syncfs(...)") threw ReferenceError every time
## and the durability callback could never fire. Redesigned instead to skip
## user://+IDBFS entirely on web and write straight to browser localStorage
## via JavaScriptBridge.eval() -- confirmed reachable in the same real-build
## test (unlike FS, localStorage/window/document are genuinely global).
## localStorage.setItem()/getItem() are synchronous, so there's no async
## durability gap to confirm in the first place: if eval() didn't throw, the
## write already happened. Same _js_bridge/_web_override DI seam as
## ad_manager.gd (ADR-0003) for testability.

const SCHEMA_VERSION := 1
const SAVE_PATH := "user://savegame.dat"
const TEMP_PATH := "user://savegame.dat.tmp"
const LOCAL_STORAGE_KEY := "windtower_save_b64"
const SAVE_FILE_SIZE_WARN_BYTES := 131072
const SAVE_FILE_SIZE_BUDGET_BYTES := 262144
## JSON has no int type -- numbers always round-trip as float (e.g. saved
## int 3 loads back as 3.0). Consumers reading numeric section fields should
## int()-cast if they need an int. This is a JSON property, not a bug here.

signal save_succeeded
signal save_failed(reason: String)
signal load_completed
signal save_corrupted_and_reset

var _sections: Dictionary = {}
var _js_bridge = JavaScriptBridge # DI 시임 -- 테스트에서 mock으로 교체 (ADR-0003과 동일 패턴)
var _web_override = null # DI 시임 -- true/false로 강제, null=실제 OS 값 사용

func _ready() -> void:
	load_from_disk()

func _is_web() -> bool:
	if _web_override != null:
		return _web_override
	return OS.has_feature("web")

func save_section(name: String, data: Variant) -> void:
	_sections[name] = data

func get_section(name: String) -> Variant:
	return _sections.get(name)

## Explicit trigger only -- nothing calls this automatically (Core Rule 2).
## Return value and durability are the same guarantee on both platforms now
## (both paths are synchronous) -- unlike the old FS.syncfs design, there's
## no separate "confirmed later" stage.
func save() -> bool:
	var payload := {"schema_version": SCHEMA_VERSION, "sections": _sections}
	var json_str := JSON.stringify(payload)
	var size := json_str.to_utf8_buffer().size()

	if size > SAVE_FILE_SIZE_BUDGET_BYTES:
		push_error("SaveManager: save size %d exceeds budget %d" % [size, SAVE_FILE_SIZE_BUDGET_BYTES])
		save_failed.emit("size_budget_exceeded")
		return false
	if size >= SAVE_FILE_SIZE_WARN_BYTES:
		push_warning("SaveManager: save size %d approaching budget %d" % [size, SAVE_FILE_SIZE_BUDGET_BYTES])

	var ok: bool = _save_web(json_str) if _is_web() else (_write_temp(json_str) and _swap())
	if not ok:
		save_failed.emit("write_failed")
		return false

	save_succeeded.emit()
	return true

## Base64 round-trip avoids ever building a JS string literal out of raw JSON
## (quotes/newlines) -- the base64 alphabet is always safe to embed directly.
func _save_web(json_str: String) -> bool:
	var b64 := Marshalls.utf8_to_base64(json_str)
	var code := "(function(){ try { localStorage.setItem('%s', '%s'); return 'ok'; } catch (e) { return 'error:' + e.message; } })()" % [LOCAL_STORAGE_KEY, b64]
	var result = _js_bridge.eval(code, true)
	return result == "ok"

func _load_web() -> String:
	var code := "(function(){ var v = localStorage.getItem('%s'); return v === null ? '' : v; })()" % LOCAL_STORAGE_KEY
	var b64 = _js_bridge.eval(code, true)
	if b64 == null or b64 == "":
		return ""
	return Marshalls.base64_to_utf8(b64)

## Exposed separately so tests can simulate "process killed between temp-write
## and swap" by calling this and never calling _swap() (GDD AC4 testability note).
func _write_temp(json_str: String) -> bool:
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(json_str)
	f.close()
	return true

func _swap() -> bool:
	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	if dir.file_exists(SAVE_PATH):
		dir.remove(SAVE_PATH)
	return dir.rename(TEMP_PATH, SAVE_PATH) == OK

func load_from_disk() -> void:
	var content: String
	if _is_web():
		content = _load_web()
		if content == "":
			return # No Save Found -- not an error, #14 initializes its own defaults
	else:
		if not FileAccess.file_exists(SAVE_PATH):
			return
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		content = f.get_as_text()
		f.close()

	if _is_corrupted(content):
		_backup_and_reset()
		return

	var parsed = JSON.parse_string(content)
	_sections = parsed["sections"]
	load_completed.emit()

## Formula 4's 5-check OR (any one true = corrupted).
func _is_corrupted(content: String) -> bool:
	if content.length() == 0:
		return true
	var parsed = JSON.parse_string(content)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return true
	if not parsed.has("schema_version"):
		return true
	var version = parsed["schema_version"]
	if not (version is int or version is float):
		return true
	if int(version) < 1 or int(version) > SCHEMA_VERSION:
		return true
	return false

func _backup_and_reset() -> void:
	if _is_web():
		var code := "(function(){ var v = localStorage.getItem('%s'); if (v !== null) localStorage.setItem('%s', v); })()" % [LOCAL_STORAGE_KEY, LOCAL_STORAGE_KEY + "_corrupted_bak"]
		_js_bridge.eval(code, true)
	else:
		var dir := DirAccess.open("user://")
		if dir and dir.file_exists(SAVE_PATH):
			dir.rename(SAVE_PATH.get_file(), SAVE_PATH.get_file() + ".corrupted.bak")
	_sections = {}
	push_error("Save file corrupted, backed up and reset")
	save_corrupted_and_reset.emit()
