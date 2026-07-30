extends GutTest
## Covers design/gdd/UI-HUD.md Core Rule 3 (single popup, FIFO queue) and AC4/AC5.

func test_first_popup_becomes_current_immediately() -> void: # AC4
	var q := HudPopupQueue.new()

	q.enqueue({"text": "first"})

	assert_eq(q.current, {"text": "first"})
	assert_true(q.is_blocking())

func test_second_popup_while_one_active_does_not_replace_current() -> void: # Core Rule 3
	var q := HudPopupQueue.new()
	q.enqueue({"text": "first"})

	q.enqueue({"text": "second"})

	assert_eq(q.current, {"text": "first"})

func test_confirm_shows_next_queued_popup() -> void: # AC5
	var q := HudPopupQueue.new()
	q.enqueue({"text": "first"})
	q.enqueue({"text": "second"})

	q.confirm()

	assert_eq(q.current, {"text": "second"})
	assert_true(q.is_blocking())

func test_confirm_with_empty_queue_clears_current_and_unblocks() -> void: # AC5
	var q := HudPopupQueue.new()
	q.enqueue({"text": "first"})

	q.confirm()

	assert_null(q.current)
	assert_false(q.is_blocking())

func test_no_popup_shown_is_not_blocking() -> void:
	var q := HudPopupQueue.new()

	assert_false(q.is_blocking())
