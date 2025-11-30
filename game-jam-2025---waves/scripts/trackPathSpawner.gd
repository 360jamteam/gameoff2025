extends Path3D

@export var buoy_scene: PackedScene = preload("res://scenes/buoy.tscn")
@export var squid_scene: PackedScene = preload("res://scenes/obstacles.tscn")
@export var meat_scene: PackedScene = preload("res://scenes/healthfood.tscn")
@export var finish_line_scene: PackedScene = preload("res://scenes/finish_line.tscn")

@export var buoy_spacing: float = 70.0
@export var buoy_offset_from_wall: float = 20.0

@export var track_width: float = 300.0
@export var wall_height: float = 700.0
@export var water_path: NodePath = "../WaterMesh"
@export var num_points_in_wall = 200 # more points = smoother curves

@export var invisible_ceiling_height := 670.0

@export var squid_spacing: float = 360.0     # distance between squids
@export var health_item_spacing: float = 480.0       # distance along track between spawn checks
@export var health_item_chance: float = 0.5 

var water: MeshInstance3D
var rng := RandomNumberGenerator.new()

func _ready():
	water = get_node(water_path)
	rng.randomize()
	if not water:
		push_error("Water node not found at path: " + str(water_path))
		return
	if not curve.sample_baked(0.0):
		push_error("Uh uh, no points in Curve3D")
		return

	spawn_buoys()
	create_invisible_walls()
	spawn_squids()
	spawn_health_items()
	spawn_finish_line()
	
var boat := get_node_or_null("../Boat")

func spawn_buoys():
	var curve_length = curve.get_baked_length()
	var num_buoys = int(curve_length / buoy_spacing)
	
	for i in range(num_buoys):
		var offset = (i * buoy_spacing)
		
		spawn_buoy_at_offset(offset, (-track_width / 2.0) - buoy_offset_from_wall)
		spawn_buoy_at_offset(offset, (track_width / 2.0) + buoy_offset_from_wall)

func spawn_buoy_at_offset(along_path: float, perpendicular_offset: float):
	var buoy = buoy_scene.instantiate()
	add_child(buoy)
	
	# this passes the water to the buoy so they can get the height they should float at
	buoy.set_water(water)
	
	var pos = curve.sample_baked(along_path)
	var forward = curve.sample_baked(along_path + 0.1) - pos
	forward = forward.normalized()
	
	var right = forward.cross(Vector3.UP).normalized()
	pos += right * perpendicular_offset
	
	buoy.global_position = pos
	
func create_invisible_walls():
	create_wall_side_mesh(-track_width / 2.0, "LeftWall")
	create_wall_side_mesh(track_width / 2.0, "RightWall")
	create_ceiling()
	
func create_ceiling() -> void:
	var ceiling = StaticBody3D.new()
	ceiling.name = "ceiling"
	add_child(ceiling)
	
	var collision_shape = CollisionShape3D.new()
	ceiling.add_child(collision_shape)
	
	var boundary_shape = WorldBoundaryShape3D.new()
	collision_shape.shape = boundary_shape
	
	boundary_shape.plane = Plane(Vector3.DOWN, 0)
	
	ceiling.position.y = invisible_ceiling_height
	
	
func create_wall_side_mesh(perpendicular_offset: float, wall_name: String):
	var wall = StaticBody3D.new()
	wall.name = wall_name
	add_child(wall)
	
	#make the wall less friction-y so the boat doesn't stick to it
	var physics_object = PhysicsMaterial.new()
	wall.physics_material_override = physics_object
	physics_object.friction = 0.0
	
	# mesh for wall
	var mesh_instance = MeshInstance3D.new()
	wall.add_child(mesh_instance)
	
	# collision shape for wall
	var collision_shape = CollisionShape3D.new()
	wall.add_child(collision_shape)
	
	# generate wall surface
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var curve_length = curve.get_baked_length()
	
	# build wall mesh along the path
	for i in range(num_points_in_wall):
		var offset = (i / float(num_points_in_wall - 1)) * curve_length
		var pos = curve.sample_baked(offset)
		
		# get perpendicular direction 
		var forward = curve.sample_baked(min(offset + 1, curve_length)) - pos
		forward = forward.normalized()
		var right = forward.cross(Vector3.UP).normalized()
		
		# put buoys at track edge
		pos += right * perpendicular_offset
		
		# create vertical wall quad
		if i < num_points_in_wall - 2: # - 2 avoids loop issue where it blocks off route, fix later
			var next_offset = ((i + 1) / float(num_points_in_wall - 1)) * curve_length
			var next_pos = curve.sample_baked(next_offset)
			
			var next_forward = curve.sample_baked(min(next_offset + 1, curve_length)) - next_pos
			next_forward = next_forward.normalized()
			var next_right = next_forward.cross(Vector3.UP).normalized()
			next_pos += next_right * perpendicular_offset
			
			# create quad (two triangles)
			var bottom1 = pos - Vector3.UP * 10
			var top1 = pos + Vector3.UP * wall_height
			var bottom2 = next_pos - Vector3.UP * 10
			var top2 = next_pos + Vector3.UP * wall_height
			
			# first triangle
			surface_tool.add_vertex(bottom1)
			surface_tool.add_vertex(top1)
			surface_tool.add_vertex(bottom2)
			
			# second triangle
			surface_tool.add_vertex(top1)
			surface_tool.add_vertex(top2)
			surface_tool.add_vertex(bottom2)
			
			# third triangle (facing in so collision on both sides)
			surface_tool.add_vertex(bottom1)
			surface_tool.add_vertex(bottom2)
			surface_tool.add_vertex(top1)

			# Fourth triangle (facing in)
			surface_tool.add_vertex(top1)
			surface_tool.add_vertex(bottom2)
			surface_tool.add_vertex(top2)
	
	var array_mesh = surface_tool.commit()
	mesh_instance.mesh = array_mesh
	
	# make mesh invisible
	mesh_instance.visible = false
	
	# create collision shape from mesh
	var concave_shape = array_mesh.create_trimesh_shape()
	collision_shape.shape = concave_shape

func spawn_squids() -> void:
	if squid_scene == null:
		push_warning("Squid scene not assigned, skipping squids")
		return

	var curve_length = curve.get_baked_length()
	if curve_length <= 0.0:
		push_warning("Curve length is zero, no squids spawned")
		return

	var half_width: float = track_width * 0.5
	var num_squids: int = int(curve_length / squid_spacing)
	
	var squid_free_zone := 400.0

	for i in range(num_squids):
		var dist: float = float(i) * squid_spacing
		
		if dist < squid_free_zone:
			continue
		
		if dist > curve_length:
			break

		var p0: Vector3 = curve.sample_baked(dist)

		var dist_next: float = min(dist + 1.0, curve_length)
		var p1: Vector3 = curve.sample_baked(dist_next)
		var forward: Vector3 = (p1 - p0).normalized()
		if forward == Vector3.ZERO:
			forward = Vector3.FORWARD

		# sideways (between walls) direction
		var right: Vector3 = forward.cross(Vector3.UP).normalized()
		if right == Vector3.ZERO:
			right = Vector3.RIGHT

		# convert center point to world so we can get water height
		var world_center: Vector3 = to_global(p0)
		var water_height: float = water.get_height(world_center)
		world_center.y = water_height   # sit on water

		var squid: Node3D = squid_scene.instantiate()
		
		setup_squid_collision(squid)
		add_child(squid)

		squid.global_position = world_center
		squid.rotation_degrees.y = 180
		
		if squid.has_method("setup"):
			squid.setup(world_center, right, half_width)


func setup_squid_collision(squid: Node3D) -> void:
	# Ensure the squid has proper collision setup
	if squid is StaticBody3D:
		# Set collision layers and masks - FIXED
		squid.collision_layer = 2  # Layer 2 for squids
		squid.collision_mask = 1   # Mask for layer 1 (boat)
		
		# Add to squid group for easy detection
		squid.add_to_group("squid")
		
		#print("Squid collision setup - Layer: ", squid.collision_layer, " Mask: ", squid.collision_mask)
		
		# Ensure collision shape exists and is enabled
		var collision_shape = squid.get_node_or_null("CollisionShape3D")
		if collision_shape:
			collision_shape.disabled = false
			#print("Squid collision shape found and enabled")
		else:
			print("WARNING: Squid has no CollisionShape3D")
			
func spawn_health_items() -> void:
	var curve_length = curve.get_baked_length()
	if curve_length <= 0.0:
		return

	var scenes: Array[PackedScene] = []
	if meat_scene:
		scenes.append(meat_scene)

	var half_width: float = track_width * 0.5
	var num_slots: int = int(curve_length / health_item_spacing)

	for i in range(num_slots):
		if rng.randf() > health_item_chance:
			continue

		var dist: float = float(i) * health_item_spacing
		if dist > curve_length:
			break

		# position along path
		var pos: Vector3 = curve.sample_baked(dist)
		var forward: Vector3 = (curve.sample_baked(dist + 0.1) - pos).normalized()
		var right: Vector3 = forward.cross(Vector3.UP).normalized()

		# somewhere near middle of the track
		var lateral_offset := rng.randf_range(-half_width * 0.25, half_width * 0.25)
		pos += right * lateral_offset

		var scene: PackedScene = scenes[rng.randi_range(0, scenes.size() - 1)]
		var pickup: Node3D = scene.instantiate()
		add_child(pickup)
		pickup.global_position = pos

		# collision for the boat
		if pickup is StaticBody3D:
			# same idea as squid: boat is on layer 1
			pickup.collision_layer = 4      # health items layer
			pickup.collision_mask = 1       # collide with boat on layer 1
		pickup.add_to_group("health_pickup")

func check_squid_collisions() -> void:
	if boat == null:
		boat = get_node_or_null("../Boat")
		if boat == null:
			return
	
	var squids = get_tree().get_nodes_in_group("squid")
	var boat_pos = boat.global_position
	
	for squid in squids:
		if is_instance_valid(squid):
			var squid_pos = squid.global_position
			var distance = boat_pos.distance_to(squid_pos)
			
			# If very close, trigger collision
			if distance < 15.0:
				#print("Manual collision detected with squid at distance: ", distance)
						
				if boat.has_method("show_ink"):
					boat.show_ink(3.0)
				break

func _process(_delta: float) -> void:
	check_squid_collisions()
	
func spawn_finish_line() -> void:
	var finish_line = finish_line_scene.instantiate()
	add_child(finish_line)
	
	# using same logic as in hRWaveSpawner.gd to make 
	# the finish line rotate to face the incoming track

	# close to start for testing
	# var end_of_track_a = to_global(curve.get_baked_points().get(1998))
	# var end_of_track_b = to_global(curve.get_baked_points().get(2000))

	# actual end of track
	var track_points = curve.get_baked_points()
	track_points.reverse()
	var end_of_track_a = to_global(track_points.get(100))
	var end_of_track_b = to_global(track_points.get(102))

	var finish_line_direction = (end_of_track_b - end_of_track_a).normalized()
	
	var finish_line_basis = Basis()
	finish_line_basis.z = -finish_line_direction
	finish_line_basis.y = Vector3.UP
	finish_line_basis.x = finish_line_basis.y.cross(finish_line_basis.z).normalized()
	
	finish_line.global_position = end_of_track_b
	finish_line.global_transform.basis = finish_line_basis
