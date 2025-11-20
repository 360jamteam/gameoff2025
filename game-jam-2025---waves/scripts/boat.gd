# buoyancy code adapted from How to make things float in Godot 4: https://www.youtube.com/watch?v=_R2KDcAp1YQ&t=200s
# 
# boat only accpts input for forward, backwards, boosts, and jump
# when submerged = true

extends RigidBody3D

@export var float_force := 11.5
@export var water_drag := 0.05
@export var water_angular_drag := 0.05

#movement settings
@export var moveSpeed := 1700.0
@export var boostMod := 2.0
@export var turnSpeed := 0.1
@export var recoverSpeed := 1200.0  
@export var jumpSpeed := 70.0

#trick settings
var totalScore := 0
var touchingWater := true
var lastRotation := Vector3.ZERO
var totalSpins := Vector3.ZERO
var spinThreshold := 360.0
var spinPoints := 100
@onready var scoreLabel: RichTextLabel = get_node_or_null("../CanvasLayer/ScoreLabel")

# wave effect settings
var inWave := false
var waveForce := 100.0
var waveTorque := 1.0

# WRONG WAY settings
@export var track_path: NodePath
@export var wrong_way_speed_min := 5.0        # don't warn if crawling
@export var wrong_way_time_threshold := 0.5   # seconds of going wrong way before showing text
@export var wave_hud_path: NodePath
var track: Path3D
var wrong_way_timer := 0.0
var wave_hud: CanvasLayer

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water_path : NodePath = "../Water/WaterMesh"

var water: MeshInstance3D
var submerged := false

func _ready():
	water = get_node(water_path)
	
	if not water:
		push_error("Water node not found at path: " + str(water_path))
		return
	
	# path the boat follows (for WRONG WAY logic)
	if track_path != NodePath():
		track = get_node_or_null(track_path) as Path3D
	
	# Wave HUD (handles WAVE / JUMP / BOOST messages + WRONG WAY label)
	if wave_hud_path != NodePath():
		wave_hud = get_node_or_null(wave_hud_path) as CanvasLayer
	
	#start tracking rotation for tricks
	lastRotation = transform.basis.get_euler()


func _integrate_forces(state: PhysicsDirectBodyState3D):
	if submerged:
		state.linear_velocity *= 1.0 - water_drag
		state.angular_velocity *= 1.0 - water_angular_drag
	
	#when not doing tricks
	if not (Input.is_action_pressed("uarrow") or Input.is_action_pressed("darrow") or Input.is_action_pressed("larrow") or Input.is_action_pressed("rarrow")):
		recoverBoat()
		#check if trick was landed
		checkTrickLanding()
	
	#track tricks
	crazyAssTricks()
	
	handleControls()
	makeItFloat()
	handleWaveCollision()
	
	# WRONG WAY detection (uses physics step delta + velocity)
	update_wrong_way(state.get_step(), state)


func handleControls():
	#movement options:
	if Input.is_action_pressed("left"):
		apply_torque_impulse(transform.basis.y * turnSpeed)
	if Input.is_action_pressed("right"):
		apply_torque_impulse(transform.basis.y * -turnSpeed)
	
	# --- HUD messages (these only fire on the first press) ---
	if Input.is_action_just_pressed("forward"):
		if wave_hud and wave_hud.has_method("show_wave_message"):
			wave_hud.call(
				"show_wave_message",
				"ACCELERATE (W)",
				Color(0.6, 1.0, 0.6)
			)

	if Input.is_action_just_pressed("jump"):
		if wave_hud and wave_hud.has_method("show_jump_message"):
			wave_hud.call(
				"show_jump_message",
				"JUMP (SPACE)",
				Color(1.0, 0.8, 0.4)
			)
	
	if Input.is_action_just_pressed("boost"):
		if wave_hud and wave_hud.has_method("show_boost_message"):
			wave_hud.call(
				"show_boost_message",
				"BOOST (SHIFT)",
				Color(0.6, 0.8, 1.0)
			)
	# --------------------------------------------------------

	if submerged:
		if Input.is_action_pressed("forward"):
			apply_central_force(transform.basis.z * moveSpeed)
			
		if Input.is_action_pressed("backward"):
			apply_central_force(-transform.basis.z * moveSpeed)
			
		if Input.is_action_pressed("boost"):
			apply_central_force(transform.basis.z * moveSpeed * boostMod)
			
		if Input.is_action_pressed("jump"):
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
	if Input.is_action_pressed("spin"):
		apply_torque_impulse(transform.basis.y * turnSpeed * 8.0)


func makeItFloat():
	submerged = false
	touchingWater = false
	var body_height = global_transform.origin.y
	var water_height = water.get_height(global_transform.origin)
	var depth = water_height - body_height
	
	if depth > 0:
		submerged = true
		apply_force(Vector3.UP * float_force * gravity * depth)
	
	if depth >= 0:
		touchingWater = true
	

func recoverBoat():
	#get up direction for boat
	var current_up = global_transform.basis.y
	#calc how much to rotate boat to get to actual up
	var correction_axis = current_up.cross(Vector3.UP)
	#apply torque to recover
	apply_torque(correction_axis * recoverSpeed)


func crazyAssTricks():
	#get current rotation in degrees
	var currentRotation = transform.basis.get_euler()
	#rotation delta
	var rotationDelta = currentRotation - lastRotation
	#handle  of over 180 degrees
	for i in range(3):
		if rotationDelta[i] > PI:
			rotationDelta[i] -= TAU
		elif rotationDelta[i] < -PI:
			rotationDelta[i] += TAU
	
	#add to total spins
	totalSpins += rotationDelta * (180.0 / PI)
	
	#update last rotation
	lastRotation = currentRotation


func checkTrickLanding():
	#calculate completed spins on each axis
	var xSpins = int(abs(totalSpins.x) / spinThreshold)
	var ySpins = int(abs(totalSpins.y) / spinThreshold)
	var zSpins = int(abs(totalSpins.z) / spinThreshold)
	
	#check if trick was landed by seeing if boat is upright and touching water
	if touchingWater and abs(totalSpins.x) < 45 and abs(totalSpins.z) < 45:
		#trick landed successfully
		if xSpins > 0 or ySpins > 0 or zSpins > 0:
			print("Holy Gnarly Trick landed! Total spins - X: ", xSpins, " Y: ", ySpins, " Z: ", zSpins)
			calcPoints(xSpins, ySpins, zSpins)
		totalSpins = Vector3.ZERO
	elif touchingWater:
		#failed trick reset
		if xSpins > 0 or ySpins > 0 or zSpins > 0:
			print("totally buggered that one")
		totalSpins = Vector3.ZERO


func calcPoints(xSpins: int, ySpins: int, zSpins: int):
	var points := 0
	
	#single axis tricks
	if xSpins > 0 and ySpins == 0 and zSpins == 0:
		points = xSpins * 100
	elif xSpins == 0 and ySpins > 0 and zSpins == 0:
		points = ySpins * 100
	elif xSpins == 0 and ySpins == 0 and zSpins > 0:
		points = zSpins * 100
	
	#double axis tricks
	elif xSpins > 0 and ySpins > 0 and zSpins == 0:
		points = (xSpins * 100) * (ySpins * 100)
	elif xSpins > 0 and ySpins == 0 and zSpins > 0:
		points = (xSpins * 100) * (zSpins * 100)
	elif xSpins == 0 and ySpins > 0 and zSpins > 0:
		points = (ySpins * 100) * (zSpins * 100)
	
	#triple axis tricks
	elif xSpins > 0 and ySpins > 0 and zSpins > 0:
		points = (xSpins * 100) * (ySpins * 100) * (zSpins * 100)
	
	totalScore += points
	print("Points earned: ", points, " | Total score: ", totalScore)
	


func update_wrong_way(delta: float, state: PhysicsDirectBodyState3D) -> void:
	if track == null:
		return

	var velocity: Vector3 = state.linear_velocity
	var speed := velocity.length()
	
	# if we're barely moving, don't warn
	if speed < wrong_way_speed_min:
		wrong_way_timer = 0.0
		if wave_hud and wave_hud.has_method("set_wrong_way"):
			wave_hud.call("set_wrong_way", false)
		return
	
	var curve := track.curve
	if curve == null or curve.get_point_count() < 2:
		return
	
	# 1) where is the boat in track local space?
	var local_pos: Vector3 = track.to_local(global_transform.origin)
	
	# 2) find closest offset on the curve
	var offset := curve.get_closest_offset(local_pos)
	
	# 3) sample a little behind and ahead to get the path tangent
	var sample_dist := 3.0
	var behind_offset := offset - sample_dist * 0.5
	var ahead_offset  := offset + sample_dist * 0.5
	
	var behind_local := curve.sample_baked(behind_offset)
	var ahead_local  := curve.sample_baked(ahead_offset)
	
	var behind_world := track.to_global(behind_local)
	var ahead_world  := track.to_global(ahead_local)
	
	var track_dir := (ahead_world - behind_world).normalized()
	var vel_dir := velocity.normalized()
	
	# dot < 0 means mostly opposite direction
	var dot := vel_dir.dot(track_dir)
	
	if dot < -0.2:
		wrong_way_timer += delta
	else:
		wrong_way_timer = 0.0
	
	var is_wrong := wrong_way_timer >= wrong_way_time_threshold

	# let WaveHUD decide what to do with the label
	if wave_hud and wave_hud.has_method("set_wrong_way"):
		wave_hud.call("set_wrong_way", is_wrong)


func setInWave() -> void:
	inWave = true
	

func setNotInWave() -> void:
	inWave = false


func handleWaveCollision() -> void:
	if not inWave:
		return
	# get boat speed
	var boatSpeed = linear_velocity.length()
	# get force multipler based on boatspeed
	var waveMultiplier = clamp(boatSpeed / 100.0, 0.7, 5.0)
	#push boat back
	apply_central_impulse(-transform.basis.z * waveForce * waveMultiplier * 2)
	#spin boat
	apply_torque_impulse(transform.basis.y * waveTorque * waveMultiplier)
