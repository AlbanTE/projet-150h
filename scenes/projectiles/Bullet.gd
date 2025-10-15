# res://projectiles/Bullet.gd
extends Area2D
class_name Bullet

@export var speed: float = 800.0
@export var damage: int = 10
var direction: Vector2 = Vector2.RIGHT

func _ready():
	
	collision_layer = 16  # Projectiles layer 16
	collision_mask = 1 | 8  # walls (1) + hurtboxes (8)
	
	add_to_group("bullets")  # Add to bullets group for HurtboxComponent detection
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func get_damage() -> int:
	return damage

func _on_area_entered(area: Area2D):
	print("Bullet hit area: ", area.name, " (", area.get_script().get_global_name() if area.get_script() else "no script", ")")
	# Don't delete the bullet here - let the HurtboxComponent handle it

func _on_body_entered(body):
	print("Bullet hit body: ", body.name)
	queue_free()

func delete_bullet():
	queue_free()
