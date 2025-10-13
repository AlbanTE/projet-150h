extends CharacterBody2D
class_name Player

# Component references
@onready var movement_component = $MovementPlayer
@onready var health_component = $HealthComponent
@onready var weapon_component = $WeaponComponent

# Player state
var is_alive: bool = true

func _ready():
	# Add player to group for easy finding by enemies
	add_to_group("player")
	
	# Set collision layers: player only collides with walls, not with enemies
	collision_layer = 4  # Player is on layer 4 (separate from enemies)
	collision_mask = 1   # Player only collides with walls (layer 1)
	
	if health_component:
		health_component.health_depleted.connect(_on_health_depleted)
		health_component.health_changed.connect(_on_health_changed)
	
	if movement_component:
		print("Movement component ready")

func _physics_process(_delta):
	# Only allow movement if player is alive
	if is_alive and movement_component:
		movement_component.update_movement(self, _delta)

func _on_health_depleted():
	print("Player died!")
	is_alive = false
	velocity = Vector2.ZERO

func _on_health_changed(current_health: int, max_health: int):
	print("Health changed: %d/%d" % [current_health, max_health])

func take_damage(damage: int):
	if health_component and is_alive:
		health_component.take_damage(damage)

func heal(heal_amount: int):
	if health_component:
		health_component.heal(heal_amount)

func _input(event):
	if weapon_component:
		weapon_component.handle_input(event)
