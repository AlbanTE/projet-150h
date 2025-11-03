extends Area2D
class_name Bulle


@export var speed: float = 150
@export var damage: int = 8
@export var knockback: float = 0.1
@export var lifetime: float = 4.0  # Durée de vie
@export var speed_decay: float = 0.7

var direction: Vector2 = Vector2.RIGHT
var initial_speed: float
var time_alive: float = 0.0

func _ready():
	
	collision_layer = 16  # Projectiles layer 16
	collision_mask = 1 | 8  # hurtboxes + walls (8)
	
	add_to_group("bullets") 
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	initial_speed = speed
	get_tree().create_timer(lifetime).timeout.connect(delete_bullet)

func _physics_process(delta):
	time_alive += delta
	
	var life_ratio = time_alive / lifetime  # 0.0 au début, 1.0 à la fin
	var current_speed = initial_speed * (1.0 - (1.0 - speed_decay) * life_ratio)
	
	position += direction * current_speed * delta

func get_damage() -> int:
	return damage

func get_knockback() -> float:
	return knockback

func _on_area_entered(area: Area2D):
	print("Bulle hit area: ", area.name)
	delete_bullet()
	
func _on_body_entered(body):
	print("Bullet hit body: ", body.name)
	delete_bullet()

func delete_bullet():
	queue_free()
