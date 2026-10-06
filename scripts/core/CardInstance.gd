extends RefCounted
class_name CardInstance

var instance_id: String = ""
var card_data: CardData
var owner: String = "player"
var zone: String = "DECK"
var attacks_used: bool = false
var summoned_this_turn: bool = false
var is_face_up: bool = true
var metadata: Dictionary = {}
var archetype: String = "NONE"
var attack_bonus: int = 0
var current_hp: int = 0
var attacks_remaining: int = 1

func _init(card: CardData, p_owner: String = "player"):
    card_data = card
    owner = p_owner
    instance_id = "%s_%s" % [card.id, str(Time.get_unix_time_from_system() + randi() % 100000)]
    zone = "DECK"
    archetype = card.archetype if card != null else "NONE"
    current_hp = card.hp if card != null else 0

func get_name() -> String:
    return card_data.name

func set_zone(new_zone: String) -> void:
    zone = new_zone.to_upper()

func get_attack() -> int:
    return int(card_data.attack) + attack_bonus

func get_hp() -> int:
    return current_hp

func get_cost() -> int:
    return int(card_data.cost)

func to_dictionary() -> Dictionary:
    return {
        "instance_id": instance_id,
        "card_id": card_data.id,
        "owner": owner,
        "zone": zone,
        "attacks_used": attacks_used,
        "summoned_this_turn": summoned_this_turn,
        "metadata": metadata,
        "archetype": archetype,
        "attack_bonus": attack_bonus,
        "current_hp": current_hp,
        "attacks_remaining": attacks_remaining,
    }
