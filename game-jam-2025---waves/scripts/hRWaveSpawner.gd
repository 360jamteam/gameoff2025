extends Node3D
class_name hRWaveSpawner

const hyper_realistic_wave_scene: PackedScene = preload("res://scenes/hyper_realistic_wave.tscn")
@onready var track_path_3d: Path3D = get_node("../Water/TrackPath")
@onready var boat: RigidBody3D = get_node("../Boat")

@export var spawn_interval: float = 5.0
@export var spawn_chance: float = .7
@export var spawn_y_offset: float = -100.0  # make it spawn under the water so we don't see a flicker
@export var spawn_distance_ahead_min: float = 90.0
@export var sample_distance: float = 5.0
@export var player_start_side := Vector3.LEFT  # which direction down the track path the waves will go

var spawn_timer: float = 0.0

func _ready() -> void:
	if not hyper_realistic_wave_scene:
		push_error("wave spawner has no wave scene D:")
	if not track_path_3d:
		push_error("wave spawner has no path to follow T.T")

func _process(delta: float) -> void:
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		
		if randf() <= spawn_chance:
			print("we made it steve")
			spawn_wave()
			
func spawn_wave() -> void:
	var wave = hyper_realistic_wave_scene.instantiate() as HyperRealisticWave
	var curve = track_path_3d.curve

	# where boat?
	var boat_pos = boat.global_position
	# get the track point closest to boat
	var closest_offset = curve.get_closest_offset(track_path_3d.to_local(boat_pos))
	
	# add an offset to it to go further ahead of the boat on the track
	var spawn_offset = closest_offset + (spawn_distance_ahead_min + 50.0 * randf())
	# then get the closest curve point to that offset
	var spawn_pos_local = curve.sample_baked(spawn_offset)
	var spawn_pos = track_path_3d.to_global(spawn_pos_local)
	#apply the y offset to make the wave start under the water level
	spawn_pos.y = spawn_y_offset
	
	# get two points on either side of the spawn offset point
	var point1_offset = spawn_offset - sample_distance * 0.5
	var point2_offset = spawn_offset + sample_distance * 0.5
	var point1 = track_path_3d.to_global(curve.sample_baked(point1_offset))
	var point2 = track_path_3d.to_global(curve.sample_baked(point2_offset))
	
	# then get the vector between those two points
	var path_direction = (point2 - point1).normalized()
	
	#create a basis for the wave based on that direction
	var wave_basis = Basis()
	wave_basis.z = -path_direction
	wave_basis.y = Vector3.UP
	wave_basis.x = wave_basis.y.cross(wave_basis.z).normalized()
	
	#we did it joe
	# we spawned the most hyperrealistic wave you've ever seen
	# with hyperrealist wave directions that change every wave
	# people won't know they're in a game
	add_child(wave)
	wave.global_position = spawn_pos
	wave.global_transform.basis = wave_basis
	
	var move_direction = wave.basis.x * sign(player_start_side.x)
	wave.set_move_direction(move_direction)
	print("spawned wave at: ", spawn_pos)
