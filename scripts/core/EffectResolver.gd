extends RefCounted
class_name EffectResolver

func resolve_effect(card: CardInstance, context: Dictionary = {}) -> Dictionary:
    if card == null or card.card_data == null:
        return {"ok": false, "message": "No card data to resolve."}

    var effect: Dictionary = card.card_data.effect
    if effect.is_empty():
        return {"ok": true, "message": "No effect"}

    match effect.get("type", "none"):
        "heal_player":
            var player: PlayerState = context.get("player", null)
            if player != null:
                player.heal(int(effect.get("amount", 1)))
            return {"ok": true, "message": "Player healed."}
        "heal_troop":
            var troop: CardInstance = context.get("target_card", null)
            if troop != null:
                troop.current_hp += int(effect.get("amount", 1))
            return {"ok": true, "message": "Troop healed."}
        "max_hp":
            var player: PlayerState = context.get("player", null)
            if player != null:
                player.max_hp += int(effect.get("amount", 1))
                player.hp += int(effect.get("amount", 1))
            return {"ok": true, "message": "Max HP increased."}
        "destroy_on_summon":
            return {"ok": true, "message": "Destroy-on-summon trigger prepared."}
        "destroy_on_destroy":
            return {"ok": true, "message": "Destroy-on-destroy trigger prepared."}
        _:
            return {"ok": true, "message": "No matching effect."}
