extends Node2D


@onready var pause_menu: Control = $PauseMenuLayer/PauseMenu
@onready var game_over: Control = $GameOverLayer/GameOver

@onready var error_banner: TextureRect = $ErrorBannerLayer/ErrorBanner
@onready var error_label: Label = $ErrorBannerLayer/ErrorLabel

@onready var miku_sprite: AnimatedSprite2D = $MikuLayer/MikuSprite

@onready var chip_1000: TextureRect = $CanvasLayer/UI_Layer/PanelContainer/ChipTray/Chip1000
@onready var chip_5000: TextureRect = $CanvasLayer/UI_Layer/PanelContainer/ChipTray/Chip5000
@onready var chip_25000: TextureRect = $CanvasLayer/UI_Layer/PanelContainer/ChipTray/Chip25000

# References to your lever nodes
@onready var spin_lever: AnimatedSprite2D = $CanvasLayer/UI_Layer/PanelContainer/ChipTray/SpinLever
@onready var table_limits_board: Control = $CanvasLayer/UI_Layer/TableLimitsBoard

# Luck Dial
@onready var luck_dial: TextureRect = $CanvasLayer/UI_Layer/LuckGauge/LuckDial

# Roulette wheel pivot (Node2D at the center of the wheel graphic)
@onready var wheel_pivot: Node2D = $CanvasLayer/WheelPivot

var is_spinning: bool = false
var _game_over_triggered: bool = false
var _error_banner_showing: bool = false
var _miku_showing: bool = false

const LUCK_DIAL_DURATION: float = 0.8
var _display_luck: float = 0.0
var _luck_scroll_from: float = 0.0
var _luck_target: int = 0
var _luck_elapsed: float = 0.0

var _pending_winning_number: int = 0

func _ready() -> void:
	chip_1000.gui_input.connect(func(event: InputEvent): _on_chip_gui_input(event, 1000))
	chip_5000.gui_input.connect(func(event: InputEvent): _on_chip_gui_input(event, 5000))
	chip_25000.gui_input.connect(func(event: InputEvent): _on_chip_gui_input(event, 25000))
	
	# Connect the animation finished signal to handle post-pull logic
	spin_lever.animation_finished.connect(_on_lever_animation_finished)
	
	# Connect the wheel spin finished signal
	wheel_pivot.spin_finished.connect(_on_wheel_spin_finished)
	
	# Start looping the idle animation (first 8 frames)
	spin_lever.play("idle")

	_display_luck = float(GameState.luck_meter)
	_luck_target = GameState.luck_meter

	GameState.show_error.connect(show_error_banner)

	# Park the error banner above the top of the screen
	_set_banner_y(-error_banner.get_texture().get_size().y)

	_check_table_minimum()

func _set_banner_y(y: float) -> void:
	var banner_tex_size: Vector2 = error_banner.get_texture().get_size()
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	var x: float = (viewport_width - banner_tex_size.x) / 2.0
	error_banner.position = Vector2(x, y)
	error_label.position = Vector2(x + 120.0, y + 15.0)

func show_error_banner(message: String) -> void:
	if _error_banner_showing:
		return
	_error_banner_showing = true
	error_label.text = message

	var parked_y: float = - error_banner.get_texture().get_size().y
	var shown_y: float = 20.0
	_set_banner_y(parked_y)

	var tween: Tween = create_tween()
	tween.tween_method(_set_banner_y, parked_y, shown_y, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(2.0)
	tween.tween_method(_set_banner_y, shown_y, parked_y, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func() -> void: _error_banner_showing = false)

func show_miku(happy: bool) -> void:
	if _miku_showing:
		return
	_miku_showing = true

	var anim: String = "happy" if happy else "sad"
	var frame_tex: Texture2D = miku_sprite.sprite_frames.get_frame_texture(anim, 0)
	var scaled_half_width: float = (frame_tex.get_width() * miku_sprite.scale.x) / 2.0
	var parked_x: float = - (scaled_half_width + 20.0)
	var shown_x: float = scaled_half_width

	miku_sprite.position.x = parked_x
	miku_sprite.play(anim)

	var hold_time: float = float(miku_sprite.sprite_frames.get_frame_count(anim)) \
		/ miku_sprite.sprite_frames.get_animation_speed(anim)

	var tween: Tween = create_tween()
	tween.tween_property(miku_sprite, "position:x", shown_x, 0.75) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(hold_time)
	tween.tween_property(miku_sprite, "position:x", parked_x, 0.75) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func() -> void: _miku_showing = false)

func _on_chip_gui_input(event: InputEvent, amount: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_chip_selected(amount)

func _on_chip_selected(amount: int) -> void:
	GameState.current_selected_chip = amount
	print("Selected chip value: ", GameState.current_selected_chip)

func _process(delta: float) -> void:
	if GameState.time_remaining > 0:
		GameState.time_remaining -= delta
	elif not _game_over_triggered:
		_game_over_triggered = true
		game_over.show_game_over()
	
	
	# --- Update Luck Dial Rotation (animated) ---
	var real_luck: int = clamp(GameState.luck_meter, 0, 100)
	if real_luck != _luck_target:
		_luck_scroll_from = _display_luck
		_luck_target = real_luck
		_luck_elapsed = 0.0

	if _luck_elapsed < LUCK_DIAL_DURATION:
		_luck_elapsed += delta
		var t: float = clamp(_luck_elapsed / LUCK_DIAL_DURATION, 0.0, 1.0)
		t = 1.0 - pow(1.0 - t, 3.0)
		_display_luck = lerpf(_luck_scroll_from, float(_luck_target), t)

	var luck_normalized: float = _display_luck / 100.0
	luck_dial.rotation = deg_to_rad(lerp(-90.0, 90.0, luck_normalized))

# Triggered when clicking the Area2D shape over the lever
func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_spinning:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameState.active_bets.is_empty():
			show_error_banner("Place a bet first!")
			return

		var total_bet: int = 0
		for amount in GameState.active_bets.values():
			total_bet += amount
		if total_bet < GameState.table_min_bet:
			show_error_banner("Bet is below table minimum of $" + GameState.format_money(GameState.table_min_bet) + "!")
			return

		is_spinning = true
		# Play the pull animation (remaining frames)
		spin_lever.play("pull")

# Triggered automatically when the 'pull' animation completes
func _on_lever_animation_finished() -> void:
	if spin_lever.animation == "pull":
		_calculate_and_start_spin()

		# Return lever to idle — is_spinning stays true until the ball lands
		spin_lever.play("idle")

## Calculates the winning number using existing luck math, then starts the ball animation.
## Results are NOT applied yet — that happens in _on_wheel_spin_finished.
func _calculate_and_start_spin() -> void:
	var red_numbers: Array = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
	var black_numbers: Array = [2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35]

	# --- Luck System ---
	var best_number: int = randi() % 38
	var best_payout: int = -1
	for candidate in range(38):
		var candidate_payout: int = _calculate_payout_for_number(candidate, red_numbers, black_numbers)
		if candidate_payout > best_payout:
			best_payout = candidate_payout
			best_number = candidate

	var winning_number: int
	if randf() < (GameState.luck_meter / 100.0):
		winning_number = best_number
		print("★ LUCK (", GameState.luck_meter, "%) steered result to: ", winning_number, " (payout: $", best_payout, ")")
	else:
		winning_number = randi() % 38

	_pending_winning_number = winning_number

	var win_str: String = str(winning_number)
	if winning_number == 0:
		win_str = "zero"
	elif winning_number == 37:
		win_str = "doublezero"
	print("--- SPINNING THE WHEEL ---")
	print("The winning number is: ", win_str)

	wheel_pivot.start_spin(winning_number)

## Called when the ball animation finishes landing. Applies all bet results.
func _on_wheel_spin_finished(winning_number: int) -> void:
	_apply_spin_results(winning_number)
	is_spinning = false

## Returns the total payout a given wheel number would produce for current active bets.
func _calculate_payout_for_number(num: int, red_numbers: Array, black_numbers: Array) -> int:
	var win_str: String = str(num)
	if num == 0:
		win_str = "zero"
	elif num == 37:
		win_str = "doublezero"

	var is_even: bool = (num != 0 and num != 37 and num % 2 == 0)
	var is_odd: bool = (num != 0 and num != 37 and num % 2 != 0)

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
					if num >= 25 and num <= 36: won = true; payout_multiplier = 3
				"2nd12":
					if num >= 13 and num <= 24: won = true; payout_multiplier = 3
				"3rd12":
					if num >= 1 and num <= 12: won = true; payout_multiplier = 3
				"row1":
					if num % 3 == 1: won = true; payout_multiplier = 3
				"row2":
					if num % 3 == 2: won = true; payout_multiplier = 3
				"row3":
					if num % 3 == 0: won = true; payout_multiplier = 3

		if won:
			total += bet_amount * payout_multiplier

	return total


func _apply_spin_results(winning_number: int) -> void:
	var red_numbers: Array = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
	var black_numbers: Array = [2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35]

	var win_str: String = str(winning_number)
	if winning_number == 0:
		win_str = "zero"
	elif winning_number == 37:
		win_str = "doublezero"

	var is_even: bool = (winning_number != 0 and winning_number != 37 and winning_number % 2 == 0)
	var is_odd: bool = (winning_number != 0 and winning_number != 37 and winning_number % 2 != 0)

	var total_winnings: int = 0
	var total_bet: int = 0

	for bet_id in GameState.active_bets.keys():
		var bet_amount: int = GameState.active_bets[bet_id]
		total_bet += bet_amount
		var won: bool = false
		var payout_multiplier: int = 0

		if bet_id == win_str:
			won = true
			payout_multiplier = 36

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
					if winning_number >= 25 and winning_number <= 36: won = true; payout_multiplier = 3
				"2nd12":
					if winning_number >= 13 and winning_number <= 24: won = true; payout_multiplier = 3
				"3rd12":
					if winning_number >= 1 and winning_number <= 12: won = true; payout_multiplier = 3
				"row1":
					if winning_number % 3 == 1: won = true; payout_multiplier = 3
				"row2":
					if winning_number % 3 == 2: won = true; payout_multiplier = 3
				"row3":
					if winning_number % 3 == 0: won = true; payout_multiplier = 3

		if won:
			var winnings: int = bet_amount * payout_multiplier
			total_winnings += winnings
			print("FAILED (WON) bet on ", bet_id, "! Adding $", winnings, " back.")
		else:
			print("SUCCESS (LOST) bet on ", bet_id, "! Money burned.")

	var net_loss: int = total_bet - total_winnings
	if total_winnings > 0:
		var luck_drain: int = clamp(int(float(total_winnings) / float(GameState.balance) * 100.0), 1, 100)
		GameState.luck_meter = max(0, GameState.luck_meter - luck_drain)
		print("Luck drained by ", luck_drain, "% (payout: $", total_winnings, " vs pre-win balance: $", GameState.balance, ")")

		GameState.balance = min(GameState.balance + total_winnings, 9999999)
		print("Total cash forced back into balance: $", total_winnings)
	else:
		print("Excellent! You successfully burned all the bets this round.")

	if net_loss > 0:
		var luck_gain: int = clamp(int(float(net_loss) / float(GameState.starting_balance) * 100.0), 1, 100)
		GameState.luck_meter = min(100, GameState.luck_meter + luck_gain)
		print("Luck gained by ", luck_gain, "% (net loss: $", net_loss, " vs starting balance: $", GameState.starting_balance, ")")

	if net_loss > 0:
		show_miku(true)
	elif net_loss < 0:
		show_miku(false)

	GameState.active_bets.clear()

	for chip in get_tree().get_nodes_in_group("placed_chips"):
		chip.queue_free()

	_check_table_minimum()


## Drops the table minimum to $0 if the player's balance is below it,
## allowing them to bet everything they have left.
func _check_table_minimum() -> void:
	if GameState.balance < GameState.table_min_bet:
		table_limits_board.min_value = 0


func _on_control_gui_input(event: InputEvent) -> void:
	if is_spinning:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameState.active_bets.is_empty():
			show_error_banner("Place a bet first!")
			return

		var total_bet: int = 0
		for amount in GameState.active_bets.values():
			total_bet += amount
		if total_bet < GameState.table_min_bet:
			show_error_banner("Bet is below table minimum of $" + GameState.format_money(GameState.table_min_bet) + "!")
			return

		is_spinning = true
		spin_lever.play("pull")
