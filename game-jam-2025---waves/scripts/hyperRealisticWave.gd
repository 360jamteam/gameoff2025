extends Area3D
class_name HyperRealisticWave

# wave movement settings
@export var horizontal_speed : float = 3.0
@export var wave_height: float = 20.0
@export var rise_duration: float = 3.0
@export var fall_duration: float = 3.0

# when player goes in the wave settings
@export var slowdown_factor: float = 0.5
@export var push_force: float = 5.0

# info for individual wave instances
var start_y: float
var current_phase: String = "uppies"
var phase_timer: float = 0.0
var movement_direction: Vector3 = Vector3.LEFT

func _ready() -> void:
	start_y = global_position.y - 35.0

func _process(delta: float) -> void:
	#keep those babies moving
	global_position += movement_direction * horizontal_speed * delta
	
	phase_timer += delta
	
	match current_phase:
		"uppies":
			var progress = phase_timer / rise_duration
			if progress >= 1.0:
				current_phase = "downies"
				phase_timer = 0.0
				progress = 1.0
			
			#smooth out the rise
			var eased = 1.0 - pow(1.0-progress, 3)
			global_position.y = start_y + (wave_height * eased)
		
		"downies":
			var progress = phase_timer / fall_duration
			if progress >= 1.0:
				current_phase = "rip_wave_you_were_a_real_one"
				progress = 1.0
				
			var eased = 1.0 - pow(progress, 3)
			global_position.y = start_y + (wave_height * eased)
			
		"rip_wave_you_were_a_real_one":
			queue_free()

func set_move_direction(dir:Vector3) -> void:
	movement_direction = dir.normalized()



# signal for when boat drives into wave
func _on_body_entered(body: Node3D) -> void:
	print("body entered")
	if body.has_method("setInWave"):
		body.setInWave()

#signal for when boat exits wave
func _on_body_exited(body: Node3D) -> void:
	print("body exited")
	if body.has_method("setNotInWave"):
		body.setNotInWave()
