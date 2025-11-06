extends Area2D
class_name HurtboxComponent

## The Hurtbox detects bullet collisions and emits signals
## Optionally communicates with a HealthComponent to apply damage.

# ────────────────
# Exported
# ────────────────
@export var health_component: NodePath
var health: HealthComponent = null

# ────────────────
# Signals
# ────────────────
signal hit_by_bullet(bullet: Node, damage: int, knockback: float)

# ────────────────
# AOE tracker (par entité, il peut y avoir plusieurs overlaps de zone)
# ────────────────
# Clé : la zone - Valeur : info de tick { next_tick: float, interval: float }
var aoe_zones: Dictionary = {}  # zone -> { next_tick, interval }

# Timer pour vérifier les dégâts périodiques
var aoe_tick_timer: Timer = null
const AOE_CHECK_INTERVAL: float = 0.1  # Vérifie toutes les 0.1s 

# ────────────────
# Lifecycle
# ────────────────
func _ready() -> void:
	
	if health_component and has_node(health_component):
		health = get_node(health_component) as HealthComponent

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	# Créer un timer pour les checks AOE
	aoe_tick_timer = Timer.new()
	aoe_tick_timer.wait_time = AOE_CHECK_INTERVAL
	aoe_tick_timer.autostart = false
	aoe_tick_timer.timeout.connect(_on_aoe_tick)
	add_child(aoe_tick_timer)

# Tick périodique pour gérer les dégâts AOE
func _on_aoe_tick() -> void:
	
	# Scan
	_scan_overlapping_aoe_zones()
	
	if aoe_zones.is_empty():
		aoe_tick_timer.stop()
		return
	
	var now = Time.get_ticks_msec() / 1000.0
	var zones_to_remove = []
	
	for zone in aoe_zones.keys():
		# Vérifier si la zone existe encore
		if not is_instance_valid(zone) or not overlaps_area(zone):
			zones_to_remove.append(zone)
			continue
		
		var zone_data = aoe_zones[zone]
		
		# Appliquer les dégâts si le temps est écoulé
		if now >= zone_data.next_tick:
			var damage = zone.get_damage() if zone.has_method("get_damage") else 0
			if health and damage > 0:
				# print("AOE: ", damage)
				health.damage(damage)
			
			# Planifier le prochain tick
			zone_data.next_tick = now + zone_data.interval
	
	for zone in zones_to_remove:
		aoe_zones.erase(zone)


# ────────────────
# Collision handlers
# ────────────────
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullets"):  
		_handle_bullet_collision(area)
	elif area.is_in_group("aoe"):
		_register_aoe_zone(area)

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("aoe"):
		aoe_zones.erase(area)
		if aoe_zones.is_empty() and aoe_tick_timer:
			aoe_tick_timer.stop()

func _on_body_entered(_body: Node2D) -> void:
	pass

# ────────────────
# AOE Management
# ────────────────
# Scan actif de toutes les zones AOE en overlap (pour détecter les zones déjà présentes)
func _scan_overlapping_aoe_zones() -> void:
	for area in get_overlapping_areas():
		if area.is_in_group("aoe") and area not in aoe_zones:
			_register_aoe_zone(area)

func _register_aoe_zone(zone: Area2D) -> void:
	if zone in aoe_zones:
		return
	
	var now = Time.get_ticks_msec() / 1000.0
	var interval = zone.get("damage_interval") if "damage_interval" in zone else 0.5
	
	# Enregistrer la zone avec dégâts immédiats
	aoe_zones[zone] = {
		"next_tick": now,  # Dégâts immédiatement
		"interval": interval
	}
	
	# Démarrer le timer si pas déjà actif
	if aoe_tick_timer:
		if aoe_tick_timer.is_stopped():
			aoe_tick_timer.start()


# ────────────────
#  logic
# ────────────────
func _handle_bullet_collision(bullet: Node2D) -> void:
	if not bullet:
		return

	var damage := 0
	if "get_damage" in bullet:
		damage = bullet.get_damage()
	else:
		push_warning("Bullet does not have get_damage()")
		
	var knockback := 0
	if "get_knockback" in bullet:
		knockback = bullet.get_knockback()
	else:
		push_warning("Bullet does not have get_knockback()")

	print("HurtboxComponent: Bullet hit for ", damage, " damage, and ", knockback, " knockback")
	emit_signal("hit_by_bullet", bullet, damage, knockback)

	if health:
		health.damage(damage)
	else:
		print("HurtboxComponent: No health component found!")

	if bullet.has_method("delete_bullet"):
		bullet.delete_bullet()
