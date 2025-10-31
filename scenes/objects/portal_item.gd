extends Area2D


func _on_body_entered(body: Node2D) -> void:
	print("Portal print")
	if body is Player:
		body.movement_component.vitesse *= 2
		queue_free()
