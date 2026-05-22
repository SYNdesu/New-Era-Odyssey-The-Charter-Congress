class_name ExitingState
extends WorldStateBase

## 退出中状态 — 清理资源后退出游戏

func _enter() -> void:
	_log("退出中...")
	if world and world.has_method("_cleanup_gameplay"):
		world._cleanup_gameplay()
	get_tree().quit()
