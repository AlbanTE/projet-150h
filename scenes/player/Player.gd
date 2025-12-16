extends CharacterBody2D
class_name Player

# ────────────────
# Component 
# ────────────────
@onready var movement_component: MovementComponent = $MovementPlayer
@onready var health_component: HealthComponent = $HealthComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var shield_spell_component: Node = $ShieldSpellComponent
# ────────────────
# Player state
# ────────────────
var is_alive: bool = true

# ────────────────
# Audio streams
# ────────────────
@onready var damage_stream: Node = $Audio_CatScream

func play_sound_by_name(audio_name : String):
	if audio_name == "Damaged":
		damage_stream.play()

# ────────────────
# Main logic
# ────────────────
func _ready() -> void:
	add_to_group("player")

	collision_layer = 4  # Player layer
	collision_mask = 1   # Collides with walls

	if health_component:
		health_component.health_depleted.connect(_on_health_depleted)
		health_component.health_changed.connect(_on_health_changed)

	print("Player ready with %d HP" % health_component.current_health)
	
	# Shield spell is automatically set up by ShieldSpellComponent
		
func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	if movement_component:
		movement_component.update_movement(self, delta)
		
		if velocity != Vector2.ZERO and velocity.normalized() != Vector2.UP and velocity.normalized() != Vector2.DOWN:
			if abs(rad_to_deg(velocity.angle())) > 90:
				$AnimatedSprite2D.flip_h = false
			else:
				$AnimatedSprite2D.flip_h = true


# ────────────────
# callbacks
# ────────────────
func _on_health_changed(prev_health: int, current_health: int, max_health: int) -> void:
	print("Health: %d/%d" % [current_health, max_health])
	if (current_health > prev_health):
		# Play heal effect
		pass
	elif (current_health == prev_health):
		# Play block effect or something...
		pass
	else:
		$FlashEffectAnim.play("hit")

func _on_health_depleted() -> void:
	print("Player died!")
	is_alive = false
	velocity = Vector2.ZERO
	# death animation or respawn 


# ────────────────
# Damage & Heal 
# ────────────────
func take_damage(damage: int) -> void:
	if not is_alive or not health_component:
		return
	health_component.damage(damage)
	play_sound_by_name("Damaged")


func heal(amount: int) -> void:
	if not is_alive or not health_component:
		return
	health_component.heal(amount)

# ────────────────
# Input
# ────────────────
func _input(event: InputEvent) -> void:
	if weapon_component and is_alive:
		weapon_component.handle_input(event)
	if shield_spell_component:
		shield_spell_component.handle_input(event)
