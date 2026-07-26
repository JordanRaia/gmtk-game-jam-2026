extends Control

signal item_picked(id: String)

@export var item_id: String = ""

@onready var bg: TextureButton = $BG
@onready var icon: TextureRect = $BG/Icon
@onready var name_label: Label = $BG/NameLabel
@onready var status_label: Label = $BG/StatusLabel

const ITEM_NAMES: Dictionary = {
	"crow": "Black Crow",
	"lighter": "Lighter",
	"smokebomb": "Smoke Bomb",
	"leek": "Leek",
	"magictrick": "Magic Trick",
	"stopwatch": "Stopwatch",
	"mikuplush": "Miku Plushie",
	"rabbitsarm": "Rabbit's Arm",
}

const ITEM_DESCRIPTIONS: Dictionary = {
	"crow": "Luck gain\nx0.5 (3 rolls)",
	"lighter": "Burn your\nlargest win",
	"smokebomb": "Clear your\nlast win",
	"leek": "Max bet\nx2 (3 rolls)",
	"magictrick": "Next win\npays 30%",
	"stopwatch": "Add\n60 seconds",
	"mikuplush": "Force loss\nnext roll",
	"rabbitsarm": "Drain all\nluck",
}

var _normal_tex: Texture2D = preload("res://Assets/art/itemsubbox.png")
var _hover_tex: Texture2D = preload("res://Assets/art/itemsubboxhover.png")


func _ready() -> void:
	bg.texture_normal = _normal_tex
	bg.texture_hover = _hover_tex
	bg.texture_pressed = _hover_tex
	bg.pressed.connect(_on_pressed)

	if item_id != "":
		setup(item_id)


func setup(id: String) -> void:
	item_id = id

	var icon_path: String = "res://Assets/art/" + id + ".png"
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)

	name_label.text = ITEM_NAMES.get(id, id)

	var desc: String = ITEM_DESCRIPTIONS.get(id, "")
	var active_label: String = ItemSystem.get_item_status_label(id)
	if active_label != "":
		status_label.text = active_label
		status_label.add_theme_color_override("font_color", _get_tier_color(active_label))
	else:
		status_label.text = desc

	_update_tint()


func _update_tint() -> void:
	if ItemSystem.is_item_active(item_id):
		var label_text: String = ItemSystem.get_item_status_label(item_id)
		if label_text.begins_with("ENHANCED"):
			modulate = Color(1.0, 0.85, 1.0)
		else:
			modulate = Color(1.0, 1.0, 0.75)
	else:
		modulate = Color.WHITE


func _get_tier_color(label: String) -> Color:
	if label.begins_with("ENHANCED"):
		return Color(0.9, 0.5, 1.0)
	return Color(1.0, 0.9, 0.3)


func _on_pressed() -> void:
	item_picked.emit(item_id)
