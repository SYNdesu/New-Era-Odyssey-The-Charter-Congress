class_name MoveState
extends PlayerBaseState

func _enter() -> void:
	_log("_enter  player=%s" % player)

func _update(delta: float) -> void:
	var input = get_input_direction()
	if input.length() < 0.1:
		_log("input=(0,0) → dispatch stop")
		dispatch(&"stop")
		return
	
	if player:
		player.update_facing_direction(input)
		player.play_animation("run")
		var vel = player.velocity.move_toward(input * player.move_speed, player.acceleration * delta)
		player.velocity = vel
		_log("input=%s velocity=%s" % [input, vel])
