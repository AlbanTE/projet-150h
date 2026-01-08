extends Item
class_name Incense_burner

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerStats.add_modifier_to(PlayerStats.duration, Stat.OperationTypes.MULT, 0.5, self)
	PlayerStats.add_modifier_to(PlayerStats.vitesse, Stat.OperationTypes.MULT, -0.25, self)
	print("Crystal active -----------")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
