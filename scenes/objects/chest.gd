extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.animation_finished.connect(destroy)
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		$AnimatedSprite2D.play("default")

func destroy() -> void:
	queue_free()
