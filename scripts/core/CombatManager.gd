extends RefCounted
class_name CombatManager

func resolve_attack(attacker: CardInstance, target: Variant, player_states: Dictionary) -> Dictionary:
    if attacker == null:
        return {"ok": false, "message": "No attacker selected."}

    var source_player: PlayerState = player_states.get(attacker.owner, null)
    if source_player == null:
        return {"ok": false, "message": "Source player not found."}

    var target_player: PlayerState = null
    var target_card: CardInstance = null

    if target is PlayerState:
        target_player = target
    elif target is CardInstance:
        target_card = target
        target_player = player_states.get(target.owner, null)

    if target_player == null and target_card == null:
        return {"ok": false, "message": "No valid target."}

    if target_card != null:
        target_card.current_hp -= max(0, attacker.get_attack())
        if target_card.current_hp <= 0:
            var destroy_result: Dictionary = destroy_card(target_card, player_states)
            _consume_attack(attacker)
            return destroy_result
        _consume_attack(attacker)
        return {"ok": true, "attacker": attacker, "target": target_card, "damage": attacker.get_attack()}

    if target_player != null:
        target_player.take_damage(attacker.get_attack())
        _consume_attack(attacker)
        return {"ok": true, "attacker": attacker, "target": target_player, "damage": attacker.get_attack()}

    return {"ok": false, "message": "Attack could not be resolved."}

func _consume_attack(attacker: CardInstance) -> void:
    attacker.attacks_remaining = max(0, attacker.attacks_remaining - 1)
    attacker.attacks_used = attacker.attacks_remaining == 0

func destroy_card(card: CardInstance, player_states: Dictionary) -> Dictionary:
    if card == null:
        return {"ok": false, "message": "No card to destroy."}

    var owner_state: PlayerState = player_states.get(card.owner, null)
    if owner_state != null:
        owner_state.field.erase(card)
        owner_state.graveyard.append(card)
        card.zone = "GRAVEYARD"

    return {"ok": true, "destroyed": card, "message": "%s was destroyed." % [card.get_name()]}
