extends Control


func show_game_over() -> void:
	visible = true
	get_tree().paused = true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	var cfg: Array = GameState.get_stage_config()
	GameState.balance = cfg[0]
	GameState.starting_balance = cfg[0]
	GameState.time_remaining = float(cfg[1])
	GameState.active_bets = {}
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
