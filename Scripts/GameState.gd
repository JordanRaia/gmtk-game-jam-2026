extends Node

var balance: int = 1000000
var time_remaining: float = 180.0 # 3 minutes countdown
var luck_meter: int = 100
var current_selected_chip: int = 1000
var active_bets: Dictionary = {} # Example: {"17_black": 50000}