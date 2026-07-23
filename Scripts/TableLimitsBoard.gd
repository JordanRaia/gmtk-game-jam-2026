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

var dollar_texture = preload("res://Assets/Numbers/dollar.png")
var comma_texture = preload("res://Assets/Numbers/comma.png")

# Digit1 is left-most, Digit10 is right-most
@onready var min_digits = [
	$Min/Digit1, $Min/Digit2, $Min/Digit3,
	$Min/Digit4, $Min/Digit5, $Min/Digit6,
	$Min/Digit7, $Min/Digit8, $Min/Digit9,
	$Min/Digit10
]

@onready var max_digits = [
	$Max/Digit1, $Max/Digit2, $Max/Digit3,
	$Max/Digit4, $Max/Digit5, $Max/Digit6,
	$Max/Digit7, $Max/Digit8, $Max/Digit9,
	$Max/Digit10
]

func _ready() -> void:
	update_board()

func update_board() -> void:
	if min_digits.is_empty() or min_digits[0] == null:
		return
	
	# $9,999,999 = 10 chars, which is the max for 10 nodes
	var safe_min = clamp(min_value, 0, 9999999)
	var safe_max = clamp(max_value, 0, 9999999)
	
	set_number_textures(safe_min, min_digits)
	set_number_textures(safe_max, max_digits)

func set_number_textures(value: int, digit_nodes: Array) -> void:
	# Build formatted string e.g. 1000 -> "$1,000", 1000000 -> "$1,000,000"
	var value_str = str(value)
	var formatted = "$"
	for i in range(value_str.length()):
		formatted += value_str[i]
		var remaining = value_str.length() - i - 1
		if remaining > 0 and remaining % 3 == 0:
			formatted += ","
	
	# Assign each character to a node left-aligned; hide unused nodes on the right
	for i in range(digit_nodes.size()):
		if i < formatted.length():
			var ch = formatted[i]
			if ch == "$":
				digit_nodes[i].texture = dollar_texture
			elif ch == ",":
				digit_nodes[i].texture = comma_texture
			else:
				digit_nodes[i].texture = number_textures[ch.to_int()]
			digit_nodes[i].visible = true
		else:
			digit_nodes[i].visible = false
