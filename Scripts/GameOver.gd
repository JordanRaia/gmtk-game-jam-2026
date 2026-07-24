extends Control


func show_game_over() -> void:
	visible = true
	get_tree().paused = true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	GameState.balance = GameState.starting_balance
	GameState.time_remaining = 180.0
	GameState.luck_meter = 50
	GameState.current_selected_chip = 1000
	GameState.active_bets = {}
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
