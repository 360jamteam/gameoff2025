extends Node3D
# Visual “ring” effect that appears on the water when you trigger a wave.
# It scales up over time and fades out, then deletes itself.

@export var lifetime: float = 0.7        # Total time (seconds) before the ripple disappears.
@export var max_scale: float = 4.0       # Final scale of the ripple at the end of its life.

var age: float = 0.0                     # How long this ripple has been alive.

func _ready() -> void:
	# Start age at zero when the ripple is spawned.
	age = 0.0

func _process(delta: float) -> void:
	# Increase age every frame.
	age += delta

	# Normalized time t goes from 0 → 1 over the ripple's lifetime.
	var t: float = clamp(age / lifetime, 0.0, 1.0)

	# When t reaches 1, the ripple is done – remove the node from the scene.
	if t >= 1.0:
		queue_free()
		return

	# Smoothly scale the ring from scale 1.0 up to max_scale over time.
	var s: float = lerp(1.0, max_scale, t)
	scale = Vector3.ONE * s

	# Fade out the ring's material alpha so it becomes more transparent over time.
	var ring: MeshInstance3D = $RingMesh
	var mat: StandardMaterial3D = ring.get_active_material(0) as StandardMaterial3D
	if mat:
		var c: Color = mat.albedo_color
		# Alpha goes from 1.0 → 0.0 as t goes from 0 → 1.
		c.a = 1.0 - t
		mat.albedo_color = c
