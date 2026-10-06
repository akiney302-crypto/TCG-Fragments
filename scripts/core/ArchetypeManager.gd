extends RefCounted
class_name ArchetypeManager

func get_deck_family(deck: DeckData, catalog: CatalogManager) -> String:
    if deck == null:
        return "NONE"

    var counts: Dictionary = {}
    for card_id in deck.card_quantities.keys():
        var card: CardData = catalog.get_card_by_id(card_id)
        if card == null:
            continue
        var key: String = card.archetype if card.archetype != "" else "NONE"
        counts[key] = int(counts.get(key, 0)) + int(deck.card_quantities[card_id])

    var winner: String = "NONE"
    var winner_value: int = 0
    for key in counts.keys():
        var value: int = int(counts[key])
        if value > winner_value:
            winner = str(key)
            winner_value = value
    return winner.to_upper()

func get_synergy_count(player: PlayerState, archetype_name: String) -> int:
    if player == null:
        return 0
    var count: int = 0
    for card in player.field:
        if card.archetype.to_upper() == archetype_name.to_upper():
            count += 1
    return count

func has_synergy(player: PlayerState, archetype_name: String) -> bool:
    return get_synergy_count(player, archetype_name) >= GameRules.SYNERGY_THRESHOLD

func activate_champion_synergy(player: PlayerState, champion: CardInstance, opponent: PlayerState = null, catalog: CatalogManager = null) -> Dictionary:
    if player == null or champion == null or champion.card_data == null:
        return {"activated": false, "message": ""}
    if champion.card_data.type != "CHAMPION":
        return {"activated": false, "message": ""}

    var synergy: Dictionary = champion.card_data.champion_synergy
    if synergy.is_empty():
        return {"activated": false, "message": ""}

    var required_archetype: String = String(synergy.get("archetype", "NONE")).to_upper()
    var required_allies: int = int(synergy.get("min_allies", GameRules.SYNERGY_THRESHOLD))
    if get_synergy_count(player, required_archetype) < required_allies:
        return {"activated": false, "message": ""}

    champion.attack_bonus += int(synergy.get("attack_bonus", 0))
    var extra_attacks: int = int(synergy.get("extra_attacks", 0))
    champion.attacks_remaining += extra_attacks
    var heal_amount: int = int(synergy.get("heal", 0))
    var draw_count: int = int(synergy.get("draw", 0))
    var message_parts: Array[String] = []
    if int(synergy.get("attack_bonus", 0)) > 0:
        message_parts.append("+%d attack" % int(synergy.get("attack_bonus", 0)))
    if extra_attacks > 0:
        message_parts.append("%d extra attack(s) this turn" % extra_attacks)
    if heal_amount > 0:
        player.heal(heal_amount)
        message_parts.append("heal %d" % heal_amount)
    if draw_count > 0:
        player.draw_cards(draw_count)
        message_parts.append("draw %d" % draw_count)

    var opponent_action: String = String(synergy.get("opponent_hand_action", ""))
    if opponent != null and opponent.hand.size() > 0 and opponent_action != "":
        var selected_index: int = randi_range(0, opponent.hand.size() - 1)
        var affected_card: CardInstance = opponent.hand[selected_index]
        opponent.hand.remove_at(selected_index)
        if opponent_action == "steal":
            affected_card.owner = champion.owner
            affected_card.set_zone("HAND")
            player.hand.append(affected_card)
            message_parts.append("steal %s" % affected_card.get_name())
        else:
            affected_card.set_zone("GRAVEYARD")
            opponent.graveyard.append(affected_card)
            message_parts.append("discard %s from rival hand" % affected_card.get_name())

    if opponent != null and opponent.field.size() > 0 and bool(synergy.get("destroy_weakest_enemy", false)):
        var weakest: CardInstance = opponent.field[0]
        for enemy_card in opponent.field:
            if enemy_card.get_hp() < weakest.get_hp():
                weakest = enemy_card
        opponent.field.erase(weakest)
        weakest.set_zone("GRAVEYARD")
        opponent.graveyard.append(weakest)
        message_parts.append("destroy %s" % weakest.get_name())

    var token_count: int = int(synergy.get("spawn_token_count", 0))
    var token_id: String = String(synergy.get("token_id", ""))
    var token_slots: int = GameRules.MAX_FIELD_SIZE - player.field.size() - 1
    if token_slots > 0 and token_count > 0 and catalog != null:
        var token_data: CardData = catalog.get_card_by_id(token_id)
        if token_data != null:
            var spawned: int = min(token_count, token_slots)
            for index in range(spawned):
                var token := CardInstance.new(token_data, champion.owner)
                token.set_zone("FIELD")
                player.field.append(token)
            message_parts.append("summon %d %s token(s)" % [spawned, token_data.name])

    var message: String = "%s synergy activated" % champion.get_name()
    if message_parts.is_empty():
        message += "."
    else:
        message += ": " + ", ".join(message_parts) + "."
    return {"activated": true, "message": message}

func count_archetype_cards(cards: Array[CardInstance]) -> Dictionary:
    var result: Dictionary = {}
    for card in cards:
        if card == null:
            continue
        var family: String = card.archetype.to_upper()
        result[family] = int(result.get(family, 0)) + 1
    return result
