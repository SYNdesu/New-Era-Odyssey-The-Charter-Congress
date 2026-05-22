class_name PlayerBaseState
extends LimboState

## 玩家状态基类 — 通用功能 + 优先级

enum Priority { LOWEST = 0, NORMAL = 10, HIGH = 50, HIGHEST = 100 }

var state_priority: Priority = Priority.LOWEST
var _player_ref: Player = null

var player: Player:
	get:
		if _player_ref is Player:
			return _player_ref
		return null


func _setup() -> void:
	if agent is Player:
		_player_ref = agent
	elif agent is LimboHSM:
		# 如果 agent 是子 HSM 则穿透取根 agent
		var root_agent = (agent as LimboHSM).agent
		if root_agent is Player:
			_player_ref = root_agent
	print("[%s] _setup agent=%s → player=%s" % [name, agent, _player_ref])


func _enter() -> void:
	pass


func _exit() -> void:
	pass

# ========== 优先级 ==========

func can_be_interrupted_by(p: Priority) -> bool:
	return p > state_priority

# ========== 便捷 ==========

func get_input_direction() -> Vector2:
	return player.get_input_direction() if player else Vector2.ZERO

func is_moving() -> bool:
	return get_input_direction().length() > 0.1

func play_anim(name: String) -> void:
	if player: player.play_animation(name)

func _log(msg: String) -> void:
	if player and player.debug_enabled:
		print("[%s] %s" % [name, msg])
