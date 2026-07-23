extends Node

var balance: int = 1000000
var starting_balance: int = 1000000  # Reference for luck gain/drain calculations
var time_remaining: float = 180.0 # 3 minutes countdown
var luck_meter: int = 100
var current_selected_chip: int = 1000
var active_bets: Dictionary = {} # Example: {"17_black": 50000}

# Set by TableLimitsBoard — enforced when betting and spinning
var table_min_bet: int = 1000   # Minimum total wager required before spinning
var table_max_bet: int = 250000 # Maximum allowed wager per individual bet spot