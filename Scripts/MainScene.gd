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
	
	luck_label.text = "LUCK: %d%%" % GameState.luck_meter

func _on_spin_button_pressed() -> void:
	if GameState.active_bets.is_empty():
		print("Place a bet first!")
		return

	# 1. Pick a random number between 0 and 37 (37 represents '00')
	var winning_number = randi() % 38
	
	# Convert it to match your exact Bet IDs
	var win_str = str(winning_number)
	if winning_number == 0:
		win_str = "zero"
	elif winning_number == 37:
		win_str = "doublezero"

	print("--- SPINNING THE WHEEL ---")
	print("The winning number is: ", win_str)

	# Define standard roulette properties for the outside bets
	var red_numbers = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
	var black_numbers = [2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35]
	var is_even = (winning_number != 0 and winning_number != 37 and winning_number % 2 == 0)
	var is_odd = (winning_number != 0 and winning_number != 37 and winning_number % 2 != 0)
	
	var total_winnings = 0

	# 2. Iterate through the ledger and check every bet placed
	for bet_id in GameState.active_bets.keys():
		var bet_amount = GameState.active_bets[bet_id]
		var won = false
		var payout_multiplier = 0 # Total return (winnings + original bet)

		# Check Straight Up (Single Number) Bets
		if bet_id == win_str:
			won = true
			payout_multiplier = 36 # 35 to 1 payout + original bet back
			
		# Check Outside Bets (only valid if it isn't 0 or 00)
		elif winning_number != 0 and winning_number != 37:
			match bet_id:
				"red":
					if winning_number in red_numbers: won = true; payout_multiplier = 2
				"black":
					if winning_number in black_numbers: won = true; payout_multiplier = 2
				"even":
					if is_even: won = true; payout_multiplier = 2
				"odd":
					if is_odd: won = true; payout_multiplier = 2
				"1thu18":
					if winning_number >= 1 and winning_number <= 18: won = true; payout_multiplier = 2
				"19thu38":
					if winning_number >= 19 and winning_number <= 36: won = true; payout_multiplier = 2
				"1st12":
					if winning_number >= 1 and winning_number <= 12: won = true; payout_multiplier = 3
				"2nd12":
					if winning_number >= 13 and winning_number <= 24: won = true; payout_multiplier = 3
				"3rd12":
					if winning_number >= 25 and winning_number <= 36: won = true; payout_multiplier = 3
				"row1":
					# Top row on board (3, 6, 9, etc.)
					if winning_number % 3 == 0: won = true; payout_multiplier = 3
				"row2":
					# Middle row on board (2, 5, 8, etc.)
					if winning_number % 3 == 2: won = true; payout_multiplier = 3
				"row3":
					# Bottom row on board (1, 4, 7, etc.)
					if winning_number % 3 == 1: won = true; payout_multiplier = 3

		# 3. Calculate the punishment
		if won:
			var winnings = bet_amount * payout_multiplier
			total_winnings += winnings
			print("FAILED (WON) bet on ", bet_id, "! Adding $", winnings, " back.")
		else:
			print("SUCCESS (LOST) bet on ", bet_id, "! Money burned.")

	# 4. Finalize the Round
	if total_winnings > 0:
		GameState.balance += total_winnings
		
		# Drain the luck meter for winning!
		GameState.luck_meter -= 5
		print("Total cash forced back into balance: $", total_winnings)
	else:
		print("Excellent! You successfully burned all the bets this round.")

	# Clear the ledger for the next round
	GameState.active_bets.clear()