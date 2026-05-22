class_name InventoryPanel
extends CanvasLayer

## 背包与玩家状态面板 — 按E打开，展示HP，预留物品列表扩展

signal close_requested

@onready var hp_label: Label = %HpLabel
@onready var btn_close: Button = %BtnClose

var _root: Control = null


func _ready() -> void:
	_root = get_child(0) as Control
	btn_close.pressed.connect(_on_close)
	_set_visible(false)


func refresh(player_node: Player) -> void:
	if not player_node:
		return
	hp_label.text = "生命值：%.0f / %.0f" % [player_node.current_health, player_node.max_health]


func open(player_node: Player = null) -> void:
	_set_visible(true)
	get_tree().paused = true
	if player_node:
		refresh(player_node)


func close() -> void:
	_set_visible(false)
	get_tree().paused = false


func _on_close() -> void:
	close()
	close_requested.emit()


func _set_visible(v: bool) -> void:
	if _root:
		_root.visible = v
