# buoyancy code adapted from How to make things float in Godot 4: https://www.youtube.com/watch?v=_R2KDcAp1YQ&t=200s
# 
# boat only accpts input for forward, backwards, boosts, and jump
# when submerged = true

extends RigidBody3D

#ink
var ink_overlay: TextureRect
@export var float_force := 11.5
@export var water_drag := 0.05
@export var water_angular_drag := 0.05

# movement settings
@export var moveSpeed := 1700.0
@export var boostMod := 2.0
@export var turnSpeed := 0.1
@export var recoverSpeed := 1200.0  
@export var jumpSpeed := 70.0
@onready var collision_sound: AudioStreamPlayer = $CollisionSound

# trick settings
var totalScore = 0.0
var touchingWater = true
var trickAngles = [180, 360, 720, 1080]

# wave effect settings
var inWave := false
var waveForce := 100.0
var waveTorque := 1.0

# countdown / control lock
var can_control := false
var countdown := 10.0   # seconds
var countdown_done := false

# WRONG WAY settings
@export var track_path: NodePath
@export var wrong_way_speed_min := 5.0
@export var wrong_way_time_threshold := 0.5
@export var wave_hud_path: NodePath


var track: Path3D
var wrong_way_timer := 0.0
var wave_hud: CanvasLayer

@onready var health_bar = %HealthBar
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
		
	if health_bar and health_bar.has_signal("died"):
		health_bar.died.connect(_on_player_died)
	
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

func _on_player_died() -> void:
	_on_ink_timeout()
	print("GAME OVER")

	# stop movement
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	set_physics_process(false)
	set_process(false)

	# pause game
	get_tree().paused = true

	# show Game Over UI
	var game_over_ui := get_tree().get_first_node_in_group("game_over_ui")
	if game_over_ui:
		game_over_ui.show_game_over()

func _on_body_entered(body: Node3D) -> void:
	print("Boat collided with: ", body.name)
	print("Body class: ", body.get_class())
	print("Is in squid group: ", body.is_in_group("squid"))
	
	if collision_sound:
		collision_sound.stop()
		collision_sound.play()
			
	if body.is_in_group("squid"):
		print("*** SQUID COLLISION DETECTED! ***")
		show_ink(3.0)
		
		# soften the hit so the boat doesn't spin forever
		angular_velocity = Vector3.ZERO
		linear_velocity *= 0.5

		# nudge the boat back upright
		recoverBoat()
		
		# small damage 
		if health_bar:
			health_bar.apply_damage(10)
	else:
		# other collisions can still do normal damage if you want
		if health_bar:
			health_bar.apply_damage(20)
	
func _integrate_forces(state: PhysicsDirectBodyState3D):
	# countdown at start (blocks player control) 
	# Always tick countdown and always tell HUD, so it can hide itself.
	countdown -= state.get_step()

	if wave_hud and wave_hud.has_method("update_countdown"):
		wave_hud.call("update_countdown", countdown)

	# Turn controls on once, when timer finishes
	if not countdown_done and countdown <= 0.0:
		countdown_done = true
		can_control = true

	if submerged:
		state.linear_velocity *= 1.0 - water_drag
		state.angular_velocity *= 1.0 - water_angular_drag

	# Only recover + control if countdown finished
	if can_control and not (
		Input.is_action_pressed("uarrow")
		or Input.is_action_pressed("darrow")
		or Input.is_action_pressed("larrow")
		or Input.is_action_pressed("rarrow")
	):
		recoverBoat()

	# Controls only after countdown
	if can_control:
		handleControls()

	# Boat physics still always run
	makeItFloat()
	handleWaveCollision()

	# WRONG WAY logic always runs
	update_wrong_way(state.get_step(), state)


func handleControls():
	# steering
	if Input.is_action_pressed("left"):
		apply_torque_impulse(transform.basis.y * turnSpeed)
	if Input.is_action_pressed("right"):
		apply_torque_impulse(transform.basis.y * -turnSpeed)

	# thrust / jumping
	if submerged:
		if Input.is_action_pressed("forward"):
			apply_central_force(transform.basis.z * moveSpeed)
			totalScore += 1
			
		if Input.is_action_pressed("backward"):
			apply_central_force(-transform.basis.z * moveSpeed)
			
		if Input.is_action_pressed("boost"):
			apply_central_force(transform.basis.z * moveSpeed * boostMod)
			totalScore += 3
			
		if Input.is_action_pressed("jump"):
			apply_central_impulse(Vector3.UP * jumpSpeed)
			totalScore += 5
		
	# tricks
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
	var body_height = global_transform.origin.y
	var water_height = water.get_height(global_transform.origin)
	var depth = water_height - body_height
	
	if depth > 0:
		submerged = true
		apply_force(Vector3.UP * float_force * gravity * depth)


func recoverBoat():
	var current_up = global_transform.basis.y
	var correction_axis = current_up.cross(Vector3.UP)
	apply_torque(correction_axis * recoverSpeed)


func update_wrong_way(delta: float, state: PhysicsDirectBodyState3D) -> void:
	if track == null:
		return

	var velocity: Vector3 = state.linear_velocity
	var speed := velocity.length()
	
	if speed < wrong_way_speed_min:
		wrong_way_timer = 0.0
		if wave_hud and wave_hud.has_method("set_wrong_way"):
			wave_hud.call("set_wrong_way", false)
		return
	
	var curve := track.curve
	if curve == null or curve.get_point_count() < 2:
		return
	
	var local_pos: Vector3 = track.to_local(global_transform.origin)
	var offset := curve.get_closest_offset(local_pos)
	
	var sample_dist := 3.0
	var behind_offset := offset - sample_dist * 0.5
	var ahead_offset  := offset + sample_dist * 0.5
	
	var behind_local := curve.sample_baked(behind_offset)
	var ahead_local  := curve.sample_baked(ahead_offset)
	
	var behind_world := track.to_global(behind_local)
	var ahead_world  := track.to_global(ahead_local)
	
	var track_dir := (ahead_world - behind_world).normalized()
	var vel_dir := velocity.normalized()
	var dot := vel_dir.dot(track_dir)
	
	if dot < -0.2:
		wrong_way_timer += delta
	else:
		wrong_way_timer = 0.0
	
	var is_wrong := wrong_way_timer >= wrong_way_time_threshold

	if wave_hud and wave_hud.has_method("set_wrong_way"):
		wave_hud.call("set_wrong_way", is_wrong)


func crazyAssTricks():
	var boat = get_node_or_null("../Boat")
	if touchingWater == false:
		var yes = 0
	# TODO: trick system


func setInWave() -> void:
	inWave = true
	
func setNotInWave() -> void:
	inWave = false


func handleWaveCollision() -> void:
	if not inWave:
		return
	
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
