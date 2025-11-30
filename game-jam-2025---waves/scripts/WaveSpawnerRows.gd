# Very simple row-based wave spawner for Nicole's water.gd
# It only calls water.add_wave_at_world_position(...) on a timer.

extends Node3D

@export var boat: NodePath
@export var water: NodePath
@export var ripple_scene: PackedScene   # WaveRipple.tscn

@export var row_interval: float = 3.0
@export var bumps_per_row: int = 8
@export var spacing: float = 2.0
@export var ahead_dist: float = 8.0
@export var start_delay: float = 3.0
@export var min_speed_for_waves: float = 3.0

var _delay_time := 0.0
var _waves_started := false
var _timer := 0.0

var _boat_ref: Node3D
var _water_ref: Node3D
var _last_boat_pos: Vector3 = Vector3.ZERO
var _last_forward_speed: float = 0.0

var _elapsed_time := 0.0              # NEW: our own clock
var _last_ripple_time := -999.0       # NEW: when we last spawned a ripple
const RIPPLE_COOLDOWN := 0.25         # seconds – tweak if needed

func _ready() -> void:
	_boat_ref = get_node_or_null(boat) as Node3D
	_water_ref = get_node_or_null(water) as Node3D

	if _boat_ref == null:
		push_warning("WaveSpawnerRows: boat is not assigned.")
	else:
		print("WaveSpawnerRows: boat =", _boat_ref)

	if _water_ref == null:
		push_warning("WaveSpawnerRows: water is not assigned.")
	else:
		print("WaveSpawnerRows: water =", _water_ref)


func _process(delta: float) -> void:
	if _boat_ref == null or _water_ref == null:
		return

	_elapsed_time += delta   # keep our clock running

	# 1) Handle initial delay
	if !_waves_started:
		_delay_time += delta
		if _delay_time < start_delay:
			return
		_waves_started = true
		_timer = 0.0

	# 2) Measure overall speed + forward speed
	var speed := 0.0
	var forward_speed := 0.0
	if delta > 0.0:
		var current_pos := _boat_ref.global_transform.origin
		var move_vec := current_pos - _last_boat_pos
		_last_boat_pos = current_pos

		speed = move_vec.length() / delta

		var boat_forward: Vector3 = _boat_ref.global_transform.basis.z.normalized()
		forward_speed = move_vec.dot(boat_forward) / delta
		_last_forward_speed = forward_speed

	# Only spawn waves at all if we're moving at least this fast
	if speed < min_speed_for_waves:
		return

	# 3) Timer for rows
	_timer += delta
	if _timer >= row_interval:
		_timer = 0.0
		_spawn_row()


func _spawn_row() -> void:
	if _boat_ref == null or _water_ref == null:
		return

	print("WaveSpawner: spawning a row of waves")

	var basis := _boat_ref.global_transform.basis
	var boat_forward: Vector3 = basis.z.normalized()
	var right: Vector3 = basis.x

	var center := _boat_ref.global_transform.origin + boat_forward * ahead_dist
	var half := (bumps_per_row - 1) * 0.5

	# 1) Shader waves along the row
	for i in range(bumps_per_row):
		var t := float(i) - half
		var pos := center + right * (t * spacing)

		if _water_ref.has_method("add_wave_at_world_position"):
			_water_ref.call("add_wave_at_world_position", pos)

	# 2) ONE mesh ring for this row, with a small cooldown so it can’t double-spawn
	if ripple_scene \
		and _last_forward_speed > 0.1 \
		and _elapsed_time - _last_ripple_time > RIPPLE_COOLDOWN:
		
		var ripple := ripple_scene.instantiate()

		var parent := _water_ref.get_parent()
		if parent:
			parent.add_child(ripple)
		else:
			add_child(ripple)

		ripple.global_transform.origin = center
		_last_ripple_time = _elapsed_time
