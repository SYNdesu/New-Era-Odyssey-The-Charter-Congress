class_name AreaPortal
extends Area2D

## 区域传送门
## 玩家进入后切换到目标场景，头顶常显目标地点名称

@export var target_scene: String = ""            ## 目标场景路径
@export var target_portal: String = ""           ## 目标场景中的出生点名称
@export var portal_display_name: String = ""     ## 传送门显示名称
@export var destination_hint: String = ""        ## 目标地点提示

@onready var collision: CollisionShape2D = $CollisionShape2D

var _portal_label: Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_portal_label()


## 创建传送门头顶常显标签
func _setup_portal_label() -> void:
	_portal_label = Label.new()
	_portal_label.name = "PortalLabel"
	_portal_label.position = Vector2(0, -36)
	_portal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portal_label.add_theme_font_size_override("font_size", 10)
	_portal_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	_portal_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_portal_label.add_theme_constant_override("outline_size", 2)
	add_child(_portal_label)
	_refresh_portal_label()


func _refresh_portal_label() -> void:
	var text = portal_display_name
	if not destination_hint.is_empty():
		text += "\n→ " + destination_hint
	_portal_label.text = text


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if target_scene.is_empty():
		push_warning("传送门 %s 未设置目标场景" % name)
		return

	# 延迟到物理查询刷新完成后执行，避免在 flushing_queries 期间添加 Area 节点
	call_deferred("_do_portal_enter", body, target_scene, target_portal)


func _do_portal_enter(body: Player, scene: String, portal: String) -> void:
	# 优先查找 World 容器，用子场景切换代替完整场景切换
	var world_root: Node = get_tree().current_scene
	if world_root and world_root is World and world_root.has_method("_on_portal_entered"):
		world_root._on_portal_entered(scene, portal)
		return

	# fallback: 直接场景切换（非 World 容器环境）
	var data = {}
	if not portal.is_empty():
		data["spawn_portal"] = portal

	CoreSystem.scene_manager.change_scene_async(target_scene, data, true)
