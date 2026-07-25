extends Control

@onready var win_anim: AnimatedSprite2D = $WinAnim
@onready var next_button: TextureButton = $NextButton


func _ready() -> void:
	visible = false
	next_button.visible = false
	next_button.pressed.connect(_on_next_pressed)
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_win_screen() -> void:
	modulate.a = 0.0
	visible = true
	next_button.visible = false
	get_tree().paused = true
	win_anim.sprite_frames.set_animation_loop("show", true)
	win_anim.play("show")
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func() -> void: next_button.visible = true)


func _on_next_pressed() -> void:
	next_button.visible = false
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func() -> void:
		get_tree().paused = false
		GameState.current_stage += 1
		var cfg: Array = GameState.get_stage_config()
		GameState.balance = cfg[0]
		GameState.starting_balance = cfg[0]
		GameState.time_remaining = float(cfg[1])
		GameState.active_bets = {}
		ItemSystem.reset_for_stage()
		get_tree().reload_current_scene()
	)
