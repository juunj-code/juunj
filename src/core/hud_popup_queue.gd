class_name HudPopupQueue
extends RefCounted
## Single-active-popup + FIFO queue state machine. See design/gdd/UI-HUD.md
## Core Rule 3 ("팝업 중첩 없음, 큐에 순서대로") and AC4/AC5. Popup content is
## caller-supplied (Dictionary) -- this class only owns ordering/blocking.

var current: Variant = null
var _queue: Array[Dictionary] = []

## AC4 (first popup shows immediately). Later ones queue instead of nesting.
func enqueue(popup: Dictionary) -> void:
	if current == null:
		current = popup
	else:
		_queue.append(popup)

## AC5 (confirm dismisses current; next queued popup takes over, if any).
func confirm() -> void:
	current = _queue.pop_front() if not _queue.is_empty() else null

## Core Rule 2 -- dungeon/battle input stays disabled while true.
func is_blocking() -> bool:
	return current != null
