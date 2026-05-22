class_name WorldStateBase
extends LimboState

## 世界状态基类 — 自动遍历查找 World 节点引用

var world: Node = null


func _setup() -> void:
	if agent is World:
		world = agent
		return
	var node: Node = agent
	while node:
		if node is World:
			world = node
			return
		node = node.get_parent()
	if agent:
		world = agent


func _log(msg: String) -> void:
	print("[World:%s] %s" % [name, msg])
