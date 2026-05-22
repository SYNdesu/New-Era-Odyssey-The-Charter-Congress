class_name PlayerInputManager
extends RefCounted

## 单玩家输入管理器
## 负责一个玩家的输入读取，支持键盘和手柄

var device_id: int = -1          ## -1=键盘, 0+=手柄
var action_prefix: String = "p1_" ## 动作前缀，区分不同玩家

var _input_direction: Vector2 = Vector2.ZERO
var _is_connected: bool = true


func _init(p_device_id: int = -1, p_prefix: String = "p1_") -> void:
	device_id = p_device_id
	action_prefix = p_prefix


func update() -> void:
	if not _is_connected:
		_input_direction = Vector2.ZERO
		return
	
	if device_id == -1:
		_update_keyboard()
	else:
		_update_joypad()


func get_input_direction() -> Vector2:
	return _input_direction


func is_action_just_pressed(action: String) -> bool:
	var full = action_prefix + action
	if device_id == -1:
		return Input.is_action_just_pressed(full)
	return _is_joypad_button_just_pressed(action)


func is_action_pressed(action: String) -> bool:
	var full = action_prefix + action
	if device_id == -1:
		return Input.is_action_pressed(full)
	return _is_joypad_button_pressed(action)


func set_connected(connected: bool) -> void:
	_is_connected = connected
	if not connected:
		_input_direction = Vector2.ZERO


func get_device_name() -> String:
	if device_id == -1:
		return "键盘鼠标"
	return Input.get_joy_name(device_id)


static func get_connected_joypads() -> Array:
	var devices: Array = []
	devices.assign(Input.get_connected_joypads())
	return devices


# ========== 私有 ==========

func _update_keyboard() -> void:
	var dir = Vector2.ZERO
	var left = action_prefix + "move_left"
	var right = action_prefix + "move_right"
	var up = action_prefix + "move_up"
	var down = action_prefix + "move_down"
	
	if InputMap.has_action(left):
		dir.x = Input.get_axis(left, right)
		dir.y = Input.get_axis(up, down)
	else:
		dir.x = Input.get_axis("ui_left", "ui_right")
		dir.y = Input.get_axis("ui_up", "ui_down")
	
	if dir.length() > 1.0:
		dir = dir.normalized()
	_input_direction = dir


func _update_joypad() -> void:
	if not Input.is_joy_known(device_id):
		_is_connected = false
		_input_direction = Vector2.ZERO
		return
	
	var x = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var y = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	var deadzone = 0.2
	
	if abs(x) < deadzone: x = 0.0
	if abs(y) < deadzone: y = 0.0
	
	_input_direction = Vector2(x, y)


func _is_joypad_button_just_pressed(action: String) -> bool:
	var btn = _get_action_button(action)
	if btn >= 0:
		return Input.is_joy_button_pressed(device_id, btn)
	return false


func _is_joypad_button_pressed(action: String) -> bool:
	var btn = _get_action_button(action)
	if btn >= 0:
		return Input.is_joy_button_pressed(device_id, btn)
	return false


func _get_action_button(action: String) -> int:
	match action:
		"action_attack", "attack": return JOY_BUTTON_A
		"action_jump", "jump": return JOY_BUTTON_B
		"action_interact", "interact": return JOY_BUTTON_X
		"action_dodge", "dodge": return JOY_BUTTON_Y
		"ui_cancel", "pause": return JOY_BUTTON_START
		_: return -1
