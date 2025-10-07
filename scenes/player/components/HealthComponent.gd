extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal health_depleted

@export var max_health: int = 500

var current_health: int

func _ready():
	current_health = max_health

func _process(_delta):
	test_health_system()

func take_damage(damage: int):
	if damage <= 0:
		return
	
	current_health = max(0, current_health - damage)
	health_changed.emit(current_health, max_health)
	$"../FlashEffectAnim".play("hit")
	
	if current_health <= 0:
		health_depleted.emit()

func heal(heal_amount: int):
	if heal_amount <= 0:
		return
	
	current_health = min(max_health, current_health + heal_amount)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

func test_health_system():
	if Input.is_action_just_pressed("ui_accept"):
		take_damage(50)
		print("Test: Dégâts -50 HP")
	
	if Input.is_action_just_pressed("ui_cancel"):
		heal(75)
		print("Test: Soins +75 HP")
	
