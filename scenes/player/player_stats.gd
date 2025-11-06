extends Node

# Movement variables
var vitesse: float = 300.0				## Vitesse du joueur
var acceleration: float = 150.0			## Acceleration du joueur

# Weapon stats
var attack_speed: float = 1.0			## Vitesse = réduction du cooldown
var additional_projectiles: int = 0		## Nombre de projectile en plus

# Projectile stats
var damage_multiplier: float = 1.0		## Multiplicateur de dégâts global
var projectile_size: float = 1.0		## Taille des projectiles
var projectile_speed: float = 1.0		## Vitesse des projectiles
var knockback: float = 1.0				## Distance d'éloignement
var duration: float = 1.0				## 

func test():
	pass
