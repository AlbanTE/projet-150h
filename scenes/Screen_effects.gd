extends CanvasLayer

var aberration_tween: Tween

func damage_flash():
	if aberration_tween:
		aberration_tween.kill()
	
	aberration_tween = create_tween()
	$Aberration.material.set_shader_parameter("ab_x", 0.2)
	$Aberration.material.set_shader_parameter("ab_y", 0.2)
	aberration_tween.tween_property($Aberration.material, "shader_parameter/ab_x", 0.0, 0.8)
	aberration_tween.parallel().tween_property($Aberration.material, "shader_parameter/ab_y", 0.0, 0.8)
