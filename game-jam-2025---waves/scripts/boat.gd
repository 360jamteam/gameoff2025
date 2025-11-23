# adapted from How to make things float in Godot 4: https://www.youtube.com/watch?v=_R2KDcAp1YQ&t=200s
# MAKE BOAT ONLY BE ABLE TO MOVE WHEN TOUCHING WATER

extends RigidBody3D

<<<<<<< Updated upstream
@export var float_force := 1.5
=======
var ink_overlay: TextureRect
@export var float_force := 11.5
>>>>>>> Stashed changes
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


<<<<<<< Updated upstream
@export var jumpSpeed := 5.0
=======
# WRONG WAY settings
@export var track_path: NodePath
@export var wrong_way_speed_min := 5.0
@export var wrong_way_time_threshold := 0.5
@export var wave_hud_path: NodePath


var track: Path3D
var wrong_way_timer := 0.0
var wave_hud: CanvasLayer
>>>>>>> Stashed changes

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water_path : NodePath = "../Water/WaterMesh"
@onready var boat: RigidBody3D = get_node("../Boat") as RigidBody3D

var water: MeshInstance3D
var probes: Array[Node] = []
var submerged := false

func _ready():
	water = get_node(water_path)
	
	
	if not water:
		push_error("Water node not found at path: " + str(water_path))
		return
<<<<<<< Updated upstream
	pass

func _physics_process(delta):
=======
	
	# path the boat follows (for WRONG WAY logic)
	if track_path != NodePath():
		track = get_node_or_null(track_path) as Path3D
	
	# Wave HUD (handles WAVE / JUMP / BOOST messages + WRONG WAY label)
	if wave_hud_path != NodePath():
		wave_hud = get_node_or_null(wave_hud_path) as CanvasLayer
		if wave_hud:
			ink_overlay = wave_hud.get_node_or_null("InkOverlay") as TextureRect
			if ink_overlay:
				print("Ink overlay found in WaveHUD")
			else:
				print("ERROR: Ink overlay NOT found in WaveHUD")

	contact_monitor = true
	max_contacts_reported = 8

	# Boat collision setup
	collision_layer = 1          # boat layer
	collision_mask = 1 | 2       # detect boat (1) + squids (2)
	body_entered.connect(_on_body_entered)
	add_to_group("boat")
	
	print("Boat collision setup - Layer: ", collision_layer, " Mask: ", collision_mask)

func _on_body_entered(body: Node3D) -> void:
	print("Boat collided with: ", body.name)
	print("Body class: ", body.get_class())
	print("Is in squid group: ", body.is_in_group("squid"))
	
	if body.is_in_group("squid"):
		print("*** SQUID COLLISION DETECTED! ***")
		show_ink(3.0)

func _integrate_forces(state: PhysicsDirectBodyState3D):
	if submerged:
		state.linear_velocity *= 1.0 - water_drag
		state.angular_velocity *= 1.0 - water_angular_drag
>>>>>>> Stashed changes
	
	#movement options:
	if Input.is_action_pressed("forward"):
		apply_central_force(transform.basis.z * moveSpeed)
		print("Boat position: ", global_position)
		
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
	
	
<<<<<<< Updated upstream
=======
	var boatSpeed = linear_velocity.length()
	var waveMultiplier = clamp(boatSpeed / 100.0, 0.7, 5.0)
	apply_central_impulse(-transform.basis.z * waveForce * waveMultiplier * 2.0)
	apply_torque_impulse(transform.basis.y * waveTorque * waveMultiplier)

func show_ink(duration: float = 3.0) -> void:
	if ink_overlay == null:
		print("show_ink: ink_overlay is NULL")
		return

	print("show_ink: showing ink for ", duration, " seconds")
	ink_overlay.visible = true

	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_on_ink_timeout)
	add_child(timer)
	timer.start()

func _on_ink_timeout() -> void:
	if ink_overlay:
		ink_overlay.visible = false
	
	# Remove the timer
	for child in get_children():
		if child is Timer:
			child.queue_free()
>>>>>>> Stashed changes
