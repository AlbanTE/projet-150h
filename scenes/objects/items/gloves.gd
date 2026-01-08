extends Item
class_name Lantern

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerStats.add_modifier_to(PlayerStats.attack_speed, Stat.OperationTypes.MULT, 0.3, self)
	PlayerStats.add_modifier_to(PlayerStats.knockback, Stat.OperationTypes.MULT, -0.1, self)
	print("Gloves active -----------")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
