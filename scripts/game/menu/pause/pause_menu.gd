class_name PauseMenu
extends CanvasLayer

## 暂停菜单
## 继续 / 背包 / 设置 / 存档 / 读档 / 返回主菜单

signal resume_requested
signal inventory_requested
signal settings_requested
signal save_requested
signal load_requested
signal main_menu_requested

@onready var btn_resume: Button = %BtnResume
@onready var btn_inventory: Button = %BtnInventory
@onready var btn_settings: Button = %BtnSettings
@onready var btn_save: Button = %BtnSave
@onready var btn_load: Button = %BtnLoad
@onready var btn_main: Button = %BtnMain

var _root: Control = null


func _ready() -> void:
	_root = get_child(0) as Control
	btn_resume.pressed.connect(func(): resume_requested.emit())
	btn_inventory.pressed.connect(func(): inventory_requested.emit())
	btn_settings.pressed.connect(func(): settings_requested.emit())
	btn_save.pressed.connect(func(): save_requested.emit())
	btn_load.pressed.connect(func(): load_requested.emit())
	btn_main.pressed.connect(func(): main_menu_requested.emit())

	_set_visible(false)
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_menu() -> void:
	_set_visible(true)
	get_tree().paused = true


func hide_menu() -> void:
	_set_visible(false)
	get_tree().paused = false


func _set_visible(v: bool) -> void:
	if _root:
		_root.visible = v


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _root and _root.visible:
		resume_requested.emit()
		get_viewport().set_input_as_handled()
