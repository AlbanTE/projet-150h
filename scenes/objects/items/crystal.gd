extends Item
class_name Crystal

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerStats.add_modifier_to(PlayerStats.additional_projectiles, Stat.OperationTypes.ADD, 3, self)
	PlayerStats.add_modifier_to(PlayerStats.damage_multiplier, Stat.OperationTypes.MULT, -0.5, self)
	print("Crystal active -----------")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
