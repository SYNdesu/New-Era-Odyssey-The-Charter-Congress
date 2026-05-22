class_name IdleState
extends PlayerBaseState

func _enter() -> void:
	if player:
		player.velocity = Vector2.ZERO
		player.play_animation("idle")
	_log("_enter  player=%s" % player)

func _update(_delta: float) -> void:
	if is_moving():
		_log("input=%s → dispatch move" % get_input_direction())
		dispatch(&"move")
