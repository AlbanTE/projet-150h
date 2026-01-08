extends Item
class_name Clover

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerStats.add_modifier_to(PlayerStats.luck, Stat.OperationTypes.MULT, 0.5, self)
	print("Clover active -----------")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
