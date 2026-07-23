extends Button

@export var chip_value: int = 1000

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Create a visual preview of the chip while dragging
	var preview = Label.new()
	preview.text = "$" + str(chip_value)
	set_drag_preview(preview)
	
	# Return the data payload you want to send to the drop zone
	return {"amount": chip_value}