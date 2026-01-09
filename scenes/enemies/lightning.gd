extends Area2D
class_name Lightning

@onready var animation_player := $AnimationPlayer

var damageable: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.animation_finished.connect(destroy)
	animation_player.play("strike")

func destroy(_anim_name: String):
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and damageable:
		body.take_damage(30)
