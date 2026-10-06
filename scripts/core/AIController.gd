extends RefCounted
class_name AIController

func choose_action(player: PlayerState, opponent: PlayerState, catalog: CatalogManager) -> Dictionary:
    var playable_cards: Array[CardInstance] = []
    for card in player.hand:
        if RuleManager.can_play_card(player, card):
            playable_cards.append(card)

    if not playable_cards.is_empty():
        playable_cards.sort_custom(func(a, b):
            return a.card_data.cost < b.card_data.cost
        )
        var best_card: CardInstance = playable_cards[0]
        return {"type": "play", "card": best_card, "target": opponent}

    for attacker in player.field:
        if RuleManager.can_attack(attacker, player):
            var target: Variant = opponent
            return {"type": "attack", "attacker": attacker, "target": target}

    return {"type": "end_turn"}
