extends RefCounted
class_name AIController

func choose_action(player: PlayerState, opponent: PlayerState, catalog: CatalogManager) -> Dictionary:
    var playable_cards: Array[Dictionary] = []
    for card in player.hand:
        if RuleManager.can_play_card(player, card):
            var target: Variant = opponent
            var effect_type: String = String(card.card_data.effect.get("type", "none"))
            if effect_type in ["damage_card", "destroy_target", "destroy_on_destroy", "destroy_on_summon"]:
                target = _weakest_card(opponent.field)
                if target == null:
                    continue
            elif effect_type == "heal_troop":
                target = _most_damaged_card(player.field)
                if target == null:
                    continue
            playable_cards.append({"card": card, "target": target})

    if not playable_cards.is_empty():
        playable_cards.sort_custom(func(a, b):
            return a["card"].card_data.cost < b["card"].card_data.cost
        )
        var best_action: Dictionary = playable_cards[0]
        return {"type": "play", "card": best_action["card"], "target": best_action["target"]}

    for attacker in player.field:
        if RuleManager.can_attack(attacker, player):
            var target: Variant = opponent
            return {"type": "attack", "attacker": attacker, "target": target}

    return {"type": "end_turn"}

func _weakest_card(cards: Array[CardInstance]) -> CardInstance:
    var weakest: CardInstance = null
    for card in cards:
        if weakest == null or card.get_hp() < weakest.get_hp():
            weakest = card
    return weakest

func _most_damaged_card(cards: Array[CardInstance]) -> CardInstance:
    var most_damaged: CardInstance = null
    var missing_hp: int = 0
    for card in cards:
        var card_missing_hp: int = card.card_data.hp - card.get_hp()
        if card_missing_hp > missing_hp:
            missing_hp = card_missing_hp
            most_damaged = card
    return most_damaged
