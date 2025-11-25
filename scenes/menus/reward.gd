extends Control

const StatModifierButtonScene = preload("res://scenes/menus/StatModifierButton.tscn")

var reward_list: Array[PlayerStats.StatModifier] = [
	PlayerStats.StatModifier.new(PlayerStats.vitesse, Stat.OperationTypes.MULT, 0.2),
	PlayerStats.StatModifier.new(PlayerStats.knockback, Stat.OperationTypes.ADD, 1),
	PlayerStats.StatModifier.new(PlayerStats.projectile_size, Stat.OperationTypes.MULT, 0.15)
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for sm in reward_list:
		var button: StatModifierButton = StatModifierButtonScene.instantiate()
		button.modifier = sm
		button.init()
		button.connect("upgrade_chosen", close)
		$VBoxContainer.add_child(button)

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_U:
			if visible:
				close()
			else:
				open()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func open():
	get_tree().paused = true
	visible = true
	
func close():
	visible = false
	get_tree().paused = false
