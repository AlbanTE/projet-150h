extends Node
# This will work as an autoload such as "PlayerStats" in Project Settings → Autoload

class StatModifier:
	var stat: Stat
	var operation: Stat.OperationTypes
	var value: float
	var source       # optional: what object applied this modifier
	
	func _init(st, op, val, src=null):
		stat = st
		operation = op
		value = val
		source = src

# -----------------------------------
#   STATS (instantiated at load time)
# -----------------------------------

var vitesse               : Stat = Stat.new(300.0, "Speed")
var acceleration          : Stat = Stat.new(150.0, "Acceleration")

var attack_speed          : Stat = Stat.new(1.0, "Attack speed")
var additional_projectiles: Stat = Stat.new(0, "Additional projectiles")

var damage_multiplier     : Stat = Stat.new(1.0, "Damage")
var projectile_size       : Stat = Stat.new(1.0, "Projectile size")
var projectile_speed      : Stat = Stat.new(1.0, "Projectile speed")
var knockback             : Stat = Stat.new(1.0, "Knockback")
var duration              : Stat = Stat.new(1.0, "Duration")


# -----------------------------------
#   GETTERS FOR FINAL CALCULATED VALUES
# -----------------------------------

func get_vitesse() -> float:
	return vitesse.get_value()

func get_acceleration() -> float:
	return acceleration.get_value()

func get_attack_speed() -> float:
	return attack_speed.get_value()

func get_additional_projectiles() -> int:
	return int(additional_projectiles.get_value())

func get_projectile_size() -> float:
	return projectile_size.get_value()

func get_projectile_speed() -> float:
	return projectile_speed.get_value()

func get_knockback() -> float:
	return knockback.get_value()

func get_duration() -> float:
	return duration.get_value()

func compute_damage(damage: float) -> float:
	return damage_multiplier.apply_modifiers(damage)

# -----------------------------------
#   UNIVERSAL UTILITY HELPERS
# -----------------------------------

func add_modifier_to(stat: Stat, operation: Stat.OperationTypes, value: float, source = null):
	# Creates + applies a modifier, returns it so caller can remove it later
	var mod = Stat.Modifier.new(operation, value, source)
	stat.add_modifier(mod)
	return mod

func remove_modifiers_from_source(source):
	# Removes all modifiers from any stat that were applied by "source"
	for s in [
		vitesse, acceleration, attack_speed, additional_projectiles,
		damage_multiplier, projectile_size, projectile_speed,
		knockback, duration
	]:
		s.remove_modifiers_from_source(source)

func reset():
	for s in [
		vitesse, acceleration, attack_speed, additional_projectiles,
		damage_multiplier, projectile_size, projectile_speed,
		knockback, duration
	]:
		s.reset()
	
