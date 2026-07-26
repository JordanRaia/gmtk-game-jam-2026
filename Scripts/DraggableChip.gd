extends TextureRect

@export var chip_value: int = 1000

const SPARKLE_TEXTURES: Array[String] = [
	"res://Assets/art/sparkleanim/sparkleanim_0000.png",
	"res://Assets/art/sparkleanim/sparkleanim_0001.png",
	"res://Assets/art/sparkleanim/sparkleanim_0002.png",
	"res://Assets/art/sparkleanim/sparkleanim_0003.png",
	"res://Assets/art/sparkleanim/sparkleanim_0004.png",
	"res://Assets/art/sparkleanim/sparkleanim_0005.png",
	"res://Assets/art/sparkleanim/sparkleanim_0006.png",
	"res://Assets/art/sparkleanim/sparkleanim_0007.png",
]

const SPARKLE_FPS: float = 14.0
const SPARKLE_SIZE: float = 22.0
const IDLE_MIN: float = 5.0
const IDLE_MAX: float = 14.0

var _loaded_frames: Array[Texture2D] = []
var _sparkle_rect: TextureRect = null
var _sparkle_playing: bool = false
var _sparkle_frame: int = 0
var _sparkle_elapsed: float = 0.0
var _idle_timer: float = 0.0
var _idle_wait: float = 0.0


func _ready() -> void:
	_preload_frames()
	_sparkle_rect = TextureRect.new()
	_sparkle_rect.size = Vector2(SPARKLE_SIZE, SPARKLE_SIZE)
	_sparkle_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sparkle_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sparkle_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sparkle_rect.modulate = Color.TRANSPARENT
	add_child(_sparkle_rect)
	_randomize_idle()


func _preload_frames() -> void:
	for path: String in SPARKLE_TEXTURES:
		_loaded_frames.append(load(path) as Texture2D)


func _randomize_idle() -> void:
	# Stagger initial wait so chips don't all sparkle at the same time.
	_idle_wait = randf_range(IDLE_MIN, IDLE_MAX)
	_idle_timer = randf_range(0.0, _idle_wait)


func _process(delta: float) -> void:
	if _sparkle_rect == null or _loaded_frames.is_empty():
		return

	if _sparkle_playing:
		_sparkle_elapsed += delta
		if _sparkle_elapsed >= 1.0 / SPARKLE_FPS:
			_sparkle_elapsed -= 1.0 / SPARKLE_FPS
			_sparkle_frame += 1
			if _sparkle_frame >= _loaded_frames.size():
				_sparkle_playing = false
				_sparkle_rect.modulate = Color.TRANSPARENT
				_randomize_idle()
			else:
				_sparkle_rect.texture = _loaded_frames[_sparkle_frame]
	else:
		_idle_timer += delta
		if _idle_timer >= _idle_wait:
			_play_sparkle()


func _play_sparkle() -> void:
	_sparkle_playing = true
	_sparkle_frame = 0
	_sparkle_elapsed = 0.0

	# Pick a random position within the chip bounds, keeping sparkle fully inside.
	var max_x: float = maxf(size.x - SPARKLE_SIZE, 0.0)
	var max_y: float = maxf(size.y - SPARKLE_SIZE, 0.0)
	_sparkle_rect.position = Vector2(randf_range(0.0, max_x), randf_range(0.0, max_y))
	_sparkle_rect.texture = _loaded_frames[0]
	_sparkle_rect.modulate = Color.WHITE


func _get_drag_data(_at_position: Vector2) -> Variant:
	AudioManager.play_ui("chip_pickup")
	var preview_texture := TextureRect.new()
	preview_texture.texture = texture
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var drag_size: Vector2 = size / 4.0
	preview_texture.size = drag_size

	var preview_control := Control.new()
	preview_control.z_index = 4096
	preview_control.add_child(preview_texture)
	preview_texture.position = -0.5 * drag_size

	set_drag_preview(preview_control)

	return {"amount": chip_value, "texture": texture}
