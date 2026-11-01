extends Node3D
## Continuously rotates and gently bobs a decorative node.

@export var degrees_per_second: Vector3 = Vector3(0.0, 30.0, 0.0)
@export var bob_height: float = 0.0
@export var bob_speed: float = 1.0

var _base_y: float
var _time: float = 0.0


func _ready() -> void:
	_base_y = position.y


func _process(delta: float) -> void:
	_time += delta
	rotation_degrees += degrees_per_second * delta
	if bob_height > 0.0:
		position.y = _base_y + sin(_time * bob_speed) * bob_height
