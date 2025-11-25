extends Node
class_name HealthComponent

## ────────────────
## Signals
## ────────────────
signal health_changed(current_health: int, max_health: int)
signal health_depleted

## ────────────────
## Properties
## ────────────────
@export var max_health: int = 100:
	set(value):
		var prev_health = current_health
		max_health = max(value, 1)
		current_health = clamp(current_health, 0, max_health)
		emit_signal("health_changed", prev_health, current_health, max_health)

var current_health: int = max_health:
	set(value):
		var prev_health = current_health
		current_health = clamp(value, 0, max_health)
		emit_signal("health_changed", prev_health, current_health, max_health)
		if current_health == 0:
			emit_signal("health_depleted")

# For zone-based damage tracking
var last_zone_damage_time: Dictionary = {}  # zone_id -> timestamp

## ────────────────
## Methods
## ────────────────
func _ready() -> void:
	current_health = clamp(current_health, 0, max_health)
	# emit_signal("health_changed", current_health, current_health, max_health)


func damage(amount: int) -> void:
	if amount <= 0:
		return
	#print("HealthComponent: -", amount, " HP (", current_health, " -> ", max(0, current_health - amount), ")")
	current_health = max(0, current_health - amount)


func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_health = min(max_health, current_health + amount)


func set_max_health(value: int) -> void:
	max_health = value


func set_current_health(value: int) -> void:
	current_health = value


func is_alive() -> bool:
	return current_health > 0


func zone_damage(zone_id: int, amount: int, interval: float) -> void:
	"""Apply damage from a zone-based weapon. Uses interval to prevent spam damage."""
	if amount <= 0:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Check if enough time has passed since last damage from this zone
	if zone_id in last_zone_damage_time:
		var last_time = last_zone_damage_time[zone_id]
		if current_time - last_time < interval:
			return  # Not enough time passed, skip damage
	
	# Apply damage and update timestamp
	last_zone_damage_time[zone_id] = current_time
	damage(amount)
