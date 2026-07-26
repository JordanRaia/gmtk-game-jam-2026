extends Control

signal tutorial_done

const HIGHLIGHT_COLOR := Color(1.0, 0.9, 0.2, 1.0)
const BORDER_WIDTH := 3.0

var _steps: Array[Dictionary] = []
var _current_step: int = 0
var _highlight_rect: Rect2 = Rect2()
var _clamped_rect: Rect2 = Rect2()
var _active: bool = false

@onready var dim_top: ColorRect = $DimTop
@onready var dim_bottom: ColorRect = $DimBottom
@onready var dim_left: ColorRect = $DimLeft
@onready var dim_right: ColorRect = $DimRight
@onready var dialog_panel: Control = $DialogPanel
@onready var dialog_label: Label = $DialogPanel/Label
@onready var hint_label: Label = $HintLabel


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func start(steps: Array[Dictionary]) -> void:
	_steps = steps
	_current_step = 0
	_active = true
	visible = true
	get_tree().paused = true
	_show_step(0)


func _show_step(index: int) -> void:
	var step: Dictionary = _steps[index]
	_highlight_rect = step.get("rect", Rect2())
	dialog_label.text = step.get("text", "")

	var vp: Vector2 = get_viewport_rect().size
	var hr: Rect2 = _highlight_rect.intersection(Rect2(Vector2.ZERO, vp))
	_clamped_rect = hr
	var has_hl: bool = hr.size.x > 0.0 and hr.size.y > 0.0

	if has_hl:
		dim_top.position = Vector2.ZERO
		dim_top.size = Vector2(vp.x, hr.position.y)
		dim_bottom.position = Vector2(0.0, hr.position.y + hr.size.y)
		dim_bottom.size = Vector2(vp.x, vp.y - dim_bottom.position.y)
		dim_left.position = Vector2(0.0, hr.position.y)
		dim_left.size = Vector2(hr.position.x, hr.size.y)
		dim_right.position = Vector2(hr.position.x + hr.size.x, hr.position.y)
		dim_right.size = Vector2(vp.x - dim_right.position.x, hr.size.y)
	else:
		dim_top.position = Vector2.ZERO
		dim_top.size = vp
		dim_bottom.size = Vector2.ZERO
		dim_left.size = Vector2.ZERO
		dim_right.size = Vector2.ZERO

	queue_redraw()
	_position_dialog(hr, has_hl, vp)

	hint_label.visible = false


func _position_dialog(hr: Rect2, has_hl: bool, vp: Vector2) -> void:
	const DW: float = 580.0
	const DH: float = 130.0
	var dx: float = (vp.x - DW) / 2.0
	var dy: float

	if has_hl:
		var below: float = hr.position.y + hr.size.y + 14.0
		var above: float = hr.position.y - DH - 14.0
		dy = below if below + DH <= vp.y - 40.0 else maxf(6.0, above)
	else:
		dy = (vp.y - DH) / 2.0

	dialog_panel.position = Vector2(dx, dy)
	dialog_panel.size = Vector2(DW, DH)


func _draw() -> void:
	if not _active or _clamped_rect.size.x <= 0.0:
		return
	draw_rect(_clamped_rect, HIGHLIGHT_COLOR, false, BORDER_WIDTH)


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_advance()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			_advance()
			get_viewport().set_input_as_handled()


func _advance() -> void:
	_current_step += 1
	if _current_step >= _steps.size():
		_finish()
		return
	_show_step(_current_step)


func _finish() -> void:
	_active = false
	visible = false
	get_tree().paused = false
	GameState.tutorial_seen = true
	tutorial_done.emit()
