extends Area2D
class_name HurtboxComponent

## The Hurtbox detects bullet collisions and emits signals
## Optionally communicates with a HealthComponent to apply damage.

# ────────────────
# Exported
# ────────────────
@export var health_component: NodePath
var health: HealthComponent = null

# ────────────────
# Signals
# ────────────────
signal hit_by_bullet(bullet: Node, damage: int, knockback: float)

# ────────────────
# Lifecycle
# ────────────────
func _ready() -> void:
	
	if health_component and has_node(health_component):
		health = get_node(health_component) as HealthComponent

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


# ────────────────
# Collision handlers
# ────────────────
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullets"):  
		_handle_bullet_collision(area)
	else:
		print("HurtboxComponent: Area is not in bullets group")


func _on_body_entered(_body: Node2D) -> void:
	pass


# ────────────────
#  logic
# ────────────────
func _handle_bullet_collision(bullet: Node2D) -> void:
	if not bullet:
		return

	var damage := 0
	if "get_damage" in bullet:
		damage = bullet.get_damage()
	else:
		push_warning("Bullet does not have get_damage()")
		
	var knockback := 0
	if "get_knockback" in bullet:
		knockback = bullet.get_knockback()
	else:
		push_warning("Bullet does not have get_knockback()")

	print("HurtboxComponent: Bullet hit for ", damage, " damage, and ", knockback, " knockback")
	emit_signal("hit_by_bullet", bullet, damage, knockback)

	if health:
		health.damage(damage)
	else:
		print("HurtboxComponent: No health component found!")

	if bullet.has_method("delete_bullet"):
		bullet.delete_bullet()
