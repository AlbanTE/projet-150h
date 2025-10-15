extends Enemy
class_name EnemyType1

func _on_enemy_ready() -> void:
	print("EnemyType1 ready with HP:", health_component.current_health)


func _apply_damage_effects(amount: int) -> void:
	print("Slime a pris ", amount, " dégats — HP:", health_component.current_health)


func _apply_death_effects() -> void:
	print("Slime mort — trucs a faire.")


func attack() -> void:
	print(" Slime attacks !")
