extends Control

@onready var win_anim: AnimatedSprite2D = $WinAnim
@onready var next_button: TextureButton = $NextButton


func _ready() -> void:
	visible = false
	next_button.visible = false
	next_button.pressed.connect(_on_next_pressed)
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_win_screen() -> void:
	visible = true
	next_button.visible = true
	get_tree().paused = true
	win_anim.sprite_frames.set_animation_loop("show", true)
	win_anim.play("show")


func _on_next_pressed() -> void:
	get_tree().paused = false
	GameState.current_stage += 1
	var cfg: Array = GameState.get_stage_config()
	GameState.balance = cfg[0]
	GameState.starting_balance = cfg[0]
	GameState.time_remaining = float(cfg[1])
	GameState.active_bets = {}
	ItemSystem.reset_for_stage()
	get_tree().reload_current_scene()
