extends CanvasLayer

var aberration_tween: Tween

func _process(_delta: float) -> void:
	$Label.text = str(Engine.get_frames_per_second())
	

func damage_flash():
	if aberration_tween:
		aberration_tween.kill()
	
	aberration_tween = create_tween()
	aberration_tween.set_ease(Tween.EASE_OUT)
	aberration_tween.set_trans(Tween.TRANS_ELASTIC)
	
	$Aberration.material.set_shader_parameter("ab_x", 0.2)
	$Aberration.material.set_shader_parameter("ab_y", 0.2)
	
	aberration_tween.tween_property($Aberration.material, "shader_parameter/ab_x", 0.0, 1.0)
	aberration_tween.parallel().tween_property($Aberration.material, "shader_parameter/ab_y", 0.0, 1.0)
