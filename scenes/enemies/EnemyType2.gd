extends Enemy
class_name EnemyType2

var activated: bool = false

func _apply_damage_effects(amount: int) -> void:
	#print("EnemyType2 a pris ", amount, " dégats — HP:", health_component.current_health)
	pass


func _apply_death_effects() -> void:
	#print("EnemyType2 mort — trucs a faire.")
	super()


func attack() -> void:
	#print("EnemyType2 attacks !")
	pass

func _process(_delta: float) -> void:
	if not activated:
		return
	super(_delta)


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	activated = true
