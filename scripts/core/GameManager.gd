extends Node
class_name GameManager

var catalog: CatalogManager = CatalogManager.new()
var deck_manager: DeckManager = DeckManager.new()
var validator: DeckValidator = DeckValidator.new()
var rule_manager: RuleManager = RuleManager.new()
var turn_manager: TurnManager = TurnManager.new()
var combat_manager: CombatManager = CombatManager.new()
var effect_resolver: EffectResolver = EffectResolver.new()
var ai_controller: AIController = AIController.new()
var archetype_manager: ArchetypeManager = ArchetypeManager.new()

var player: PlayerState
var enemy: PlayerState
var deck_data: DeckData
var active_deck: DeckData
var log_messages: Array[String] = []

signal game_started
signal turn_started(turn_number, phase)
signal battle_resolved(result)
signal game_over(winner)
signal card_moved(card, from_zone, to_zone, owner, source_owner)
signal sound_requested(sound_name)

func _ready() -> void:
    catalog.load_catalog("res://resources/cards/catalog.json")

func create_default_deck() -> DeckData:
    var deck: DeckData = DeckSaveManager.load_starter_deck("knight_starter")
    return deck if deck != null else DeckData.new("knight_starter", "Knight Training Deck")

func start_new_game(deck_override: DeckData = null, first_player_index: int = 0) -> void:
    log_messages.clear()
    player = PlayerState.new("Player", false)
    enemy = PlayerState.new("A.I.", true)

    active_deck = deck_override.clone() if deck_override != null else DeckSaveManager.load_active_deck()
    if active_deck == null:
        active_deck = create_default_deck()
    var validation := validator.validate(active_deck, catalog)
    if not validation["valid"]:
        push_warning("Selected deck is invalid; using Knight Training Deck: %s" % [str(validation["errors"])])
        active_deck = create_default_deck()

    deck_data = active_deck.clone()
    deck_data.family_name = archetype_manager.get_deck_family(deck_data, catalog)

    player.deck = deck_manager.create_instance_deck(deck_data, catalog, "player")
    enemy.deck = deck_manager.create_instance_deck(create_default_deck(), catalog, "enemy")

    emit_signal("sound_requested", "shuffle")
    emit_signal("sound_requested", "shuffle")
    _draw_cards_for(player, GameRules.OPENING_HAND_SIZE)
    _draw_cards_for(enemy, GameRules.OPENING_HAND_SIZE)

    turn_manager.current_turn = 1
    turn_manager.active_player_index = clampi(first_player_index, 0, 1)
    log_messages.append("%s won the coin toss and goes first." % ["Player" if turn_manager.active_player_index == 0 else "A.I."])
    _begin_active_turn()
    emit_signal("game_started")

func begin_turn_for(player_name: String) -> void:
    var state: PlayerState = player if player_name == "player" else enemy
    if state == null:
        return
    _begin_turn(state)

func _begin_active_turn() -> void:
    _begin_turn(player if turn_manager.active_player_index == 0 else enemy)

func _begin_turn(state: PlayerState) -> void:
    if state == null:
        return
    state.reset_turn_state()
    state.gain_energy(GameRules.TURN_START_ENERGY_GAIN)
    _draw_cards_for(state, GameRules.TURN_START_DRAW_COUNT)
    turn_manager.begin_turn()
    emit_signal("turn_started", turn_manager.current_turn, turn_manager.phase)

func _draw_cards_for(state: PlayerState, amount: int) -> int:
    var drawn_count: int = 0
    for index in range(amount):
        if state.hand.size() >= GameRules.MAX_HAND_SIZE:
            break
        var card: CardInstance = deck_manager.draw_card(state)
        if card == null:
            break
        var owner: String = "enemy" if state.is_ai else "player"
        emit_signal("card_moved", card, "DECK", "HAND", owner, owner)
        drawn_count += 1
    return drawn_count

func advance_game_phase() -> void:
    if turn_manager.phase == "END_TURN":
        return
    turn_manager.advance_phase()
    emit_signal("turn_started", turn_manager.current_turn, turn_manager.phase)

func process_phase() -> void:
    if turn_manager.active_player_index == 1:
        execute_ai_phase()

func check_victory() -> String:
    if player.hp <= 0 and enemy.hp <= 0:
        return "draw"
    if player.hp <= 0:
        return "enemy"
    if enemy.hp <= 0:
        return "player"
    return "ongoing"

func play_card_from_hand(card: CardInstance, target: Variant = null) -> Dictionary:
    if player == null or turn_manager.active_player_index != 0:
        return {"ok": false, "message": "It is not your turn."}
    if card == null or card.card_data == null:
        return {"ok": false, "message": "No card selected."}
    if turn_manager.phase not in ["PLACEMENT_1", "PLACEMENT_2"]:
        return {"ok": false, "message": "Cards can only be placed during a placement phase."}
    if card_requires_target(card.card_data) and not is_valid_effect_target(player, enemy, card.card_data, target):
        return {"ok": false, "message": "Select a valid target for this card's effect."}
    return _play_card_for(player, enemy, card, target)

func card_requires_target(card_data: CardData) -> bool:
    if card_data == null:
        return false
    return String(card_data.effect.get("type", "none")) in ["heal_troop", "damage_card", "destroy_target", "destroy_on_destroy", "destroy_on_summon"]

func is_valid_effect_target(state: PlayerState, opponent: PlayerState, card_data: CardData, target: Variant) -> bool:
    if card_data == null or not target is CardInstance:
        return false
    var effect_type: String = String(card_data.effect.get("type", "none"))
    if effect_type == "heal_troop":
        return state.field.has(target)
    if effect_type in ["damage_card", "destroy_target", "destroy_on_destroy", "destroy_on_summon"]:
        return opponent.field.has(target)
    return true

func _play_card_for(state: PlayerState, opponent: PlayerState, card: CardInstance, target: Variant = null) -> Dictionary:
    if state == null or card == null:
        return {"ok": false, "message": "No card selected."}
    if not RuleManager.can_play_card(state, card):
        return {"ok": false, "message": "Cannot play this card."}
    if card_requires_target(card.card_data) and not is_valid_effect_target(state, opponent, card.card_data, target):
        return {"ok": false, "message": "No legal effect target is available."}
    var is_unit: bool = card.card_data.type in ["TROOP", "CHAMPION"]
    if is_unit and state.field.size() >= GameRules.MAX_FIELD_SIZE:
        return {"ok": false, "message": "Field is full."}

    var hand_before: Dictionary = {}
    for held_card in state.hand:
        hand_before[held_card.instance_id] = true
    var opponent_hand_before: Dictionary = {}
    for held_card in opponent.hand:
        opponent_hand_before[held_card.instance_id] = true
    state.hand.erase(card)
    state.energy -= card.card_data.cost
    var owner: String = "enemy" if state.is_ai else "player"
    if is_unit:
        card.set_zone("FIELD")
        card.summoned_this_turn = true
        state.field.append(card)
        emit_signal("card_moved", card, "HAND", "FIELD", owner, owner)
        emit_signal("sound_requested", "summon")
    else:
        card.set_zone("GRAVEYARD")
        state.graveyard.append(card)
        emit_signal("card_moved", card, "HAND", "GRAVEYARD", owner, owner)
        emit_signal("sound_requested", "effect")
    var opponent_graveyard_size: int = opponent.graveyard.size()
    var field_size_before_synergy: int = state.field.size()
    if is_unit and card.card_data.type == "CHAMPION":
        var synergy_result: Dictionary = archetype_manager.activate_champion_synergy(state, card, opponent, catalog)
        if synergy_result["activated"]:
            log_messages.append(synergy_result["message"])
            emit_signal("sound_requested", "effect")
    for index in range(opponent_graveyard_size, opponent.graveyard.size()):
        var moved_card: CardInstance = opponent.graveyard[index]
        var source_zone: String = "HAND" if opponent_hand_before.has(moved_card.instance_id) else "FIELD"
        emit_signal("card_moved", moved_card, source_zone, "GRAVEYARD", "enemy" if opponent.is_ai else "player", "enemy" if opponent.is_ai else "player")
        emit_signal("sound_requested", "discard" if source_zone == "HAND" else "destroy")
    for index in range(field_size_before_synergy, state.field.size()):
        var token: CardInstance = state.field[index]
        emit_signal("card_moved", token, "SUMMON", "FIELD", owner, owner)
        emit_signal("sound_requested", "summon")

    var effect_result: Dictionary = effect_resolver.resolve_effect(card, {
        "player": state,
        "opponent": opponent,
        "target_card": target,
        "game_manager": self,
    })
    if card.card_data.effect.get("type", "none") != "none":
        emit_signal("sound_requested", "effect")
    log_messages.append(effect_result["message"])
    for held_card in state.hand:
        if not hand_before.has(held_card.instance_id):
            if opponent_hand_before.has(held_card.instance_id):
                emit_signal("card_moved", held_card, "HAND", "HAND", owner, "enemy" if opponent.is_ai else "player")
            else:
                emit_signal("card_moved", held_card, "DECK", "HAND", owner, owner)
    var winner: String = check_victory()
    if winner != "ongoing":
        emit_signal("game_over", winner)
    return {"ok": true, "card": card, "effect": effect_result}

func draw_cards_for_state(state: PlayerState, amount: int) -> int:
    if state == null:
        return 0
    return _draw_cards_for(state, amount)

func destroy_card_instance(card: CardInstance) -> Dictionary:
    if card == null:
        return {"ok": false, "message": "No target card."}
    var owner_state: PlayerState = player if card.owner == "player" else enemy
    if owner_state == null or not owner_state.field.has(card):
        return {"ok": false, "message": "Target is not on the field."}
    owner_state.field.erase(card)
    card.set_zone("GRAVEYARD")
    owner_state.graveyard.append(card)
    var card_owner: String = "enemy" if owner_state.is_ai else "player"
    emit_signal("card_moved", card, "FIELD", "GRAVEYARD", card_owner, card_owner)
    emit_signal("sound_requested", "destroy")
    return {"ok": true, "destroyed": card, "message": "%s was destroyed." % card.get_name()}

func discard_random_card(state: PlayerState) -> Dictionary:
    if state == null or state.hand.is_empty():
        return {"ok": false, "message": "The opponent has no card to discard."}
    var card: CardInstance = state.hand.pop_at(randi_range(0, state.hand.size() - 1))
    card.set_zone("GRAVEYARD")
    state.graveyard.append(card)
    var owner: String = "enemy" if state.is_ai else "player"
    emit_signal("card_moved", card, "HAND", "GRAVEYARD", owner, owner)
    emit_signal("sound_requested", "discard")
    return {"ok": true, "card": card}

func steal_random_card(receiver: PlayerState, source: PlayerState) -> Dictionary:
    if receiver == null or source == null or source.hand.is_empty():
        return {"ok": false, "message": "No card can be stolen."}
    if receiver.hand.size() >= GameRules.MAX_HAND_SIZE:
        return {"ok": false, "message": "Your hand is full."}
    var card: CardInstance = source.hand.pop_at(randi_range(0, source.hand.size() - 1))
    card.owner = "enemy" if receiver.is_ai else "player"
    card.set_zone("HAND")
    receiver.hand.append(card)
    var owner: String = "enemy" if receiver.is_ai else "player"
    var source_owner: String = "enemy" if source.is_ai else "player"
    emit_signal("card_moved", card, "HAND", "HAND", owner, source_owner)
    emit_signal("sound_requested", "effect")
    return {"ok": true, "card": card}

func discard_card_from_hand(card: CardInstance) -> Dictionary:
    if turn_manager.active_player_index != 0 or turn_manager.phase not in ["PLACEMENT_1", "PLACEMENT_2"]:
        return {"ok": false, "message": "You can only discard during a placement phase."}
    if card == null or not player.hand.has(card):
        return {"ok": false, "message": "Select a card in your hand."}
    player.hand.erase(card)
    card.set_zone("GRAVEYARD")
    player.graveyard.append(card)
    emit_signal("card_moved", card, "HAND", "GRAVEYARD", "player", "player")
    emit_signal("sound_requested", "discard")
    return {"ok": true, "card": card}

func attack(attacker: CardInstance, target: Variant) -> Dictionary:
    if turn_manager.active_player_index != 0 or turn_manager.phase != "ATTACK":
        return {"ok": false, "message": "Attacks are only allowed during the attack phase."}
    return _attack_for(player, enemy, attacker, target)

func _attack_for(state: PlayerState, opponent: PlayerState, attacker: CardInstance, target: Variant) -> Dictionary:
    if not RuleManager.can_attack(attacker, state):
        return {"ok": false, "message": "Attacker cannot attack."}
    var states: Dictionary = {"player": player, "enemy": enemy}
    var result: Dictionary = combat_manager.resolve_attack(attacker, target, states)
    emit_signal("battle_resolved", result)
    if result.get("ok", false):
        log_messages.append("%s attacked for %d damage." % [attacker.get_name(), attacker.get_attack()])
        emit_signal("sound_requested", "damage")
        if result.has("destroyed"):
            var destroyed: CardInstance = result["destroyed"]
            emit_signal("card_moved", destroyed, "FIELD", "GRAVEYARD", destroyed.owner, destroyed.owner)
            emit_signal("sound_requested", "destroy")
    var winner: String = check_victory()
    if winner != "ongoing":
        emit_signal("game_over", winner)
    return result

func end_turn(requesting_player_index: int = -1) -> bool:
    if player == null or enemy == null or check_victory() != "ongoing":
        return false
    if requesting_player_index >= 0 and requesting_player_index != turn_manager.active_player_index:
        return false
    turn_manager.start_next_turn()
    log_messages.append("Turn %d: %s begins." % [turn_manager.current_turn, "Player" if turn_manager.active_player_index == 0 else "A.I."])
    _begin_active_turn()
    return true

func execute_ai_phase() -> void:
    if enemy == null or turn_manager.active_player_index != 1:
        return
    if turn_manager.phase in ["PLACEMENT_1", "PLACEMENT_2"]:
        var action: Dictionary = ai_controller.choose_action(enemy, player, catalog)
        if action.get("type") == "play":
            _play_card_for(enemy, player, action["card"], action.get("target", player))
    elif turn_manager.phase == "ATTACK":
        for attacker in enemy.field.duplicate():
            if RuleManager.can_attack(attacker, enemy):
                _attack_for(enemy, player, attacker, player)

func execute_ai_turn() -> void:
    await run_ai_turn()

func run_ai_turn() -> void:
    if turn_manager.active_player_index != 1:
        return
    while turn_manager.active_player_index == 1 and check_victory() == "ongoing":
        await get_tree().create_timer(0.4, false).timeout
        if turn_manager.phase == "END_TURN":
            end_turn(1)
        else:
            if turn_manager.phase != "DRAW":
                execute_ai_phase()
            advance_game_phase()
