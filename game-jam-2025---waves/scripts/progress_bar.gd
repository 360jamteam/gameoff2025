extends ProgressBar

@export var max_health: int = 100
@export var invincibility_duration: float = 2.0
@export var damage_flash_color: Color = Color(1, 0, 0)  # bright red

var health: int
var can_take_damage: bool = true
var invincibility_timer: Timer

var base_color: Color = Color(0.1, 0.8, 0.1) # current fill color (green/yellow/red)
var style_background: StyleBoxFlat
var style_fill: StyleBoxFlat

signal died
signal damaged(amount: int)

@onready var custom_font: Font = load("res://assets/fonts/BungeeTint-Regular.ttf")


func _ready() -> void:
	# Basic health setup
	health = max_health
	max_value = max_health
	value = health
	
	# Make sure nothing is tinted/transparent
	self.modulate = Color(1, 1, 1, 1)
	self.self_modulate = Color(1, 1, 1, 1)
	
	# Background
	style_background = StyleBoxFlat.new()
	style_background.bg_color = Color(0, 0, 0, 1)
	style_background.border_color = Color(0, 0, 0, 1) 
	style_background.border_width_left = 4
	style_background.border_width_right = 4
	style_background.border_width_top = 4
	style_background.border_width_bottom = 4
	style_background.corner_radius_top_left = 10
	style_background.corner_radius_top_right = 10
	style_background.corner_radius_bottom_left = 10
	style_background.corner_radius_bottom_right = 10
	add_theme_stylebox_override("background", style_background)

	# Health bar color
	style_fill = StyleBoxFlat.new()
	style_fill.bg_color = base_color
	style_fill.corner_radius_top_left = 10
	style_fill.corner_radius_top_right = 10
	style_fill.corner_radius_bottom_left = 10
	style_fill.corner_radius_bottom_right = 10
	add_theme_stylebox_override("fill", style_fill)
	add_theme_stylebox_override("fg", style_fill)

	# text and font
	if custom_font:
		add_theme_font_override("font", custom_font)
		add_theme_font_size_override("font_size", 32)
	update_bar_color()

	# invincible after collision for 2 sec
	invincibility_timer = Timer.new()
	invincibility_timer.one_shot = true
	invincibility_timer.wait_time = invincibility_duration
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(invincibility_timer)

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	value = health
	update_bar_color()

func apply_damage(amount: int) -> void:
	if not can_take_damage:
		return

	can_take_damage = false
	if invincibility_timer:
		invincibility_timer.start()

	health = max(health - amount, 0)
	value = health

	update_bar_color()
	flash_damage()

	emit_signal("damaged", amount)

	if health <= 0:
		emit_signal("died")


func _on_invincibility_timeout() -> void:
	can_take_damage = true


func update_bar_color() -> void:
	var ratio := float(health) / float(max_health)

	if ratio > 0.6:
		base_color = Color(0.1, 0.8, 0.1, 1) # green
	elif ratio > 0.3:
		base_color = Color(0.9, 0.8, 0.1, 1) # yellow
	else:
		base_color = Color(0.9, 0.1, 0.1, 1) # red

	if style_fill:
		style_fill.bg_color = base_color


func flash_damage() -> void:
	if not style_fill:
		return

	var tween := create_tween()
	for i in range(3):
		tween.tween_property(style_fill, "bg_color", damage_flash_color, 0.1)
		tween.tween_property(style_fill, "bg_color", base_color, 0.1)
