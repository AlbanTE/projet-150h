extends Projectile
class_name Bulle

@export var speed_decay: float = 0.7

var direction: Vector2 = Vector2.RIGHT
var initial_speed: float
var time_alive: float = 0.0

func _ready():
	super()
	initial_speed = speed

func _physics_process(delta):
	time_alive += delta
	
	var life_ratio = time_alive / lifetime  # 0.0 au début, 1.0 à la fin
	var current_speed = initial_speed * (1.0 - (1.0 - speed_decay) * life_ratio)
	
	position += direction * current_speed * delta
