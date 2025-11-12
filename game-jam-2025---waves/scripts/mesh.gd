# adapted from How to make things float in Godot 4: https://www.youtube.com/watch?v=_R2KDcAp1YQ&t=200s
extends RigidBody3D

@export var float_force := 1.5
@export var water_drag := 0.05
@export var water_angular_drag := 0.05
@export var use_probes := false

#movement settings
@export var moveSpeed := 20.0
@export var boostMod := 3.0
@export var turnSpeed := 0.03


@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water_path : NodePath = "../Water"

var water: MeshInstance3D
var probes: Array[Node] = []
var submerged := false

func _ready():
	water = get_node(water_path)
	
	if not water:
		push_error("Water node not found at path: " + str(water_path))
		return
	
	# Find probe points if using multi-point buoyancy
	if use_probes:
		var probe_container = get_node_or_null("ProbeContainer")
		if probe_container:
			probes = probe_container.get_children()
			print("Found ", probes.size(), " probes for ", name)
		else:
			push_warning("use_probes enabled but no ProbeContainer found. Add Node3D children under a 'ProbeContainer' node.")
			use_probes = false
	pass

func _physics_process(delta):
	
	#movement options:
	if Input.is_action_pressed("forward"):
		apply_central_force(transform.basis.z * moveSpeed)
	if Input.is_action_pressed("backward"):
		apply_central_force(-transform.basis.z * moveSpeed)

	if Input.is_action_pressed("left"):
		apply_torque_impulse(transform.basis.y * turnSpeed)
	if Input.is_action_pressed("right"):
		apply_torque_impulse(transform.basis.y * -turnSpeed)
		
	if Input.is_action_pressed("boost"):
		apply_central_force(transform.basis.z * moveSpeed * boostMod)
		
		
	#tricks
	if Input.is_action_pressed("uarrow"):
		add_constant_torque(transform.basis.x * turnSpeed * boostMod)
	if Input.is_action_pressed("darrow"):
		add_constant_torque(-transform.basis.x * turnSpeed * boostMod)
	if Input.is_action_pressed("rarrow"):
		add_constant_torque(transform.basis.z * turnSpeed * boostMod)
	if Input.is_action_pressed("larrow"):
		add_constant_torque(-transform.basis.z * turnSpeed * boostMod)

		
	submerged = false
	
	if use_probes and probes.size() > 0:
		# Multi-point buoyancy - creates realistic tilting
		for p in probes:
			var depth = water.get_height(p.global_position) - p.global_position.y
			if depth > 0:
				submerged = true
				# Apply force at the probe position (creates torque)
				var force = Vector3.UP * float_force * gravity * depth
				var position = p.global_position - global_position
				apply_force(force, position)
	else:
		var body_height = global_transform.origin.y
		var water_height = water.get_height(global_transform.origin)
		var depth = water_height - body_height
		
		if depth > 0:
			submerged = true
			apply_force(Vector3.UP * float_force * gravity * depth)

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if submerged:
		state.linear_velocity *= 1.0 - water_drag
		state.angular_velocity *= 1.0 - water_angular_drag
