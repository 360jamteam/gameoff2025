extends Control

@onready var Root = get_tree().root.get_node("Root")

func _on_button_start_pressed():
	Root.load_game()

func _on_button_settings_pressed():
	Root.load_settings_from_main_menu()

func _on_button_quit_pressed():
	get_tree().quit()
