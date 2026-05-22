class_name DialogState
extends PlayerBaseState

## 对话状态 — 由玩家状态机控制对话流程

func _init() -> void:
	state_priority = Priority.NORMAL

func _enter() -> void:
	if player:
		player.velocity = Vector2.ZERO
		player.play_animation("idle")
	_log("_enter")
	
	# 发送对话开始事件
	if CoreSystem and CoreSystem.event_bus:
		CoreSystem.event_bus.push_event("dialog_start", {
			"player_id": player.player_id if player else -1,
		})

func _exit() -> void:
	_log("_exit")
	if CoreSystem and CoreSystem.event_bus:
		CoreSystem.event_bus.push_event("dialog_end", {
			"player_id": player.player_id if player else -1,
		})
