extends Node

signal show_error(message: String)

static func format_money(n: int) -> String:
	var s: String = str(n)
	var result: String = ""
	var count: int = 0
	for i: int in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

var balance: int = 1000000
var starting_balance: int = 1000000 # Reference for luck gain/drain calculations
var time_remaining: float = 180.0 # 3 minutes countdown
var luck_meter: int = 50
var current_selected_chip: int = 1000
var active_bets: Dictionary = {} # Example: {"17_black": 50000}

# Set by TableLimitsBoard — enforced when betting and spinning
var table_min_bet: int = 1000 # Minimum total wager required before spinning
var table_max_bet: int = 250000 # Maximum allowed wager per individual bet spot