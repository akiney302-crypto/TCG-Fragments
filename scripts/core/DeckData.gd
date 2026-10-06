extends Resource
class_name DeckData

@export var id: String = "custom_deck"
@export var name: String = "Custom Deck"
@export var card_quantities: Dictionary = {}
@export var family_name: String = "NONE"

func _init(p_id: String = "custom_deck", p_name: String = "Custom Deck"):
    id = p_id
    name = p_name
    card_quantities = {}
    family_name = "NONE"

func add_card(card_id: String, count: int = 1) -> void:
    if count <= 0:
        return
    if not card_quantities.has(card_id):
        card_quantities[card_id] = 0
    card_quantities[card_id] = int(card_quantities[card_id]) + count

func remove_card(card_id: String, count: int = 1) -> void:
    if not card_quantities.has(card_id):
        return
    var new_value: int = int(card_quantities[card_id]) - count
    if new_value <= 0:
        card_quantities.erase(card_id)
    else:
        card_quantities[card_id] = new_value

func get_total_cards() -> int:
    var total: int = 0
    for value in card_quantities.values():
        total += int(value)
    return total

func clone() -> DeckData:
    var copy := DeckData.new(id, name)
    copy.card_quantities = card_quantities.duplicate(true)
    copy.family_name = family_name
    return copy

func to_dictionary() -> Dictionary:
    return {
        "id": id,
        "name": name,
        "card_quantities": card_quantities.duplicate(true),
        "family_name": family_name,
    }

static func from_dictionary(data: Dictionary) -> DeckData:
    var deck := DeckData.new(String(data.get("id", "custom_deck")), String(data.get("name", "Custom Deck")))
    deck.card_quantities = data.get("card_quantities", {}).duplicate(true)
    deck.family_name = String(data.get("family_name", "NONE")).to_upper()
    return deck
