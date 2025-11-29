extends Node3D

@onready var Root = get_tree().root.get_node("Root")

func _ready() -> void:
		pass
	
func _input(event):
	var game_over = get_tree().get_first_node_in_group("game_over_ui")
	if game_over and game_over.visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		Root.open_pause_menu()
