extends Button
class_name StatModifierButton

@export var custom_text: String = "Oublié de set trallala"
var modifier: PlayerStats.StatModifier

signal upgrade_chosen

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func init() -> void:
	if modifier.operation == Stat.OperationTypes.ADD:
		text = modifier.stat.get_name() + " + " + str(modifier.value)
	else:
		text = modifier.stat.get_name() + " + " + str(modifier.value*100) + "%"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	PlayerStats.add_modifier_to(modifier.stat, modifier.operation, modifier.value)
	emit_signal("upgrade_chosen")
