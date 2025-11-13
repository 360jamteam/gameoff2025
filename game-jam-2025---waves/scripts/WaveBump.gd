extends Node3D
# This script controls a single wave bump.
# The bump moves forward, rises up, then sinks back down and deletes itself.

@export var speed: float = 4.0          # How fast the wave moves forward
@export var rise_height: float = 1.2    # How tall the bump gets at its peak
@export var lifetime: float = 2.5       # How long the bump lasts before disappearing

var _dir: Vector3 = Vector3.FORWARD     # Direction the bump travels (set by spawner)
var _water_y: float = 0.0               # Water height at the moment of spawning
var _time: float = 0.0                  # Tracks how long this bump has been alive

# Called by the spawner whenever a new bump is created.
func activate(xform: Transform3D, dir: Vector3, water_y: float) -> void:
	# Starting position and direction for this bump
	global_transform = xform
	_dir = dir.normalized()
	_water_y = water_y
	_time = 0.0
	visible = true

func _physics_process(delta: float) -> void:
	if !visible:
		return
	_time += delta

	# Kill the bump when its time is over
	if _time >= lifetime:
		queue_free()
		return

	# Move the bump forward in the direction it was given (world space)
	global_translate(_dir * speed * delta)

	# Make the bump rise and fall in a smooth arc.
	var k: float = clamp(_time / max(lifetime, 0.001), 0.0, 1.0)
	var h: float = rise_height * (4.0 * k * (1.0 - k))

	var p := global_transform.origin
	p.y = _water_y + h
	global_transform.origin = p
