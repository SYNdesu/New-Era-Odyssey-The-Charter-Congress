class_name World
extends Node2D

## 世界根节点 — 驱动 WorldHSM，管理玩家/子场景/菜单堆栈

const SavingStateScript = preload("res://scripts/world/states/saving_state.gd")
const InventoryPanelScript = preload("res://scripts/game/menu/inventory_panel.gd")

@onready var world_hsm: LimboHSM = $WorldHSM

var _loading_context: Dictionary = {}
var player_node: Player = null
var _current_sub_scene: Node = null
var _current_sub_scene_path: String = ""

var _main_menu: MainMenu = null
var _pause_menu: PauseMenu = null
var _settings_panel: SettingsPanel = null
var _inventory_panel: InventoryPanelScript = null

## 菜单堆栈 — 记录当前打开的菜单面板（用于堆栈导航）
var _menu_stack: Array[Node] = []


func _ready() -> void:
	CoreSystem.save_manager.register_saveable_node(self)
	_setup_state_machine()


func _process(_delta: float) -> void:
	_check_esc_input()
	_check_e_input()


# ========== 状态机 ==========

func _setup_state_machine() -> void:
	var loading = world_hsm.get_node_or_null("LoadingState") as LimboState
	var main_menu = world_hsm.get_node_or_null("MainMenuState") as LimboState
	var gameplay = world_hsm.get_node_or_null("GameplayHSM") as LimboHSM
	var saving = world_hsm.get_node_or_null("SavingState") as LimboState
	var exiting = world_hsm.get_node_or_null("ExitingState") as LimboState

	# 1. 先添加 GameplayHSM 的子状态过渡
	if gameplay:
		_add_gameplay_transitions(gameplay)

	# 2. 添加 WorldHSM 的跨状态过渡
	if loading and main_menu:
		world_hsm.add_transition(loading, main_menu, &"loading_done")
	if loading and gameplay:
		world_hsm.add_transition(loading, gameplay, &"game_loaded")
	if main_menu and loading:
		world_hsm.add_transition(main_menu, loading, &"start_new_game")
		world_hsm.add_transition(main_menu, loading, &"load_game")
	if main_menu and exiting:
		world_hsm.add_transition(main_menu, exiting, &"quit")
	if gameplay and saving:
		world_hsm.add_transition(gameplay, saving, &"save")
		world_hsm.add_transition(gameplay, saving, &"save_and_quit")
	if gameplay and main_menu:
		world_hsm.add_transition(gameplay, main_menu, &"return_main")
	if saving and gameplay:
		world_hsm.add_transition(saving, gameplay, &"save_done")
	if saving and exiting:
		world_hsm.add_transition(saving, exiting, &"save_done_quit")

	# 3. initialize（会递归给所有 HSM 设 agent，保留已添加的过渡）
	world_hsm.initialize(self)

	# 4. 设置所有 HSM 的 initial_state
	if gameplay:
		gameplay.initial_state = gameplay.get_node_or_null("ExplorationState") as LimboState
	world_hsm.initial_state = loading

	# 5. 激活
	world_hsm.set_active(true)
	print("[World] WorldHSM 已激活")


func _add_gameplay_transitions(hsm: LimboHSM) -> void:
	if not hsm:
		return
	var explore = hsm.get_node_or_null("ExplorationState") as LimboState
	var combat_pve = hsm.get_node_or_null("CombatState") as LimboState
	var paused = hsm.get_node_or_null("PausedState") as LimboState
	if explore:
		if combat_pve:
			hsm.add_transition(explore, combat_pve, &"enter_combat")
			hsm.add_transition(combat_pve, explore, &"exit_combat")
		if paused:
			hsm.add_transition(explore, paused, &"pause")
			hsm.add_transition(paused, explore, &"resume")


# ========== 输入 ==========

func _check_esc_input() -> void:
	if not Input.is_action_just_pressed("ui_cancel"):
		return

	var active = world_hsm.get_active_state()
	if not active:
		return

	if active.name == "GameplayHSM":
		_dispatch_to_gameplay(&"pause")
	elif active.name == "MainMenuState":
		world_hsm.dispatch(&"quit")


func _check_e_input() -> void:
	if not Input.is_action_just_pressed("p1_inventory"):
		return

	var active = world_hsm.get_active_state()
	if not active:
		return

	if active.name == "MainMenuState":
		return

	if not _menu_stack.is_empty():
		pop_menu()
		return

	_open_inventory()


func _dispatch_to_gameplay(event: StringName) -> void:
	var gameplay_hsm = world_hsm.get_node_or_null("GameplayHSM") as LimboHSM
	if gameplay_hsm:
		gameplay_hsm.dispatch(event)


# ========== 菜单堆栈 ==========

## CanvasLayer 无 visible 属性，通过其子 Control 控制显隐
func _set_canvas_visible(panel: Node, v: bool) -> void:
	if panel is CanvasLayer:
		for child in panel.get_children():
			if child is Control:
				child.visible = v
				return

func _is_canvas_visible(panel: Node) -> bool:
	if panel is CanvasLayer:
		for child in panel.get_children():
			if child is Control:
				return child.visible
	return false

func push_menu(panel: Node) -> void:
	if not _menu_stack.is_empty():
		var top = _menu_stack.back()
		_set_canvas_visible(top, false)
	_menu_stack.append(panel)
	_set_canvas_visible(panel, true)


func pop_menu() -> void:
	if _menu_stack.is_empty():
		return
	var top = _menu_stack.pop_back()
	_set_canvas_visible(top, false)
	if top is InventoryPanelScript:
		(top as InventoryPanelScript).close()
	elif top is PauseMenu:
		(top as PauseMenu).hide_menu()
	if not _menu_stack.is_empty():
		var new_top = _menu_stack.back()
		_set_canvas_visible(new_top, true)
		if new_top is PauseMenu:
			(new_top as PauseMenu).show_menu()


func close_all_menus() -> void:
	while not _menu_stack.is_empty():
		var top = _menu_stack.pop_back()
		_set_canvas_visible(top, false)
		if top is PauseMenu:
			(top as PauseMenu).hide_menu()
		elif top is InventoryPanelScript:
			(top as InventoryPanelScript).close()
	get_tree().paused = false


# ========== 玩家管理 ==========

func _spawn_player() -> void:
	if player_node:
		return
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	player_node = player_scene.instantiate()
	player_node.name = "Player"
	add_child(player_node)
	CoreSystem.save_manager.register_saveable_node(player_node)


func _remove_player() -> void:
	if player_node:
		player_node.queue_free()
		player_node = null


# ========== 子场景管理 ==========

func _load_sub_scene(path: String) -> void:
	if _current_sub_scene:
		_cleanup_sub_scene()

	var scene: PackedScene = load(path)
	_current_sub_scene = scene.instantiate()
	_current_sub_scene.name = "SubScene"
	_current_sub_scene_path = path
	add_child(_current_sub_scene)
	move_child(_current_sub_scene, 0)

	_place_player_at_spawn("")
	_place_player_in_render_layer()


func _place_player_at_spawn(portal_id: String = "") -> void:
	if not player_node or not _current_sub_scene:
		return
	var spawn: Marker2D = _find_spawn_point(portal_id)
	if spawn:
		player_node.global_position = spawn.global_position
	else:
		var first_spawn: Marker2D = _find_first_spawn()
		if first_spawn:
			player_node.global_position = first_spawn.global_position


func _find_spawn_point(portal_id: String) -> Marker2D:
	if not _current_sub_scene:
		return null
	for child in _current_sub_scene.get_children():
		if child is Marker2D and child.get("portal_id") == portal_id:
			return child
	return null


func _find_first_spawn() -> Marker2D:
	if not _current_sub_scene:
		return null
	for child in _current_sub_scene.get_children():
		if child is Marker2D:
			return child
	return null


func _cleanup_sub_scene() -> void:
	if _current_sub_scene:
		if player_node and player_node.is_inside_tree() and player_node.get_parent() == _current_sub_scene:
			var saved_pos = player_node.global_position
			player_node.reparent(self)
			player_node.global_position = saved_pos
		_current_sub_scene.queue_free()
		_current_sub_scene = null
	_current_sub_scene_path = ""


func _place_player_in_render_layer() -> void:
	if not player_node or not _current_sub_scene:
		return

	var saved_position = player_node.global_position
	player_node.reparent(_current_sub_scene)
	player_node.global_position = saved_position

	var insert_index = _current_sub_scene.get_child_count()
	for i in range(_current_sub_scene.get_child_count()):
		var child = _current_sub_scene.get_child(i)
		if child.name.to_upper().begins_with("DECO_HIGH"):
			insert_index = i
			break

	_current_sub_scene.move_child(player_node, insert_index)


# ========== 传送门处理 ==========

func _on_portal_entered(target_scene: String, target_portal: String) -> void:
	if not player_node:
		return
	player_node.velocity = Vector2.ZERO
	_load_sub_scene(target_scene)
	_place_player_at_spawn(target_portal)
	_place_player_in_render_layer()


# ========== 主菜单 ==========

func _get_or_create_main_menu() -> MainMenu:
	if _main_menu:
		return _main_menu
	var scene: PackedScene = load("res://scenes/menu/main_menu.tscn")
	_main_menu = scene.instantiate()
	_main_menu.name = "MainMenu"
	add_child(_main_menu)
	return _main_menu


# ========== 暂停菜单 ==========

func show_pause_menu() -> void:
	if not _pause_menu:
		_create_pause_menu()
	if _pause_menu:
		_pause_menu.show_menu()
		push_menu(_pause_menu)


func hide_pause_menu() -> void:
	if _pause_menu:
		_pause_menu.hide_menu()


func _create_pause_menu() -> void:
	var scene: PackedScene = load("res://scenes/menu/pause_menu.tscn")
	_pause_menu = scene.instantiate()
	_pause_menu.name = "PauseMenu"
	add_child(_pause_menu)
	_connect_pause_signals()


func _connect_pause_signals() -> void:
	if not _pause_menu:
		return
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.settings_requested.connect(_on_pause_settings)
	_pause_menu.save_requested.connect(_on_pause_save)
	_pause_menu.main_menu_requested.connect(_on_pause_return_main)
	_pause_menu.inventory_requested.connect(_on_pause_inventory)
	_pause_menu.load_requested.connect(_on_pause_load)


func _on_pause_resume() -> void:
	close_all_menus()
	_dispatch_to_gameplay(&"resume")


func _on_pause_save() -> void:
	var saving_node = world_hsm.get_node_or_null("SavingState") as SavingStateScript
	if saving_node:
		saving_node._after_save_target = ""
	world_hsm.dispatch(&"save")


func _on_pause_load() -> void:
	close_all_menus()
	_cleanup_gameplay()
	world_hsm.dispatch(&"return_main")


func _on_pause_settings() -> void:
	if not _settings_panel:
		_create_settings_panel()
	if _settings_panel:
		_set_canvas_visible(_settings_panel, true)
		push_menu(_settings_panel)


func _create_settings_panel() -> void:
	var scene: PackedScene = load("res://scenes/menu/settings_panel.tscn")
	_settings_panel = scene.instantiate()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.back_requested.connect(_on_settings_back)
	add_child(_settings_panel)


func _on_settings_back() -> void:
	if _settings_panel:
		_settings_panel.save_settings()
	pop_menu()


func _on_pause_return_main() -> void:
	close_all_menus()
	_cleanup_gameplay()
	world_hsm.dispatch(&"return_main")


func _on_pause_inventory() -> void:
	close_all_menus()
	_dispatch_to_gameplay(&"resume")
	_open_inventory()


# ========== 背包 ==========

func _open_inventory() -> void:
	if not _inventory_panel:
		_create_inventory_panel()
	if not player_node:
		return
	if _inventory_panel:
		_inventory_panel.refresh(player_node)
		_inventory_panel.open(player_node)
		push_menu(_inventory_panel)


func _create_inventory_panel() -> void:
	var scene: PackedScene = load("res://scenes/menu/inventory_panel.tscn")
	_inventory_panel = scene.instantiate()
	_inventory_panel.name = "InventoryPanel"
	_inventory_panel.close_requested.connect(_on_inventory_closed)
	add_child(_inventory_panel)


func _on_inventory_closed() -> void:
	if not _menu_stack.is_empty() and _menu_stack.back() == _inventory_panel:
		_menu_stack.pop_back()
	get_tree().paused = false


# ========== 保存接口 ==========

func save() -> Dictionary:
	return {
		"sub_scene": _current_sub_scene_path,
	}


func load_data(data: Dictionary) -> void:
	_current_sub_scene_path = data.get("sub_scene", "res://scenes/world/world_main.tscn")


# ========== 清理 ==========

func _cleanup_gameplay() -> void:
	_remove_player()
	_cleanup_sub_scene()
	close_all_menus()
	if _pause_menu:
		_pause_menu.hide_menu()
	if _settings_panel:
		_set_canvas_visible(_settings_panel, false)
	if _inventory_panel:
		_set_canvas_visible(_inventory_panel, false)
	_current_sub_scene_path = ""
