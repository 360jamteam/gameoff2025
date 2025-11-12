extends Node3D

@export var lifetime := 1.6
@export var start_scale := 0.6
@export var end_scale := 3.0
@export var start_height := 0.40
@export var end_height := 0.10

# use color/alpha via material (not modulate)
@export var start_color: Color = Color(0.50, 0.90, 1.00, 0.85)
@export var end_color:   Color = Color(0.50, 0.90, 1.00, 0.00)

@export var mesh_path: NodePath = ^"MeshInstance3D"

var _t := 0.0
var _active := false
var _mesh: MeshInstance3D
var _mat: Material                # the material we’ll edit
var _return_cb: Callable = Callable()

func _ready() -> void:
	_mesh = get_node_or_null(mesh_path)
	visible = false
	if _mesh:
		# Grab the active material; make it unique so edits are per-instance.
		_mat = _mesh.get_active_material(0)
		if _mat and !_mat.resource_local_to_scene:
			_mat = _mat.duplicate()
			_mesh.material_override = _mat

func setup_return(cb: Callable) -> void:
	_return_cb = cb

func set_end_scale(v: float) -> void:
	end_scale = v

func activate(xf: Transform3D) -> void:
	xf.origin.y += 0.03
	global_transform = xf
	_t = 0.0
	_active = true
	visible = true
	_apply_scale(start_scale, start_height)
	_set_color(0.0)  # start color

func _process(delta: float) -> void:
	if !_active: return
	_t += delta
	var k: float = clamp(_t / max(lifetime, 0.001), 0.0, 1.0)

	var w: float = lerp(start_scale,  end_scale,   k)
	var h: float = lerp(start_height, end_height,  k)
	_apply_scale(w, h)

	_set_color(k)

	if _t >= lifetime:
		_active = false
		visible = false
		if _return_cb.is_valid():
			_return_cb.call(self)

func _apply_scale(w: float, h: float) -> void:
	scale = Vector3(w, h, w)

# ====== NEW: set material color/alpha instead of mesh.modulate ======
func _set_color(k: float) -> void:
	var col: Color = start_color.lerp(end_color, k)
	if _mat is BaseMaterial3D:
		var bm := _mat as BaseMaterial3D
		bm.albedo_color = col
	elif _mat is ShaderMaterial:
		# If your material is a ShaderMaterial, expose a uniform like `tint`
		# and set it here. Change "tint" to your uniform name if different.
		(_mat as ShaderMaterial).set_shader_parameter("tint", col)
