class_name SettingsMenu
extends Control

signal back_pressed

func _on_button_back_pressed() -> void:
	emit_signal("back_pressed")
