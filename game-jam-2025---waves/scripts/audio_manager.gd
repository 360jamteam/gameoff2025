extends Node

var menu_music_player: AudioStreamPlayer
var game_music_player: AudioStreamPlayer
var game_ambient_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	#print("AudioManager initialized")
	menu_music_player = AudioStreamPlayer.new()
	menu_music_player.bus = "music"
	menu_music_player.stream = preload("res://assets/audio/background_music.ogg")
	menu_music_player.volume_db = 0
	add_child(menu_music_player)
	
	game_music_player = AudioStreamPlayer.new()
	game_music_player.bus = "music"
	game_music_player.stream = preload("res://assets/audio/blossom_mountain_bpm140.ogg")
	game_music_player.volume_db = -10
	add_child(game_music_player)
	
	game_ambient_player = AudioStreamPlayer.new()
	game_ambient_player.bus = "ambient"
	game_ambient_player.stream = preload("res://assets/audio/wave_loop.ogg")
	#game_ambient_player.volume_db = 10
	add_child(game_ambient_player)

func play_menu_music():
	#print("play_menu_music called")
	if game_music_player.playing:
		game_music_player.stop()
	if game_ambient_player.playing:
		game_ambient_player.stop()
	if not menu_music_player.playing:
		menu_music_player.play()

func play_game_music():
	#print("play_game_music called")
	if menu_music_player.playing:
		menu_music_player.stop()
	if not game_music_player.playing:
		game_music_player.play()
	if not game_ambient_player.playing:
		game_ambient_player.play()
		
func stop_all():
	menu_music_player.stop()
	game_music_player.stop()
	game_ambient_player.stop()
