# res://projectiles/Bullet.gd
extends Area2D
class_name Bullet

@export var speed: float = 800.0
@export var damage: int = 10
var direction: Vector2 = Vector2.RIGHT

func _ready():
	
	collision_layer = 16  # Projectiles layer 16
	collision_mask = 1  # walls (1)
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func get_damage() -> int:
	return damage

func _on_area_entered(area: Area2D):
	print("Bullet hit area: ", area.name)
	# Le projectile ne traite plus les dégâts, c'est l'ennemi qui s'en charge

func _on_body_entered(body):
	print("Bullet hit body: ", body.name)
	queue_free()
