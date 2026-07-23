extends Control

@export var min_value: int = 1000:
	set(value):
		min_value = value
		update_board()

@export var max_value: int = 250000:
	set(value):
		max_value = value
		update_board()

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

# Connected to your newly named nodes (Digit1 is left-most, Digit6 is right-most)
@onready var min_digits = [
	$Min/Digit1, $Min/Digit2, $Min/Digit3,
	$Min/Digit4, $Min/Digit5, $Min/Digit6
]

@onready var max_digits = [
	$Max/Digit1, $Max/Digit2, $Max/Digit3,
	$Max/Digit4, $Max/Digit5, $Max/Digit6
]

func _ready() -> void:
	update_board()

func update_board() -> void:
	if min_digits.is_empty() or min_digits[0] == null:
		return
	
	var safe_min = clamp(min_value, 0, 999999)
	var safe_max = clamp(max_value, 0, 999999)
	
	set_number_textures(safe_min, min_digits)
	set_number_textures(safe_max, max_digits)

func set_number_textures(value: int, digit_nodes: Array) -> void:
	# Convert the value into a string (e.g. 1000 becomes "1000")
	var value_str = str(value)
	
	# Pad with leading zeros if it's less than 6 digits (e.g., "001000")
	while value_str.length() < digit_nodes.size():
		value_str = "0" + value_str
	
	# Assign each character of the string to the corresponding node from left to right
	for i in range(digit_nodes.size()):
		var digit_char = value_str[i]
		var digit_int = digit_char.to_int()
		digit_nodes[i].texture = number_textures[digit_int]