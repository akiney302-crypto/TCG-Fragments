extends Control

const CARD_PATHS: Array[String] = [
	"res://resources/cards/test_guard.tres",
	"res://resources/cards/test_dragon.tres",
	"res://resources/cards/swift_scout.tres",
	"res://resources/cards/stone_sentinel.tres",
	"res://resources/cards/ember_wolf.tres",
	"res://resources/cards/soul_archer.tres",
	"res://resources/cards/shadow_stalker.tres",
	"res://resources/cards/dawn_guardian.tres",
	"res://resources/cards/soul_golem.tres",
	"res://resources/cards/ancient_titan.tres"
]
const DECK_LIMIT: int = 20

@onready var card_list: VBoxContainer = $Margin/Layout/Content/Content/CardList
@onready var count_label: Label = $Margin/Layout/Header/CountLabel
@onready var message_label: Label = $Margin/Layout/Content/Content/MessageLabel
@onready var back_button: Button = $Margin/Layout/BackButton

var collection: Array[CardData] = []
var deck_counts: Dictionary = {}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_load_collection()
	_refresh()


func _load_collection() -> void:
	for path: String in CARD_PATHS:
		var card_data: CardData = load(path) as CardData
		if card_data != null:
			collection.append(card_data)


func _refresh() -> void:
	for child: Node in card_list.get_children():
		child.queue_free()
	var total: int = _deck_size()
	count_label.text = "Cartas: %d / %d" % [total, DECK_LIMIT]
	for card_data: CardData in collection:
		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 42)
		card_list.add_child(row)
		var label: Label = Label.new()
		label.text = "%s  [%s]" % [card_data.card_name, card_data.card_type]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var amount: Label = Label.new()
		amount.text = str(deck_counts.get(card_data.card_id, 0))
		amount.custom_minimum_size = Vector2(40, 0)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(amount)
		var remove_button: Button = Button.new()
		remove_button.text = "-"
		remove_button.custom_minimum_size = Vector2(38, 38)
		remove_button.pressed.connect(_remove_card.bind(card_data))
		row.add_child(remove_button)
		var add_button: Button = Button.new()
		add_button.text = "+"
		add_button.custom_minimum_size = Vector2(38, 38)
		add_button.pressed.connect(_add_card.bind(card_data))
		row.add_child(add_button)


func _add_card(card_data: CardData) -> void:
	var current: int = deck_counts.get(card_data.card_id, 0)
	var limit: int = 1 if card_data.card_type == "CHAMPION" else 3
	if _deck_size() >= DECK_LIMIT:
		message_label.text = "El deck ya tiene 20 cartas."
		return
	if current >= limit:
		message_label.text = "Limite de copias: %d." % limit
		return
	deck_counts[card_data.card_id] = current + 1
	message_label.text = ""
	_refresh()


func _remove_card(card_data: CardData) -> void:
	var current: int = deck_counts.get(card_data.card_id, 0)
	if current <= 0:
		return
	deck_counts[card_data.card_id] = current - 1
	_refresh()


func _deck_size() -> int:
	var total: int = 0
	for amount: int in deck_counts.values():
		total += amount
	return total


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
