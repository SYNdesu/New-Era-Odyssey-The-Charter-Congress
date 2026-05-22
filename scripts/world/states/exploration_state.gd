class_name ExplorationState
extends WorldStateBase

## 探索模式 — 队伍在世界中自由移动

func _enter() -> void:
	_log("进入探索模式")

func _update(_delta: float) -> void:
	# 检测战斗触发、区域切换等
	pass
