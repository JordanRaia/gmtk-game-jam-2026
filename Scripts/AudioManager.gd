extends Node

const STREAMS_UI: Dictionary = {
	"slide_advance": preload("res://Assets/Audio/sfx_slide_advance.ogg"),
	"button_click": preload("res://Assets/Audio/sfx_button_click.ogg"),
	"button_hover": preload("res://Assets/Audio/sfx_button_hover.ogg"),
	"pause_open": preload("res://Assets/Audio/sfx_pause_open.ogg"),
	"pause_close": preload("res://Assets/Audio/sfx_pause_close.ogg"),
	"game_over": preload("res://Assets/Audio/sfx_game_over.ogg"),
	"win_fanfare": preload("res://Assets/Audio/sfx_win_fanfare.ogg"),
	"error": preload("res://Assets/Audio/sfx_error.ogg"),
	"chip_pickup": preload("res://Assets/Audio/sfx_chip_pickup.ogg"),
	"chip_drop_invalid": preload("res://Assets/Audio/sfx_chip_drop_invalid.ogg"),
	"timer_expired": preload("res://Assets/Audio/sfx_timer_expired.ogg"),
}

const STREAMS_WORLD: Dictionary = {
	"chip_drop": preload("res://Assets/Audio/sfx_chip_drop.ogg"),
	"chips_reset": preload("res://Assets/Audio/sfx_chips_reset.ogg"),
	"lever_pull": preload("res://Assets/Audio/sfx_lever_pull.ogg"),
	"ball_bouncing": preload("res://Assets/Audio/sfx_ball_bouncing.ogg"),
	"ball_lands": preload("res://Assets/Audio/sfx_ball_lands.ogg"),
}

## Volume offsets in dB per sound key. 0.0 = unchanged. Negative = quieter.
const VOLUME_OFFSETS: Dictionary = {
	# UI
	"button_hover": - 28.0,
	"button_click": - 4.0,
	"slide_advance": - 8.0,
	"error": - 10.0,
	# Ambience (Ambience bus is already at -12 dB; these fine-tune on top)
	"ambience_casino": - 8.0, # -20 dB total
	"ambience_wind": 0.0, # -12 dB total
	# Casino / World
	"chip_drop": - 8.0,
	"chips_reset": - 8.0,
	"lever_pull": - 8.0,
	"ball_bouncing": - 8.0,
	"ball_lands": - 8.0,
}

const POOL_SIZE: int = 8

var _ui_pool: Array[AudioStreamPlayer] = []
var _world_pool: Array[AudioStreamPlayer] = []
var _ui_pool_index: int = 0
var _world_pool_index: int = 0

var _wheel_loop_player: AudioStreamPlayer
var _timer_loop_player: AudioStreamPlayer
var _fanfare_player: AudioStreamPlayer
var _casino_ambience_player: AudioStreamPlayer
var _wind_ambience_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i: int in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX_UI"
		add_child(p)
		_ui_pool.append(p)

	for i: int in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX_World"
		add_child(p)
		_world_pool.append(p)

	var wheel_stream := preload("res://Assets/Audio/sfx_wheel_spin_loop.ogg") as AudioStreamOggVorbis
	wheel_stream.loop = true
	_wheel_loop_player = AudioStreamPlayer.new()
	_wheel_loop_player.bus = &"SFX_World"
	_wheel_loop_player.stream = wheel_stream
	add_child(_wheel_loop_player)

	var timer_stream := preload("res://Assets/Audio/sfx_timer_tick_loop.ogg") as AudioStreamOggVorbis
	timer_stream.loop = true
	_timer_loop_player = AudioStreamPlayer.new()
	_timer_loop_player.bus = &"SFX_UI"
	_timer_loop_player.stream = timer_stream
	add_child(_timer_loop_player)

	_fanfare_player = AudioStreamPlayer.new()
	_fanfare_player.bus = &"SFX_UI"
	_fanfare_player.stream = preload("res://Assets/Audio/sfx_win_fanfare.ogg")
	_fanfare_player.volume_db = VOLUME_OFFSETS.get("win_fanfare", 0.0)
	add_child(_fanfare_player)

	var casino_stream := preload("res://Assets/Audio/ambience_casino.ogg") as AudioStreamOggVorbis
	casino_stream.loop = true
	_casino_ambience_player = AudioStreamPlayer.new()
	_casino_ambience_player.bus = &"Ambience"
	_casino_ambience_player.stream = casino_stream
	_casino_ambience_player.volume_db = VOLUME_OFFSETS.get("ambience_casino", 0.0)
	add_child(_casino_ambience_player)

	var wind_stream := preload("res://Assets/Audio/ambience_wind.ogg") as AudioStreamOggVorbis
	wind_stream.loop = true
	_wind_ambience_player = AudioStreamPlayer.new()
	_wind_ambience_player.bus = &"Ambience"
	_wind_ambience_player.stream = wind_stream
	_wind_ambience_player.volume_db = VOLUME_OFFSETS.get("ambience_wind", 0.0)
	add_child(_wind_ambience_player)


func play_ui(key: String) -> void:
	if not STREAMS_UI.has(key):
		push_warning("AudioManager: unknown UI sound key: " + key)
		return
	if key == "win_fanfare":
		_fanfare_player.stop()
		_fanfare_player.play()
		return
	var player := _get_next_player(_ui_pool, _ui_pool_index)
	_ui_pool_index = (_ui_pool_index + 1) % POOL_SIZE
	player.stream = STREAMS_UI[key]
	player.volume_db = VOLUME_OFFSETS.get(key, 0.0)
	player.play()


func play_world(key: String) -> void:
	if not STREAMS_WORLD.has(key):
		push_warning("AudioManager: unknown World sound key: " + key)
		return
	var player := _get_next_player(_world_pool, _world_pool_index)
	_world_pool_index = (_world_pool_index + 1) % POOL_SIZE
	player.stream = STREAMS_WORLD[key]
	player.volume_db = VOLUME_OFFSETS.get(key, 0.0)
	player.play()


func _get_next_player(pool: Array[AudioStreamPlayer], preferred_index: int) -> AudioStreamPlayer:
	# Try to find a free player first
	for p: AudioStreamPlayer in pool:
		if not p.playing:
			return p
	# All busy — steal the next in round-robin order
	var stolen: AudioStreamPlayer = pool[preferred_index]
	stolen.stop()
	return stolen


func start_wheel_spin() -> void:
	if not _wheel_loop_player.playing:
		_wheel_loop_player.play()


func stop_wheel_spin() -> void:
	_wheel_loop_player.stop()


func start_timer_tick() -> void:
	if not _timer_loop_player.playing:
		_timer_loop_player.play()


func stop_timer_tick() -> void:
	if _timer_loop_player.playing:
		_timer_loop_player.stop()


func start_casino_ambience() -> void:
	_wind_ambience_player.stop()
	if not _casino_ambience_player.playing:
		_casino_ambience_player.play()


func start_wind_ambience() -> void:
	_casino_ambience_player.stop()
	if not _wind_ambience_player.playing:
		_wind_ambience_player.play()


func stop_ambience() -> void:
	_casino_ambience_player.stop()
	_wind_ambience_player.stop()


func stop_all() -> void:
	for p: AudioStreamPlayer in _ui_pool:
		p.stop()
	for p: AudioStreamPlayer in _world_pool:
		p.stop()
	_wheel_loop_player.stop()
	_timer_loop_player.stop()
	_fanfare_player.stop()
	_casino_ambience_player.stop()
	_wind_ambience_player.stop()
