extends Enemy
class_name EnemyType1

# Called after base enemy initialization
func _on_enemy_ready() -> void:
	pass

func _apply_damage_effects(_amount: int):
	print("Petit slime a pris ", _amount, " damage, vie : ", health)
	
func attack() -> void:
	# Custom attack implementation for EnemyType1
	# Example: melee attack animation, deal damage to player
	pass
