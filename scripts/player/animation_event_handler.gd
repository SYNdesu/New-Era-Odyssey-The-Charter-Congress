class_name AnimationEventHandler
extends Node

## 动画事件处理器 - 监听动画播放并在特定帧触发事件

signal event_triggered(event: AnimationEvent)

var _events: Dictionary = {}           # {anim_name: [AnimationEvent]}
var _last_animation: String = ""
var _last_position: float = 0.0      ## 上一帧的动画位置
var _anim_player: AnimationPlayer


func _init(p_anim_player: AnimationPlayer) -> void:
	_anim_player = p_anim_player


func _process(delta: float) -> void:
	if not _anim_player or not _anim_player.is_playing():
		_last_animation = ""
		return
	
	var current_anim = _anim_player.current_animation
	var current_pos = _anim_player.current_animation_position
	
	# 动画切换时重置
	if current_anim != _last_animation:
		_last_animation = current_anim
		_last_position = 0.0
	
	# 检查是否有事件在当前帧区间内
	if _events.has(current_anim):
		for event in _events[current_anim]:
			var evt = event as AnimationEvent
			if evt.frame > _last_position and evt.frame <= current_pos:
				event_triggered.emit(evt)
				print("动画事件触发: %s @ %.2f" % [evt.event_name, evt.frame])
	
	_last_position = current_pos


func register_event(anim_name: String, event: AnimationEvent) -> void:
	## 注册动画事件
	if not _events.has(anim_name):
		_events[anim_name] = []
	_events[anim_name].append(event)


func register_events(anim_name: String, events: Array) -> void:
	## 批量注册动画事件
	if not _events.has(anim_name):
		_events[anim_name] = []
	_events[anim_name].append_array(events)


func clear_events(anim_name: String = "") -> void:
	## 清除动画事件
	if anim_name.is_empty():
		_events.clear()
	else:
		_events.erase(anim_name)
