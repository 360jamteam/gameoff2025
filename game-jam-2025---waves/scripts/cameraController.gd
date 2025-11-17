extends Camera3D

@export var followSpeed := 5.0
@export var followOffset := Vector3(0, 15, -25)
@onready var boat := get_node_or_null("../Boat")


#duration of cinematic
@export var duration = 3.0
var elapsed = 0.0
	
#final cam position
var finalCamPos = Vector3.ZERO
#starting height of cam
var startHeight = 0.0
#radius of orbit
@export var radius = 0.0
var startAngle = 0.0
var rotateDir = 1.0

@export var introDone = false


func _ready():
	finalCamPos = boat.global_transform.origin + boat.global_transform.basis * followOffset
	startHeight = finalCamPos.y + 50
	radius = followOffset.length()
	#start angle so the orbit begins from the current camera offset relative to the boat
	startAngle = atan2(global_position.z - boat.global_position.z, global_position.x - boat.global_position.x)


func _physics_process(delta):
	if introDone == false:
		introCam(delta)
	else:
		followBoat(delta)


func followBoat(delta):
	#get position behind the boat
	var targetPos = boat.global_transform.origin + boat.global_transform.basis * followOffset
	#move camera to target lerp for smooth
	position = position.lerp(targetPos, followSpeed * delta)
	#make camera look at the boat
	look_at(boat.global_position, Vector3.UP)


func introCam(delta):
	#elapsed time and slider for progress
	elapsed += delta
	var timeSlider = clamp(elapsed/duration, 0.0, 1.0)

	#angle around orbit based on progress, tau = 360*
	var angle = startAngle + rotateDir * timeSlider * TAU

	#get horizontal orbit offsets
	var offsetX = cos(angle) * radius
	var offsetZ = sin(angle) * radius

	#recompute finalCamPos each frame so follows boat if it moves
	finalCamPos = boat.global_transform.origin + boat.global_transform.basis * followOffset

	#interpolate height from start to final height
	var currentY = lerp(startHeight, finalCamPos.y, timeSlider)

	#find target position if moving
	var orbitTarget = Vector3(boat.global_position.x + offsetX, currentY, boat.global_position.z + offsetZ)

	#move camera toward the target
	position = position.lerp(orbitTarget, followSpeed * delta)

	#make camera look at the boat
	look_at(boat.global_position, Vector3.UP)

	#end of cinematic
	if timeSlider >= 1.0:
		introDone = true
