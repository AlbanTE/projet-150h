extends Spell
class_name Zoomies

var target_player: Player

var is_active: bool = false
var current_cooldown: float = 0.0
var active_time: float = 0.0
var max_active_time: float = 10.0

var damage_modifier: Stat.Modifier

func _ready() -> void:
	damage_modifier = Stat.Modifier.new(Stat.OperationTypes.MULT, 1.0, self)

func _process(delta: float) -> void:
	if current_cooldown > 0:
		current_cooldown -= delta
		
	if is_active:
		active_time -= delta
		if active_time <= 0:
			deactivate()

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(input_action):
		print("Zoomies Activated")
		activate()

func activate() -> void:
	if current_cooldown > 0:
		return
		
	if is_active:
		active_time = max_active_time
		return
		
	if not target_player:
		if get_parent() is Player:
			target_player = get_parent()
		else:
			return

	is_active = true
	current_cooldown = cooldown
	active_time = max_active_time
	
	PlayerStats.damage_multiplier.add_modifier(damage_modifier)

	# Shader
	var screen_effects = target_player.get_node_or_null("../ScreenEffects")
	if screen_effects and screen_effects.has_method("enable_berserk"):
		print("Shader zoomies activated")
		screen_effects.enable_berserk()
		
	# Audio
	$zoomie_sfx.play()

func deactivate() -> void:
	if not is_active:
		return
	is_active = false
	if damage_modifier:
		PlayerStats.damage_multiplier.remove_modifier(damage_modifier)
	# Shader
	if target_player:
		var screen_effects = target_player.get_node_or_null("../ScreenEffects")
		if screen_effects and screen_effects.has_method("disable_berserk"):
			screen_effects.disable_berserk()
	# Audio
	$zoomie_sfx.stop()

func _exit_tree() -> void:
	if is_active:
		deactivate()
