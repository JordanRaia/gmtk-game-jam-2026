extends Node2D

signal spin_finished(winning_number: int)

# Standard American roulette wheel order clockwise (37 = doublezero)
const WHEEL_ORDER: Array[int] = [
	0, 28, 9, 26, 30, 11, 7, 20, 32, 17, 5, 22, 34, 15, 3, 24,
	36, 13, 1, 37, 27, 10, 25, 29, 12, 8, 19, 31, 18, 6, 21, 33,
	16, 4, 23, 35, 14, 2
]

const SLOT_ANGLE_DEG: float = 360.0 / 38.0

@export var orbit_radius: float = 120.0
@export var spin_duration: float = 3.5
@export var full_spins: int = 5
## Rotate this until the ball lands on the correct slot on your wheel image.
## -90 = slot 0 (zero) sits at 12 o'clock.
@export var angle_offset_deg: float = -90.0
## Set to true if your wheel image numbers increase clockwise, false for CCW.
@export var clockwise: bool = true

@onready var ball: Sprite2D = $Ball

var _angle_deg: float = 0.0


func start_spin(target_number: int) -> void:
	var target_idx: int = WHEEL_ORDER.find(target_number)
	if target_idx == -1:
		target_idx = 0

	var direction: float = 1.0 if clockwise else -1.0
	var target_angle: float = angle_offset_deg + direction * float(target_idx) * SLOT_ANGLE_DEG

	var current_norm: float = fmod(_angle_deg, 360.0)
	if current_norm < 0.0:
		current_norm += 360.0

	var target_norm: float = fmod(target_angle, 360.0)
	if target_norm < 0.0:
		target_norm += 360.0

	var delta: float = target_norm - current_norm
	if delta < 0.0:
		delta += 360.0

	# Always spin in the clockwise direction for the visual
	var total_end: float = _angle_deg + float(full_spins) * 360.0 + delta

	var tween: Tween = create_tween()
	tween.tween_property(self, "_angle_deg", total_end, spin_duration) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func() -> void: spin_finished.emit(target_number))


func _process(_delta: float) -> void:
	if ball == null:
		return
	var rad: float = deg_to_rad(_angle_deg)
	ball.position = Vector2(cos(rad), sin(rad)) * orbit_radius
