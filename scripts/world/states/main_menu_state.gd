class_name MainMenuState
extends WorldStateBase

## 主菜单状态 — CanvasLayer显隐控制，监听主菜单事件并dispatch到WorldHSM

var _main_menu: MainMenu = null


func _enter() -> void:
	_log("进入主菜单")
	_show_main_menu()
	_connect_menu_signals()
	if _main_menu:
		_main_menu.refresh_save_list()


func _show_main_menu() -> void:
	if not world.has_method("_get_or_create_main_menu"):
		return
	_main_menu = world._get_or_create_main_menu()
	if _main_menu:
		world._set_canvas_visible(_main_menu, true)


func _connect_menu_signals() -> void:
	if not _main_menu:
		return
	if not _main_menu.start_game_requested.is_connected(_on_start_game):
		_main_menu.start_game_requested.connect(_on_start_game)
	if not _main_menu.load_game_requested.is_connected(_on_load_game):
		_main_menu.load_game_requested.connect(_on_load_game)
	if not _main_menu.quit_requested.is_connected(_on_quit):
		_main_menu.quit_requested.connect(_on_quit)
	if not _main_menu.settings_requested.is_connected(_on_open_settings):
		_main_menu.settings_requested.connect(_on_open_settings)


func _on_start_game() -> void:
	world._loading_context = {"from": "new_game"}
	dispatch(&"start_new_game")


func _on_load_game(save_id: String) -> void:
	world._loading_context = {"from": "load_save", "save_id": save_id}
	dispatch(&"load_game")


func _on_quit() -> void:
	dispatch(&"quit")


func _on_open_settings() -> void:
	if world and world.has_method("_on_pause_settings"):
		world._on_pause_settings()


func _exit() -> void:
	_log("退出主菜单")
	_disconnect_menu_signals()
	if _main_menu:
		world._set_canvas_visible(_main_menu, false)


func _disconnect_menu_signals() -> void:
	if not _main_menu:
		return
	if _main_menu.start_game_requested.is_connected(_on_start_game):
		_main_menu.start_game_requested.disconnect(_on_start_game)
	if _main_menu.load_game_requested.is_connected(_on_load_game):
		_main_menu.load_game_requested.disconnect(_on_load_game)
	if _main_menu.quit_requested.is_connected(_on_quit):
		_main_menu.quit_requested.disconnect(_on_quit)
	if _main_menu.settings_requested.is_connected(_on_open_settings):
		_main_menu.settings_requested.disconnect(_on_open_settings)
