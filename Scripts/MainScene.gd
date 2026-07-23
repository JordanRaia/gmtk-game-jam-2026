extends Node2D

@onready var balance_label: Label = $CanvasLayer/UI_Layer/BalanceLabel
@onready var timer_label: Label = $CanvasLayer/UI_Layer/TimerLabel
@onready var luck_label: Label = $CanvasLayer/UI_Layer/LuckLabel

@onready var chip_1000: Button = $CanvasLayer/UI_Layer/ChipTray/Chip1000
@onready var chip_5000: Button = $CanvasLayer/UI_Layer/ChipTray/Chip5000
@onready var chip_25000: Button = $CanvasLayer/UI_Layer/ChipTray/Chip25000

func _ready() -> void:
	chip_1000.pressed.connect(func(): _on_chip_selected(1000))
	chip_5000.pressed.connect(func(): _on_chip_selected(5000))
	chip_25000.pressed.connect(func(): _on_chip_selected(25000))

func _on_chip_selected(amount: int) -> void:
	GameState.current_selected_chip = amount
	print("Selected chip value: ", GameState.current_selected_chip)

func _process(delta: float) -> void:
	balance_label.text = "BALANCE: $%d" % GameState.balance
	
	if GameState.time_remaining > 0:
		GameState.time_remaining -= delta
	
	var minutes = int(GameState.time_remaining) / 60
	var seconds = int(GameState.time_remaining) % 60
	timer_label.text = "TIME: %02d:%02d" % [minutes, seconds]
	
	luck_label.text = "LUCK: %d%" % GameState.luck_meter