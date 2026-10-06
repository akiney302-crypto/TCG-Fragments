extends RefCounted
class_name PlayerState

var name_label: String = "Player"
var is_ai: bool = false
var hp: int = GameRules.STARTING_HP
var max_hp: int = GameRules.MAX_HP
var energy: int = GameRules.STARTING_ENERGY
var max_energy: int = GameRules.MAX_ENERGY
var hand: Array[CardInstance] = []
var field: Array[CardInstance] = []
var deck: Array[CardInstance] = []
var graveyard: Array[CardInstance] = []
var attacks_used_this_turn: int = 0
var summon_sickness: bool = false
var alive: bool = true

func _init(player_name: String = "Player", ai_enabled: bool = false):
    name_label = player_name
    is_ai = ai_enabled
    reset_stats()

func reset_stats() -> void:
    hp = GameRules.STARTING_HP
    max_hp = GameRules.MAX_HP
    energy = GameRules.STARTING_ENERGY
    max_energy = GameRules.MAX_ENERGY
    hand.clear()
    field.clear()
    deck.clear()
    graveyard.clear()
    attacks_used_this_turn = 0
    summon_sickness = false
    alive = true

func draw_cards(amount: int) -> Array[CardInstance]:
    var drawn: Array[CardInstance] = []
    var remaining: int = amount
    while remaining > 0 and deck.size() > 0 and hand.size() < GameRules.MAX_HAND_SIZE:
        var card: CardInstance = deck.pop_front()
        card.set_zone("HAND")
        hand.append(card)
        drawn.append(card)
        remaining -= 1
    return drawn

func gain_energy(amount: int = 1) -> void:
    energy = clamp(energy + amount, 0, max_energy)

func add_card_to_zone(card: CardInstance, zone_name: String) -> void:
    card.set_zone(zone_name)
    card.owner = name_label
    match zone_name.to_upper():
        "HAND":
            if not hand.has(card):
                hand.append(card)
        "FIELD":
            if not field.has(card):
                field.append(card)
        "GRAVEYARD":
            if not graveyard.has(card):
                graveyard.append(card)
        "DECK":
            if not deck.has(card):
                deck.append(card)

func remove_card_from_zone(card: CardInstance) -> void:
    hand.erase(card)
    field.erase(card)
    graveyard.erase(card)
    deck.erase(card)

func reset_turn_state() -> void:
    attacks_used_this_turn = 0
    summon_sickness = false
    for card in field:
        card.attacks_used = false
        card.attacks_remaining = 1
        card.summoned_this_turn = false

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    alive = hp > 0

func heal(amount: int) -> void:
    hp = min(max_hp, hp + amount)
    alive = hp > 0

func get_field_size() -> int:
    return field.size()

func get_hand_size() -> int:
    return hand.size()
