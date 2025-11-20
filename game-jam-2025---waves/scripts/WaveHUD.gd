extends CanvasLayer
# Handles:
#  - WAVE (W) hint
#  - JUMP (SPACE) hint
#  - BOOST (SHIFT) hint
#  - WRONG WAY warning (separate label so it never overlaps)

@onready var wave_label: Label      = $WaveLabel
@onready var jump_label: Label      = $JumpLabel
@onready var boost_label: Label     = $BoostLabel
@onready var wrong_way_label: Label = $WrongWayLabel

var _wave_timer:  float = 0.0
var _jump_timer:  float = 0.0
var _boost_timer: float = 0.0

@export var message_duration: float = 0.7   # how long W/JUMP/BOOST stay on screen

func _ready() -> void:
	# make sure everything starts hidden
	if wave_label:
		wave_label.visible = false
	if jump_label:
		jump_label.visible = false
	if boost_label:
		boost_label.visible = false
	if wrong_way_label:
		wrong_way_label.visible = false
		wrong_way_label.modulate = Color(1.0, 0.3, 0.3) # red-ish

func _process(delta: float) -> void:
	# WAVE text timer
	if _wave_timer > 0.0:
		_wave_timer -= delta
		if _wave_timer <= 0.0 and wave_label:
			wave_label.visible = false

	# JUMP text timer
	if _jump_timer > 0.0:
		_jump_timer -= delta
		if _jump_timer <= 0.0 and jump_label:
			jump_label.visible = false

	# BOOST text timer
	if _boost_timer > 0.0:
		_boost_timer -= delta
		if _boost_timer <= 0.0 and boost_label:
			boost_label.visible = false

# called from boat.gd 

func show_wave_message(text: String, color: Color) -> void:
	if not wave_label:
		return
	wave_label.text = text
	wave_label.modulate = color
	wave_label.visible = true
	_wave_timer = message_duration

func show_jump_message(text: String, color: Color) -> void:
	if not jump_label:
		return
	jump_label.text = text
	jump_label.modulate = color
	jump_label.visible = true
	_jump_timer = message_duration

func show_boost_message(text: String, color: Color) -> void:
	if not boost_label:
		return
	boost_label.text = text
	boost_label.modulate = color
	boost_label.visible = true
	_boost_timer = message_duration

func set_wrong_way(enabled: bool) -> void:
	if not wrong_way_label:
		return
	wrong_way_label.visible = enabled
	if enabled:
		wrong_way_label.text = "WRONG WAY"

# COUNTDOWN DISPLAY SUPPORT
# Called from boat.gd

func update_countdown(time_left: float) -> void:
	var label := $CountdownLabel   

	# show label
	label.visible = true

	if time_left > 0.0:
		# show 10, 9, 8, ... 1
		label.text = str(ceil(time_left))
	else:
		# after countdown ends, show GO!
		label.text = "GO!"

	# hide label a moment after GO
	if time_left < -0.5:
		label.visible = false
