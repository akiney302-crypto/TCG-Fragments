extends RefCounted
class_name RuleManager

static func can_play_card(player: PlayerState, card: CardInstance) -> bool:
    if player == null or card == null:
        return false
    if card.zone != "HAND":
        return false
    if player.energy < card.card_data.cost:
        return false
    if card.card_data.type in ["TROOP", "CHAMPION"] and player.field.size() >= GameRules.MAX_FIELD_SIZE:
        return false
    return true

static func can_attack(attacker: CardInstance, player: PlayerState) -> bool:
    if attacker == null or player == null:
        return false
    if attacker.zone != "FIELD":
        return false
    if attacker.attacks_remaining <= 0:
        return false
    if player.field.has(attacker) == false:
        return false
    return true

static func is_valid_target(target_type: String) -> bool:
    return GameRules.get_valid_target_types().has(target_type.to_upper())

static func can_end_turn(player: PlayerState) -> bool:
    return player != null
