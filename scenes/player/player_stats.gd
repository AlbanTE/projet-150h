extends Node

# Movement variables
var vitesse: float = 300.0				## Vitesse du joueur
var acceleration: float = 150.0			## Acceleration du joueur

# Weapon stats
var damage_multiplier: float = 1.0		## Multiplicateur de dégâts global
var attack_speed: float = 1.0			## Vitesse = réduction du cooldown
var knockback: float = 1.0

# Projectile stats
var additional_projectiles: int = 0		## Nombre de projectile en plus
var projectile_size: float = 1.0		## Taille des projectiles
var projectile_speed: float = 1.0		## Vitesse des projectiles

func test():
	pass
