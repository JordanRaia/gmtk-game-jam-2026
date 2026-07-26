extends Control


func _ready() -> void:
	visible = false
	_connect_button_hovers(self)


func _connect_button_hovers(node: Node) -> void:
	for child: Node in node.get_children():
		if child is TextureButton:
			child.mouse_entered.connect(func() -> void: AudioManager.play_ui("button_hover"))
		_connect_button_hovers(child)


func show_pause() -> void:
	AudioManager.play_ui("pause_open")
	visible = true
	get_tree().paused = true


func hide_pause() -> void:
	AudioManager.play_ui("pause_close")
	visible = false
	get_tree().paused = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if visible:
			hide_pause()
		else:
			show_pause()


func _on_continue_pressed() -> void:
	AudioManager.play_ui("button_click")
	hide_pause()


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
