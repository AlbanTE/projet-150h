# res://weapons/LanceTomatoGun.gd
extends Weapon
class_name LanceTomatoGun

@onready var muzzle = $Muzzle

var area_offset: float = 50

func spawn_projectile(player: Node2D) -> void:
	var target_pos = get_global_mouse_position()
	target_pos.x += randf_range(-area_offset/2., area_offset/2.)
	target_pos.y += randf_range(-area_offset/2., area_offset/2.)
	
	if projectile_scene:
		var tomate = projectile_scene.instantiate()
		tomate.global_position = muzzle.global_position
		tomate.damage = damage
		
		player.get_tree().current_scene.add_child(tomate)
		
		tomate.setup(target_pos)
