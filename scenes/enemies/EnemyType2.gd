extends Enemy
class_name EnemyType2

func _ready():
	enemy_color = Color.RED
	health = 100
	speed = 80
	attack_type = AttackType.MELEE
	damage = 30
	detection_radius = 200.0
	follow_range = 150.0
	attack_range = 50.0
	super._ready()