extends CanvasLayer
# Handles:
#  - WAVE (W) hint
#  - JUMP (SPACE) hint
#  - BOOST (SHIFT) hint
#  - WRONG WAY warning (separate label so it never overlaps)

@onready var wrong_way_label: Label = $WrongWayLabel
@onready var ink_overlay: TextureRect = $InkOverlay

@export var message_duration: float = 0.7   # how long W/JUMP/BOOST stay on screen

func _ready() -> void:
	# make sure everything starts hidden
	if wrong_way_label:
		wrong_way_label.visible = false
		wrong_way_label.modulate = Color(1.0, 0.3, 0.3) # red-ish

func _process(_delta: float) -> void:
	pass

# called from boat.gd 

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
		label.text = str(int(ceil(time_left)))
	else:
		# after countdown ends, show GO!
		label.text = "GO!"

	# hide label a moment after GO
	if time_left < -0.5:
		label.visible = false
