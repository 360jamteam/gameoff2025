extends Control

signal resume_pressed
signal restart_pressed
signal settings_pressed
signal main_menu_pressed

func _on_button_resume_pressed():
	emit_signal("resume_pressed")
	
func _on_button_settings_pressed():
	emit_signal("settings_pressed")

func _on_button_restart_pressed():
	emit_signal("restart_pressed")

func _on_button_main_menu_pressed():
	emit_signal("main_menu_pressed")
