extends Enemy
class_name EnemyType1

@export var health_override: int = 50
@export var speed_override: float = 100.0
@export var attack_type_override: AttackType = AttackType.MELEE
@export var damage_override: int = 15
@export var detection_radius_override: float = 300
@export var attack_range_override: float = 40.0

func _ready():
	enemy_color = Color.ORANGE
	health = health_override
	speed = speed_override
	attack_type = attack_type_override
	damage = damage_override
	detection_radius = detection_radius_override
	attack_range = attack_range_override
	super._ready()
