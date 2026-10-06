extends RefCounted
class_name CatalogManager

var cards: Array[CardData] = []
var index_by_id: Dictionary = {}

func load_catalog(path: String = "res://resources/cards/catalog.json") -> void:
    cards.clear()
    index_by_id.clear()

    if not FileAccess.file_exists(path):
        _create_default_catalog()
        return

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        _create_default_catalog()
        return

    var raw_text: String = file.get_as_text()
    file.close()

    var json := JSON.new()
    var error := json.parse(raw_text)
    if error != OK:
        push_error("Catalog JSON parse failed: %s" % [json.get_error_message()])
        _create_default_catalog()
        return

    var payload: Dictionary = json.data
    var items: Array = payload.get("cards", [])
    for entry in items:
        var card := CardData.from_dictionary(entry)
        cards.append(card)
        index_by_id[card.id] = card

    if cards.is_empty():
        _create_default_catalog()

func _create_default_catalog() -> void:
    cards = [
        CardData.from_dictionary({"id": "ember_knight", "name": "Ember Knight", "type": "TROOP", "cost": 2, "attack": 2, "hp": 3, "text": "A reliable entry unit.", "effect": {"type": "none"}}),
        CardData.from_dictionary({"id": "sunwisp", "name": "Sunwisp", "type": "TROOP", "cost": 1, "attack": 1, "hp": 2, "text": "Light support.", "effect": {"type": "heal_player", "amount": 1}}),
        CardData.from_dictionary({"id": "spire_guard", "name": "Spire Guard", "type": "CHAMPION", "cost": 4, "attack": 3, "hp": 5, "text": "A durable field leader.", "effect": {"type": "max_hp", "amount": 1}}),
        CardData.from_dictionary({"id": "lunar_truth", "name": "Lunar Truth", "type": "TRUTH", "cost": 2, "attack": 0, "hp": 0, "text": "Gain 2 life.", "effect": {"type": "heal_player", "amount": 2}}),
        CardData.from_dictionary({"id": "whisper_secret", "name": "Whisper Secret", "type": "SECRETS", "cost": 3, "attack": 0, "hp": 0, "text": "Secret effect placeholder.", "effect": {"type": "destroy_on_destroy"}}),
    ]
    for card in cards:
        index_by_id[card.id] = card

func get_card_by_id(card_id: String) -> CardData:
    return index_by_id.get(card_id, null)

func get_all_cards() -> Array[CardData]:
    return cards

func get_cards_by_type(type_name: String) -> Array[CardData]:
    var type_filter: String = type_name.to_upper()
    var result: Array[CardData] = []
    for card in cards:
        if card.type == type_filter:
            result.append(card)
    return result
