extends RefCounted
class_name DeckManager

func create_instance_deck(deck_data: DeckData, catalog: CatalogManager, owner_name: String = "player") -> Array[CardInstance]:
    var result: Array[CardInstance] = []
    for card_id in deck_data.card_quantities.keys():
        var card_data: CardData = catalog.get_card_by_id(card_id)
        if card_data == null:
            continue
        var quantity: int = int(deck_data.card_quantities[card_id])
        for i in range(quantity):
            var instance := CardInstance.new(card_data, owner_name)
            instance.zone = "DECK"
            result.append(instance)
    result.shuffle()
    return result

func draw_card(player_state: PlayerState) -> CardInstance:
    if player_state.deck.is_empty():
        return null
    var card: CardInstance = player_state.deck.pop_front()
    card.set_zone("HAND")
    player_state.hand.append(card)
    return card

func shuffle_deck(deck: Array[CardInstance]) -> Array[CardInstance]:
    deck.shuffle()
    return deck
