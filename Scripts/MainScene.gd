extends Node2D

@onready var balance_label: Label = $CanvasLayer/UI_Layer/BalanceLabel
@onready var timer_label: Label = $CanvasLayer/UI_Layer/TimerLabel
@onready var luck_label: Label = $CanvasLayer/UI_Layer/LuckLabel

@onready var chip_1000: TextureRect = $CanvasLayer/UI_Layer/ChipTray/Chip1000
@onready var chip_5000: TextureRect = $CanvasLayer/UI_Layer/ChipTray/Chip5000
@onready var chip_25000: TextureRect = $CanvasLayer/UI_Layer/ChipTray/Chip25000

# References to your lever nodes
@onready var spin_lever: AnimatedSprite2D = $CanvasLayer/UI_Layer/ChipTray/SpinLever

var is_spinning: bool = false

func _ready() -> void:
	chip_1000.gui_input.connect(func(event: InputEvent): _on_chip_gui_input(event, 1000))
	chip_5000.gui_input.connect(func(event: InputEvent): _on_chip_gui_input(event, 5000))
	chip_25000.gui_input.connect(func(event: InputEvent): _on_chip_gui_input(event, 25000))
	
	# Connect the animation finished signal to handle post-pull logic
	spin_lever.animation_finished.connect(_on_lever_animation_finished)
	
	# Start looping the idle animation (first 8 frames)
	spin_lever.play("idle")

func _on_chip_gui_input(event: InputEvent, amount: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_chip_selected(amount)

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

# Triggered when clicking the Area2D shape over the lever
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if is_spinning:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameState.active_bets.is_empty():
			print("Place a bet first!")
			return

		var total_bet: int = 0
		for amount in GameState.active_bets.values():
			total_bet += amount
		if total_bet < GameState.table_min_bet:
			print("Total bets ($", total_bet, ") are below the table minimum of $", GameState.table_min_bet, "!")
			return

		is_spinning = true
		# Play the pull animation (remaining frames)
		spin_lever.play("pull")

# Triggered automatically when the 'pull' animation completes
func _on_lever_animation_finished() -> void:
	if spin_lever.animation == "pull":
		execute_spin_logic()
		
		# Return back to idle loop and allow pulling again
		spin_lever.play("idle")
		is_spinning = false

## Returns the total payout a given wheel number would produce for current active bets.
func _calculate_payout_for_number(num: int, red_numbers: Array, black_numbers: Array) -> int:
	var win_str = str(num)
	if num == 0:
		win_str = "zero"
	elif num == 37:
		win_str = "doublezero"

	var is_even = (num != 0 and num != 37 and num % 2 == 0)
	var is_odd  = (num != 0 and num != 37 and num % 2 != 0)

	var total: int = 0
	for bet_id in GameState.active_bets.keys():
		var bet_amount: int = GameState.active_bets[bet_id]
		var won := false
		var payout_multiplier := 0

		if bet_id == win_str:
			won = true
			payout_multiplier = 36
		elif num != 0 and num != 37:
			match bet_id:
				"red":
					if num in red_numbers: won = true; payout_multiplier = 2
				"black":
					if num in black_numbers: won = true; payout_multiplier = 2
				"even":
					if is_even: won = true; payout_multiplier = 2
				"odd":
					if is_odd: won = true; payout_multiplier = 2
				"1thu18":
					if num >= 1 and num <= 18: won = true; payout_multiplier = 2
				"19thu38":
					if num >= 19 and num <= 36: won = true; payout_multiplier = 2
				"1st12":
					if num >= 1 and num <= 12: won = true; payout_multiplier = 3
				"2nd12":
					if num >= 13 and num <= 24: won = true; payout_multiplier = 3
				"3rd12":
					if num >= 25 and num <= 36: won = true; payout_multiplier = 3
				"row1":
					if num % 3 == 0: won = true; payout_multiplier = 3
				"row2":
					if num % 3 == 2: won = true; payout_multiplier = 3
				"row3":
					if num % 3 == 1: won = true; payout_multiplier = 3

		if won:
			total += bet_amount * payout_multiplier

	return total


func execute_spin_logic() -> void:
	var red_numbers = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
	var black_numbers = [2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35]

	# --- Luck System ---
	# Find the wheel number that would give the highest return on current bets.
	var best_number: int = randi() % 38
	var best_payout: int = -1
	for candidate in range(38):
		var candidate_payout = _calculate_payout_for_number(candidate, red_numbers, black_numbers)
		if candidate_payout > best_payout:
			best_payout = candidate_payout
			best_number = candidate

	# luck_meter (0–100) is the % chance the result steers toward the best number.
	# At 100% luck the best number always lands; at 0% luck the result is fully random.
	var winning_number: int
	if randf() < (GameState.luck_meter / 100.0):
		winning_number = best_number
		print("★ LUCK (", GameState.luck_meter, "%) steered result to: ", winning_number, " (payout: $", best_payout, ")")
	else:
		winning_number = randi() % 38

	# Convert it to match your exact Bet IDs
	var win_str = str(winning_number)
	if winning_number == 0:
		win_str = "zero"
	elif winning_number == 37:
		win_str = "doublezero"

	print("--- SPINNING THE WHEEL ---")
	print("The winning number is: ", win_str)

	var is_even = (winning_number != 0 and winning_number != 37 and winning_number % 2 == 0)
	var is_odd = (winning_number != 0 and winning_number != 37 and winning_number % 2 != 0)
	
	var total_winnings = 0
	var total_bet = 0

	# 2. Iterate through the ledger and check every bet placed
	for bet_id in GameState.active_bets.keys():
		var bet_amount = GameState.active_bets[bet_id]
		total_bet += bet_amount
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
	var net_loss = total_bet - total_winnings
	if total_winnings > 0:
		# Calculate luck drain BEFORE adding winnings so the ratio uses
		# the pre-win balance (otherwise the payout inflates the divisor).
		var luck_drain: int = clamp(int(float(total_winnings) / float(GameState.balance) * 100.0), 1, 100)
		GameState.luck_meter = max(0, GameState.luck_meter - luck_drain)
		print("Luck drained by ", luck_drain, "% (payout: $", total_winnings, " vs pre-win balance: $", GameState.balance, ")")

		GameState.balance += total_winnings
		print("Total cash forced back into balance: $", total_winnings)
	else:
		print("Excellent! You successfully burned all the bets this round.")

	# Gain luck from any money lost (net loss vs starting balance).
	# Losing 10% of starting balance = +10% luck, capped at 100.
	if net_loss > 0:
		var luck_gain: int = clamp(int(float(net_loss) / float(GameState.starting_balance) * 100.0), 1, 100)
		GameState.luck_meter = min(100, GameState.luck_meter + luck_gain)
		print("Luck gained by ", luck_gain, "% (net loss: $", net_loss, " vs starting balance: $", GameState.starting_balance, ")")

	# Clear the ledger for the next round
	GameState.active_bets.clear()
	
	# Clear all visual chips from the board
	for chip in get_tree().get_nodes_in_group("placed_chips"):
		chip.queue_free()


func _on_control_gui_input(event: InputEvent) -> void:
	if is_spinning:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameState.active_bets.is_empty():
			print("Place a bet first!")
			return

		var total_bet: int = 0
		for amount in GameState.active_bets.values():
			total_bet += amount
		if total_bet < GameState.table_min_bet:
			print("Total bets ($", total_bet, ") are below the table minimum of $", GameState.table_min_bet, "!")
			return

		is_spinning = true
		spin_lever.play("pull")
