class_name settings_menu
extends Control

static var previous_menu_path: String = ""

func _on_button_back_pressed():
	if previous_menu_path != "":
		get_tree().change_scene_to_file(previous_menu_path)
	else:
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
