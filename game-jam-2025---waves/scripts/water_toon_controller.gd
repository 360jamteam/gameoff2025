extends Node3D

var pause_menu_scene := preload("res://ui/PauseMenu.tscn")
var pause_menu_instance: Control = null

func _input(event):
	var game_over = get_tree().get_first_node_in_group("game_over_ui")
	if game_over and game_over.visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		unpause_game()
	else:
		pause_game()

func pause_game():
	get_tree().paused = true

	pause_menu_instance = pause_menu_scene.instantiate()
	get_tree().root.add_child(pause_menu_instance)

	# CONNECT SIGNALS
	pause_menu_instance.resume_pressed.connect(_on_resume)
	pause_menu_instance.restart_pressed.connect(_on_restart)
	pause_menu_instance.main_menu_pressed.connect(_on_main_menu)

func unpause_game():
	get_tree().paused = false
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null

func _on_resume():
	unpause_game()

func _on_restart():
	unpause_game()
	get_tree().reload_current_scene()

func _on_main_menu():
	unpause_game()
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
