extends Node2D

const SLIDE_1 := preload("res://Assets/art/introscene1.png")
const SLIDE_2 := preload("res://Assets/art/introscene2.png")
const SLIDE_3 := preload("res://Assets/art/introscene3.png")
const SLIDE_4 := preload("res://Assets/art/introscene4.png")

const DISPLAY_TIME: float = 4.0
const FADE_TIME: float = 0.4
const DRIFT_AMOUNT: float = 20.0
const DRIFT_SPEED: float = 6.0  # pixels per second — constant across all slides

var slides: Array[Texture2D] = []
var current_index: int = 0
var is_transitioning: bool = false
var drift_tween: Tween
var fade_tween: Tween

@onready var scene_image: TextureRect = $CanvasLayer/SceneImage
@onready var fade_overlay: ColorRect = $CanvasLayer/FadeOverlay
@onready var auto_timer: Timer = $CanvasLayer/AutoTimer

func _ready() -> void:
	slides = [SLIDE_1, SLIDE_2, SLIDE_3, SLIDE_4]
	auto_timer.timeout.connect(_on_auto_timer_timeout)
	fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	_show_slide(0)
	_fade_in()

func _show_slide(index: int) -> void:
	scene_image.texture = slides[index]
	_start_drift()

func _start_drift() -> void:
	if drift_tween:
		drift_tween.kill()
	drift_tween = create_tween()
	# Duration derived from speed so every slide drifts at exactly the same rate.
	var tween_duration: float = (DRIFT_AMOUNT * 2.0) / DRIFT_SPEED
	var cx: float = -(scene_image.size.x - 1280.0) * 0.5
	var cy: float = -(scene_image.size.y - 720.0) * 0.5
	scene_image.position = Vector2(cx - DRIFT_AMOUNT, cy)
	drift_tween.tween_property(scene_image, "position", Vector2(cx + DRIFT_AMOUNT, cy), tween_duration) \
		.set_trans(Tween.TRANS_LINEAR)

func _fade_in() -> void:
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "color:a", 0.0, FADE_TIME)
	fade_tween.tween_callback(func() -> void: auto_timer.start(DISPLAY_TIME))

func _advance() -> void:
	AudioManager.play_ui("slide_advance")
	if is_transitioning:
		return
	is_transitioning = true
	auto_timer.stop()
	if drift_tween:
		drift_tween.kill()
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "color:a", 1.0, FADE_TIME)
	fade_tween.tween_callback(_on_fade_out_done)

func _on_fade_out_done() -> void:
	current_index += 1
	if current_index >= slides.size():
		get_tree().change_scene_to_file("res://MainScene.tscn")
		return
	_show_slide(current_index)
	is_transitioning = false
	_fade_in()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			_advance()
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_advance()

func _on_auto_timer_timeout() -> void:
	_advance()
