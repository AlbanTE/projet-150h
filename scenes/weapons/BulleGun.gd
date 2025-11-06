# res://weapons/BulleGun.gd
extends Weapon
class_name BulleGun

@onready var muzzle = $Muzzle

func spawn_projectile(player: Node2D) -> void:
	var cible = get_direction_to_mouse()
	creer_projectile(cible, player)

func get_direction_to_mouse() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	return (mouse_pos - muzzle.global_position).normalized()

func creer_projectile(base_direction: Vector2, player: Node2D):
	var bulle: Bulle = projectile_scene.instantiate()
	bulle.global_position = muzzle.global_position
	
	var angle = randf_range(-10.0, 10.0)  
	var random_direction = base_direction.rotated(deg_to_rad(angle))
	bulle.speed *= randf_range(0.8, 1.2)
	
	bulle.direction = random_direction
	bulle.rotation = random_direction.angle()
		
	player.get_tree().current_scene.add_child(bulle)
