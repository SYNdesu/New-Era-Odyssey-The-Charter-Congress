class_name CombatState
extends WorldStateBase

## 战斗模式 — 回合制战棋

func _enter() -> void:
	_log("进入战斗")

func _update(_delta: float) -> void:
	pass

func _exit() -> void:
	_log("退出战斗")
