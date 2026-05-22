class_name ChestStorage
extends StaticBody2D

## 可保存物品的箱子
## 加入saveable组后，物品变化会实时存入存档系统

signal opened                  ## 箱子被打开
signal closed                  ## 箱子被关闭
signal item_added(item_id: String, count: int)   ## 物品被放入
signal item_removed(item_id: String, count: int)  ## 物品被取出
signal contents_changed        ## 物品变化

@export var chest_name: String = "箱子"            ## 箱子名称
@export var capacity: int = 20                      ## 容量上限
@export var interact_text: String = "打开"          ## 交互提示文本

var items: Array[Dictionary] = []                   ## 物品列表 [{id, name, count}]


func _ready() -> void:
	await get_tree().process_frame
	CoreSystem.save_manager.register_saveable_node(self)


func interact(player: Player) -> void:
	opened.emit()
	print("[%s] 被打开" % chest_name)


## 添加物品
func add_item(item_id: String, item_name: String = "", count: int = 1) -> bool:
	if items.size() >= capacity:
		push_warning("箱子已满，无法放入物品")
		return false

	var existing = _find_item(item_id)
	if existing != null:
		existing.count += count
	else:
		items.append({"id": item_id, "name": item_name, "count": count})

	item_added.emit(item_id, count)
	contents_changed.emit()
	return true


## 移除物品
func remove_item(item_id: String, count: int = 1) -> bool:
	var existing = _find_item(item_id)
	if existing == null or existing.count < count:
		push_warning("物品不足，无法取出")
		return false

	existing.count -= count
	if existing.count <= 0:
		items.erase(existing)

	item_removed.emit(item_id, count)
	contents_changed.emit()
	return true


## 获取一种物品数量
func get_item_count(item_id: String) -> int:
	var existing = _find_item(item_id)
	return existing.count if existing else 0


## 获取所有物品（供UI显示）
func get_all_items() -> Array:
	return items.duplicate(true)


## 检查箱子是否为空
func is_empty() -> bool:
	return items.is_empty()


## 检查箱子是否已满
func is_full() -> bool:
	return items.size() >= capacity


## 查找指定ID的物品
func _find_item(item_id: String):
	for item in items:
		if item.id == item_id:
			return item
	return null


## ===== 存档系统接口 =====

## 保存箱子数据（由SaveManager调用）
func save() -> Dictionary:
	var item_list: Array[Dictionary] = []
	for item in items:
		item_list.append({
			"id": item.get("id", ""),
			"name": item.get("name", ""),
			"count": item.get("count", 0)
		})

	return {
		"node_path": get_path(),
		"chest_name": chest_name,
		"position_x": position.x,
		"position_y": position.y,
		"items": item_list
	}


## 加载箱子数据（由SaveManager调用）
func load_data(data: Dictionary) -> void:
	chest_name = data.get("chest_name", chest_name)

	position.x = data.get("position_x", position.x)
	position.y = data.get("position_y", position.y)

	items.clear()
	var item_list: Array = data.get("items", [])
	for item_data in item_list:
		items.append({
			"id": item_data.get("id", ""),
			"name": item_data.get("name", ""),
			"count": item_data.get("count", 0)
		})

	print("[%s] 从存档恢复 %d 种物品" % [chest_name, items.size()])
