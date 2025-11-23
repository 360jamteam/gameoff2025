<<<<<<< Updated upstream
<<<<<<< Updated upstream
extends MeshInstance3D

@export var move_distance: float = 15.0     # how far left-right it moves
@export var move_speed: float = 3.0         # speed of oscillation
@export var axis: Vector3 = Vector3.RIGHT   # movement axis (local)

var t := 0.0
=======
extends StaticBody3D

=======
extends StaticBody3D

>>>>>>> Stashed changes
@export var move_distance_local: float = 130.0    # desired side-to-side movement
@export var base_move_speed: float = 1.0          # average swing speed
@export var margin_from_wall: float = 2.0        # how far to stay away from walls
@export var base_spin_speed_deg: float = 90.0     # average rotation speed (deg/sec)

@export var jump_height: float = 40.0             # how high the squid jumps
@export var jump_duration: float = 0.8            # time for a full jump up+down (seconds)
@export var jump_chance: float = 0.5              # chance to jump when a window happens
@export var jump_interval_min: float = 2.0        # shortest time between jump checks
@export var jump_interval_max: float = 5.0        # longest time between jump checks

var base_position: Vector3
var lateral_axis: Vector3
var max_distance: float = 0.0

var t: float = 0.0
var phase_offset: float = 0.0
var move_speed_actual: float = 0.0
var spin_speed_actual: float = 0.0
var direction: float = 1.0

# Jump state
var jump_timer: float = 0.0
var next_jump_time: float = 0.0
var is_jumping: bool = false
var jump_t: float = 0.0
var vertical_offset: float = 0.0

var rng := RandomNumberGenerator.new()

func setup(start_pos: Vector3, right_dir: Vector3, track_half_width: float) -> void:
	base_position = start_pos
	lateral_axis = right_dir.normalized()

	max_distance = min(move_distance_local, max(0.0, track_half_width - margin_from_wall))
>>>>>>> Stashed changes

	rng.randomize()
	phase_offset = rng.randf_range(0.0, PI * 2.0)

	var speed_factor: float = rng.randf_range(0.7, 1.3)
	move_speed_actual = base_move_speed * speed_factor
	spin_speed_actual = base_spin_speed_deg * speed_factor
	direction = 1.0 if rng.randi_range(0, 1) == 0 else -1.0

	jump_timer = 0.0
	next_jump_time = rng.randf_range(jump_interval_min, jump_interval_max)
	is_jumping = false
	jump_t = 0.0
	vertical_offset = 0.0
	global_position = base_position


	rng.randomize()
	phase_offset = rng.randf_range(0.0, PI * 2.0)

	var speed_factor: float = rng.randf_range(0.7, 1.3)
	move_speed_actual = base_move_speed * speed_factor
	spin_speed_actual = base_spin_speed_deg * speed_factor
	direction = 1.0 if rng.randi_range(0, 1) == 0 else -1.0

	jump_timer = 0.0
	next_jump_time = rng.randf_range(jump_interval_min, jump_interval_max)
	is_jumping = false
	jump_t = 0.0
	vertical_offset = 0.0
	global_position = base_position


func _process(delta: float) -> void:
<<<<<<< Updated upstream
	t += delta * move_speed
	# Ping-pong motion
	var offset = axis * (sin(t) * move_distance)
	global_transform.origin = base_position + offset

var base_position: Vector3

func set_start_position(pos: Vector3, basis: Basis) -> void:
	base_position = pos
	# Movement axis should be perpendicular to track
	axis = basis.x # local X axis (track left-right)
=======
	if lateral_axis == Vector3.ZERO:
		return
	t += delta * move_speed_actual
	_update_jump(delta)

	var offset_val: float = sin(t + phase_offset) * max_distance * direction
	var pos: Vector3 = base_position + lateral_axis * offset_val
	pos.y += vertical_offset
	global_position = pos

	rotate_y(deg_to_rad(spin_speed_actual * delta * direction))

func _update_jump(delta: float) -> void:
	if not is_jumping:
		jump_timer += delta
		if jump_timer >= next_jump_time:
			if rng.randf() <= jump_chance:
				is_jumping = true
				jump_t = 0.0
			jump_timer = 0.0
			next_jump_time = rng.randf_range(jump_interval_min, jump_interval_max)
	else:
		jump_t += delta
		var phase: float = jump_t / jump_duration
		if phase >= 1.0:
			is_jumping = false
			vertical_offset = 0.0
		else:
			vertical_offset = sin(phase * PI) * jump_height
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
