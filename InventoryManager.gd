extends Node
class_name InventoryManager

var inventory: Array[Item] = []

var Broom: PackedScene = preload("res://scenes/objects/items/nimbus_2000.tscn")

func _ready() -> void:
	var broom = Broom.instantiate()
	inventory.append(broom)
	inventory.append(broom)
	inventory.append(broom)


func _process(_delta: float) -> void:
	pass
