# Adapted from "How to Make a Wave Spawner in Godot 4"
# Source: https://www.youtube.com/watch?v=MKsr119jyzs

extends Node3D
# This script spawns a whole row of wave bumps in front of the boat.
# A new row appears every few seconds, creating a line of waves for the player to hit/jump over.

@export var bump_scene: PackedScene        # The wave bump scene we want to spawn
@export var boat: NodePath                 # Reference to the boat so we know where “forward” is
@export var water: NodePath                # Water node to match the correct Y height

@export var row_interval: float = 2.0      # Time between each row of waves
@export var bumps_per_row: int = 11        # How many wave bumps appear across the row
@export var spacing: float = 1.0           # Distance between each bump in the row
@export var ahead_dist: float = 8.0        # How far in front of the boat the row should spawn
@export var bump_speed: float = 4.0        # Forward speed that each bump uses
@export var start_margin: float = 2.0      # (Not used now, but kept for future logic)
@export var start_delay: float = 3.0       # How long to wait before the first wave appears

var _delay_time := 0.0                     # Timer for waiting before waves start
var _waves_started: bool = false           # True once spawning begins
var _timer: float = 0.0                    # Timer between rows

func _process(delta: float) -> void:
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
	if bump_scene == null:
		return

	var boat_node := get_node_or_null(boat) as Node3D
	var water_node := get_node_or_null(water) as Node3D
	if boat_node == null or water_node == null:
		return

	# Determine the boat's forward direction (used to push waves toward the boat)
	var basis := boat_node.global_transform.basis
	var fwd: Vector3 = -basis.z.normalized()
	var right: Vector3 = basis.x.normalized()

	# Match the bumps to the water height
	var y := water_node.global_transform.origin.y

	# Starting point of the whole row
	var center := boat_node.global_transform.origin + fwd * ahead_dist
	center.y = y + 0.02   # Slightly above water so bumps don’t clip

	# Spread bumps left/right around the center
	var half := (bumps_per_row - 1) * 0.5

	for i in bumps_per_row:
		var t := float(i) - half
		var pos := center + right * (t * spacing)

		var xf := Transform3D.IDENTITY
		xf.origin = pos

		# Spawn a bump and activate it
		var bump := bump_scene.instantiate() as Node3D
		add_child(bump)

		# Give it position, direction, and water height
		bump.call("activate", xf, fwd, y)

		# Pass speed through directly so it matches spawner settings
		bump.set("speed", bump_speed)
