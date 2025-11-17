extends CanvasLayer
# Simple HUD for short messages ("WAVE (W)", "JUMP (SPACE)")
# and for showing/hiding the WRONG WAY warning.

@onready var wave_label: Label = $WaveLabel
@onready var wrong_way_label: Label = $WrongWayLabel

var _timer: float = 0.0
@export var message_duration: float = 0.7

func _ready() -> void:
	# Make sure WRONG WAY starts hidden
	if wrong_way_label:
		wrong_way_label.visible = false

func _process(delta: float) -> void:
	# Handle auto-hide for the small action messages
	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0 and wave_label:
			wave_label.visible = false

func show_message(text: String, color: Color) -> void:
	# Called from boat.gd to show WAVE / JUMP messages.
	if wave_label == null:
		return
	wave_label.text = text
	wave_label.modulate = color
	wave_label.visible = true
	_timer = message_duration

func set_wrong_way(is_wrong: bool) -> void:
	# Called from boat.gd, just toggles the WRONG WAY label.
	if wrong_way_label == null:
		return

	wrong_way_label.visible = is_wrong
	if is_wrong:
		wrong_way_label.text = "WRONG WAY"
		# make it reddish here instead of in boat.gd
		wrong_way_label.modulate = Color(1.0, 0.3, 0.3)
