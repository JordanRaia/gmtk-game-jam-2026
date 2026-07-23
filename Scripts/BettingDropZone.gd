extends Panel

@export var bet_id: String = ""

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.has("amount")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
    var chip_value = data["amount"]
    
    if GameState.balance >= chip_value:
        # Deduct from balance
        GameState.balance -= chip_value
        
        # Register the bet in the GameState ledger
        if GameState.active_bets.has(bet_id):
            GameState.active_bets[bet_id] += chip_value
        else:
            GameState.active_bets[bet_id] = chip_value
            
        print("Dropped $", chip_value, " on: ", bet_id)
        print("Current Ledger: ", GameState.active_bets)
        
        # TODO: Instantiate a visual chip sprite
    else:
        print("Not enough balance to place this bet!")