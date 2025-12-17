extends Node
class_name InventoryManager

var inventory: Array[Item] = []
const size: int = 3

signal update_inventory

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass

func add_item(item: Item):
	if inventory.size() < size:
		inventory.append(item)
		add_child(item)
		
	emit_signal("update_inventory")
