extends CanvasLayer

var aberration_tween: Tween
var berserk_tween: Tween
var berserk_rect: ColorRect

const BERSERK_SHADER = preload("res://shaders/berserk.gdshader")

func _ready() -> void:
	if not has_node("BerserkOverlay"):
		berserk_rect = ColorRect.new()
		berserk_rect.name = "BerserkOverlay"
		berserk_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		berserk_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var mat = ShaderMaterial.new()
		mat.shader = BERSERK_SHADER
		mat.set_shader_parameter("intensity", 0.0)
		berserk_rect.material = mat
		
		add_child(berserk_rect)
		# Ensure it's drawn on top of other effects like Aberration
		# move_child(berserk_rect, get_child_count() - 1) 
	else:
		berserk_rect = $BerserkOverlay

func damage_flash():
	if aberration_tween:
		aberration_tween.kill()
	
	aberration_tween = create_tween()
	$Aberration.material.set_shader_parameter("ab_x", 0.2)
	$Aberration.material.set_shader_parameter("ab_y", 0.2)
	aberration_tween.tween_property($Aberration.material, "shader_parameter/ab_x", 0.0, 0.8)
	aberration_tween.parallel().tween_property($Aberration.material, "shader_parameter/ab_y", 0.0, 0.8)

func enable_berserk(duration: float = 0.5):
	if berserk_tween:
		berserk_tween.kill()
	berserk_tween = create_tween()
	berserk_tween.tween_property(berserk_rect.material, "shader_parameter/intensity", 1.0, duration)

func disable_berserk(duration: float = 0.5):
	if berserk_tween:
		berserk_tween.kill()
	berserk_tween = create_tween()
	berserk_tween.tween_property(berserk_rect.material, "shader_parameter/intensity", 0.0, duration)
