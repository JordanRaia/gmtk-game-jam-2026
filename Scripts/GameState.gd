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

var current_stage: int = 1

# Per-stage config: [balance, time_sec, table_min, table_max, chips_available, starting_luck]
# TEST VALUES — swap comment blocks to restore originals
# const STAGE_CONFIG: Array = [
# 	[1000, 999, 0, 10000, [1000, 5000, 10000], 0], # Stage 1 — easymode
# 	[1000, 999, 0, 50000, [1000, 5000, 10000, 25000], 0], # Stage 2 — mid chips
# 	[1000, 999, 0, 100000, [1000, 5000, 10000, 25000, 50000], 0], # Stage 3 — big bets
# 	[1000, 999, 0, 250000, [1000, 5000, 10000, 25000, 50000, 100000], 0], # Stage 4 — max pressure
# ]

# ORIGINAL VALUES
const STAGE_CONFIG: Array = [
	[50000, 180, 500, 10000, [1000, 5000, 10000], 0], # Stage 1 — easymode
	[150000, 150, 1000, 50000, [1000, 5000, 10000, 25000], 30], # Stage 2 — mid chips
	[300000, 120, 5000, 100000, [1000, 5000, 10000, 25000, 50000], 55], # Stage 3 — big bets
	[600000, 90, 25000, 250000, [1000, 5000, 10000, 25000, 50000, 100000], 75], # Stage 4 — max pressure
]

func get_stage_config() -> Array:
	var idx: int = clamp(current_stage - 1, 0, STAGE_CONFIG.size() - 1)
	return STAGE_CONFIG[idx]

var balance: int = STAGE_CONFIG[0][0]
var starting_balance: int = STAGE_CONFIG[0][0]
var time_remaining: float = float(STAGE_CONFIG[0][1])
var luck_meter: int = 50
var current_selected_chip: int = 1000
var active_bets: Dictionary = {}
var tutorial_seen: bool = false

# Set by TableLimitsBoard — enforced when betting and spinning
var table_min_bet: int = 500
var table_max_bet: int = 10000