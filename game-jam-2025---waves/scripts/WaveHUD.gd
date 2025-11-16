extends CanvasLayer
# Simple HUD that briefly shows text like "WAVE (W)" or "JUMP (SPACE)"
# whenever the boat script calls show_message().

@onready var wave_label: Label = $WaveLabel
# wave_label – the Label node in this CanvasLayer that actually displays the text.

var _timer: float = 0.0
# _timer – counts down how much longer the message should stay visible.

@export var message_duration: float = 0.7
# message_duration – how long (in seconds) each message stays on screen.

func _process(delta: float) -> void:
	# If there is time left on the timer, count it down.
	if _timer > 0.0:
		_timer -= delta
		# Once the timer hits zero, hide the label.
		if _timer <= 0.0:
			wave_label.visible = false

func show_message(text: String, color: Color) -> void:
	# Called from boat.gd to display a short status message.
	# Example: show_message("WAVE (W)", Color(0.6, 1.0, 0.6))
	wave_label.text = text
	wave_label.modulate = color   # Tint the text so different actions can have different colors.
	wave_label.visible = true
	_timer = message_duration     # Reset timer so the label will auto-hide after a moment.
