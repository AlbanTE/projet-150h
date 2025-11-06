# res://projectiles/Tomate.gd
extends Projectile
class_name Tomate

# VARIABLES AOE
@export var max_arc_height: float = 150.0
@export var min_arc_height: float = 30.0
@export var landing_area_scale: float = 5.0 # Taille de la zone AOE - modifier avec composant stats
@export var damage_interval: float = 0.5 # Ticks

var start_position: Vector2
var target_position: Vector2
var travel_time: float = 0.8
var current_time: float = 0.0
var is_flying: bool = true
var actual_arc_height: float = 150.0 

func _ready():
	collision_layer = 16
	collision_mask = 0  # Pas de collision du projectile (AOE)
	start_position = global_position
	
	setup_stats()
	damage_interval /= PlayerStats.attack_speed

func setup(target_pos: Vector2):
	target_position = target_pos
	start_position = global_position
		
	# Avoir un joli arc de cercle
	var distance = start_position.distance_to(target_position)
	var distance_ratio = clamp(distance / 500.0, 0.0, 1.0)
	actual_arc_height = lerp(min_arc_height, max_arc_height, distance_ratio)
	
	# Avoir un travel time min si close target
	travel_time = max(0.3, distance / speed)

func _physics_process(delta):
	if is_flying:
		_handle_flight(delta)

# Ouais ca jsp mais ca rend plutot ok 
func _handle_flight(delta):
	current_time += delta
	var progress = clamp(current_time / travel_time, 0.0, 1.0)
	
	var linear_pos = start_position.lerp(target_position, progress)
	var arc_offset = sin(progress * PI) * actual_arc_height
	global_position = linear_pos + Vector2(0, -arc_offset)
	
	if progress < 1.0:
		var next_progress = clamp((current_time + delta) / travel_time, 0.0, 1.0)
		var next_pos = start_position.lerp(target_position, next_progress) + Vector2(0, -sin(next_progress * PI) * actual_arc_height)
		var direction = (next_pos - global_position).normalized()
		rotation = direction.angle()
	
	if progress >= 1.0:
		_land()

# Ici on passe à la zone AOE 
func _land():
	is_flying = false
	global_position = target_position
	
	rotation = (target_position-start_position).angle()
	
	add_to_group("aoe")
	collision_mask = 8  # On active les collisions avec les hurtbox - a voir avec les murs ???
	
	# TEXTURE 
	if has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		sprite.modulate = Color(1.0, 0.3, 0.3, 0.4)
		
	self.scale *= Vector2(landing_area_scale, landing_area_scale)
	
	# Forcer un monitoring_enabled pour détecter les overlaps
	monitoring = true
	monitorable = true
	
	# Forcer un update de la physique pour que get_overlapping_areas() fonctionne
	await get_tree().physics_frame
	
	# Déclencher area_entered pour toutes les entités déjà présentes
	for area in get_overlapping_areas():
		if area is HurtboxComponent:
			area._on_area_entered(self)
	
	# AUTO DESTRUCTION (DURATION)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	set_physics_process(false) 
