extends CharacterBody2D
class_name Player

# Component references
@onready var movement_component = $MovementPlayer
@onready var health_component = $HealthComponent

# Player state
var is_alive: bool = true

func _ready():
	if health_component:
		health_component.health_depleted.connect(_on_health_depleted)
		health_component.health_changed.connect(_on_health_changed)
	
	if movement_component:
		print("Movement component ready")

func _physics_process(_delta):
	# Only allow movement if player is alive
	if is_alive and movement_component:
		movement_component.handle_input()
		velocity.x = move_toward(velocity.x, movement_component.vect_direction.x * movement_component.vitesse, movement_component.acceleration)
		velocity.y = move_toward(velocity.y, movement_component.vect_direction.y * movement_component.vitesse, movement_component.acceleration)
		move_and_slide()

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
