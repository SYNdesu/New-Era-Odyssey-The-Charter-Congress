class_name AnimationEvent
extends Resource

## 动画事件数据 - 在动画时间轴的特定帧触发
## 可用于攻击判定、音效、特效生成等

var frame: float = 0.0          ## 触发帧（时间点）
var event_name: String = ""     ## 事件名称
var data: Dictionary = {}       ## 事件附带数据


func _init(p_frame: float = 0.0, p_event_name: String = "", p_data: Dictionary = {}) -> void:
	frame = p_frame
	event_name = p_event_name
	data = p_data
