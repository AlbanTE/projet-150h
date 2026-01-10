extends CharacterBody2D
class_name Player

# ────────────────
# Component 
# ────────────────
@onready var movement_component: MovementComponent = $MovementPlayer
@onready var health_component: HealthComponent = $HealthComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var inventory_manager: InventoryManager = $InventoryManager
@onready var health_bar: ProgressBar = $HealthBar

var shield_spell_scene : PackedScene = preload("res://scenes/objects/spells/shield.tscn")
var shield_instance : Shield

var heal_spell_scene : PackedScene = preload("res://scenes/objects/spells/heal.tscn")
var heal_instance : Heal

var zoomies_spell_scene : PackedScene = preload("res://scenes/objects/spells/zoomies.tscn")
var zoomies_instance : Zoomies

# ────────────────
# Player state
# ────────────────
var is_alive: bool = true

var disabled_inputs: bool = false
var invicible: bool = false

signal player_died

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

	$HealthBar/Label.text = str(health_component.current_health) + " / " + str(health_component.max_health)
	print("Player ready with %d HP" % health_component.current_health)

	if shield_spell_scene:
		shield_instance = shield_spell_scene.instantiate()
		add_child(shield_instance)
		shield_instance.target_sprite = $AnimatedSprite2D
	
	if heal_spell_scene:
		heal_instance = heal_spell_scene.instantiate()
		add_child(heal_instance)
		heal_instance.target_player = self
	
	if zoomies_spell_scene:
		zoomies_instance = zoomies_spell_scene.instantiate()
		add_child(zoomies_instance)
		zoomies_instance.target_player = self
	
func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	if movement_component:
		if not disabled_inputs:
			movement_component.update_movement(self, delta)
		
		if velocity != Vector2.ZERO and velocity.normalized() != Vector2.UP and velocity.normalized() != Vector2.DOWN:
			if abs(rad_to_deg(velocity.angle())) > 90:
				$AnimatedSprite2D.flip_h = false
			else:
				$AnimatedSprite2D.flip_h = true

func make_invicible():
	invicible = true

func unmake_invincible():
	invicible = false

# ────────────────
# callbacks
# ────────────────
func _on_health_changed(prev_health: int, current_health: int, max_health: int) -> void:
	health_bar.value = current_health
	$HealthBar/Label.text = str(current_health) + " / " + str(max_health)
	if (current_health > prev_health):
		if heal_instance:
			heal_instance.play_anim()
	elif (current_health == prev_health):
		pass
	else:
		print("Player took ", prev_health - current_health)
		$FlashEffectAnim.play("hit")
		get_node("../ScreenEffects").damage_flash()
		play_sound_by_name("Damaged")
		
		make_invicible()
		get_tree().create_timer(1).timeout.connect(unmake_invincible)
		

func _on_health_depleted() -> void:
	print("Player died!")
	is_alive = false
	velocity = Vector2.ZERO
	player_died.emit()
	# death animation or respawn 


# ────────────────
# Damage & Heal 
# ────────────────
func take_damage(damage: int) -> void:
	if not is_alive or not health_component or invicible:
		return

	if shield_instance and shield_instance.is_active:
		shield_instance.deactivate()
		return
	
	health_component.damage(damage)


func heal(amount: int) -> void:
	if not is_alive or not health_component:
		return
	health_component.heal(amount)

# ────────────────
# Input
# ────────────────
func _input(event: InputEvent) -> void:
	if disabled_inputs:
		return
	
	if weapon_component and is_alive:
		weapon_component.handle_input(event)
	if shield_instance:
		shield_instance.handle_input(event)
	if heal_instance:
		heal_instance.handle_input(event)
	if zoomies_instance:
		zoomies_instance.handle_input(event)

func disable_input():
	disabled_inputs = true
	
func enable_input():
	disabled_inputs = false
