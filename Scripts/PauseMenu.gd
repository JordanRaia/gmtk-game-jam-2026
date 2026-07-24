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
	GameState.balance = GameState.starting_balance
	GameState.time_remaining = 180.0
	GameState.luck_meter = 50
	GameState.current_selected_chip = 1000
	GameState.active_bets = {}
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
