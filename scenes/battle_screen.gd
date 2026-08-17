extends Control
## S-05 BattleScreen. See design/gdd/턴제-전투.md, design/gdd/UI-HUD.md. Renders
## TurnBattle's #20 signal contract and forwards player choices back via
## submit_action()/submit_target(). AC1(HP)은 신호->렌더 그대로 바인딩(HudRules에
## 로직 없음, 여기서 직접 처리).

@onready var _party_container: HBoxContainer = %PartyContainer
@onready var _enemy_container: HBoxContainer = %EnemyContainer
@onready var _turn_label: Label = %TurnLabel
@onready var _turn_queue_row: HBoxContainer = %TurnQueueRow
@onready var _basic_attack_button: Button = %BasicAttackButton
@onready var _skill_button: Button = %SkillButton
@onready var _target_container: VBoxContainer = %TargetContainer

var _battle: TurnBattle
var _labels: Dictionary = {} # "id#index" (TD-001) -> Label
var _hp_bars: Dictionary = {} # "id#index" -> ProgressBar
var _sp_labels: Dictionary = {} # "id#index" -> Label
var _status_rows: Dictionary = {} # "id#index" -> HBoxContainer
var _base_hp: Dictionary = {} # "id#index" -> int
var _cards: Dictionary = {} # "id#index" -> PanelContainer, for hit feedback (pop/damage number)
var _display_names: Dictionary = {} # unit_id -> String, for signals that only carry unit_id
var _current_unit: Dictionary = {}
var _queue_chips: Dictionary = {} # "id#index" (TD-001) -> PanelContainer, for current-turn highlight

static func _unit_key(id: String, index: int) -> String:
	return "%s#%d" % [id, index]

func _ready() -> void:
	if RunManager.state != "IN_COMBAT":
		push_warning("BattleScreen loaded while RunManager.state=%s -- ignoring" % RunManager.state)
		return
	_battle = TurnBattle.new()
	add_child(_battle)
	_battle.setup(RunManager.party, RunManager.current_enemies)
	_build_rows(_battle.party_units, _party_container)
	_build_rows(_battle.enemy_units, _enemy_container)

	_battle.turn_order_changed.connect(_on_turn_order_changed)
	_battle.turn_started.connect(_on_turn_started)
	_battle.action_executed.connect(_on_action_executed)
	_battle.player_input_requested.connect(_on_player_input_requested)
	_battle.unit_hp_changed.connect(_on_unit_hp_changed)
	_battle.unit_sp_changed.connect(_on_unit_sp_changed)
	_battle.status_effects_changed.connect(_on_status_effects_changed)
	AudioManager.bind_battle(_battle)

	_basic_attack_button.pressed.connect(_on_basic_attack_pressed)
	_skill_button.pressed.connect(_on_skill_pressed)
	_set_action_buttons_enabled(false)

	_battle.run_battle()

## 2026-08-15: bumped from 96x96 -- documented in art-bible.md Section 3-3
## "동료 카드 초상화 표시 크기". Companion portraits are being unified to a
## chest-up bust framing (portrait-prompts.md's original spec); this size
## is tuned for that framing, not a full-body figure.
const _PORTRAIT_SIZE := Vector2(150, 150)

## 2026-08-09: visual polish pass -- was flat sprite+label+label+row siblings
## directly in the party/enemy VBoxContainer, which (a) let each unit's sprite/
## portrait stretch to the full container width under EXPAND_FIT_WIDTH_
## PROPORTIONAL (the "smeared into a wide box" look), and (b) showed raw
## companion_id/enemy_id strings instead of display names. Now each unit gets
## its own bordered card (CompanionData.color_accent as the border for
## companions -- reusing the field #3's discovery flash already uses, no new
## asset needed) with a centered, size-locked portrait/sprite and a real HP bar.
func _build_rows(units: Array, container: HBoxContainer) -> void:
	for unit in units:
		var key := _unit_key(unit["id"], unit["index"])
		_display_names[unit["id"]] = _display_name(unit)
		container.add_child(_build_card(unit, key))

func _display_name(unit: Dictionary) -> String:
	if unit["is_companion"]:
		return CompanionRegistry.get_by_id(unit["id"]).name
	return EnemyRegistry.get_by_id(unit["id"]).name

func _portrait_path(unit: Dictionary) -> String:
	if unit["is_companion"]:
		return CompanionRegistry.get_by_id(unit["id"]).portrait_id
	return unit.get("sprite_id", "")

func _accent_color(unit: Dictionary) -> Color:
	if unit["is_companion"]:
		return CompanionRegistry.get_by_id(unit["id"]).color_accent
	return Color(0.45, 0.48, 0.55) # neutral -- EnemyData has no accent color field

## Standing token card -- HBoxContainer parents (UnitsRow's Party/EnemyContainer)
## shrink cards to content width instead of stretching them full-width, so
## units read as figures standing in the room rather than list rows. Enemy
## portraits are mirrored to face the party (screen-left), completing the
## "facing off" read the background alone couldn't give.
func _build_card(unit: Dictionary, key: String) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.15, 0.18, 0.78)
	style.border_color = _accent_color(unit)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 10)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var portrait_path := _portrait_path(unit)
	if portrait_path != "":
		var center := CenterContainer.new()
		vbox.add_child(center)
		var portrait := TextureRect.new()
		portrait.texture = load(portrait_path)
		portrait.custom_minimum_size = _PORTRAIT_SIZE
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER # don't stretch to card width
		portrait.flip_h = not unit["is_companion"]
		center.add_child(portrait)

	var name_label := Label.new()
	name_label.text = _display_name(unit)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var hp_bar := ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = unit["base_hp"]
	hp_bar.value = unit["current_hp"]
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(hp_bar)
	_hp_bars[key] = hp_bar

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	_labels[key] = label
	_base_hp[key] = unit["base_hp"]
	_render_label(label, key, unit["current_hp"])

	var sp_label := Label.new()
	sp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sp_label)
	_sp_labels[key] = sp_label
	sp_label.text = HudRules.sp_dots(unit["current_sp"])

	var status_row := HBoxContainer.new()
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(status_row)
	_status_rows[key] = status_row
	_render_status_row(status_row, unit["active_effects"])

	_cards[key] = card
	return card

func _render_label(label: Label, key: String, hp: int) -> void:
	label.text = "%d/%d HP" % [hp, _base_hp[key]]

const _STATUS_ICON_SIZE := Vector2(24, 24) ## design/art/art-bible.md Section 5 icon frame

func _render_status_row(row: HBoxContainer, effects: Array) -> void:
	for child in row.get_children():
		child.queue_free()
	for effect in effects:
		if effect.icon_id != "":
			var icon := TextureRect.new()
			icon.texture = load(effect.icon_id)
			icon.custom_minimum_size = _STATUS_ICON_SIZE
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			row.add_child(icon)
		else:
			var name_label := Label.new()
			name_label.text = effect.name
			row.add_child(name_label)
		var duration_label := Label.new()
		duration_label.text = "(%d)" % effect.duration
		row.add_child(duration_label)

## 2026-08-15: hit feedback -- floating damage/heal number + a squash-pop on
## the hit unit's card (game-feel skill's "eased tween, not linear" pattern).
## HP delta isn't in the signal (unit_hp_changed only carries the new value,
## per UI-HUD.md's contract) -- diffed here against the bar's current value
## instead of touching that signal's shape.
func _on_unit_hp_changed(unit_id: String, unit_index: int, new_hp: int) -> void:
	var key := _unit_key(unit_id, unit_index)
	if _labels.has(key):
		_render_label(_labels[key], key, new_hp)
	if _hp_bars.has(key):
		var hp_bar: ProgressBar = _hp_bars[key]
		var delta := int(hp_bar.value) - new_hp
		if delta != 0:
			var stagger := _next_stagger_delay()
			_spawn_damage_number(key, delta, stagger)
			_pop_card(key, stagger)
		hp_bar.value = new_hp

const _DAMAGE_COLOR := Color(0.85, 0.25, 0.25)
const _HEAL_COLOR := Color(0.35, 0.85, 0.45)
const _STAGGER_STEP := 0.08 ## seconds between same-frame multi-hits (all_allies heal etc.)

var _last_hit_frame := -999
var _hit_batch_index := 0

## Party-wide skills (all_allies) call _sync() per unit synchronously in the
## same frame -- without this, every number in the batch would pop and float
## in perfect lockstep instead of reading as a sequence (damage-number
## research: multi-hit numbers should stagger by tens of ms, not fire at once).
func _next_stagger_delay() -> float:
	var frame := Engine.get_process_frames()
	_hit_batch_index = (_hit_batch_index + 1) if frame - _last_hit_frame <= 1 else 0
	_last_hit_frame = frame
	return _hit_batch_index * _STAGGER_STEP

func _spawn_damage_number(key: String, delta: int, stagger: float) -> void:
	if not _cards.has(key):
		return
	var card: Control = _cards[key]
	var label := Label.new()
	label.text = "-%d" % delta if delta > 0 else "+%d" % -delta
	label.add_theme_color_override("font_color", _DAMAGE_COLOR if delta > 0 else _HEAL_COLOR)
	label.add_theme_font_size_override("font_size", 22)
	label.z_index = 10
	label.modulate.a = 0.0
	add_child(label)
	label.global_position = card.global_position + Vector2(card.size.x / 2 - 12, 4)
	var start_y := label.global_position.y

	var tw := create_tween()
	tw.tween_interval(stagger)
	tw.tween_callback(func(): label.modulate.a = 1.0)
	tw.set_parallel(true)
	tw.tween_property(label, "global_position:y", start_y - 36, 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.15)
	tw.chain().tween_callback(label.queue_free)

func _pop_card(key: String, stagger: float) -> void:
	if not _cards.has(key):
		return
	var card: Control = _cards[key]
	card.pivot_offset = card.size / 2
	var tw := create_tween()
	tw.tween_interval(stagger)
	tw.tween_callback(func(): card.scale = Vector2(1.15, 0.85))
	tw.tween_property(card, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

const _LUNGE_DISTANCE := 24.0

## Combat had zero attacker motion (menu-driven, HP just changed) -- the
## reason hit-stop was skipped in the last polish pass ("no movement to
## stop"). This gives every action a small lunge-and-return toward its
## target, attacker or target identified via action_executed (unit_hp_changed
## alone can't tell who acted). Runs before the hit-pop/damage-number tween
## on the target card, so the two read as one impact instead of overlapping.
func _on_action_executed(actor_id: String, actor_index: int, target_id: String, target_index: int, _action: String) -> void:
	var actor_key := _unit_key(actor_id, actor_index)
	var target_key := _unit_key(target_id, target_index)
	if not _cards.has(actor_key) or not _cards.has(target_key) or actor_key == target_key:
		return
	var actor_card: Control = _cards[actor_key]
	var target_card: Control = _cards[target_key]
	var direction := (target_card.global_position - actor_card.global_position).normalized()
	var start_pos := actor_card.position
	var tw := create_tween()
	tw.tween_property(actor_card, "position", start_pos + direction * _LUNGE_DISTANCE, 0.09) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(actor_card, "position", start_pos, 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _on_unit_sp_changed(unit_id: String, unit_index: int, new_sp: int) -> void:
	var key := _unit_key(unit_id, unit_index)
	if _sp_labels.has(key):
		_sp_labels[key].text = HudRules.sp_dots(new_sp)

func _on_status_effects_changed(unit_id: String, unit_index: int, effects: Array) -> void:
	var key := _unit_key(unit_id, unit_index)
	if _status_rows.has(key):
		_render_status_row(_status_rows[key], effects)

const _QUEUE_CHIP_SIZE := Vector2(40, 40)

## Small portrait strip previewing the round's spd-sorted turn order (reuses
## _portrait_path()/_accent_color() -- no new art). Rebuilt every round since
## TurnBattle recomputes turn_order() each round; keeping it dumb-simple
## (rebuild vs. diff) avoids tracking staleness for a once-per-round event.
func _on_turn_order_changed(turn_order: Array) -> void:
	for child in _turn_queue_row.get_children():
		child.queue_free()
	_queue_chips.clear()
	for unit in turn_order:
		var chip := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.15, 0.18, 0.78)
		style.border_color = _accent_color(unit)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(2)
		chip.add_theme_stylebox_override("panel", style)
		var portrait_path := _portrait_path(unit)
		if portrait_path != "":
			var portrait := TextureRect.new()
			portrait.texture = load(portrait_path)
			portrait.custom_minimum_size = _QUEUE_CHIP_SIZE
			portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			portrait.flip_h = not unit["is_companion"]
			chip.add_child(portrait)
		_turn_queue_row.add_child(chip)
		_queue_chips[_unit_key(unit["id"], unit["index"])] = chip
	_highlight_current_in_queue("")

## turn_started only carries unit_id (not index -- TD-001's known ceiling), so
## a duplicate-id pair of enemies would highlight both chips together; rare
## and harmless enough not to widen the signal contract for.
func _highlight_current_in_queue(unit_id: String) -> void:
	for key in _queue_chips:
		var is_current: bool = unit_id != "" and key.begins_with(unit_id + "#")
		_queue_chips[key].modulate = Color.WHITE if is_current else Color(1, 1, 1, 0.5)

func _on_turn_started(unit_id: String) -> void:
	_turn_label.text = "%s의 차례" % _display_names.get(unit_id, unit_id)
	_highlight_current_in_queue(unit_id)
	for unit in _battle.party_units:
		if unit["id"] == unit_id:
			_current_unit = unit
			return
	_current_unit = {}

func _on_player_input_requested(_unit_id: String) -> void:
	_set_action_buttons_enabled(true)

## Skill button used to just say "스킬" -- players were picking blind (no
## name/cost/effect shown before committing). Label + tooltip now come
## straight from SkillData, no new UI element needed.
func _set_action_buttons_enabled(enabled: bool) -> void:
	_basic_attack_button.disabled = not enabled
	var skill: SkillData = SkillRegistry.get_by_id(_current_unit.get("skill_id", ""))
	if skill != null:
		_skill_button.text = "%s (SP %d)" % [skill.name, skill.cost_sp]
		_skill_button.tooltip_text = skill.description
	else:
		_skill_button.text = "스킬"
		_skill_button.tooltip_text = ""
	_skill_button.disabled = not enabled or skill == null \
		or HudRules.is_skill_disabled(_current_unit.get("current_sp", 0), skill.cost_sp)
	_clear_targets()

func _on_basic_attack_pressed() -> void:
	_battle.submit_action("basic_attack")
	_set_action_buttons_enabled(false)
	_show_targets(_battle.enemy_units)

func _on_skill_pressed() -> void:
	var skill: SkillData = SkillRegistry.get_by_id(_current_unit["skill_id"])
	_battle.submit_action("skill")
	_set_action_buttons_enabled(false)
	if skill.target_type == "enemy":
		_show_targets(_battle.enemy_units)
	else: # "ally"/"self"/"all_allies" -- all resolve to picking one ally; an
		# all_allies skill applies to the whole party regardless of which ally
		# button was pressed (see TurnBattle._execute_action()).
		_show_targets(_battle.party_units)

func _show_targets(units: Array) -> void:
	_clear_targets()
	for unit in units:
		if unit["current_hp"] <= 0:
			continue
		var button := Button.new()
		button.text = _display_names.get(unit["id"], unit["id"])
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(_battle.submit_target.bind(unit))
		_target_container.add_child(button)

func _clear_targets() -> void:
	for child in _target_container.get_children():
		child.queue_free()
