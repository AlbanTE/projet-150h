extends Enemy
class_name EnemyType1

func _ready():
	enemy_color = Color.ORANGE
	health = 50
	speed = 100
	attack_type = AttackType.MELEE
	damage = 15
	detection_radius = 180.0
	follow_range = 120.0
	attack_range = 40.0
	super._ready()