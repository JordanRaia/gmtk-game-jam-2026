extends Control

## Emitted after the player picks an item so MainScene can unpause.
signal panel_closed

@onready var item_button_0: Control = $ItemButton0
@onready var item_button_1: Control = $ItemButton1
@onready var item_button_2: Control = $ItemButton2

var _buttons: Array[Control] = []
var _closing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_buttons = [item_button_0, item_button_1, item_button_2]
	for btn: Control in _buttons:
		btn.item_picked.connect(_on_item_picked)


## Called by MainScene. Populates the 3 slots and shows the panel.
func open(offered: Array[String]) -> void:
	_closing = false
	for i: int in range(3):
		_buttons[i].setup(offered[i])
	modulate.a = 0.0
	visible = true
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _on_item_picked(id: String) -> void:
	if _closing:
		return
	_closing = true
	ItemSystem.apply_item(id)
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func() -> void:
		visible = false
		_closing = false
		panel_closed.emit()
	)
