extends Spell
class_name Heal

var target_player
var is_active: bool = false
var current_cooldown : float = 0.0
var time_healing : float = 0.0
var max_time_healing : float = 10.0
var healing_accumulator : float = 0.0

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if animated_sprite:
		animated_sprite.visible = false
		animated_sprite.stop()

func _process(delta: float) -> void:
	if current_cooldown > 0:
		current_cooldown -= delta
	
	if is_active:
		if time_healing > 0:
			time_healing -= delta
			
			if target_player and target_player.health_component:
				var heal_amount_per_sec = float(target_player.health_component.max_health) * 0.03
				healing_accumulator += heal_amount_per_sec * delta
				
				if healing_accumulator >= 1.0:
					var amount_to_heal = int(healing_accumulator)
					target_player.heal(amount_to_heal)
					healing_accumulator -= amount_to_heal
		else:
			deactivate()

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
	time_healing = max_time_healing
	healing_accumulator = 0.0
	print("Heal activated!")


func deactivate() -> void:
	if not is_active:
		return
	is_active = false
	time_healing = 0.0
	
	if animated_sprite:
		animated_sprite.visible = false
		animated_sprite.stop()

func play_anim() -> void:
	if animated_sprite:
		animated_sprite.visible = true
		animated_sprite.play("heal_anim")
		
func _on_animation_finished() -> void:
	pass
