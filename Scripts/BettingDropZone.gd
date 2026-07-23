extends Panel

@export var bet_id: String = ""

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.has("amount")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
    var chip_value = data["amount"]

    if GameState.balance < chip_value:
        print("Not enough balance to place this bet!")
        return

    # Enforce total table maximum across all bet spots
    var total_all_bets: int = 0
    for amount in GameState.active_bets.values():
        total_all_bets += amount
    if total_all_bets + chip_value > GameState.table_max_bet:
        print("Total bets would exceed table maximum of $", GameState.table_max_bet, "!")
        return

    # Deduct from balance
    GameState.balance -= chip_value

    # Register the bet in the GameState ledger
    if GameState.active_bets.has(bet_id):
        GameState.active_bets[bet_id] += chip_value
    else:
        GameState.active_bets[bet_id] = chip_value

    print("Dropped $", chip_value, " on: ", bet_id)
    print("Current Ledger: ", GameState.active_bets)

    # Instantiate a visual chip on the drop zone
    var chip_display := TextureRect.new()
    chip_display.texture = data["texture"]
    chip_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    chip_display.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var chip_size := Vector2(32.0, 32.0)
    chip_display.size = chip_size

    # Count existing placed chips on this zone for stacking offset
    var existing_chip_count := 0
    for child in get_children():
        if child.is_in_group("placed_chips"):
            existing_chip_count += 1

    # Center the chip in the zone, offset each additional chip slightly
    var offset := Vector2(existing_chip_count * 4.0, existing_chip_count * -4.0)
    chip_display.position = (size / 2.0) - (chip_size / 2.0) + offset

    # Use an absolute z_index so left-zone chips render above right-zone chips.
    # Further left (smaller x) = higher z_index = drawn on top.
    chip_display.z_as_relative = false
    chip_display.z_index = 1000 - int(global_position.x / 10.0)
    chip_display.add_to_group("placed_chips")
    add_child(chip_display)