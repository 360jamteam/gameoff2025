# Adapted from "How to Make a Wave Spawner in Godot 4"
# Source: https://www.youtube.com/watch?v=MKsr119jyzs

extends Node3D

# --- Scene references ---
@export var wave_scene: PackedScene                       # your wave_pulse.tscn
@export var boat: NodePath                                # drag the boat node
@export var water_node: NodePath                          # drag the water node
@export var intro_player: NodePath                        # drag the AnimationPlayer (optional)
@export var intro_animation: StringName = &"Intro"        # name of the intro animation

# --- Timing ---
@export var row_interval: float = 2.2                     # seconds between wave rows
@export var pool_size: int = 64                           # total pooled wave pulses

# --- Row shape settings ---
@export var pulses_per_row: int = 9                       # how many waves across
@export var pulse_spacing: float = 1.6                    # space between waves
@export var row_start_offset: float = 8.0                 # distance in front of boat
@export var jitter: float = 0.25                          # random offset for natural look
@export var small_wave_scale: float = 2.2                 # size of each wave pulse

# === global scatter settings ===
@export var scatter_mode: bool = false
@export var area_x: float = 40.0
@export var area_z: float = 40.0
@export var waves_per_second: float = 6.0
@export var random_scale_range: Vector2 = Vector2(2.0, 3.2)

var _scatter_timer: float = 0.0

# --- Internal state ---
var _pool: Array[Node3D] = []
var _free: Array[Node3D] = []
var _tick: float = 0.0
var _running: bool = false

# --- Lifecycle ---
func _ready() -> void:
	_init_pool()
	# if intro_player != NodePath():
	#	var ap := get_node_or_null(intro_player) as AnimationPlayer
	#	if ap:
	#		ap.animation_finished.connect(_on_intro_finished)
	#		return
	# fallback: start immediately if no AnimationPlayer set
	start_spawning()
	_spawn_row()

func _process(delta: float) -> void:
	if !_running:
		return

	_tick += delta
	if _tick >= row_interval:
		_tick = 0.0
		_spawn_row()
	
	if scatter_mode:
		_scatter_timer += delta * waves_per_second
		while _scatter_timer >= 1.0:
			_scatter_timer -= 1.0
			_spawn_scatter()

func _spawn_scatter() -> void:
	if _free.is_empty(): return
	var water := get_node_or_null(water_node) as Node3D
	if water == null: return

	var center := water.global_transform.origin
	var y := center.y + 0.03
	var x := randf_range(-area_x * 0.5, area_x * 0.5)
	var z := randf_range(-area_z * 0.5, area_z * 0.5)

	var xf := Transform3D.IDENTITY
	xf.origin = Vector3(center.x + x, y, center.z + z)

	var p := _free.pop_back() as Node3D
	if p.has_method("set_end_scale"):
		var scale := randf_range(random_scale_range.x, random_scale_range.y)
		p.call("set_end_scale", scale)
	p.call("activate", xf)


# --- Start after intro ---
func start_spawning() -> void:
	_running = true

func _on_intro_finished(anim: StringName) -> void:
	if anim == intro_animation:
		start_spawning()

# --- Row spawning logic ---
func _spawn_row() -> void:
	if _free.is_empty():
		return

	var boat_node := get_node_or_null(boat) as Node3D
	var water := get_node_or_null(water_node) as Node3D
	if boat_node == null:
		return

	var water_y := water.global_transform.origin.y if water else global_transform.origin.y

	# Boat’s direction
	var basis := boat_node.global_transform.basis
	var fwd := -basis.z.normalized()
	var right := basis.x.normalized()

	# Row position (ahead of boat)
	var row_center := boat_node.global_transform.origin + fwd * row_start_offset
	row_center.y = water_y + 0.02

	var half := (pulses_per_row - 1) * 0.5
	for i in pulses_per_row:
		if _free.is_empty():
			break
		var t := float(i) - half
		var pos := row_center + right * (t * pulse_spacing)
		pos.x += randf_range(-jitter, jitter)
		pos.z += randf_range(-jitter, jitter)

		var xf := Transform3D.IDENTITY
		xf.origin = pos

		var p := _free.pop_back() as Node3D
		if p.has_method("set_end_scale"):
			p.call("set_end_scale", small_wave_scale)
		if p.has_method("activate"):
			p.call("activate", xf)
		else:
			p.global_transform = xf
			p.visible = true

# --- Pool handling ---
func _return_pulse(p: Node3D) -> void:
	if is_instance_valid(p):
		p.visible = false
		_free.append(p)

func _init_pool() -> void:
	_pool.clear()
	_free.clear()
	if wave_scene == null:
		push_error("WaveSpawner: wave_scene not assigned")
		return
	for i in pool_size:
		var n := wave_scene.instantiate() as Node3D
		add_child(n, true)
		n.visible = false
		if n.has_method("setup_return"):
			n.call("setup_return", Callable(self, "_return_pulse"))
		_pool.append(n)
		_free.append(n)
