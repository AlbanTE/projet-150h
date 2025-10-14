# res://projectiles/Bullet.gd
extends Area2D
class_name Bullet

@export var speed: float = 800.0
@export var damage: int = 10
var direction: Vector2 = Vector2.RIGHT

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	print("Hit !")
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
	queue_free()
