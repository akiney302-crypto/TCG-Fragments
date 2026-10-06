extends Control

const CARD_VIEW_SCENE: PackedScene = preload("res://scenes/card_view.tscn")

@onready var catalog_list: ItemList = $MarginContainer/HBoxContainer/LeftPanel/CatalogList
@onready var deck_list: ItemList = $MarginContainer/HBoxContainer/CenterPanel/DeckList
@onready var deck_count_label: Label = $MarginContainer/HBoxContainer/CenterPanel/DeckCountLabel
@onready var save_button: Button = $MarginContainer/HBoxContainer/RightPanel/SaveButton
@onready var reset_button: Button = $MarginContainer/HBoxContainer/RightPanel/ResetButton
@onready var back_button: Button = $MarginContainer/HBoxContainer/RightPanel/BackButton
@onready var inspector: VBoxContainer = $MarginContainer/HBoxContainer/RightPanel/Inspector
@onready var deck_selector: OptionButton = $MarginContainer/HBoxContainer/RightPanel/DeckSelector
@onready var deck_name_input: LineEdit = $MarginContainer/HBoxContainer/RightPanel/DeckNameInput

var catalog: CatalogManager = CatalogManager.new()
var deck_data: DeckData = DeckData.new("player_deck", "Player Deck")
var selected_catalog_card: CardData = null
var selected_deck_card_id: String = ""

func _ready() -> void:
	catalog.load_catalog("res://resources/cards/catalog.json")
	_reload_catalog()
	_populate_deck_selector()
	save_button.pressed.connect(_on_save_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	catalog_list.item_selected.connect(_on_catalog_selected)
	deck_list.item_selected.connect(_on_deck_selected)
	deck_selector.item_selected.connect(_on_deck_option_selected)

func _reload_catalog() -> void:
	catalog_list.clear()
	for card in catalog.get_all_cards():
		catalog_list.add_item("%s  |  %s  |  %d" % [card.name, card.type, card.cost], CardView.get_type_icon(card.type))

func _on_catalog_selected(index: int) -> void:
	var card := catalog.get_all_cards()[index]
	selected_catalog_card = card
	_update_inspector(card)

func _on_deck_selected(index: int) -> void:
	if deck_list.item_count == 0:
		return
	var item_text: String = deck_list.get_item_text(index)
	selected_deck_card_id = item_text.split("(")[0].strip_edges()

func _update_inspector(card: CardData) -> void:
	for child in inspector.get_children():
		child.queue_free()
	if card == null:
		return
	var preview: CardView = CARD_VIEW_SCENE.instantiate()
	inspector.add_child(preview)
	preview.set_card_data(card)
	var copies_label := Label.new()
	copies_label.text = "In deck: %d / %d" % [int(deck_data.card_quantities.get(card.id, 0)), card.max_copies]
	inspector.add_child(copies_label)

	var add_button := Button.new()
	add_button.text = "Add to deck"
	add_button.pressed.connect(_on_add_to_deck.bind(card.id))
	inspector.add_child(add_button)

	var remove_button := Button.new()
	remove_button.text = "Remove from deck"
	remove_button.pressed.connect(_remove_from_deck.bind(card.id))
	inspector.add_child(remove_button)

func _on_add_to_deck(card_id: String) -> void:
	if deck_data.get_total_cards() >= GameRules.MAX_DECK_SIZE:
		return
	var card: CardData = catalog.get_card_by_id(card_id)
	if card == null or int(deck_data.card_quantities.get(card_id, 0)) >= card.max_copies:
		return
	if card.type == "CHAMPION":
		for existing_id in deck_data.card_quantities.keys():
			var existing_card: CardData = catalog.get_card_by_id(existing_id)
			if existing_card != null and existing_card.type == "CHAMPION":
				return
	deck_data.add_card(card_id, 1)
	_refresh_deck_list()

func _refresh_deck_list() -> void:
	deck_list.clear()
	for card_id in deck_data.card_quantities.keys():
		var card := catalog.get_card_by_id(card_id)
		if card == null:
			continue
		deck_list.add_item("%s  x%d" % [card.name, deck_data.card_quantities[card_id]], CardView.get_type_icon(card.type))
	deck_count_label.text = "Cards: %d / %d" % [deck_data.get_total_cards(), GameRules.MAX_DECK_SIZE]

func _on_save_pressed() -> void:
	deck_data.name = deck_name_input.text.strip_edges()
	if deck_data.name.is_empty():
		deck_data.name = "My Deck"
	deck_data.id = deck_data.name.to_lower().replace(" ", "_").validate_filename()
	var validation := DeckValidator.new().validate(deck_data, catalog)
	if not validation["valid"]:
		print(validation["errors"])
		return
	if not DeckSaveManager.save_deck(deck_data):
		print("Could not save deck.")
		return
	DeckSaveManager.set_active_deck(deck_data.id)
	_populate_deck_selector(deck_data.id)
	print("Deck saved and selected for the next match.")

func _on_reset_pressed() -> void:
	deck_data = DeckData.new("new_deck", "New Deck")
	deck_name_input.text = deck_data.name
	_refresh_deck_list()

func _remove_from_deck(card_id: String) -> void:
	if deck_data.card_quantities.has(card_id):
		deck_data.remove_card(card_id, 1)
		_refresh_deck_list()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _populate_deck_selector(preferred_id: String = "") -> void:
	deck_selector.clear()
	var ids: Array[String] = []
	for starter in DeckSaveManager.load_starter_decks():
		deck_selector.add_item(starter.name)
		deck_selector.set_item_metadata(deck_selector.item_count - 1, starter.id)
		ids.append(starter.id)
	for path in DeckSaveManager.list_saved_decks():
		var saved: DeckData = DeckSaveManager.load_deck(path)
		if saved == null or ids.has(saved.id):
			continue
		deck_selector.add_item(saved.name)
		deck_selector.set_item_metadata(deck_selector.item_count - 1, saved.id)
		ids.append(saved.id)
	var desired_id: String = preferred_id
	if desired_id.is_empty():
		desired_id = DeckSaveManager.get_active_deck_id()
	if not ids.has(desired_id):
		desired_id = "knight_starter"
	for index in range(deck_selector.item_count):
		if String(deck_selector.get_item_metadata(index)) == desired_id:
			deck_selector.select(index)
			_on_deck_option_selected(index)
			return

func _on_deck_option_selected(index: int) -> void:
	var deck_id: String = String(deck_selector.get_item_metadata(index))
	var loaded: DeckData = DeckSaveManager.load_deck(DeckSaveManager.SAVE_DIRECTORY + "/%s.json" % deck_id)
	if loaded == null:
		loaded = DeckSaveManager.load_starter_deck(deck_id)
	if loaded == null:
		return
	deck_data = loaded
	deck_name_input.text = deck_data.name
	DeckSaveManager.set_active_deck(deck_data.id)
	_refresh_deck_list()
