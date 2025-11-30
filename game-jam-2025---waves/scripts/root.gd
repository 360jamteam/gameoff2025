extends Node

const MAIN_MENU_PATH = "res://ui/MainMenu.tscn"
const GAME_PATH = "res://scenes/water_toon.tscn"
const SETTINGS_MENU_PATH = "res://ui/SettingsMenu.tscn"
const PAUSE_MENU_PATH = "res://ui/PauseMenu.tscn"

var main_menu_scene : PackedScene = preload(MAIN_MENU_PATH)
var game_scene : PackedScene = preload(GAME_PATH)
var settings_menu_scene : PackedScene = preload(SETTINGS_MENU_PATH)
var pause_menu_scene : PackedScene = preload(PAUSE_MENU_PATH)

var current_scene: Node = null
var pause_menu_instance: Node = null
# to store paused game so we dont lose it
var paused_game_instance: Node = null

# for tracking where settings was opend from
enum SettingsContext { MAIN_MENU, PAUSE_MENU }
var settings_context: SettingsContext = SettingsContext.MAIN_MENU

@onready var scene_container = $SceneContainer

func _ready() -> void:
	# start w main menu
	change_scene_to(main_menu_scene)
	AudioManager.play_menu_music()
	
func change_scene_to(packed_scene: PackedScene) -> void:
	# clear paused game when doing full scene chance
	paused_game_instance = null
	
	if current_scene:
		current_scene.queue_free()
		await current_scene.tree_exited
	
	current_scene = packed_scene.instantiate()
	scene_container.add_child(current_scene)
	
	_connect_scene_signals(current_scene)

func _connect_scene_signals(scene: Node):

	if scene.has_signal("play_pressed"):
		scene.play_pressed.connect(load_game)
	
	if scene.has_signal("settings_pressed"):

		if settings_context == SettingsContext.PAUSE_MENU:
			scene.settings_pressed.connect(load_settings_from_pause)
		else:
			scene.settings_pressed.connect(load_settings_from_main_menu)
	
	if scene.has_signal("quit_pressed"):
		scene.quit_pressed.connect(func(): get_tree().quit())
	
	if scene.has_signal("back_pressed"):
		scene.back_pressed.connect(exit_settings)
	
	if scene.has_signal("restart_pressed"):
		scene.restart_pressed.connect(restart_game)
	
	if scene.has_signal("main_menu_pressed"):
		scene.main_menu_pressed.connect(load_main_menu)
	
func load_main_menu() -> void:
	free_pause_menu()
	get_tree().paused = false
	paused_game_instance = null
	change_scene_to(main_menu_scene)
	AudioManager.play_menu_music()
	
func load_game() -> void:
	get_tree().paused = false
	paused_game_instance = null
	change_scene_to(game_scene)
	AudioManager.play_game_music()
	
func restart_game() -> void:
	close_pause_menu()
	get_tree().paused = false
	paused_game_instance = null
	change_scene_to(game_scene)
	
func open_pause_menu() -> void:
	if pause_menu_instance:
		return
	
	get_tree().paused = true
	pause_menu_instance = pause_menu_scene.instantiate()
	get_tree().root.add_child(pause_menu_instance)
	
	pause_menu_instance.resume_pressed.connect(close_pause_menu)
	pause_menu_instance.settings_pressed.connect(load_settings_from_pause)
	pause_menu_instance.restart_pressed.connect(restart_game)
	pause_menu_instance.main_menu_pressed.connect(load_main_menu)
		
func close_pause_menu() -> void:
	get_tree().paused = false
	free_pause_menu()
	
func free_pause_menu() -> void:
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null
	
func load_settings_from_main_menu() -> void:
	settings_context = SettingsContext.MAIN_MENU
	change_scene_to(settings_menu_scene)
	
func load_settings_from_pause() -> void:
	settings_context = SettingsContext.PAUSE_MENU
	free_pause_menu()
	
	if current_scene:
		paused_game_instance = current_scene
		current_scene.visible = false
		scene_container.remove_child(paused_game_instance)
	
	var settings_menu_instance = settings_menu_scene.instantiate()
	scene_container.add_child(settings_menu_instance)

	current_scene = settings_menu_instance
	
	print("made a settings menu instance")
	_connect_scene_signals(settings_menu_instance)
	
func exit_settings() -> void:
	print("exit_settings")
	match settings_context:
		
		SettingsContext.MAIN_MENU:
			load_main_menu()
			
		SettingsContext.PAUSE_MENU:
			if current_scene:
				print("if current scne in exit_settings")
				current_scene.queue_free()
				await current_scene.tree_exited
				
			if paused_game_instance:
				paused_game_instance.visible = true
				current_scene = paused_game_instance
				
				scene_container.add_child(current_scene)
				
				await get_tree().process_frame
				open_pause_menu()
			else:
				load_game()
