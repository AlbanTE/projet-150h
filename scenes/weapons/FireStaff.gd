# res://weapons/Gun.gd
extends Weapon
class_name Gun

@onready var muzzle = $Muzzle

func spawn_projectile(player: Node2D) -> void:
	if projectile_scene:
		var bullet = projectile_scene.instantiate()
		bullet.global_position = muzzle.global_position
		
		var mouse_pos = get_global_mouse_position()
		bullet.direction = (mouse_pos - bullet.global_position).normalized()
		bullet.rotation = bullet.direction.angle()
		
		player.get_tree().current_scene.add_child(bullet)
