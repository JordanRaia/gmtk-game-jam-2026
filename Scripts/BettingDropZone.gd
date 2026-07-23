extends Panel

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Check if the data being dragged is a valid chip value
	return data is Dictionary and data.has("amount")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var chip_value = data["amount"]
	print("Dropped chip of value: ", chip_value, " onto ", name)
	
	# Deduct from balance and register bet via GameState
	if GameState.balance >= chip_value:
		GameState.balance -= chip_value
		# TODO: Instantiate a visual chip sprite directly inside this panel zone
	else:
		print("Not enough balance to place this bet!")