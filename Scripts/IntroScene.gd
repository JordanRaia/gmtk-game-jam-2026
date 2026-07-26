extends Node2D

const SLIDE_1 := preload("res://Assets/art/introscene1.png")
const SLIDE_2 := preload("res://Assets/art/introscene2.png")
const SLIDE_3 := preload("res://Assets/art/introscene3.png")
const SLIDE_4 := preload("res://Assets/art/introscene4.png")

const TEXT_ANIM_FPS: float = 12.0
const POST_ANIM_WAIT: float = 1.0
const FADE_TIME: float = 0.4
const DRIFT_AMOUNT: float = 20.0
const DRIFT_SPEED: float = 6.0
# Per-scene text overlay config.
# margin_b — gap (px) between the bottom of the text and the bottom of the screen.
const TEXT_CONFIG: Array = [
	{"margin_b": 10.0}, # scene 1
	{"margin_b": 100.0}, # scene 2
	{"margin_b": 40.0}, # scene 3
	{"margin_b": 10.0}, # scene 4
]

enum TextState {ANIMATING, DONE, TRANSITIONING}

var slides: Array[Texture2D] = []
var current_index: int = 0
var text_frames: Array[Texture2D] = []
var text_frame_index: int = 0
var text_state: TextState = TextState.ANIMATING
var drift_tween: Tween
var fade_tween: Tween

@onready var scene_image: TextureRect = $CanvasLayer/SceneImage
@onready var fade_overlay: ColorRect = $CanvasLayer/FadeOverlay
@onready var text_overlay: TextureRect = $CanvasLayer/TextOverlay
@onready var auto_timer: Timer = $CanvasLayer/AutoTimer
@onready var text_anim_timer: Timer = $CanvasLayer/TextAnimTimer

func _ready() -> void:
	slides = [SLIDE_1, SLIDE_2, SLIDE_3, SLIDE_4]
	auto_timer.timeout.connect(_on_auto_timer_timeout)
	text_anim_timer.timeout.connect(_on_text_anim_timer_timeout)
	fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	AudioManager.start_music()
	_show_slide(0)
	_fade_in()

func _load_text_frames(slide_index: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var scene_num := slide_index + 1
	var base_name := "mikutxtscene%d" % scene_num
	var folder := "res://Assets/art/mikutextscene%d/" % scene_num
	var i := 0
	while true:
		var path := "%s%s_%04d.png" % [folder, base_name, i]
		if not ResourceLoader.exists(path):
			break
		frames.append(load(path) as Texture2D)
		i += 1
	return frames

func _position_text_overlay() -> void:
	if text_frames.is_empty():
		return
	var cfg: Dictionary = TEXT_CONFIG[current_index]
	var display_w := float(text_frames[0].get_width())
	var display_h := float(text_frames[0].get_height())
	var x := (1280.0 - display_w) * 0.5
	var y := 720.0 - display_h - float(cfg.margin_b)
	text_overlay.offset_left = x
	text_overlay.offset_top = y
	text_overlay.offset_right = x + display_w
	text_overlay.offset_bottom = y + display_h

func _show_slide(index: int) -> void:
	scene_image.texture = slides[index]
	text_frames = _load_text_frames(index)
	text_frame_index = 0
	text_state = TextState.ANIMATING
	if text_frames.size() > 0:
		text_overlay.texture = text_frames[0]
		_position_text_overlay()
	else:
		text_overlay.texture = null
	text_anim_timer.wait_time = 1.0 / TEXT_ANIM_FPS
	text_anim_timer.start()
	_start_drift()

func _start_drift() -> void:
	if drift_tween:
		drift_tween.kill()
	drift_tween = create_tween()
	var tween_duration: float = (DRIFT_AMOUNT * 2.0) / DRIFT_SPEED
	var cx: float = - (scene_image.size.x - 1280.0) * 0.5
	var cy: float = - (scene_image.size.y - 720.0) * 0.5
	scene_image.position = Vector2(cx - DRIFT_AMOUNT, cy)
	drift_tween.tween_property(scene_image, "position", Vector2(cx + DRIFT_AMOUNT, cy), tween_duration) \
		.set_trans(Tween.TRANS_LINEAR)

func _fade_in() -> void:
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "color:a", 0.0, FADE_TIME)

func _on_text_anim_timer_timeout() -> void:
	if text_state != TextState.ANIMATING:
		return
	text_frame_index += 1
	if text_frame_index >= text_frames.size():
		text_anim_timer.stop()
		text_frame_index = text_frames.size() - 1
		text_overlay.texture = text_frames[text_frame_index]
		text_state = TextState.DONE
		auto_timer.start(POST_ANIM_WAIT)
	else:
		text_overlay.texture = text_frames[text_frame_index]

func _on_auto_timer_timeout() -> void:
	_advance_slide()

func _advance_slide() -> void:
	AudioManager.play_ui("slide_advance")
	text_state = TextState.TRANSITIONING
	auto_timer.stop()
	text_anim_timer.stop()
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
	_fade_in()

func _input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		pressed = key_event.pressed and not key_event.echo

	if not pressed:
		return

	match text_state:
		TextState.ANIMATING:
			text_anim_timer.stop()
			auto_timer.stop()
			text_frame_index = text_frames.size() - 1
			text_overlay.texture = text_frames[text_frame_index]
			text_state = TextState.DONE
			auto_timer.start(POST_ANIM_WAIT)
		TextState.DONE:
			auto_timer.stop()
			_advance_slide()
		TextState.TRANSITIONING:
			pass
