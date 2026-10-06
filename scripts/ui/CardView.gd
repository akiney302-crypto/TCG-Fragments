extends PanelContainer
class_name CardView

signal selected(card: CardInstance)

@onready var card_frame: TextureRect = $CardCanvas/FrameArt
@onready var artwork: TextureRect = $CardCanvas/MarginContainer/VBoxContainer/ArtworkRegion/Artwork
@onready var cost_label: Label = $CardCanvas/MarginContainer/VBoxContainer/ArtworkRegion/CostBadge/CostLabel
@onready var type_icon: TextureRect = $CardCanvas/MarginContainer/VBoxContainer/TypeRow/TypeIcon
@onready var card_name: Label = $CardCanvas/MarginContainer/VBoxContainer/NameLabel
@onready var card_type: Label = $CardCanvas/MarginContainer/VBoxContainer/TypeRow/TypeLabel
@onready var card_attack: Label = $CardCanvas/MarginContainer/VBoxContainer/StatsRow/AttackLabel
@onready var card_hp: Label = $CardCanvas/MarginContainer/VBoxContainer/StatsRow/HPLabel
@onready var card_text: Label = $CardCanvas/MarginContainer/VBoxContainer/EffectText
@onready var card_archetype: Label = $CardCanvas/MarginContainer/VBoxContainer/ArchetypeLabel
var card_instance: CardInstance = null
var is_selected: bool = false

func _ready() -> void:
	for child in find_children("*", "Control", true, true):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gui_input.connect(_on_gui_input)

func set_compact(compact: bool = true) -> void:
	if not compact:
		custom_minimum_size = Vector2(160, 224)
		return
	custom_minimum_size = Vector2(132, 184)
	type_icon.custom_minimum_size = Vector2(18, 18)
	card_name.add_theme_font_size_override("font_size", 11)
	card_type.add_theme_font_size_override("font_size", 8)
	card_attack.add_theme_font_size_override("font_size", 9)
	card_hp.add_theme_font_size_override("font_size", 9)
	card_archetype.add_theme_font_size_override("font_size", 7)
	card_text.add_theme_font_size_override("font_size", 8)

func _on_gui_input(event: InputEvent) -> void:
	var was_pressed: bool = false
	if event is InputEventMouseButton:
		was_pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	elif event is InputEventScreenTouch:
		was_pressed = event.pressed
	if was_pressed and card_instance != null:
		selected.emit(card_instance)
		accept_event()

static func get_type_icon(type_name: String) -> Texture2D:
	return load(CardVisualTheme.get_theme(type_name)["icon"]) as Texture2D

static func get_type_color(type_name: String) -> Color:
	return CardVisualTheme.get_theme(type_name)["accent"]


func set_selected(selected_state: bool) -> void:
	is_selected = selected_state
	var target_scale: Vector2 = Vector2(1.035, 1.035) if is_selected else Vector2.ONE
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.14).set_trans(Tween.TRANS_SINE)
	card_frame.modulate = CardVisualTheme.get_theme(card_type.text)["accent"].lightened(0.22) if is_selected else Color.WHITE

func _set_card(name: String, type_name: String, cost: int, attack: int, hp: int, family: String, tags: Array[String], description: String, art_path: String = "") -> void:
	var type_theme: Dictionary = CardVisualTheme.get_theme(type_name)
	card_frame.texture = load(type_theme["frame"]) as Texture2D
	type_icon.texture = get_type_icon(type_name)
	var artwork_path: String = art_path if not art_path.is_empty() and ResourceLoader.exists(art_path) else "res://art/ui/soul_core_placeholder.svg"
	artwork.texture = load(artwork_path) as Texture2D
	cost_label.text = str(cost)
	card_name.text = name
	card_type.text = type_name.to_upper()
	card_attack.text = "ATK  %d" % attack
	card_hp.text = "HP  %d" % hp
	card_archetype.text = family if tags.is_empty() else "%s  /  %s" % [family, ", ".join(tags)]
	card_text.text = description
	var tint: Color = type_theme["accent"]
	card_type.add_theme_color_override("font_color", tint)
	card_attack.add_theme_color_override("font_color", tint)
	card_hp.add_theme_color_override("font_color", tint)
	card_frame.modulate = tint.lightened(0.22) if is_selected else Color.WHITE

func set_card_instance(card: CardInstance) -> void:
	card_instance = card
	if card == null or card.card_data == null:
		_set_card("Empty", "TROOP", 0, 0, 0, "NONE", [], "")
		return

	_set_card(card.get_name(), card.card_data.type, card.get_cost(), card.get_attack(), card.get_hp(), card.archetype, card.card_data.archetype_tags, card.card_data.text, card.card_data.art_path)

func set_card_data(card: CardData) -> void:
	if card == null:
		_set_card("Empty", "TROOP", 0, 0, 0, "NONE", [], "")
		return

	_set_card(card.name, card.type, card.cost, card.attack, card.hp, card.archetype, card.archetype_tags, card.text, card.art_path)
