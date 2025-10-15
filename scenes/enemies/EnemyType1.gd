extends Enemy
class_name EnemyType1


func _apply_damage_effects(_amount: int) -> void:
	pass

func _apply_death_effects() -> void:
	print("Slime mort — trucs a faire.")


func attack() -> void:
	print(" Slime attacks !")
