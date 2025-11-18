extends Control

@onready var health_label = $HealthLabel
@onready var time_label = $TimeLabel

var current_time := 0.0

func _process(delta):
	current_time += delta
	time_label.text = "Time: " + str(roundf(current_time * 10) / 10.0 )

func update_health(value):
	health_label.text = "Health: " + str(value)
