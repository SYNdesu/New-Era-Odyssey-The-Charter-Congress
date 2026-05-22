class_name Player
extends CharacterBody2D

## 玩家角色控制器
## 两层状态机：PlayerHSM（漫游/战斗模式）+ RoamingHSM（移动/交互等）

@export var player_id: int = 1
@export var move_speed: float = 200.0
@export var acceleration: float = 1500.0
@export var debug_enabled: bool = true

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: LimboHSM = $PlayerHSM
@onready var camera: Camera2D = $Camera2D

var facing_direction: Vector2 = Vector2.DOWN
var input_mgr: PlayerInputManager


func _ready() -> void:
	current_health = max_health
	_setup_input()
	_setup_animations()
	_setup_state_machine()
	_setup_debug()
	_print_log("Player %d 就绪" % player_id)


var _frame_counter: int = 0


func _physics_process(_delta: float) -> void:
	if input_mgr:
		input_mgr.update()
		var raw_dir = input_mgr.get_input_direction()
		if raw_dir.length() > 0.1:
			print("[P%d] KEY: input_mgr dir=%s pos=%s" % [player_id, raw_dir, position])
	if velocity.length() > 0.1:
		print("[P%d] PHYS: velocity=%s  pos=%s" % [player_id, velocity, position])
	_frame_counter += 1
	if _frame_counter % 60 == 0:
		print("[P%d] POS: pos=%s" % [player_id, position])
	move_and_slide()


func _process(_delta: float) -> void:
	_check_action_input()


# ========== 初始化 ==========

func _setup_input() -> void:
	input_mgr = PlayerInputManager.new(-1, "p%d_" % player_id)


func _setup_animations() -> void:
	pass  # 暂不接入动画系统，player.tscn中已预设AnimatedSprite2D动画


func _setup_state_machine() -> void:
	var roaming_hsm = state_machine.get_node_or_null("RoamingHSM") as LimboHSM
	var combat_hsm = state_machine.get_node_or_null("CombatHSM") as LimboHSM

	# 1. 先添加所有子 HSM 的过渡
	_add_roaming_transitions(roaming_hsm)
	_add_combat_transitions(combat_hsm)
	# 父 HSM 的跨模式过渡
	if roaming_hsm and combat_hsm:
		state_machine.add_transition(roaming_hsm, combat_hsm, &"combat_start")
		state_machine.add_transition(combat_hsm, roaming_hsm, &"combat_end")

	# 2. initialize（会递归给所有 HSM 设 agent，保留已添加的过渡）
	state_machine.initialize(self)
	print("[P%d] PlayerHSM agent=%s" % [player_id, state_machine.agent])

	# 3. 设置所有 HSM 的 initial_state
	if roaming_hsm:
		roaming_hsm.initial_state = roaming_hsm.get_node_or_null("IdleState") as LimboState
	if combat_hsm:
		combat_hsm.initial_state = combat_hsm.get_node_or_null("WaitTurnState") as LimboState
	state_machine.initial_state = roaming_hsm

	# 4. 激活
	state_machine.set_active(true)
	print("[P%d] PlayerHSM 已激活，active_state=%s" % [player_id, state_machine.get_active_state()])


func _add_roaming_transitions(hsm: LimboHSM) -> void:
	if not hsm:
		return
	var idle = hsm.get_node_or_null("IdleState") as LimboState
	var move = hsm.get_node_or_null("MoveState") as LimboState
	var interact = hsm.get_node_or_null("InteractState") as LimboState
	var dialog = hsm.get_node_or_null("DialogState") as LimboState
	var follow = hsm.get_node_or_null("FollowState") as LimboState
	if idle:
		if move:
			hsm.add_transition(idle, move, &"move")
			hsm.add_transition(move, idle, &"stop")
		if interact:
			if idle: hsm.add_transition(idle, interact, &"interact")
			if move: hsm.add_transition(move, interact, &"interact")
			hsm.add_transition(interact, idle, &"finished")
		if dialog:
			if idle: hsm.add_transition(idle, dialog, &"dialog")
			hsm.add_transition(dialog, idle, &"dialog_end")
		if follow:
			if idle: hsm.add_transition(idle, follow, &"follow")
			hsm.add_transition(follow, idle, &"stop")


func _add_combat_transitions(hsm: LimboHSM) -> void:
	if not hsm:
		return
	var wait_turn = hsm.get_node_or_null("WaitTurnState") as LimboState
	var select_turn = hsm.get_node_or_null("SelectTurnState") as LimboState
	var execute_action = hsm.get_node_or_null("ExecuteActionState") as LimboState
	var end_turn = hsm.get_node_or_null("EndTurnState") as LimboState
	if wait_turn and select_turn:
		hsm.add_transition(wait_turn, select_turn, &"select_turn")
	if select_turn and execute_action:
		hsm.add_transition(select_turn, execute_action, &"turn_selected")
	if execute_action and end_turn:
		hsm.add_transition(execute_action, end_turn, &"action_done")
	if end_turn and wait_turn:
		hsm.add_transition(end_turn, wait_turn, &"next_turn")


func _setup_debug() -> void:
	if not debug_enabled:
		return
	call_deferred("_add_debug_display")


func _add_debug_display() -> void:
	var debug = PlayerDebugDisplay.create_for_player(self)
	debug.name = "DebugDisplay"
	get_tree().root.add_child(debug)


# ========== 输入 ==========

func _check_action_input() -> void:
	var active = state_machine.get_active_state()
	if not active or active.name == "CombatHSM":
		return

	if is_action_just_pressed("attack"):
		pass  # 战斗攻击信号，路由到 CombatHSM 时使用
	if is_action_just_pressed("interact"):
		_dispatch_to_roaming(&"interact")


func get_input_direction() -> Vector2:
	if input_mgr:
		return input_mgr.get_input_direction()
	return Vector2.ZERO


func is_action_just_pressed(action: String) -> bool:
	if input_mgr:
		return input_mgr.is_action_just_pressed(action)
	return false


# ========== 模式切换（供 World 状态机调用） ==========

func enter_combat_mode() -> void:
	state_machine.dispatch(&"combat_start")


func enter_roaming_mode() -> void:
	state_machine.dispatch(&"combat_end")


# ========== 子HSM路由 ==========

func _dispatch_to_roaming(event: StringName) -> void:
	var roaming_hsm = state_machine.get_node_or_null("RoamingHSM") as LimboHSM
	if roaming_hsm:
		roaming_hsm.dispatch(event)


# ========== 朝向 ==========

func update_facing_direction(dir: Vector2) -> void:
	if dir.length() > 0.1:
		facing_direction = dir
		if abs(facing_direction.x) > abs(facing_direction.y):
			anim_sprite.flip_h = facing_direction.x < 0


func get_direction_suffix() -> String:
	var d = facing_direction
	if abs(d.x) >= abs(d.y):
		return "left" if d.x < 0 else "right"
	return "up" if d.y < 0 else "down"


# ========== 动画 ==========

func play_animation(base: String) -> void:
	var name = base + "_" + get_direction_suffix()
	if anim_player.has_animation(name):
		anim_player.play(name)


# ========== 战斗属性 ==========

@export var max_health: float = 100.0
var current_health: float = 100.0
var is_invincible: bool = false

func take_damage(amount: float) -> void:
	if is_invincible:
		return
	current_health = max(current_health - amount, 0.0)


func set_invincible(active: bool, duration: float = 0.0) -> void:
	is_invincible = active
	if duration > 0:
		get_tree().create_timer(duration).timeout.connect(_on_invincible_end)


func _on_invincible_end() -> void:
	is_invincible = false


# ========== 存档接口 ==========

func save() -> Dictionary:
	return {
		"player_id": player_id,
		"position": position,
		"facing_direction": facing_direction,
		"current_health": current_health,
		"max_health": max_health,
	}


func load_data(data: Dictionary) -> void:
	player_id = data.get("player_id", player_id)
	position = data.get("position", position)
	facing_direction = data.get("facing_direction", facing_direction)
	current_health = data.get("current_health", current_health)
	max_health = data.get("max_health", max_health)


# ========== 工具 ==========

func _print_log(msg: String) -> void:
	if debug_enabled:
		print("[P%d] %s" % [player_id, msg])
