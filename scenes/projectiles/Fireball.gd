# res://projectiles/Fireball.gd
extends Projectile
class_name Fireball

var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta):
	position += direction * speed * delta
