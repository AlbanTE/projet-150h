extends Node

# Movement variables
var vitesse: float = 300.0				## Vitesse du joueur
var acceleration: float = 150.0			## Acceleration du joueur

# Weapon stats
var damage_multiplier: float = 1.0		## Multiplicateur de dégâts global - Pas encore utilisé
var attack_speed: float = 1.0			## Vitesse = réduction du cooldown

# Projectile stats
var additional_projectiles: int = 0		## Nombre de projectile en plus
var projectile_size: float = 1.0		## Taille des projectiles - Pas encore utilisé
var projectile_speed: float = 1.0		## Vitesse des projectiles - Pas encore utilisé

func test():
	pass
