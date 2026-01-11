extends Area2D
class_name SkeletonArrow

@export var speed: float = 50
@export var damage: float = 20
@export var lifetime: float = 1
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta):
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage)
	queue_free()
