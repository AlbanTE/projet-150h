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
var luck                  : Stat = Stat.new(1.0, "Luck")

# -----------------------------------
#   INGAME COUNTERS
# -----------------------------------

var UPGRADES_COUNT: int = 0
var UPGRADES_MAX: int = 10

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

func get_luck() -> float:
	return luck.get_value()

func compute_damage(damage: float) -> float:
	return damage_multiplier.apply_modifiers(damage)

# -----------------------------------
#   UNIVERSAL UTILITY HELPERS
# -----------------------------------
func add_modifier_to(stat: Stat, operation: Stat.OperationTypes, value: float, source = null):
	var mod = Stat.Modifier.new(operation, value, source)
	stat.add_modifier(mod)
	return mod

func remove_modifiers_from_source(source):
	for s in [
		vitesse, acceleration, attack_speed, additional_projectiles,
		damage_multiplier, projectile_size, projectile_speed,
		knockback, duration, luck
	]:
		s.remove_modifiers_from_source(source)

func reset():
	for s in [
		vitesse, acceleration, attack_speed, additional_projectiles,
		damage_multiplier, projectile_size, projectile_speed,
		knockback, duration, luck
	]:
		s.reset()

# -----------------------------------
#   STAT RARITY & BALANCE CONFIG
# -----------------------------------
enum Rarity { COMMON, UNCOMMON, RARE }

const STAT_RARITY = {
	# Stats communes
	"vitesse": Rarity.COMMON,
	"acceleration": Rarity.COMMON,
	"projectile_speed": Rarity.COMMON,
	"duration": Rarity.COMMON,
	"knockback": Rarity.COMMON,
	# Stats peu communes
	"damage_multiplier": Rarity.UNCOMMON,
	"attack_speed": Rarity.UNCOMMON,
	"projectile_size": Rarity.UNCOMMON,
	# Stats rares
	"additional_projectiles": Rarity.RARE,
	"luck": Rarity.RARE,
}

# Probabilités de base pour chaque rareté (sans luck)
const BASE_RARITY_WEIGHTS = {
	Rarity.COMMON: 10.0,
	Rarity.UNCOMMON: 5.0,
	Rarity.RARE: 2.0,
}

func _get_stat_rarity(stat: Stat) -> Rarity:
	match stat:
		vitesse, acceleration, projectile_speed, duration, knockback:
			return Rarity.COMMON
		damage_multiplier, attack_speed, projectile_size:
			return Rarity.UNCOMMON
		additional_projectiles, luck:
			return Rarity.RARE
	return Rarity.COMMON

func _get_adjusted_rarity_weights() -> Dictionary:
	var luck_value = get_luck()
	var weights = {}
	
	# La luck augmente les chances de stats rares/uncommon
	# Formule : poids_base * (1 + (luck - 1) * multiplicateur)
	weights[Rarity.COMMON] = BASE_RARITY_WEIGHTS[Rarity.COMMON]
	weights[Rarity.UNCOMMON] = BASE_RARITY_WEIGHTS[Rarity.UNCOMMON] * (1.0 + (luck_value - 1.0) * 0.5)
	weights[Rarity.RARE] = BASE_RARITY_WEIGHTS[Rarity.RARE] * (1.0 + (luck_value - 1.0) * 1.0)
	
	return weights

func _get_stat_pool() -> Array:
	var weights = _get_adjusted_rarity_weights()
	var pool = []
	
	# Stats communes
	for i in weights[Rarity.COMMON]:
		pool.append_array([vitesse, acceleration, projectile_speed, duration, knockback])
	
	# Stats peu communes
	for i in weights[Rarity.UNCOMMON]:
		pool.append_array([damage_multiplier, attack_speed, projectile_size])
	
	# Stats rares
	for i in weights[Rarity.RARE]:
		pool.append_array([additional_projectiles, luck])
	
	return pool

func _apply_luck_to_value(base_min: float, base_max: float, is_mult: bool = false) -> float:
	var luck_value = get_luck()
	# La luck augmente légèrement la valeur vers le maximum
	# Formule : lerp entre min et max, biaisé par la luck
	var luck_bias = clamp((luck_value - 1.0) * 0.3, 0.0, 0.5)  # Max +50% de bias
	var random_factor = randf() + luck_bias
	random_factor = clamp(random_factor, 0.0, 1.0)
	
	var value = lerp(base_min, base_max, random_factor)
	
	if is_mult:
		return snappedf(value, 0.01)
	return value

func generate_random_buffs(n: int) -> Array[StatModifier]:
	var buffs: Array[StatModifier] = []
	var selected_stats = []
	
	for i in n:
		var pool = _get_stat_pool()
		# Retire les stats déjà sélectionnées du pool
		for selected in selected_stats:
			pool = pool.filter(func(s): return s != selected)
		
		if pool.is_empty():
			break
			
		var stat = pool.pick_random()
		selected_stats.append(stat)
		
		var mod_type: Stat.OperationTypes
		var value: float
		
		# Configuration spécifique par stat pour un bon équilibrage
		match stat:
			additional_projectiles:
				mod_type = Stat.OperationTypes.ADD
				value = 1  # Toujours +1 projectile (très puissant)
				
			luck:
				mod_type = Stat.OperationTypes.MULT
				value = _apply_luck_to_value(0.10, 0.25, true)  # +10% à +25%
				
			attack_speed:
				mod_type = Stat.OperationTypes.MULT
				value = _apply_luck_to_value(0.08, 0.15, true)  # +8% à +15%
				
			damage_multiplier:
				mod_type = Stat.OperationTypes.MULT
				value = _apply_luck_to_value(0.10, 0.20, true)  # +10% à +20%
				
			projectile_size:
				mod_type = Stat.OperationTypes.MULT
				value = _apply_luck_to_value(0.08, 0.15, true)  # +8% à +15%
				
			vitesse:
				if randf() > 0.3:  # 70% ADD, 30% MULT
					mod_type = Stat.OperationTypes.ADD
					value = snappedf(_apply_luck_to_value(20, 50), 1.0)  # +20 à +50
				else:
					mod_type = Stat.OperationTypes.MULT
					value = _apply_luck_to_value(0.08, 0.12, true)  # +8% à +12%
					
			acceleration:
				if randf() > 0.3:
					mod_type = Stat.OperationTypes.ADD
					value = snappedf(_apply_luck_to_value(15, 40), 1.0)  # +15 à +40
				else:
					mod_type = Stat.OperationTypes.MULT
					value = _apply_luck_to_value(0.08, 0.12, true)  # +8% à +12%
					
			projectile_speed:
				mod_type = Stat.OperationTypes.MULT
				value = _apply_luck_to_value(0.10, 0.20, true)  # +10% à +20%
				
			duration:
				mod_type = Stat.OperationTypes.MULT
				value = _apply_luck_to_value(0.10, 0.20, true)  # +10% à +20%
				
			knockback:
				mod_type = Stat.OperationTypes.MULT
				value = _apply_luck_to_value(0.15, 0.30, true)  # +15% à +30%
		
		buffs.append(StatModifier.new(stat, mod_type, value))
	
	return buffs
