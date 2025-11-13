extends Camera3D

@export var followSpeed := 5.0
@export var followOffset := Vector3(0, 15, -35)
@onready var boat := get_node_or_null("../Boat")

func _physics_process(delta):
	#get position behind the boat
	var targetPos = boat.global_transform.origin + boat.global_transform.basis * followOffset
	#move camera to target lerp for smooth
	position = position.lerp(targetPos, followSpeed * delta)
	#make camera look at the boat
	look_at(boat.global_position, Vector3.UP)
