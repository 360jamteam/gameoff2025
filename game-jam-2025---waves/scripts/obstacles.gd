extends MeshInstance3D

@export var move_distance: float = 15.0     # how far left-right it moves
@export var move_speed: float = 3.0         # speed of oscillation
@export var axis: Vector3 = Vector3.RIGHT   # movement axis (local)

var t := 0.0

func _process(delta: float) -> void:
	t += delta * move_speed
	# Ping-pong motion
	var offset = axis * (sin(t) * move_distance)
	global_transform.origin = base_position + offset

var base_position: Vector3

func set_start_position(pos: Vector3, basis: Basis) -> void:
	base_position = pos
	# Movement axis should be perpendicular to track
	axis = basis.x # local X axis (track left-right)
