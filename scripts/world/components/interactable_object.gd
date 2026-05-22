class_name InteractableObject
extends StaticBody2D

## 可交互物体
## 玩家靠近时头顶显示名称和介绍，按交互键触发

signal interacted(player: Player)

@export var object_name: String = "物体"         ## 物体名称
@export var display_name: String = ""            ## 头顶显示的短名称（空则用object_name）
@export var description: String = ""             ## 头顶显示的功能简介
@export var interaction_text: String = "按 F 交互" ## 交互提示文本
@export var detection_range: float = 48.0        ## 玩家检测范围

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var _info_label: Label
var _player_nearby: bool = false


func _ready() -> void:
	_setup_detection_area()
	_setup_info_label()


## 创建检测区域，内嵌的Area2D检测玩家靠近
func _setup_detection_area() -> void:
	var detector = Area2D.new()
	detector.name = "Detector"
	detector.collision_layer = 0
	detector.collision_mask = 1       # 和Player碰撞层一致

	var shape = CollisionShape2D.new()
	shape.name = "DetectorShape"
	shape.shape = CircleShape2D.new()
	shape.shape.radius = detection_range
	detector.add_child(shape)

	detector.body_entered.connect(_on_player_near)
	detector.body_exited.connect(_on_player_leave)

	add_child(detector)


## 创建头顶信息标签
func _setup_info_label() -> void:
	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.position = Vector2.ZERO     # 由_update_label_position调整
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", 10)
	_info_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	_info_label.visible = false
	add_child(_info_label)
	_refresh_label_text()


func _update_label_position() -> void:
	_info_label.position = Vector2(0, -28)


func _refresh_label_text() -> void:
	var dname = display_name if not display_name.is_empty() else object_name
	var text = dname
	if not description.is_empty():
		text += "\n[i]" + description + "[/i]"
	text += "\n" + interaction_text
	_info_label.text = text
	_update_label_position()


func _on_player_near(body: Node2D) -> void:
	if body is Player:
		_player_nearby = true
		_refresh_label_text()
		_info_label.visible = true


func _on_player_leave(body: Node2D) -> void:
	if body is Player:
		_player_nearby = false
		_info_label.visible = false


func interact(player: Player) -> void:
	interacted.emit(player)
