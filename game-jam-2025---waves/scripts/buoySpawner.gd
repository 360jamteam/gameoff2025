extends Path3D

@export var buoy_scene: PackedScene = preload("res://scenes/buoy.tscn")
@export var buoy_spacing: float = 25.0
@export var track_width: float = 60.0
@export var wall_height: float = 50.0
@export var water_path: NodePath = "../WaterMesh"
@export var num_points_in_wall = 200 # more points = smoother curves

var water: MeshInstance3D

func _ready():
	water = get_node(water_path)
	
	if not water:
		push_error("Water node not found at path: " + str(water_path))
		return
	if not curve.sample_baked(0.0):
		push_error("Uh uh, no points in Curve3D")
		return
	
	spawn_buoys()
	create_invisible_walls()

func spawn_buoys():
	var curve_length = curve.get_baked_length()
	var num_buoys = int(curve_length / buoy_spacing)
	
	for i in range(num_buoys):
		var offset = (i * buoy_spacing)
		
		spawn_buoy_at_offset(offset, -track_width / 2.0)
		spawn_buoy_at_offset(offset, track_width / 2.0)

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
	
func create_wall_side_mesh(perpendicular_offset: float, wall_name: String):
	var wall = StaticBody3D.new()
	wall.name = wall_name
	add_child(wall)
	
	#make the wall less friction-y so the boat doesn't stick to it
	var physics_object = PhysicsMaterial.new()
	wall.physics_material_override = physics_object
	physics_object.friction = 0.1
	
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
			var bottom1 = pos - Vector3.UP * wall_height
			var top1 = pos + Vector3.UP * wall_height
			var bottom2 = next_pos - Vector3.UP * wall_height
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
	#mesh_instance.visible = false
	
	# make it kinda see through for debug
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0, 0.3) 
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material

	# create collision shape from mesh
	var concave_shape = array_mesh.create_trimesh_shape()
	collision_shape.shape = concave_shape
