# Adapted from "How to Make a Wave Spawner in Godot 4"
# This now only spawns waves when the boat is actually moving fast enough.

extends Node3D

@export var boat: NodePath                 # Reference to the boat
@export var water: NodePath                # Water node that handles wave height

@export var row_interval: float = 3.0      # Time between each row of waves
@export var bumps_per_row: int = 8.0       # How many wave bumps appear across the row
@export var spacing: float = 2.0           # Distance between each bump in the row
@export var ahead_dist: float = 8.0        # How far in front of the boat the row should spawn
@export var start_delay: float = 3.0       # How long to wait before waves start

@export var min_speed_for_waves: float = 3.0
# NEW: boat must be moving at least this fast (units/sec) to spawn waves

var _delay_time := 0.0
var _waves_started: bool = false
var _timer: float = 0.0

var _boat_ref: Node3D
var _water_ref: Node3D

var _last_boat_pos: Vector3 = Vector3.ZERO   # NEW: track previous position for speed

func _ready() -> void:
	_boat_ref = get_node_or_null(boat) as Node3D
	_water_ref = get_node_or_null(water) as Node3D

	if _boat_ref:
		_last_boat_pos = _boat_ref.global_transform.origin

func _process(delta: float) -> void:
	if _boat_ref == null or _water_ref == null:
		return

	# 1) Handle initial delay so the boat can settle
	if !_waves_started:
		_delay_time += delta
		if _delay_time < start_delay:
			return

		_waves_started = true
		_timer = 0.0

	# 2) Measure how fast the boat is moving in world space
	var speed := 0.0
	if delta > 0.0:
		var current_pos := _boat_ref.global_transform.origin
		speed = current_pos.distance_to(_last_boat_pos) / delta
		_last_boat_pos = current_pos

	# If the boat is basically not moving, don't spawn a row this frame
	if speed < min_speed_for_waves:
		return

	# 3) Count toward the next row only when we're actually moving
	_timer += delta
	if _timer >= row_interval:
		_timer = 0.0
		_spawn_row()

func _spawn_row() -> void:
	if _boat_ref == null or _water_ref == null:
		return
		
	print("WaveSpawner: spawning a row of waves")  # DEBUG

	var basis := _boat_ref.global_transform.basis
	var boat_forward: Vector3 = basis.z.normalized()
	var right: Vector3 = basis.x

	var center := _boat_ref.global_transform.origin + boat_forward * ahead_dist
	var half := (bumps_per_row - 1) * 0.5

	for i in range(bumps_per_row):
		var t := float(i) - half
		var pos := center + right * (t * spacing)

		if _water_ref.has_method("add_wave_at_world_position"):
			_water_ref.call("add_wave_at_world_position", pos)
