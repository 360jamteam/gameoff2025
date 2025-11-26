extends Control

@onready var custom_font: Font = load("res://assets/fonts/BungeeTint-Regular.ttf")
@onready var lbl: Label = $CenterContainer/VBoxContainer/GameoverLabel
@onready var restart_btn: Button = $CenterContainer/VBoxContainer/RestartButton
@onready var vbox: VBoxContainer = $CenterContainer/VBoxContainer

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS   # IMPORTANT: allows escape to work while paused

	# Label font
	lbl.add_theme_font_override("font", custom_font)
	lbl.add_theme_font_size_override("font_size", 72)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)

	# Button font
	restart_btn.add_theme_font_override("font", custom_font)
	restart_btn.add_theme_font_size_override("font_size", 42)
	restart_btn.add_theme_color_override("font_color", Color.WHITE)
	restart_btn.add_theme_color_override("font_outline_color", Color.BLACK)
	restart_btn.add_theme_constant_override("outline_size", 4)


func show_game_over():
	visible = true


func _on_RestartButton_pressed():
	# Fully reset the world — DO NOT use reload_current_scene() here
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/water_toon.tscn")


# Allow ESC to jump straight to Main Menu on Game Over
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = false
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
