extends Spell
class_name Shield

@export var shield_material: ShaderMaterial  

var target_sprite: CanvasItem
var is_active: bool = false
var original_material: Material
var current_cooldown : float = 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if current_cooldown > 0:
		current_cooldown -= delta

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(input_action):
		activate()

func activate() -> void:
	if current_cooldown > 0:
		return
	
	if is_active:
		return

	is_active = true
	current_cooldown = cooldown
	if target_sprite and shield_material:
		original_material = target_sprite.material
		target_sprite.material = shield_material

func deactivate() -> void:
	if not is_active:
		return
	play_shield_break()
	is_active = false
	if target_sprite:
		target_sprite.material = original_material

func play_shield_break() -> void :
	$break_sfx.play()
