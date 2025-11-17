extends Node3D

@export var move_distance_local: float = 10.0  # desired side-to-side movement
@export var move_speed: float = 2.0            # how fast it swings
@export var margin_from_wall: float = 2.0      # how far to stay away from walls

var base_position: Vector3        # center point on the track
var lateral_axis: Vector3         # direction from center toward wall (right/left along track)
var max_distance: float = 0.0     # actual allowed distance (clamped by track width)
var t: float = 0.0

func setup(start_pos: Vector3, right_dir: Vector3, track_half_width: float) -> void:
	base_position = start_pos
	lateral_axis = right_dir.normalized()

	# don't go outside walls: keep within track_half_width - margin
	max_distance = min(move_distance_local, max(0.0, track_half_width - margin_from_wall))

func _process(delta: float) -> void:
	if lateral_axis == Vector3.ZERO:
		return

	t += delta * move_speed
	var offset = sin(t) * max_distance
	global_position = base_position + lateral_axis * offset
