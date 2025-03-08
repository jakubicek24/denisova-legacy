extends Node2D

@onready var timer_game_restart: Timer = $TimerGameRestart


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		timer_game_restart.start()
		
	


func _on_timer_game_restart_timeout() -> void:
	get_tree().reload_current_scene()
