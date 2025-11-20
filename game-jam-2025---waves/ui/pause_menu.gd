extends Control

func _on_button_settings_pressed():
	# Tell Settings Menu to return to Pause Menu
	settings_menu.previous_menu_path = "res://ui/PauseMenu.tscn"
	get_tree().change_scene_to_file("res://ui/SettingsMenu.tscn")

func _on_button_main_menu_pressed():
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
