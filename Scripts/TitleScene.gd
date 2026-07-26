extends Node2D

@onready var play_button: TextureButton = $CanvasLayer/PlayButton


func _ready() -> void:
	AudioManager.start_wind_ambience()
	play_button.pressed.connect(_on_play_pressed)
	play_button.mouse_entered.connect(func() -> void: AudioManager.play_ui("button_hover"))


func _on_play_pressed() -> void:
	AudioManager.play_ui("button_click")
	AudioManager.stop_ambience()
	get_tree().change_scene_to_file("res://IntroScene.tscn")
