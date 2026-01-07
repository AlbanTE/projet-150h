extends Node
class_name InventoryManager

var inventory: Array[Item] = []
const size: int = 3

var new_item: Item = null

signal update_inventory
signal choosing_item(item: Item)
signal item_chosen

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass

func add_item(item: Item):
	if inventory.size() < size:
		inventory.append(item)
		add_child(item)
		emit_signal("update_inventory")
	else:
		new_item = item
		emit_signal("choosing_item", item)
		
func replace_item(slot: int):
	if slot == 0:
		print("Not replacing anything")
		emit_signal("item_chosen")
		return
	
	print("Replacing slot ", slot)
	var item_to_delete = inventory[slot-1]
	item_to_delete.destroy()
	
	inventory[slot-1] = new_item
	add_child(new_item)
	
	emit_signal("item_chosen")
