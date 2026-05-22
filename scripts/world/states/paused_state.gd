class_name PausedState
extends WorldStateBase

## 暂停状态 — 仅ESC触发，显示暂停菜单，冻结游戏

func _enter() -> void:
	_log("暂停")
	get_tree().paused = true
	if world and world.has_method("show_pause_menu"):
		world.show_pause_menu()


func _exit() -> void:
	get_tree().paused = false
	if world and world.has_method("hide_pause_menu"):
		world.hide_pause_menu()
