# res://weapons/LanceTomatoGun.gd
extends Weapon
class_name LanceTomatoGun

@onready var muzzle = $Muzzle

func fire(player: Node2D) -> void:
	if not can_fire():
		return
	
	_can_fire = false
	
	var target_pos = get_global_mouse_position()
	
	if projectile_scene:
		var tomate = projectile_scene.instantiate()
		tomate.global_position = muzzle.global_position
		tomate.damage = damage
		
		player.get_tree().current_scene.add_child(tomate)
		
		tomate.setup(target_pos)
	
	await get_tree().create_timer(fire_rate).timeout
	_can_fire = true
