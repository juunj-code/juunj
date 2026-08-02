extends Node
## Autoload. Section-based local save/load. See design/gdd/로컬-세이브.md.
##
## ponytail: implements the synchronous core (section API, atomic write via
## separately-callable _write_temp()/_swap() per the GDD's own AC4 testability
## note, schema_version, corruption detection, size budget) against real
## FileAccess -- this is correct and fully testable on desktop today.
##
## KNOWN BROKEN on real web builds (confirmed 2026-08-02, see
## prototypes/status-icon-smoke/README.md): `FS` is not a global JS symbol
## reachable from JavaScriptBridge.eval() in this Godot 4.7.1 web export --
## Emscripten's Module/FS live in a closure the export doesn't expose on
## `window`. _confirm_durable_write()'s eval() call below throws
## ReferenceError every time on web, so _on_indexeddb_sync_done() and the
## timeout failsafe never fire and save_succeeded/save_failed never emit on
## web. Desktop/editor path (the `not _is_web()` branch) is unaffected and
## correct. Needs a redesign, not a patch -- see the README for candidate
## directions (trust Godot's own internal user:// sync instead of calling
## FS.syncfs() ourselves, or find whichever API surface, if any, Godot 4.7
## actually exposes for this). Left as-is rather than half-fixed blind.
##
## ADR-0001 stage 2 (IndexedDB durable-sync confirmation via FS.syncfs(),
## same JS-bridge DI pattern as ad_manager.gd/ADR-0003) is implemented below.
## save()'s bool RETURN VALUE still means stage 1 only (vFS write succeeded)
## -- unchanged from before, so ProgressManager.commit_run_end()'s synchronous
## use of it keeps working as-is. The save_succeeded/save_failed SIGNALS are
## what ADR-0001 actually governs: on web they now wait for stage 2 (durable
## confirm) before firing; on non-web stage 2 is a same-frame passthrough so
## signal timing is unchanged there. Nothing currently listens to those
## signals (checked 2026-08-02), so this split costs no caller a migration
## today -- a future "저장 중..." web UI should listen to the signals, not
## the return value, to get the real durability guarantee.
##
## Still deferred: the retry/timeout/queue *state machine* (exponential
## backoff, SAVE_LOCK_QUEUE_MAX) ADR-0001 describes for repeated failures --
## its timing constants are explicitly unmeasured placeholders in the ADR
## (Validation Criteria needs real mobile Safari/Chrome data first). Built
## instead: a single SAVE_SYNC_TIMEOUT_MS failsafe (same shape as
## ad_manager.gd's AD_TIMEOUT_MS, no retry loop) so a hung/missing JS
## callback can't wedge the save flow forever. Add real retry/backoff once
## ADR-0001 is Accepted with measured numbers.

const SCHEMA_VERSION := 1
const SAVE_PATH := "user://savegame.dat"
const TEMP_PATH := "user://savegame.dat.tmp"
const SAVE_FILE_SIZE_WARN_BYTES := 131072
const SAVE_FILE_SIZE_BUDGET_BYTES := 262144
const SAVE_SYNC_TIMEOUT_MS := 5000
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
var _sync_timeout_timer: SceneTreeTimer

func _ready() -> void:
	load_from_disk()
	if _is_web():
		_js_bridge.eval("window.GodotSaveBridge = {};", true)
		var bridge = _js_bridge.get_interface("window").GodotSaveBridge
		bridge.onSyncDone = _js_bridge.create_callback(_on_indexeddb_sync_done)

func _is_web() -> bool:
	if _web_override != null:
		return _web_override
	return OS.has_feature("web")

func save_section(name: String, data: Variant) -> void:
	_sections[name] = data

func get_section(name: String) -> Variant:
	return _sections.get(name)

## Explicit trigger only -- nothing calls this automatically (Core Rule 2).
## Return value is stage 1 (vFS write) only -- see file header re: signals.
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

	if not _write_temp(json_str):
		save_failed.emit("write_failed")
		return false
	if not _swap():
		save_failed.emit("swap_failed")
		return false

	_confirm_durable_write()
	return true

## ADR-0001 stage 2. Non-web: durability isn't in question (real disk via
## FileAccess), so confirm immediately. Web: ask the browser to flush the
## Emscripten virtual FS to IndexedDB and wait for its callback, with a
## single timeout failsafe so a missing/hung callback can't wedge forever.
func _confirm_durable_write() -> void:
	if not _is_web():
		_on_indexeddb_sync_done(null)
		return
	_sync_timeout_timer = get_tree().create_timer(SAVE_SYNC_TIMEOUT_MS / 1000.0)
	_sync_timeout_timer.timeout.connect(_on_sync_timeout)
	_js_bridge.eval("FS.syncfs(false, function(err) { GodotSaveBridge.onSyncDone(err); });")

func _on_indexeddb_sync_done(err) -> void: # JS에서 GodotSaveBridge.onSyncDone(err) 호출 시
	if _sync_timeout_timer:
		_sync_timeout_timer.timeout.disconnect(_on_sync_timeout)
		_sync_timeout_timer = null
	if err:
		save_failed.emit("indexeddb_sync_failed")
	else:
		save_succeeded.emit()

func _on_sync_timeout() -> void:
	_sync_timeout_timer = null
	save_failed.emit("indexeddb_sync_timeout")

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
	if not FileAccess.file_exists(SAVE_PATH):
		return # No Save Found -- not an error, #14 initializes its own defaults

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content := f.get_as_text()
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
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists(SAVE_PATH):
		dir.rename(SAVE_PATH.get_file(), SAVE_PATH.get_file() + ".corrupted.bak")
	_sections = {}
	push_error("Save file corrupted, backed up and reset")
	save_corrupted_and_reset.emit()
