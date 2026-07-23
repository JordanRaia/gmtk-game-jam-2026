extends Control

const SCROLL_DURATION: float = 0.6

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
@onready var digits: Array = [
	$Digits/Digit1, $Digits/Digit2, $Digits/Digit3,
	$Digits/Digit4, $Digits/Digit5, $Digits/Digit6,
	$Digits/Digit7, $Digits/Digit8, $Digits/Digit9,
	$Digits/Digit10
]

var _display_balance: float = 0.0
var _target_balance: int = 0
var _scroll_elapsed: float = 0.0
var _scroll_from: float = 0.0

func _ready() -> void:
	_display_balance = float(clamp(GameState.balance, 0, 9999999))
	_target_balance = GameState.balance
	update_display()

func _process(delta: float) -> void:
	var real_target: int = clamp(GameState.balance, 0, 9999999)
	if real_target != _target_balance:
		_scroll_from = _display_balance
		_target_balance = real_target
		_scroll_elapsed = 0.0

	if _scroll_elapsed < SCROLL_DURATION:
		_scroll_elapsed += delta
		var t: float = clamp(_scroll_elapsed / SCROLL_DURATION, 0.0, 1.0)
		# Ease-out cubic so it decelerates into the final value
		t = 1.0 - pow(1.0 - t, 3.0)
		_display_balance = lerpf(_scroll_from, float(_target_balance), t)

	update_display()

func update_display() -> void:
	if digits.is_empty() or digits[0] == null:
		return
	set_number_textures(roundi(_display_balance), digits)

func set_number_textures(value: int, digit_nodes: Array) -> void:
	# Build formatted string: e.g. 1000 -> "$1,000", 1000000 -> "$1,000,000"
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
