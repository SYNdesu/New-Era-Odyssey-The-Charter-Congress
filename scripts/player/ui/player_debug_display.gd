class_name PlayerDebugDisplay
extends CanvasLayer

## 玩家调试信息显示
## 左上角面板：速度/输入/生命 + 世界状态树 + 玩家状态树
## 右上角：绝对坐标

static func create_for_player(p: Player) -> PlayerDebugDisplay:
	var debug := PlayerDebugDisplay.new()
	debug.player = p
	debug._create_layout()
	return debug

var player: Player

var _left_panel: VBoxContainer
var _info_lines: Array[Label] = []
var _world_hsm_label: Label
var _player_hsm_label: Label
var _pos_label: Label


func _create_layout() -> void:
	_create_left_panel()
	_create_pos_label()


func _create_left_panel() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	margin.position = Vector2(4, 4)
	margin.size = Vector2(380, 600)
	add_child(margin)

	_left_panel = VBoxContainer.new()
	_left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_left_panel)

	_info_lines.append(_make_label("", Color.WHITE))
	_info_lines.append(_make_label("", Color.WHITE))
	_info_lines.append(_make_label("", Color.WHITE))
	_info_lines.append(_make_label("", Color.WHITE))
	_info_lines.append(_make_label("", Color.WHITE))

	var sep1 = HSeparator.new()
	sep1.custom_minimum_size.y = 4
	_left_panel.add_child(sep1)

	_world_hsm_label = _make_label("", Color(0.5, 0.8, 1.0))

	var sep2 = HSeparator.new()
	sep2.custom_minimum_size.y = 4
	_left_panel.add_child(sep2)

	_player_hsm_label = _make_label("", Color(0.5, 1.0, 0.5))


func _make_label(text: String, col: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", col)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	_left_panel.add_child(label)
	return label


func _create_pos_label() -> void:
	var right_margin = MarginContainer.new()
	right_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right_margin.position = Vector2(-8, 4)
	right_margin.size = Vector2(200, 30)
	add_child(right_margin)

	_pos_label = Label.new()
	_pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pos_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pos_label.add_theme_font_size_override("font_size", 14)
	_pos_label.add_theme_color_override("font_color", Color(0, 1, 0))
	_pos_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_pos_label.add_theme_constant_override("outline_size", 2)
	right_margin.add_child(_pos_label)


func _process(_delta: float) -> void:
	if not player:
		return

	var active = player.state_machine.get_active_state() if player.state_machine else null
	var state_name = active.name if active else "无"
	var priority = (active as PlayerBaseState).state_priority if active is PlayerBaseState else 0

	_info_lines[0].text = "状态: %s (优先级:%d)" % [state_name, priority]
	_info_lines[1].text = "输入: (%.1f, %.1f)" % [player.get_input_direction().x, player.get_input_direction().y]
	_info_lines[2].text = "速度: %.0f" % player.velocity.length()
	_info_lines[3].text = "生命: %.0f/%.0f %s" % [player.current_health, player.max_health, "无敌" if player.is_invincible else ""]
	_info_lines[4].text = "设备: %s" % (player.input_mgr.get_device_name() if player.input_mgr else "无")

	_pos_label.text = "坐标: (%.0f, %.0f)" % [player.global_position.x, player.global_position.y]

	var world_text = "[世界状态机]\n  未连接"
	var parent = player.get_parent()
	if parent and "world_hsm" in parent:
		var world_hsm: LimboHSM = parent.world_hsm
		world_text = "[世界状态机]\n" + _build_state_tree(world_hsm)
	_world_hsm_label.text = world_text

	var player_text = "[玩家状态机]\n  未就绪"
	if player.state_machine:
		player_text = "[玩家状态机]\n" + _build_state_tree(player.state_machine)
	_player_hsm_label.text = player_text


# ========== 状态树构建 ==========

# ▶=当前活动状态  ·=非活动状态  递归展开 LimboHSM 子状态
func _build_state_tree(root: LimboHSM) -> String:
	if not root:
		return "  (nil)"
	return _show_states(root, root.get_active_state(), "")


# 遍历 hsm 的直接 LimboState 子节点；遇 LimboHSM 则递归展开
func _show_states(hsm: LimboHSM, active: LimboState, indent: String) -> String:
	var result = ""
	for child in hsm.get_children():
		if not child is LimboState:
			continue
		var state: LimboState = child as LimboState
		var marker = "▶" if state == active else "·"
		result += "\n" + indent + marker + " " + state.name + "  ← " + _agent_name(state)
		if child is LimboHSM:
			# 这个直接子节点本身是HSM → 递归展开其子状态
			var sub = child as LimboHSM
			result += _show_states(sub, sub.get_active_state(), indent + "│  ")
	return result


func _agent_name(state: LimboState) -> String:
	if state.agent == null:
		return "agent=?"
	if state.agent is Node:
		return "agent=" + state.agent.name
	return "agent=" + str(state.agent)
