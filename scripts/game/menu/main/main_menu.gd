class_name MainMenu
extends CanvasLayer

## 游戏主菜单
## 开始游戏 / 继续游戏 / 设置 / 退出

signal start_game_requested
signal load_game_requested(save_id: String)
signal settings_requested
signal quit_requested

@onready var btn_start: Button = %BtnStart
@onready var btn_continue: Button = %BtnContinue
@onready var btn_settings: Button = %BtnSettings
@onready var btn_quit: Button = %BtnQuit
@onready var save_list: ItemList = %SaveList

var _has_saves: bool = false
## 存档显示文本 → save_id 映射表
var _save_map: Dictionary = {}
var _root: Control = null


func _ready() -> void:
	_root = get_child(0) as Control
	btn_start.pressed.connect(_on_start)
	btn_continue.pressed.connect(_on_continue)
	btn_settings.pressed.connect(_on_settings)
	btn_quit.pressed.connect(_on_quit)

	if _root:
		_root.visible = false
	_check_saves()


func refresh_save_list() -> void:
	## 从 MainMenuState 的 _enter 调用，刷新存档列表
	_check_saves()


func _check_saves() -> void:
	var saves = await CoreSystem.save_manager.get_save_list()
	_has_saves = not saves.is_empty()

	_save_map.clear()
	save_list.clear()
	for save in saves:
		var sid: String = save.get("save_id", "")
		var meta = save.get("metadata", {})
		var date = meta.get("save_date", "未知")
		save_list.add_item(date)
		var idx = save_list.item_count - 1
		_save_map[date] = sid

	_update_continue_button()


func _update_continue_button() -> void:
	btn_continue.disabled = not _has_saves
	btn_continue.modulate = Color.WHITE if _has_saves else Color(0.3, 0.3, 0.3)


func _on_start() -> void:
	start_game_requested.emit()


func _on_continue() -> void:
	var selected = save_list.get_selected_items()
	if selected.is_empty():
		return
	var date = save_list.get_item_text(selected[0])
	var save_id = _save_map.get(date, "")
	if save_id.is_empty():
		return
	load_game_requested.emit(save_id)


func _on_settings() -> void:
	settings_requested.emit()


func _on_quit() -> void:
	quit_requested.emit()
