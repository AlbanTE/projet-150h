extends Area2D

static var available_items: Array[PackedScene] = []
var opened: bool = false

func _ready() -> void:
	
	if available_items.is_empty():
		#available_items.append(preload("res://scenes/objects/items/nimbus_2000.tscn"))
		#available_items.append(preload("res://scenes/objects/items/gloves.tscn"))
		available_items.append(preload("res://scenes/objects/items/crystal.tscn"))
		#available_items.append(preload("res://scenes/objects/items/incense_burner.tscn"))
		#available_items.append(preload("res://scenes/objects/items/clover.tscn"))
		
	$AnimatedSprite2D.animation_finished.connect(destroy)
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and not opened:
		opened = true
		
		$AnimatedSprite2D.play("default")
		var player: Player = body
		
		await $AnimatedSprite2D.animation_finished
		
		if not available_items.is_empty():
			var random_index: int = randi() % available_items.size()
			var item_scene: PackedScene = available_items[random_index]
			var item: Item = item_scene.instantiate()
			player.inventory_manager.add_item(item)

func destroy() -> void:
	queue_free()
