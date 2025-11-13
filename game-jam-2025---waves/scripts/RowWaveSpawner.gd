# Adapted from "How to Make a Wave Spawner in Godot 4"
# Source: https://www.youtube.com/watch?v=MKsr119jyzs

extends Node3D
# This script spawns a whole row of waves in front of the boat.
# Originally it spawned 3D bump scenes, but now it tells the water script
# to create wave bumps directly in the water height calculation.

@export var bump_scene: PackedScene        # (No longer used, but kept here in case we want visual bumps later)
@export var boat: NodePath                 # Reference to the boat so we know where “forward” is
@export var water: NodePath                # Water node that handles wave height

@export var row_interval: float = 2.0      # Time between each row of waves
@export var bumps_per_row: int = 11        # How many wave bumps appear across the row
@export var spacing: float = 1.0           # Distance between each bump in the row
@export var ahead_dist: float = 8.0        # How far in front of the boat the row should spawn
@export var bump_speed: float = 4.0        # Kept from old logic (not used now)
@export var start_margin: float = 2.0      # (Not used now, but kept for future logic)
@export var start_delay: float = 3.0       # How long to wait before the first wave appears

var _delay_time := 0.0                     # Timer for waiting before waves start
var _waves_started: bool = false           # True once spawning begins
var _timer: float = 0.0                    # Timer between rows

var _boat_ref: Node3D                      # Cached boat node
var _water_ref: Node3D                     # Cached water node (with water.gd)


func _ready() -> void:
	# Grab references once so we don't look them up every frame
	_boat_ref = get_node_or_null(boat) as Node3D
	_water_ref = get_node_or_null(water) as Node3D


func _process(delta: float) -> void:
	# Before doing anything, make sure we have boat + water
	if _boat_ref == null or _water_ref == null:
		return

	# Before doing anything, wait for the starting delay so the boat can settle on the water
	if !_waves_started:
		_delay_time += delta
		if _delay_time < start_delay:
			return  # Still waiting, don't spawn waves yet

		# Delay finished → now waves can start
		_waves_started = true
		_timer = 0.0

	# Once waves are active, count toward the next row
	_timer += delta
	if _timer >= row_interval:
		_timer = 0.0
		_spawn_row()


func _spawn_row() -> void:
	if _boat_ref == null or _water_ref == null:
		return

	# Determine the boat's forward direction (used to line up the row)
	var basis := _boat_ref.global_transform.basis
	var boat_forward: Vector3 = basis.z.normalized()
	var right: Vector3 = basis.x

	# This is the center point of the row, placed ahead of the boat
	var center := _boat_ref.global_transform.origin + boat_forward * ahead_dist

	var half := (bumps_per_row - 1) * 0.5

	# Spread bumps left/right around the center
	for i in range(bumps_per_row):
		var t := float(i) - half
		var pos := center + right * (t * spacing)

		# Instead of spawning 3D bump scenes, we now tell the water script
		# to create a wave bump in the water height math.
		# This keeps everything inside the water mesh, without adding nodes.
		if _water_ref.has_method("add_wave_at_world_position"):
			_water_ref.call("add_wave_at_world_position", pos)

		# (Old bump instancing removed here — we keep the comments clean and minimal)
