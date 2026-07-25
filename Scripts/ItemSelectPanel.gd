extends Control

## Emitted after the player picks an item so MainScene can unpause.
signal panel_closed

@onready var item_button_0: Control = $ItemButton0
@onready var item_button_1: Control = $ItemButton1
@onready var item_button_2: Control = $ItemButton2

var _buttons: Array[Control] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_buttons = [item_button_0, item_button_1, item_button_2]
	for btn: Control in _buttons:
		btn.item_picked.connect(_on_item_picked)


## Called by MainScene. Populates the 3 slots and shows the panel.
func open(offered: Array[String]) -> void:
	for i: int in range(3):
		_buttons[i].setup(offered[i])
	visible = true


func _on_item_picked(id: String) -> void:
	ItemSystem.apply_item(id)
	visible = false
	panel_closed.emit()
