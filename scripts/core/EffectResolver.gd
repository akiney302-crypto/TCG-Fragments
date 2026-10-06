extends RefCounted
class_name EffectResolver

func resolve_effect(card: CardInstance, context: Dictionary = {}) -> Dictionary:
    if card == null or card.card_data == null:
        return {"ok": false, "message": "No card data to resolve."}

    var effect: Dictionary = card.card_data.effect
    var effect_type: String = String(effect.get("type", "none"))
    var player: PlayerState = context.get("player", null)
    var opponent: PlayerState = context.get("opponent", null)
    var target: Variant = context.get("target_card", null)
    var game_manager: GameManager = context.get("game_manager", null)

    match effect_type:
        "none":
            return {"ok": true, "message": "No effect."}
        "heal_player":
            if player != null:
                player.heal(maxi(0, int(effect.get("amount", 1))))
            return {"ok": true, "message": "Player healed for %d." % int(effect.get("amount", 1))}
        "heal_troop":
            if not target is CardInstance or player == null or not player.field.has(target):
                return {"ok": false, "message": "Choose one of your units to heal."}
            target.current_hp = mini(target.card_data.hp, target.current_hp + maxi(0, int(effect.get("amount", 1))))
            return {"ok": true, "message": "%s healed." % target.get_name()}
        "max_hp":
            if player != null:
                var amount: int = maxi(0, int(effect.get("amount", 1)))
                player.max_hp += amount
                player.heal(amount)
            return {"ok": true, "message": "Maximum HP increased by %d." % int(effect.get("amount", 1))}
        "damage_player":
            if opponent != null:
                opponent.take_damage(maxi(0, int(effect.get("amount", 1))))
            return {"ok": true, "message": "The opponent took %d damage." % int(effect.get("amount", 1))}
        "damage_card":
            if not target is CardInstance or opponent == null or not opponent.field.has(target):
                return {"ok": false, "message": "Choose an enemy unit to damage."}
            target.current_hp -= maxi(0, int(effect.get("amount", 1)))
            if target.current_hp <= 0 and game_manager != null:
                return game_manager.destroy_card_instance(target)
            return {"ok": true, "message": "%s took damage." % target.get_name()}
        "destroy_target", "destroy_on_summon", "destroy_on_destroy":
            if not target is CardInstance or opponent == null or not opponent.field.has(target):
                return {"ok": false, "message": "Choose an enemy unit to destroy."}
            if game_manager != null:
                return game_manager.destroy_card_instance(target)
            return {"ok": false, "message": "The effect could not be resolved."}
        "draw_cards":
            if player == null or game_manager == null:
                return {"ok": false, "message": "The draw effect could not be resolved."}
            var drawn: int = game_manager.draw_cards_for_state(player, maxi(0, int(effect.get("amount", 1))))
            return {"ok": true, "message": "Drew %d card(s)." % drawn}
        "discard_random":
            if opponent == null or game_manager == null:
                return {"ok": false, "message": "The discard effect could not be resolved."}
            return game_manager.discard_random_card(opponent)
        "steal_random":
            if player == null or opponent == null or game_manager == null:
                return {"ok": false, "message": "The steal effect could not be resolved."}
            return game_manager.steal_random_card(player, opponent)
        _:
            return {"ok": false, "message": "Unknown effect: %s." % effect_type}
