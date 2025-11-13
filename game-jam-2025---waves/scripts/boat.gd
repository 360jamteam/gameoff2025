# adapted from How to make things float in Godot 4: https://www.youtube.com/watch?v=_R2KDcAp1YQ&t=200s
# MAKE BOAT ONLY BE ABLE TO MOVE WHEN TOUCHING WATER

extends RigidBody3D

@export var float_force := 1.5
@export var water_drag := 0.05
@export var water_angular_drag := 0.05

#movement settings
@export var moveSpeed := 100.0
@export var boostMod := 3.0
@export var turnSpeed := 0.03
@export var recoverSpeed := 2.0  

#trick settings
var totalScore = 0.0
var touchingWater = true
var trickAngles = [180, 360, 720, 1080]


@export var jumpSpeed := 5.0

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water_path : NodePath = "../Water/WaterMesh"


var water: MeshInstance3D
var probes: Array[Node] = []
var submerged := false

func _ready():
	water = get_node(water_path)
	
	if not water:
		push_error("Water node not found at path: " + str(water_path))
		return
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
		
	if Input.is_action_pressed("jump"):
		if submerged:
			apply_central_impulse(Vector3.UP * jumpSpeed)
		
	#tricks
	if Input.is_action_pressed("uarrow"):
		apply_torque_impulse(transform.basis.x * turnSpeed)
	if Input.is_action_pressed("darrow"):
		apply_torque_impulse(-transform.basis.x * turnSpeed)
	if Input.is_action_pressed("rarrow"):
		apply_torque_impulse(transform.basis.z * -turnSpeed)
	if Input.is_action_pressed("larrow"):
		apply_torque_impulse(transform.basis.z * turnSpeed)
		
	#when not doing tricks, 
	if not (Input.is_action_pressed("uarrow") or Input.is_action_pressed("darrow") or Input.is_action_pressed("larrow") or Input.is_action_pressed("rarrow")):
		recoverBoat(delta)

	submerged = false
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

func recoverBoat(delta):
	var boat = get_node("../Boat")
	#get boats cureent basis
	var curBasis = boat.transform.basis
	#get current y rotation of boat
	var curRotationY = curBasis.get_euler().y
	#create target basis where boat upright, but still facing correct direction
	var targetBasis = Basis(Vector3.UP, curRotationY)
	#interpolate from current to upright
	boat.transform.basis = curBasis.slerp(targetBasis, recoverSpeed * delta)



func crazyAssTricks():
	var boat = get_node_or_null("../Boat")
	if touchingWater == false:
		var yes = 0
	#fill out later with when not touching water, track the angles rotated
	#maybe use an array of angles, [180, 360, 720, 1080], and more 
	#set flags when angle passses x amount
	#add scores based on tricks, with multiplier based on tricks within a timer that starts after landing first trick
	#then add to total score
	
	
