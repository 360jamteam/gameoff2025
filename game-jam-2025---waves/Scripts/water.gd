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

func _ready():
	material = mesh.surface_get_material(0)
	wave_size = material.get_shader_parameter("wave_size")
	wave_speed = material.get_shader_parameter("wave_speed")
	height = material.get_shader_parameter("height")

func _process(delta):
	# keep this in sync w shader
	time += delta

func get_height(world_position: Vector3) -> float:
	# use mesh aabb to determine uvs
	var aabb = mesh.get_aabb()
	var mesh_size = aabb.size
	
	var local_pos = to_local(world_position)
	
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
	
	# return wave height at this pos
	return global_position.y + dist_y * height
