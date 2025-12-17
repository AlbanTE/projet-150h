extends Item
class_name Broom

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerStats.add_modifier_to(PlayerStats.vitesse, Stat.OperationTypes.MULT, 0.2, self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
