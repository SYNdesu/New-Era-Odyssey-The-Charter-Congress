class_name MultiplayerInputSystem
extends Node

## 多玩家输入分配系统
## 管理多个玩家与输入设备的映射关系

signal player_joined(player_id: int, device_id: int)
signal player_left(player_id: int)
signal device_connected(device_id: int, device_name: String)
signal device_disconnected(device_id: int)

var _player_inputs: Dictionary = {}      ## {player_id: PlayerInputManager}
var _device_to_player: Dictionary = {}   ## {device_id: player_id}
var max_players: int = 4


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_changed)


func _process(_delta: float) -> void:
	for id in _player_inputs:
		var mgr = _player_inputs[id] as PlayerInputManager
		if mgr:
			mgr.update()


func register_player(player_id: int, device_id: int = -1) -> PlayerInputManager:
	if _player_inputs.has(player_id):
		push_warning("玩家 %d 已注册" % player_id)
		return _player_inputs[player_id]
	
	if device_id != -1 and _device_to_player.has(device_id):
		push_warning("设备 %d 已被玩家 %d 使用" % [device_id, _device_to_player[device_id]])
		return null
	
	var prefix = "p%d_" % player_id
	var mgr = PlayerInputManager.new(device_id, prefix)
	_player_inputs[player_id] = mgr
	
	if device_id != -1:
		_device_to_player[device_id] = player_id
	
	player_joined.emit(player_id, device_id)
	return mgr


func unregister_player(player_id: int) -> void:
	if not _player_inputs.has(player_id):
		return
	
	var mgr = _player_inputs[player_id] as PlayerInputManager
	var dev_id = mgr.device_id
	
	_player_inputs.erase(player_id)
	if dev_id != -1 and _device_to_player.has(dev_id):
		_device_to_player.erase(dev_id)
	
	player_left.emit(player_id)


func get_player_input(player_id: int) -> PlayerInputManager:
	return _player_inputs.get(player_id, null)


func switch_device(player_id: int, new_device: int) -> bool:
	if not _player_inputs.has(player_id):
		return false
	
	if new_device != -1 and _device_to_player.has(new_device):
		if _device_to_player[new_device] != player_id:
			return false
	
	var mgr = _player_inputs[player_id] as PlayerInputManager
	var old = mgr.device_id
	
	if old != -1:
		_device_to_player.erase(old)
	
	mgr.device_id = new_device
	mgr.set_connected(true)
	
	if new_device != -1:
		_device_to_player[new_device] = player_id
	
	return true


func auto_assign(player_id: int) -> bool:
	if player_id == 1 and not _is_device_assigned(-1):
		return register_player(player_id, -1) != null
	
	for dev in PlayerInputManager.get_connected_joypads():
		if not _is_device_assigned(dev):
			return register_player(player_id, dev) != null
	
	return false


func get_available_devices() -> Dictionary:
	var result = {"keyboard": not _is_device_assigned(-1), "joypads": []}
	for dev in PlayerInputManager.get_connected_joypads():
		if not _is_device_assigned(dev):
			result["joypads"].append({"id": dev, "name": Input.get_joy_name(dev)})
	return result


func clear_all() -> void:
	_player_inputs.clear()
	_device_to_player.clear()


# ========== 私有 ==========

func _is_device_assigned(device_id: int) -> bool:
	if device_id == -1:
		for id in _player_inputs:
			if (_player_inputs[id] as PlayerInputManager).device_id == -1:
				return true
		return false
	return _device_to_player.has(device_id)


func _on_joy_changed(device_id: int, connected: bool) -> void:
	if connected:
		device_connected.emit(device_id, Input.get_joy_name(device_id))
	else:
		device_disconnected.emit(device_id)
		if _device_to_player.has(device_id):
			var pid = _device_to_player[device_id]
			var mgr = _player_inputs.get(pid) as PlayerInputManager
			if mgr:
				mgr.set_connected(false)
