extends Node
class_name Item

@export var item_name: String
@export var item_desc: String
@export var item_sprite: CompressedTexture2D

func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	pass

func destroy() -> void:
	PlayerStats.remove_modifiers_from_source(self)
	print("Removing item ----------")
	queue_free()
