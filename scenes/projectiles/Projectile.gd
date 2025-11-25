extends Area2D
class_name Projectile

@export var speed: float = 150
@export var damage: float = 8
@export var knockback: float = 0.1
@export var lifetime: float = 1

func _ready():
	
	collision_layer = 16  # Projectiles layer 16
	collision_mask = 1 | 8  # walls (1) + hurtboxes (8)
	
	add_to_group("bullets")  # Add to bullets group for HurtboxComponent detection
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	setup_stats()
	
	get_tree().create_timer(lifetime).timeout.connect(delete_bullet)

func setup_stats() -> void:
	speed *= PlayerStats.get_projectile_size()
	damage = PlayerStats.compute_damage(damage)
	knockback *= PlayerStats.get_knockback()
	scale *= Vector2(PlayerStats.get_projectile_size(), PlayerStats.get_projectile_size())
	lifetime *= PlayerStats.get_duration()

func get_damage() -> float:
	return damage

func get_knockback() -> float:
	return knockback

func _on_area_entered(area: Area2D):
	# print("Bullet hit area: ", area.name, " (", area.get_script().get_global_name() if area.get_script() else "no script", ")")
	# Don't delete the bullet here - let the HurtboxComponent handle it
	pass

func _on_body_entered(body):
	print("Bullet hit body: ", body.name)
	delete_bullet()

func delete_bullet():
	queue_free()
