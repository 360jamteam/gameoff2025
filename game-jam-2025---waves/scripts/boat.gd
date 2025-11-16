# adapted from How to make things float in Godot 4: https://www.youtube.com/watch?v=_R2KDcAp1YQ&t=200s
# This script:
#  - Makes the boat float on the moving water surface.
#  - Handles movement, boost, jump, and trick inputs.
#  - Shows debug HUD messages + spawns a visual ripple when the player presses W (wave) or SPACE (jump).

extends RigidBody3D

# Floating / water interaction settings
@export var float_force := 11.5
@export var water_drag := 0.05
@export var water_angular_drag := 0.05

# Debug HUD + ripple settings
@export var debug_hud_path: NodePath                 # Path to WaveHUD CanvasLayer in the scene.
@export var debug_ripple_scene: PackedScene          # PackedScene for the WaveRipple.tscn.
@export var debug_ripple_y_offset: float = 0.2       # Small height offset so the ripple sits on top of the water.

# Movement settings
@export var moveSpeed := 1700.0
@export var boostMod := 2.0
@export var turnSpeed := 0.1
@export var recoverSpeed := 1200.0  

# Trick settings (left here for later scoring / rotation tricks)
var totalScore = 0.0
var touchingWater = true
var trickAngles = [180, 360, 720, 1080]

@export var jumpSpeed := 70.0                       # Strength of the jump when SPACE is pressed.

# References to global settings and the water node
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water_path : NodePath = "../Water/WaterMesh"

var water: MeshInstance3D
var submerged := false                              # True when the boat is below water surface and floating should apply.

# Cached reference to the HUD so we don't look it up every time.
var debug_hud: CanvasLayer

func _ready():
	# Grab the water mesh so we can query its height for floating.
	water = get_node(water_path)

	if not water:
		push_error("Water node not found at path: " + str(water_path))
		return
	
	# If a HUD path was assigned in the inspector, cache it.
	if debug_hud_path != NodePath():
		debug_hud = get_node_or_null(debug_hud_path) as CanvasLayer
		
func _integrate_forces(state: PhysicsDirectBodyState3D):
	# Apply extra drag when the boat is submerged
	if submerged:
		state.linear_velocity *= 1.0 - water_drag
		state.angular_velocity *= 1.0 - water_angular_drag
	
	# When not holding trick keys, keep the boat upright.
	if not (Input.is_action_pressed("uarrow") or Input.is_action_pressed("darrow") or Input.is_action_pressed("larrow") or Input.is_action_pressed("rarrow")):
		recoverBoat()
		
	# Handle player inputs and floating each physics step.
	handleControls()
	makeItFloat()

func handleControls():
	# Left / right steering (always allowed, even if slightly out of the water)
	if Input.is_action_pressed("left"):
		apply_torque_impulse(transform.basis.y * turnSpeed)
	if Input.is_action_pressed("right"):
		apply_torque_impulse(transform.basis.y * -turnSpeed)
	
	# Only allow forward / backward / boost / jump while actually in the water.
	if submerged:
		# W = forward movement, which we treat as "riding a wave".
		if Input.is_action_pressed("forward"):
			apply_central_force(transform.basis.z * moveSpeed)

			# Only show HUD + ripple once when the key is first pressed, not every frame.
			if Input.is_action_just_pressed("forward"):
				if debug_hud:
					debug_hud.call("show_message", "WAVE (W)", Color(0.6, 1.0, 0.6))
				spawn_debug_ripple()

		# S = move backwards.
		if Input.is_action_pressed("backward"):
			apply_central_force(-transform.basis.z * moveSpeed)
			
		# Shift (or whatever is mapped to "boost") – stronger forward push.
		if Input.is_action_pressed("boost"):
			apply_central_force(transform.basis.z * moveSpeed * boostMod)
			
		# SPACE = jump. Separate from the W "wave" movement.
		if Input.is_action_just_pressed("jump"):
			apply_central_impulse(Vector3.UP * jumpSpeed)
			if debug_hud:
				debug_hud.call("show_message", "JUMP (SPACE)", Color(1.0, 0.8, 0.4))

	# Trick inputs (spins/flips). These can be tuned later for scoring.
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
	# Figure out how far the boat is below the water surface and push it up accordingly.
	submerged = false
	var body_height = global_transform.origin.y
	var water_height = water.get_height(global_transform.origin)
	var depth = water_height - body_height
	
	if depth > 0:
		submerged = true
		# Apply an upward force proportional to how deep the boat is.
		apply_force(Vector3.UP * float_force * gravity * depth)
	
func recoverBoat():
	# Try to keep the boat upright so it doesn't stay flipped over.
	var current_up = global_transform.basis.y
	var correction_axis = current_up.cross(Vector3.UP)
	apply_torque(correction_axis * recoverSpeed)

func spawn_debug_ripple() -> void:
	# Spawns a visual water ring under the boat when W is first pressed.
	if debug_ripple_scene == null:
		return

	var ripple := debug_ripple_scene.instantiate() as Node3D

	# Parent is usually the main world node that also owns the water and boat.
	var parent := get_parent() as Node3D
	if parent == null:
		return

	# Get the world-space position under the boat.
	var world_pos := global_transform.origin
	if water:
		# Place the ripple slightly above the water height so it doesn't clip through.
		world_pos.y = water.get_height(world_pos) + debug_ripple_y_offset

	# Convert that world position into the parent's local space,
	# so the ripple lines up correctly when added as a child of parent.
	var local_pos := parent.to_local(world_pos)
	ripple.position = local_pos

	# Add the ripple to the scene – WaveRipple.gd handles the animation + self-delete.
	parent.add_child(ripple)

func crazyAssTricks():
	@warning_ignore("unused_variable")
	var boat = get_node_or_null("../Boat")
	if touchingWater == false:
		@warning_ignore("unused_variable")
		var yes = 0
	# TODO: when tricks are implemented:
	#  - track rotation angles while in the air
	#  - detect when certain thresholds (180, 360, 720, 1080, etc.) are passed
	#  - award score / multipliers and feed into totalScore
