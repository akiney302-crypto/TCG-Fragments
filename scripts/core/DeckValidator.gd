extends RefCounted
class_name DeckValidator

func validate(deck_data: DeckData, catalog: CatalogManager) -> Dictionary:
    var errors: Array[String] = []
    var counts: Dictionary = {}

    if deck_data == null:
        return {"valid": false, "errors": ["Deck is null."], "card_count": 0}

    for card_id in deck_data.card_quantities.keys():
        var quantity: int = int(deck_data.card_quantities[card_id])
        if quantity <= 0:
            errors.append("Deck contains a non-positive quantity for %s." % [card_id])
            continue
        var card: CardData = catalog.get_card_by_id(card_id)
        if card == null:
            errors.append("Card %s does not exist in the catalog." % [card_id])
            continue
        if quantity > card.max_copies:
            errors.append("Card %s exceeds the allowed copy limit (%d)." % [card_id, card.max_copies])
        counts[card_id] = quantity

    var total_cards: int = 0
    var champion_count: int = 0
    for value in counts.values():
        total_cards += int(value)
    for card_id in counts.keys():
        var card: CardData = catalog.get_card_by_id(card_id)
        if card != null and card.type == "CHAMPION":
            champion_count += int(counts[card_id])

    if total_cards != GameRules.MAX_DECK_SIZE:
        errors.append("Deck size must be exactly %d cards." % [GameRules.MAX_DECK_SIZE])
    if champion_count != 1:
        errors.append("Deck must contain exactly one Champion (its Ace).")

    var family_counts: Dictionary = {}
    for card_id in deck_data.card_quantities.keys():
        var card: CardData = catalog.get_card_by_id(card_id)
        if card == null:
            continue
        var family: String = card.archetype.to_upper()
        family_counts[family] = int(family_counts.get(family, 0)) + int(deck_data.card_quantities[card_id])

    if not family_counts.is_empty():
        var strongest_family: String = "NONE"
        var strongest_value: int = 0
        for family in family_counts.keys():
            if int(family_counts[family]) > strongest_value:
                strongest_value = int(family_counts[family])
                strongest_family = family
        if strongest_value >= 6:
            deck_data.family_name = strongest_family

    return {
        "valid": errors.is_empty(),
        "errors": errors,
        "card_count": total_cards,
    }
