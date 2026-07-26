extends Node

signal request_lighter_effect
signal request_smoke_bomb_effect
signal items_updated

const ITEMS: Array[String] = ["crow", "lighter", "smokebomb", "leek", "magictrick", "stopwatch", "mikuplush", "rabbitsarm"]
const ROLLS_PER_OFFER: int = 2

var rolls_since_last_offer: int = 0

# --- Crow: reduces luck gain on net losses ---
var crow_rolls_remaining: int = 0
var crow_luck_multiplier: float = 1.0 # 1.0 = inactive; 0.5 = base; 0.25 = enhanced

# --- Leek: multiplies table max bet ---
var leek_rolls_remaining: int = 0
var leek_multiplier: float = 1.0 # 1.0 = inactive; 2.0 = base; 3.0 = enhanced

# --- Magic Trick: cuts next-win payout ---
var magic_trick_active: bool = false
var magic_trick_fraction: float = 0.3 # 0.3 = base; 0.1 = enhanced

# --- Miku Plushie: forces a bad outcome ---
var miku_plush_active: bool = false
var miku_plush_enhanced: bool = false # enhanced = actively seek the worst number

# --- Lighter: subtracts largest historical win (instant) ---
var largest_win_amount: int = 0
var lighter_times_used: int = 0 # 0 = base next use; 1+ = enhanced next use

# --- Smoke Bomb: restores a past snapshot (instant) ---
var smokebomb_times_used: int = 0
var spin_snapshots: Array[Dictionary] = [] # ring of last 2: {balance, luck_meter, time_remaining}
var last_win_amount: int = 0

# --- Stopwatch: adds time (instant) ---
var stopwatch_times_used: int = 0

# --- Rabbit's Arm: drains luck to 0 (instant); enhanced also locks luck gain for 3 rolls ---
var luck_locked_rolls: int = 0
var rabbitsarm_times_used: int = 0

# --- Recent items display (last 3 used, newest first) ---
var recent_items: Array[String] = []


func reset_for_stage() -> void:
	rolls_since_last_offer = 0
	crow_rolls_remaining = 0
	crow_luck_multiplier = 1.0
	leek_rolls_remaining = 0
	leek_multiplier = 1.0
	magic_trick_active = false
	magic_trick_fraction = 0.3
	miku_plush_active = false
	miku_plush_enhanced = false
	largest_win_amount = 0
	last_win_amount = 0
	lighter_times_used = 0
	smokebomb_times_used = 0
	stopwatch_times_used = 0
	spin_snapshots.clear()
	luck_locked_rolls = 0
	rabbitsarm_times_used = 0
	recent_items.clear()
	items_updated.emit()


## Returns true for items that have hit their per-stage use limit.
func is_item_exhausted(id: String) -> bool:
	match id:
		"lighter": return lighter_times_used >= 1
	return false


func get_draft_offer() -> Array[String]:
	var pool: Array[String] = ITEMS.filter(func(id: String) -> bool: return not is_item_exhausted(id))
	pool.shuffle()
	return pool.slice(0, min(3, pool.size()))


func should_offer_items() -> bool:
	return rolls_since_last_offer >= ROLLS_PER_OFFER


func consume_offer() -> void:
	rolls_since_last_offer = 0


func apply_item(id: String) -> void:
	match id:
		"crow":
			if crow_rolls_remaining > 0:
				crow_luck_multiplier = 0.25
				crow_rolls_remaining = 3
				print("Crow ENHANCED: luck gain x0.25 for 3 rolls.")
			else:
				crow_luck_multiplier = 0.5
				crow_rolls_remaining = 3
				print("Crow ACTIVE: luck gain x0.5 for 3 rolls.")
			_record_item_used(id)

		"leek":
			if leek_rolls_remaining > 0:
				leek_multiplier = 3.0
				leek_rolls_remaining = 3
				print("Leek ENHANCED: max bet x3 for 3 rolls.")
			else:
				leek_multiplier = 2.0
				leek_rolls_remaining = 3
				print("Leek ACTIVE: max bet x2 for 3 rolls.")
			_record_item_used(id)

		"magictrick":
			if magic_trick_active:
				magic_trick_fraction = 0.1
				print("Magic Trick ENHANCED: next win pays 10%.")
			else:
				magic_trick_fraction = 0.3
				magic_trick_active = true
				print("Magic Trick ACTIVE: next win pays 30%.")
			_record_item_used(id)

		"mikuplush":
			if miku_plush_active:
				miku_plush_enhanced = true
				print("Miku Plushie ENHANCED: worst number forced.")
			else:
				miku_plush_active = true
				miku_plush_enhanced = false
				print("Miku Plushie ACTIVE: pure random outcome.")
			_record_item_used(id)

		"lighter":
			if lighter_times_used >= 1:
				print("Lighter: already used this stage!")
				return
			if largest_win_amount <= 0:
				print("Lighter: no wins to burn yet!")
				return
			lighter_times_used += 1
			request_lighter_effect.emit()
			print("Lighter: burning win history (tier ", lighter_times_used, ")")
			_record_item_used(id)

		"smokebomb":
			if last_win_amount <= 0:
				print("Smoke Bomb: no wins to clear!")
				return
			smokebomb_times_used += 1
			request_smoke_bomb_effect.emit()
			print("Smoke Bomb: clearing win (tier ", smokebomb_times_used, ")")
			_record_item_used(id)

		"stopwatch":
			stopwatch_times_used += 1
			var add_secs: float = 90.0 if stopwatch_times_used > 1 else 60.0
			GameState.time_remaining += add_secs
			print("Stopwatch: added ", add_secs, "s (tier ", stopwatch_times_used, ")")
			_record_item_used(id)

		"rabbitsarm":
			rabbitsarm_times_used += 1
			GameState.luck_meter = 0
			if rabbitsarm_times_used > 1:
				luck_locked_rolls = 3
				print("Rabbit's Arm ENHANCED: luck drained and locked for 3 rolls.")
			else:
				print("Rabbit's Arm: luck fully drained.")
			_record_item_used(id)


func _record_item_used(id: String) -> void:
	recent_items.push_front(id)
	if recent_items.size() > 3:
		recent_items.pop_back()
	items_updated.emit()


## Amount lighter will subtract from balance this use.
func get_lighter_subtract_amount() -> int:
	var mult: int = 2 if lighter_times_used > 1 else 1
	return largest_win_amount * mult


## Snapshot to restore for smoke bomb this use.
## First use: most recent snapshot. Enhanced (2nd+ use): the older one.
func get_smoke_bomb_snapshot() -> Dictionary:
	if spin_snapshots.is_empty():
		return {}
	if smokebomb_times_used > 1 and spin_snapshots.size() >= 2:
		return spin_snapshots[0]
	return spin_snapshots[spin_snapshots.size() - 1]


## Called by MainScene after each spin fully resolves.
func on_spin_complete(net_winnings: int) -> void:
	rolls_since_last_offer += 1

	if crow_rolls_remaining > 0:
		crow_rolls_remaining -= 1
		if crow_rolls_remaining == 0:
			crow_luck_multiplier = 1.0
			print("Crow effect expired.")

	if leek_rolls_remaining > 0:
		leek_rolls_remaining -= 1
		if leek_rolls_remaining == 0:
			leek_multiplier = 1.0
			print("Leek effect expired.")

	# Magic Trick persists until it actually fires (a winning spin), so it is
	# cleared inside MainScene._apply_spin_results() instead of here.
	miku_plush_active = false
	miku_plush_enhanced = false

	if luck_locked_rolls > 0:
		luck_locked_rolls -= 1
		if luck_locked_rolls == 0:
			print("Rabbit's Arm luck lock expired.")

	if net_winnings > largest_win_amount:
		largest_win_amount = net_winnings
		print("Lighter: new largest win recorded: $", largest_win_amount)

	if net_winnings > 0:
		last_win_amount = net_winnings


func save_spin_snapshot() -> void:
	var snap: Dictionary = {
		"balance": GameState.balance,
		"luck_meter": GameState.luck_meter,
		"time_remaining": GameState.time_remaining,
	}
	spin_snapshots.append(snap)
	if spin_snapshots.size() > 2:
		spin_snapshots.pop_front()


func get_effective_max_bet() -> int:
	return int(float(GameState.table_max_bet) * leek_multiplier)


func is_item_active(id: String) -> bool:
	match id:
		"crow": return crow_rolls_remaining > 0
		"leek": return leek_rolls_remaining > 0
		"magictrick": return magic_trick_active
		"mikuplush": return miku_plush_active
		"rabbitsarm": return luck_locked_rolls > 0
	return false


## Short label shown on active items in the panel.
func get_item_status_label(id: String) -> String:
	match id:
		"crow":
			if crow_rolls_remaining > 0:
				var tier: String = "ENHANCED" if crow_luck_multiplier <= 0.25 else "ACTIVE"
				return tier + " (" + str(crow_rolls_remaining) + ")"
		"leek":
			if leek_rolls_remaining > 0:
				var tier: String = "ENHANCED" if leek_multiplier >= 3.0 else "ACTIVE"
				return tier + " (" + str(leek_rolls_remaining) + ")"
		"magictrick":
			if magic_trick_active:
				return "ENHANCED" if magic_trick_fraction <= 0.1 else "ACTIVE"
		"mikuplush":
			if miku_plush_active:
				return "ENHANCED" if miku_plush_enhanced else "ACTIVE"
		"rabbitsarm":
			if luck_locked_rolls > 0:
				return "LOCKED (" + str(luck_locked_rolls) + ")"
	return ""
