extends Area2D

signal exit_reached
var can_exit: bool = false

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	can_exit = true

func _on_body_entered(body: Node2D) -> void:
	if body is Player and can_exit:
		can_exit = false
		exit_reached.emit()
