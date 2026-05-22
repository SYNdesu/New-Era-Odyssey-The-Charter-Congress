class_name InteractState
extends PlayerBaseState

## 交互状态 — NPC对话、物体交互、场景加载时冻结玩家

var _target: Node = null

func _init() -> void:
	state_priority = Priority.NORMAL

func setup(target: Node) -> void:
	_target = target

func _enter() -> void:
	if player:
		player.velocity = Vector2.ZERO
		player.play_animation("idle")
	_log("_enter  target=%s" % _target)

	if _target and _target.has_method("interact"):
		_target.interact(player)
		call_deferred("_finish")
	# _target 为空时保持冻结，由外部 dispatch("finished") 恢复


func _finish() -> void:
	if is_active:
		dispatch(&"finished")

func _exit() -> void:
	_target = null
