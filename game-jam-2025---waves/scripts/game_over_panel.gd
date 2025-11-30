extends Control

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS   # IMPORTANT: allows escape to work while paused

func show_game_over():
	visible = true


func _on_RestartButton_pressed():
	# Fully reset the world — DO NOT use reload_current_scene() here
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/water_toon.tscn")


# Allow ESC to jump straight to Main Menu on Game Over
func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = false
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
