extends Enemy
class_name EnemyType2

func _apply_damage_effects(amount: int) -> void:
	print("EnemyType2 a pris ", amount, " dégats — HP:", health_component.current_health)


func _apply_death_effects() -> void:
	print("EnemyType2 mort — trucs a faire.")


func attack() -> void:
	print("EnemyType2 attacks !")


