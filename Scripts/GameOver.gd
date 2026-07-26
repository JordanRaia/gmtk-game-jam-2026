extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_button_hovers(self)


func _connect_button_hovers(node: Node) -> void:
	for child: Node in node.get_children():
		if child is TextureButton:
			child.mouse_entered.connect(func() -> void: AudioManager.play_ui("button_hover"))
		_connect_button_hovers(child)


func show_game_over() -> void:
	AudioManager.play_ui("game_over")
	modulate.a = 0.0
	visible = true
	get_tree().paused = true
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _on_retry_pressed() -> void:
	AudioManager.play_ui("button_click")
	AudioManager.stop_all()
	get_tree().paused = false
	var cfg: Array = GameState.get_stage_config()
	GameState.balance = cfg[0]
	GameState.starting_balance = cfg[0]
	GameState.time_remaining = float(cfg[1])
	GameState.active_bets = {}
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	AudioManager.play_ui("button_click")
	get_tree().quit()
