extends Control
## S-05 BattleScreen. See design/gdd/턴제-전투.md, design/gdd/UI-HUD.md. Renders
## TurnBattle's #20 signal contract and forwards player choices back via
## submit_action()/submit_target(). AC1(HP)은 신호->렌더 그대로 바인딩(HudRules에
## 로직 없음, 여기서 직접 처리).
##
## ponytail: unit_hp_changed is keyed by unit_id, which two same-enemy_id units
## in one battle can share (see TurnBattle's signal contract comment) -- both
## labels update together instead of independently. Not fixed here; add a
## per-instance index to the signal if a duplicate-enemy encounter needs to
## disambiguate on screen.

@onready var _party_container: VBoxContainer = %PartyContainer
@onready var _enemy_container: VBoxContainer = %EnemyContainer
@onready var _turn_label: Label = %TurnLabel
@onready var _basic_attack_button: Button = %BasicAttackButton
@onready var _skill_button: Button = %SkillButton
@onready var _target_container: VBoxContainer = %TargetContainer

var _battle: TurnBattle
var _labels: Dictionary = {} # id -> Array[Label]
var _sp_labels: Dictionary = {} # id -> Array[Label]
var _status_rows: Dictionary = {} # id -> Array[HBoxContainer]
var _base_hp: Dictionary = {} # id -> int
var _current_unit: Dictionary = {}

func _ready() -> void:
	if RunManager.state != "IN_COMBAT":
		push_warning("BattleScreen loaded while RunManager.state=%s -- ignoring" % RunManager.state)
		return
	_battle = TurnBattle.new()
	add_child(_battle)
	_battle.setup(RunManager.party, RunManager.current_enemies)
	_build_rows(_battle.party_units, _party_container)
	_build_rows(_battle.enemy_units, _enemy_container)

	_battle.turn_started.connect(_on_turn_started)
	_battle.player_input_requested.connect(_on_player_input_requested)
	_battle.unit_hp_changed.connect(_on_unit_hp_changed)
	_battle.unit_sp_changed.connect(_on_unit_sp_changed)
	_battle.status_effects_changed.connect(_on_status_effects_changed)

	_basic_attack_button.pressed.connect(_on_basic_attack_pressed)
	_skill_button.pressed.connect(_on_skill_pressed)
	_set_action_buttons_enabled(false)

	_battle.run_battle()

func _build_rows(units: Array, container: VBoxContainer) -> void:
	for unit in units:
		var label := Label.new()
		container.add_child(label)
		if not _labels.has(unit["id"]):
			_labels[unit["id"]] = []
		_labels[unit["id"]].append(label)
		_base_hp[unit["id"]] = unit["base_hp"]
		_render_label(label, unit["id"], unit["current_hp"])

		var sp_label := Label.new()
		container.add_child(sp_label)
		if not _sp_labels.has(unit["id"]):
			_sp_labels[unit["id"]] = []
		_sp_labels[unit["id"]].append(sp_label)
		sp_label.text = HudRules.sp_dots(unit["current_sp"])

		var status_row := HBoxContainer.new()
		container.add_child(status_row)
		if not _status_rows.has(unit["id"]):
			_status_rows[unit["id"]] = []
		_status_rows[unit["id"]].append(status_row)
		_render_status_row(status_row, unit["active_effects"])

func _render_label(label: Label, id: String, hp: int) -> void:
	label.text = "%s  %d/%d HP" % [id, hp, _base_hp[id]]

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

func _on_unit_hp_changed(unit_id: String, new_hp: int) -> void:
	for label in _labels.get(unit_id, []):
		_render_label(label, unit_id, new_hp)

func _on_unit_sp_changed(unit_id: String, new_sp: int) -> void:
	for label in _sp_labels.get(unit_id, []):
		label.text = HudRules.sp_dots(new_sp)

func _on_status_effects_changed(unit_id: String, effects: Array) -> void:
	for row in _status_rows.get(unit_id, []):
		_render_status_row(row, effects)

func _on_turn_started(unit_id: String) -> void:
	_turn_label.text = "%s의 차례" % unit_id
	for unit in _battle.party_units:
		if unit["id"] == unit_id:
			_current_unit = unit
			return
	_current_unit = {}

func _on_player_input_requested(_unit_id: String) -> void:
	_set_action_buttons_enabled(true)

func _set_action_buttons_enabled(enabled: bool) -> void:
	_basic_attack_button.disabled = not enabled
	var skill: SkillData = SkillRegistry.get_by_id(_current_unit.get("skill_id", ""))
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
		button.text = unit["id"]
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(_battle.submit_target.bind(unit))
		_target_container.add_child(button)

func _clear_targets() -> void:
	for child in _target_container.get_children():
		child.queue_free()
