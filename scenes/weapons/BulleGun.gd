# res://weapons/BulleGun.gd
extends Weapon
class_name BulleGun

@onready var muzzle = $Muzzle

@export var projectile_count: int = 3

func fire(player: Node2D) -> void:
	if not can_fire():
		return
	
	_can_fire = false
	
	var cible = get_direction_to_mouse()
	
	for i in projectile_count:
		creer_projectile(cible, player)
	
	await get_tree().create_timer(fire_rate).timeout
	_can_fire = true

func get_direction_to_mouse() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	return (mouse_pos - muzzle.global_position).normalized()

func creer_projectile(base_direction: Vector2, player: Node2D):
	var bulle = projectile_scene.instantiate()
	bulle.global_position = muzzle.global_position
	
	var angle = randf_range(-10.0, 10.0)  
	var random_direction = base_direction.rotated(deg_to_rad(angle))
	var random_speed = projectile_speed * randf_range(0.8, 1.2)
	
	bulle.direction = random_direction
	bulle.rotation = random_direction.angle()
	bulle.speed = random_speed
	bulle.damage = damage
	
	player.get_tree().current_scene.add_child(bulle)
