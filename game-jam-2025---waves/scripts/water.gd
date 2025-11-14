# adapted from How to make things float in Godot 4: https://www.youtube.com/watch?v=_R2KDcAp1YQ&t=200s
extends MeshInstance3D

var material: ShaderMaterial

# shader params
var wave_size: Vector2
var wave_speed: float
var height: float

var time: float = 0.0

const M_2PI = 6.283185307
const M_6PI = 18.84955592

const MAX_SPAWNED_WAVES := 32   # how many we send to the shader

# List of waves that are spawned. Each one stores where it happened and when.
var spawned_waves: Array = []  # each = { center = Vector2, time = float }

@export var spawned_wave_radius: float = 5.0        # how wide each bump is
@export var spawned_wave_height: float = 0.9        # how strong the bump is
@export var spawned_wave_lifetime: float = 5.0      # how long it lives (seconds)


func _ready():
	material = mesh.surface_get_material(0)
	wave_size = material.get_shader_parameter("wave_size")
	wave_speed = material.get_shader_parameter("wave_speed")
	height = material.get_shader_parameter("height")


func _process(delta):
	# keep this in sync with shader
	time += delta

	# keep only active waves (Dictionary access with ["time"])
	spawned_waves = spawned_waves.filter(
		func(w):
			return time - float(w["time"]) <= spawned_wave_lifetime
	)

	if material == null:
		return

	var count: int = min(spawned_waves.size(), MAX_SPAWNED_WAVES)

	var centers := PackedVector2Array()
	var times := PackedFloat32Array()

	for i in range(count):
		var w: Dictionary = spawned_waves[i]
		centers.append(w["center"])
		times.append(w["time"])

	# pad arrays so the shader always has a full set
	while centers.size() < MAX_SPAWNED_WAVES:
		centers.append(Vector2.ZERO)
		times.append(-9999.0)

	# send everything to the shader
	material.set_shader_parameter("water_time", time)
	material.set_shader_parameter("spawned_wave_count", count)
	material.set_shader_parameter("spawned_wave_centers", centers)
	material.set_shader_parameter("spawned_wave_times", times)
	material.set_shader_parameter("spawned_wave_radius", spawned_wave_radius)
	material.set_shader_parameter("spawned_wave_height", spawned_wave_height)
	material.set_shader_parameter("spawned_wave_lifetime", spawned_wave_lifetime)


# called by RowWaveSpawner instead of spawning a 3D bump
func add_wave_at_world_position(world_position: Vector3) -> void:
	# convert world pos into water's local space
	var local := to_local(world_position)
	var center_xz := Vector2(local.x, local.z)

	var data := {
		"center": center_xz,
		"time": time,
	}
	spawned_waves.append(data)
	print("spawned_waves:", spawned_waves.size())  # keep this for now as debug


func get_height(world_position: Vector3) -> float:
	# use mesh aabb to determine uvs
	var aabb = mesh.get_aabb()
	var mesh_size = aabb.size
	
	var local_pos := to_local(world_position)
	
	# calculate uv (0 to 1) based on position within the mesh 
	# offset by half the mesh size to center it
	var uv_x = (local_pos.x + mesh_size.x * 0.5) / mesh_size.x
	var uv_z = (local_pos.z + mesh_size.z * 0.5) / mesh_size.z
	
	# apply wave_size multiplier like shader does
	var uv = Vector2(uv_x, uv_z) * wave_size
	
	# calculate wave height using the same formula as shader
	var current_time = time * wave_speed
	
	var d1 = fmod(uv.x + uv.y, M_2PI)
	var d2 = fmod((uv.x + uv.y + 0.25) * 1.3, M_6PI)
	d1 = current_time * 0.07 + d1
	d2 = current_time * 0.5 + d2
	
	var dist_y = cos(d1) * 0.15 + cos(d2) * 0.05

	# use local XZ so this matches what we store in spawned_waves
	var local_xz := Vector2(local_pos.x, local_pos.z)

	for w in spawned_waves:
		var age: float = time - w.time
		if age < 0.0 or age > spawned_wave_lifetime:
			continue

		var center: Vector2 = w.center
		var dist := local_xz.distance_to(center)
		if dist > spawned_wave_radius:
			continue

		# spatial falloff: 1 at center -> 0 at radius
		var k := 1.0 - dist / spawned_wave_radius
		k *= k  # smoother curve

		# temporal pulse: 0 -> 1 -> 0 over its life
		var t_norm := age / spawned_wave_lifetime
		var pulse := sin(t_norm * PI)

		dist_y += k * pulse * spawned_wave_height
	
	# return wave height at this pos
	return global_position.y + dist_y * height
