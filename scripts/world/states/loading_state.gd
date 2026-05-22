class_name LoadingState
extends WorldStateBase

## 加载中状态 — 所有场景/玩家资源的入口

var _overlay: ColorRect
var _label: Label


func _enter() -> void:
	_log("加载中...")
	_create_loading_screen()
	call_deferred("_do_load")


func _create_loading_screen() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 1)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_label = Label.new()
	_label.text = "加载中..."
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 48)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_overlay.add_child(_label)
	world.add_child(_overlay)


func _do_load() -> void:
	await world.get_tree().process_frame

	var ctx: Dictionary = world._loading_context
	var from: String = ctx.get("from", "")

	if from == "load_save":
		# 读档：先加载存档数据，再生成玩家和子场景
		var save_id: String = ctx.get("save_id", "")
		await CoreSystem.save_manager.load_save(save_id)
		world._spawn_player()
		var sub_path = world._current_sub_scene_path
		if sub_path.is_empty():
			sub_path = "res://scenes/world/world_main.tscn"
		world._load_sub_scene(sub_path)
		dispatch(&"game_loaded")

	elif from == "new_game":
		# 新游戏：直接生成玩家和默认地图
		world._spawn_player()
		world._load_sub_scene("res://scenes/world/world_main.tscn")
		dispatch(&"game_loaded")

	else:
		# 冷启动：只需跳到主菜单
		dispatch(&"loading_done")


func _exit() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null
		_label = null
