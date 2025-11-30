extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("finishRun"):
		body.finishRun()
	
	# send signal for bring up scoreboard/end scene
	
	
	
