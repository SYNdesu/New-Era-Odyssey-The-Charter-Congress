class_name FollowState
extends PlayerBaseState

## AI跟随状态 — 非控制角色自动跟随队长

var _leader: Player = null
var _follow_distance: float = 64.0
var _follow_speed: float = 150.0

func setup(leader: Player, distance: float = 64.0) -> void:
	_leader = leader
	_follow_distance = distance

func _enter() -> void:
	_log("_enter  leader=%s" % _leader)
	if player:
		player.play_animation("idle")

func _update(delta: float) -> void:
	if not player or not is_instance_valid(_leader):
		return
	
	var to_leader = _leader.global_position - player.global_position
	var dist = to_leader.length()
	
	if dist > _follow_distance:
		var dir = to_leader.normalized()
		player.update_facing_direction(dir)
		player.velocity = dir * _follow_speed
		player.play_animation("run")
	else:
		player.velocity = Vector2.ZERO
		player.play_animation("idle")
