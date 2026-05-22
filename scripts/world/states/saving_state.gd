class_name SavingState
extends WorldStateBase

## 保存中状态 — 异步收集数据并保存，_after_save_target标记目标

var _after_save_target: String = ""


func _enter() -> void:
	_log("保存中...")
	get_tree().paused = true
	call_deferred("_do_save")


func _do_save() -> void:
	await CoreSystem.save_manager.create_save()
	get_tree().paused = false
	
	if _after_save_target == "quit":
		dispatch(&"save_done_quit")
	else:
		dispatch(&"save_done")


func _exit() -> void:
	_after_save_target = ""
