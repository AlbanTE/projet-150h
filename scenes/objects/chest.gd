extends Area2D

var Broom: PackedScene = preload("res://scenes/objects/items/nimbus_2000.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.animation_finished.connect(destroy)
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		$AnimatedSprite2D.play("default")
		var player: Player = body
		
		await $AnimatedSprite2D.animation_finished
		
		var broom: Item = Broom.instantiate()
		# Si pas de place dans l'inventaire, l'instance n'est pas attachée (pas de add_child)
		# Donc, ses effets ne s'activent pas (pas d'appel du ready) 
		player.inventory_manager.add_item(broom)

func destroy() -> void:
	queue_free()
