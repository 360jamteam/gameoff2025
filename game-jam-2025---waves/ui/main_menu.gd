extends Control

func _on_button_start_pressed():
	get_tree().change_scene_to_file("res://scenes/water_toon.tscn")

func _on_button_settings_pressed():
	SettingsMenu.previous_menu_path = "res://ui/MainMenu.tscn"
	get_tree().change_scene_to_file("res://ui/SettingsMenu.tscn")

func _on_button_quit_pressed():
	get_tree().quit()
