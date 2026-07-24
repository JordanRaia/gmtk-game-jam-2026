extends Control


func _ready() -> void:
	visible = false


func show_pause() -> void:
	visible = true
	get_tree().paused = true


func hide_pause() -> void:
	visible = false
	get_tree().paused = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if visible:
			hide_pause()
		else:
			show_pause()


func _on_continue_pressed() -> void:
	hide_pause()


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
