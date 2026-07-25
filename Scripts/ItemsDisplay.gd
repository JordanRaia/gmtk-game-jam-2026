extends Control

## Shows the last 3 items used inside the itemsui.png HUD panel on the right.

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
	"crow": "Luck gain x0.5\n(3 rolls)",
	"lighter": "Burn your\nlargest win",
	"smokebomb": "Clear 75% of\nlargest win",
	"leek": "Max bet x2\n(3 rolls)",
	"magictrick": "Next win\npays 30%",
	"stopwatch": "Add 60\nseconds",
	"mikuplush": "Force loss\nnext roll",
	"rabbitsarm": "Drain all\nluck",
}

var _icon_rects: Array[TextureRect] = []
var _name_labels: Array[Label] = []
var _desc_labels: Array[Label] = []

@onready var _panel_bg: TextureRect = $TextureRect


func _ready() -> void:
	_create_slots()
	ItemSystem.items_updated.connect(_refresh)
	await get_tree().process_frame
	_position_slots()
	_refresh()


func _create_slots() -> void:
	for i: int in range(3):
		var icon := TextureRect.new()
		icon.layout_mode = 0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color.TRANSPARENT
		add_child(icon)
		_icon_rects.append(icon)

		var name_lbl := Label.new()
		name_lbl.layout_mode = 0
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.modulate = Color.TRANSPARENT
		add_child(name_lbl)
		_name_labels.append(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.layout_mode = 0
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color.TRANSPARENT
		add_child(desc_lbl)
		_desc_labels.append(desc_lbl)


func _position_slots() -> void:
	var bx: float = _panel_bg.position.x
	var by: float = _panel_bg.position.y
	var bw: float = _panel_bg.size.x * _panel_bg.scale.x
	var bh: float = _panel_bg.size.y * _panel_bg.scale.y

	var icon_size := Vector2(52.0, 52.0)
	var margin: float = 22.0
	var gap: float = 8.0

	# Icon sits at the left edge; text fills the remaining width to the right.
	var icon_x: float = bx + margin
	var text_x: float = icon_x + icon_size.x + gap
	var text_w: float = bw - icon_size.x - margin * 2.0 - gap

	# First icon starts 28% down (below the "ITEMS" title), spaced evenly after.
	var y_start: float = by + bh * 0.28
	var y_step: float = bh * 0.24

	for i: int in range(3):
		var row_y: float = y_start + y_step * float(i)

		_icon_rects[i].size = icon_size
		_icon_rects[i].position = Vector2(icon_x, row_y)

		_name_labels[i].position = Vector2(text_x, row_y + 2.0)
		_name_labels[i].size = Vector2(text_w, 20.0)

		_desc_labels[i].position = Vector2(text_x, row_y + 24.0)
		_desc_labels[i].size = Vector2(text_w, 30.0)


func _refresh() -> void:
	for i: int in range(3):
		if i < ItemSystem.recent_items.size():
			var id: String = ItemSystem.recent_items[i]
			var path: String = "res://Assets/art/" + id + ".png"
			if ResourceLoader.exists(path):
				_icon_rects[i].texture = load(path)
			else:
				_icon_rects[i].texture = null
			_icon_rects[i].modulate = Color.WHITE
			_name_labels[i].text = ITEM_NAMES.get(id, id)
			_name_labels[i].modulate = Color.WHITE
			_desc_labels[i].text = ITEM_DESCRIPTIONS.get(id, "")
			_desc_labels[i].modulate = Color(0.85, 0.85, 0.85)
		else:
			_icon_rects[i].texture = null
			_icon_rects[i].modulate = Color.TRANSPARENT
			_name_labels[i].text = ""
			_name_labels[i].modulate = Color.TRANSPARENT
			_desc_labels[i].text = ""
			_desc_labels[i].modulate = Color.TRANSPARENT
