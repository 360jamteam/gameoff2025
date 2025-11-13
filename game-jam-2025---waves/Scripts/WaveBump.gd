extends Node3D
# This script controls a single wave bump.
# The bump moves forward, rises up, then sinks back down and deletes itself.

@export var speed: float = 4.0          # How fast the wave moves forward
@export var rise_height: float = 1.2    # How tall the bump gets at its peak
@export var lifetime: float = 2.5       # How long the bump lasts before disappearing

var _dir: Vector3 = -Vector3.FORWARD     # Direction the bump travels (set by spawner)
var _water_y: float = 0.0                # Water height at the moment of spawning
var _timer: float = 0.0                  # Tracks how long this bump has been alive

# Called by the spawner whenever a new bump is created.
func activate(origin: Transform3D, dir: Vector3, water_y: float) -> void:
	# Starting position and direction for this bump
	global_transform = origin
	_dir = dir.normalized()
	_water_y = water_y

	# Reset its timer so animation starts from zero
	_timer = 0.0
	visible = true

func _process(delta: float) -> void:
	if !visible:
		return

	# Count how long the bump has existed
	_timer += delta

	# Move the bump forward in the direction it was given
	global_position += _dir * speed * delta

	# Make the bump rise and fall in a smooth arc.
	# k goes from 0 → 1 during its lifetime.
	var k: float = clamp(_timer / max(lifetime, 0.001), 0.0, 1.0)

	# This creates a simple arch shape: rises in the middle and drops back down.
	var h: float = rise_height * (4.0 * k * (1.0 - k))
	global_position.y = _water_y + h

	# Once its lifetime is over, remove it completely.
	if _timer >= lifetime:
		queue_free()
