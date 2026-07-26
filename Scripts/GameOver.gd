extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_game_over() -> void:
	modulate.a = 0.0
	visible = true
	get_tree().paused = true
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


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
