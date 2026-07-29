extends Node
## Autoload. Section-based local save/load. See design/gdd/로컬-세이브.md.
##
## ponytail: implements the synchronous core (section API, atomic write via
## separately-callable _write_temp()/_swap() per the GDD's own AC4 testability
## note, schema_version, corruption detection, size budget) against real
## FileAccess -- this is correct and fully testable on desktop today. Deferred:
## the retry/timeout/queue state machine (SAVE_WRITE_TIMEOUT_MS, exponential
## backoff, SAVE_LOCK_QUEUE_MAX) -- that machinery exists specifically to
## paper over HTML5/IndexedDB's unverified async write durability (ADR-0001,
## still Proposed), which doesn't exist on synchronous desktop FileAccess.
## Add when ADR-0001 is Accepted and there's a real web build to test against.

const SCHEMA_VERSION := 1
const SAVE_PATH := "user://savegame.dat"
const TEMP_PATH := "user://savegame.dat.tmp"
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

func _ready() -> void:
	load_from_disk()

func save_section(name: String, data: Variant) -> void:
	_sections[name] = data

func get_section(name: String) -> Variant:
	return _sections.get(name)

## Explicit trigger only -- nothing calls this automatically (Core Rule 2).
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

	save_succeeded.emit()
	return true

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
