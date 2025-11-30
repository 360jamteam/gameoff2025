extends Node3D

@onready var _mesh: MeshInstance3D = $RingMesh

@export var duration: float = 0.8      # seconds before it disappears
@export var start_scale: float = 0.5   # starting size
@export var end_scale: float = 4.0     # final size

var _time := 0.0

func _ready() -> void:
	_mesh = get_node("RingMesh")
	scale = Vector3.ONE * start_scale

func _process(delta: float) -> void:
	_time += delta
	var t := _time / duration

	if t >= 1.0:
		queue_free()
		return

	# scale outward
	var s: float = lerp(start_scale, end_scale, t)
	scale = Vector3.ONE * s

	# fade out alpha
	var mat := _mesh.get_surface_override_material(0)
	if mat == null:
		mat = _mesh.get_active_material(0)
	if mat is StandardMaterial3D:
		var c: Color = mat.albedo_color
		c.a = 1.0 - t
		mat.albedo_color = c
