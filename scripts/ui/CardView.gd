extends PanelContainer
class_name CardView

signal selected(card: CardInstance)

@onready var card_frame: TextureRect = $CardCanvas/FrameArt
@onready var type_icon: TextureRect = $CardCanvas/MarginContainer/VBoxContainer/TypeIcon
@onready var card_name: Label = $CardCanvas/MarginContainer/VBoxContainer/NameLabel
@onready var card_type: Label = $CardCanvas/MarginContainer/VBoxContainer/TypeLabel
@onready var card_stats: Label = $CardCanvas/MarginContainer/VBoxContainer/StatsLabel
@onready var card_text: Label = $CardCanvas/MarginContainer/VBoxContainer/TextLabel
@onready var card_archetype: Label = $CardCanvas/MarginContainer/VBoxContainer/ArchetypeLabel
var card_instance: CardInstance = null

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func set_compact(compact: bool = true) -> void:
	if not compact:
		custom_minimum_size = Vector2(210, 300)
		return
	custom_minimum_size = Vector2(132, 184)
	type_icon.custom_minimum_size = Vector2(28, 28)
	card_name.add_theme_font_size_override("font_size", 13)
	card_type.add_theme_font_size_override("font_size", 9)
	card_stats.add_theme_font_size_override("font_size", 9)
	card_archetype.add_theme_font_size_override("font_size", 8)
	card_text.add_theme_font_size_override("font_size", 9)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and card_instance != null:
		selected.emit(card_instance)
		accept_event()

static func get_type_key(type_name: String) -> String:
	match type_name.to_upper():
		"CHAMPION":
			return "champion"
		"TRUTH":
			return "truth"
		"SECRETS":
			return "secrets"
		_:
			return "troop"

static func get_type_icon(type_name: String) -> Texture2D:
	return load("res://art/ui/card_types/%s.svg" % get_type_key(type_name)) as Texture2D

static func get_type_color(type_name: String) -> Color:
	match type_name.to_upper():
		"CHAMPION":
			return Color("edc66e")
		"TRUTH":
			return Color("82dbe4")
		"SECRETS":
			return Color("e58b99")
		_:
			return Color("66d8b5")

func _set_card(name: String, type_name: String, cost: int, attack: int, hp: int, family: String, tags: Array[String], description: String) -> void:
	var type_key: String = get_type_key(type_name)
	card_frame.texture = load("res://art/ui/card_frames/%s.svg" % type_key)
	type_icon.texture = get_type_icon(type_name)
	card_name.text = name
	card_type.text = type_name.to_upper()
	card_stats.text = "COST %d   ATK %d   HP %d" % [cost, attack, hp]
	card_archetype.text = family if tags.is_empty() else "%s  /  %s" % [family, ", ".join(tags)]
	card_text.text = description
	var tint: Color = get_type_color(type_name)
	card_type.add_theme_color_override("font_color", tint)
	card_stats.add_theme_color_override("font_color", tint)

func set_card_instance(card: CardInstance) -> void:
	card_instance = card
	if card == null or card.card_data == null:
		_set_card("Empty", "TROOP", 0, 0, 0, "NONE", [], "")
		return

	_set_card(card.get_name(), card.card_data.type, card.get_cost(), card.get_attack(), card.get_hp(), card.archetype, card.card_data.archetype_tags, card.card_data.text)

func set_card_data(card: CardData) -> void:
	if card == null:
		_set_card("Empty", "TROOP", 0, 0, 0, "NONE", [], "")
		return

	_set_card(card.name, card.type, card.cost, card.attack, card.hp, card.archetype, card.archetype_tags, card.text)
