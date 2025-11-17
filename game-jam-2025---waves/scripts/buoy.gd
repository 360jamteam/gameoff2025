extends StaticBody3D

var water: MeshInstance3D  

# buoySpawner.gd calls this to get the water
func set_water(water_node: MeshInstance3D):
	water = water_node

func _process(_delta):
	if not water:
		return
	# set buoy y pos to water height
	var water_height = water.get_height(global_position)
	position.y = water_height
