extends Node

const SCREENSHOT_KEY := KEY_F12
const SAVE_DIR := "user://screenshots/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == SCREENSHOT_KEY and key_event.pressed and not key_event.echo:
			_take_screenshot()

func _take_screenshot() -> void:
	var image := get_viewport().get_texture().get_image()
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename := "screenshot_%s.png" % timestamp
	var path := SAVE_DIR + filename
	var err := image.save_png(path)
	if err == OK:
		print("Screenshot saved: ", ProjectSettings.globalize_path(path))
	else:
		push_error("Screenshot failed to save (error %d)" % err)
