extends Node
class_name Spell

@export var spell_name: String
@export var spell_desc: String
@export var item_sprite: CompressedTexture2D
@export var cooldown : float
@export var input_action: String

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func destroy() -> void:
	print("Removing spell ----------")
	queue_free()
