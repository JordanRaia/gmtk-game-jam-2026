extends Control

const FLASH_THRESHOLD: float = 30.0
const FLASH_SPEED: float = 5.0

var _flash_time: float = 0.0

var number_textures = [
	preload("res://Assets/Numbers/0.png"),
	preload("res://Assets/Numbers/1.png"),
	preload("res://Assets/Numbers/2.png"),
	preload("res://Assets/Numbers/3.png"),
	preload("res://Assets/Numbers/4.png"),
	preload("res://Assets/Numbers/5.png"),
	preload("res://Assets/Numbers/6.png"),
	preload("res://Assets/Numbers/7.png"),
	preload("res://Assets/Numbers/8.png"),
	preload("res://Assets/Numbers/9.png")
]

var colon_texture = preload("res://Assets/Numbers/colon.png")

# Digit1=tens of minutes, Digit2=ones of minutes, Digit3=colon, Digit4=tens of seconds, Digit5=ones of seconds
@onready var digits: Array = [
	$Digits/Digit1, $Digits/Digit2, $Digits/Digit3,
	$Digits/Digit4, $Digits/Digit5
]

func _ready() -> void:
	update_display()

func _process(delta: float) -> void:
	_flash_time += delta
	update_display()
	_update_flash()

func update_display() -> void:
	if digits.is_empty() or digits[0] == null:
		return

	var total_seconds = max(0, int(GameState.time_remaining))
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60

	# Format: MM:SS across 5 nodes
	var chars = [
		str(minutes / 10),
		str(minutes % 10),
		":",
		str(seconds / 10),
		str(seconds % 10)
	]

	for i in range(digits.size()):
		var ch = chars[i]
		if ch == ":":
			digits[i].texture = colon_texture
		else:
			digits[i].texture = number_textures[ch.to_int()]
		digits[i].visible = true

func _update_flash() -> void:
	if digits.is_empty() or digits[0] == null:
		return

	if GameState.time_remaining < FLASH_THRESHOLD:
		var t: float = (sin(_flash_time * FLASH_SPEED) + 1.0) / 2.0
		var flash_color: Color = Color(1.0, t, t, 1.0)
		for d in digits:
			d.modulate = flash_color
	else:
		for d in digits:
			d.modulate = Color.WHITE
