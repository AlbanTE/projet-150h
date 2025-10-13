# res://weapons/Gun.gd
extends Weapon
class_name Gun

@onready var muzzle = $Muzzle

func fire(player: Node2D) -> void:
	if not can_fire():
		return

	_can_fire = false
	ammo -= 1

	# Spawn projectile
	if projectile_scene:
		var bullet = projectile_scene.instantiate()
		bullet.global_position = muzzle.global_position
		
		var mouse_pos = get_global_mouse_position()
		bullet.direction = (mouse_pos - bullet.global_position).normalized()
		bullet.rotation = bullet.direction.angle()
		bullet.speed = projectile_speed
		bullet.damage = damage
		player.get_tree().current_scene.add_child(bullet)

	# Simple cooldown
	await get_tree().create_timer(fire_rate).timeout
	_can_fire = true
