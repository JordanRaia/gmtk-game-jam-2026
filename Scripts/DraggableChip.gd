extends TextureRect

@export var chip_value: int = 1000

func _get_drag_data(_at_position: Vector2) -> Variant:
    # Create a visual preview of the chip while dragging
    var preview_texture = TextureRect.new()
    preview_texture.texture = texture
    preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    var drag_size = size / 4.0
    preview_texture.size = drag_size
    
    # Center the preview on the mouse cursor
    var preview_control = Control.new()
    preview_control.add_child(preview_texture)
    preview_texture.position = -0.5 * drag_size
    
    set_drag_preview(preview_control)
    
    # Return the data payload you want to send to the drop zone
    return {"amount": chip_value}