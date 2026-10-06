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

func _ready() -> void:
    catalog.load_catalog("res://resources/cards/catalog.json")

func create_default_deck() -> DeckData:
    var deck: DeckData = DeckSaveManager.load_starter_deck("knight_starter")
    return deck if deck != null else DeckData.new("knight_starter", "Knight Training Deck")

func start_new_game(deck_override: DeckData = null, first_player_index: int = 0) -> void:
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

    player.draw_cards(GameRules.STARTING_HAND_SIZE)
    enemy.draw_cards(GameRules.STARTING_HAND_SIZE)

    turn_manager.current_turn = 1
    turn_manager.phase = "START"
    turn_manager.active_player_index = clampi(first_player_index, 0, 1)
    log_messages.append("%s won the coin toss and goes first." % ["Player" if first_player_index == 0 else "A.I."])
    if turn_manager.active_player_index == 1:
        execute_ai_turn()
        turn_manager.active_player_index = 0
    emit_signal("game_started")
    emit_signal("turn_started", turn_manager.current_turn, turn_manager.phase)

func begin_turn_for(player_name: String) -> void:
    var state: PlayerState = player if player_name == "player" else enemy
    if state == null:
        return

    state.gain_energy(GameRules.TURN_START_ENERGY_GAIN)
    state.draw_cards(GameRules.TURN_START_DRAW_COUNT)
    state.reset_turn_state()
    turn_manager.begin_turn()
    emit_signal("turn_started", turn_manager.current_turn, turn_manager.phase)

func advance_game_phase() -> void:
    turn_manager.advance_phase()
    if turn_manager.phase == "END":
        emit_signal("turn_started", turn_manager.current_turn, turn_manager.phase)
        return
    emit_signal("turn_started", turn_manager.current_turn, turn_manager.phase)

func process_phase() -> void:
    match turn_manager.phase:
        "START":
            if turn_manager.active_player_index == 0:
                begin_turn_for("player")
            else:
                begin_turn_for("enemy")
        "MAIN":
            pass
        "BATTLE":
            pass
        "END":
            if turn_manager.active_player_index == 0:
                end_turn()
            else:
                execute_ai_turn()

func check_victory() -> String:
    if player.hp <= 0 and enemy.hp <= 0:
        return "draw"
    if player.hp <= 0:
        return "enemy"
    if enemy.hp <= 0:
        return "player"
    return "ongoing"

func play_card_from_hand(card: CardInstance, target: Variant = null) -> Dictionary:
    if player == null:
        return {"ok": false, "message": "Game not initialized."}
    if card == null:
        return {"ok": false, "message": "No card selected."}
    if not RuleManager.can_play_card(player, card):
        return {"ok": false, "message": "Cannot play this card."}
    if player.field.size() >= GameRules.MAX_FIELD_SIZE:
        return {"ok": false, "message": "Field is full."}

    player.hand.erase(card)
    player.energy -= card.card_data.cost
    card.set_zone("FIELD")
    var synergy_result: Dictionary = archetype_manager.activate_champion_synergy(player, card, enemy, catalog)
    player.field.append(card)
    if synergy_result["activated"]:
        log_messages.append(synergy_result["message"])

    var effect_result := effect_resolver.resolve_effect(card, {"player": player, "target": target})
    log_messages.append(effect_result["message"])

    return {"ok": true, "card": card, "effect": effect_result}

func attack(attacker: CardInstance, target: Variant) -> Dictionary:
    if not RuleManager.can_attack(attacker, player):
        return {"ok": false, "message": "Attacker cannot attack."}

    var result := combat_manager.resolve_attack(attacker, target, {"player": player, "enemy": enemy})
    emit_signal("battle_resolved", result)
    if result.get("ok", false):
        if target is PlayerState:
            log_messages.append("%s attacked %s for %d damage." % [attacker.get_name(), target.name_label, attacker.get_attack()])
        elif target is CardInstance:
            log_messages.append("%s attacked %s for %d damage." % [attacker.get_name(), target.get_name(), attacker.get_attack()])

    return result

func end_turn() -> void:
    if player == null:
        return

    player.energy = min(player.max_energy, player.energy + 1)
    player.draw_cards(1)
    player.reset_turn_state()

    enemy.energy = min(enemy.max_energy, enemy.energy + 1)
    enemy.draw_cards(1)
    enemy.reset_turn_state()

    turn_manager.start_next_turn()
    emit_signal("turn_started", turn_manager.current_turn, turn_manager.phase)

    log_messages.append("Turn advanced to %s." % [turn_manager.phase])

    var winner: String = check_victory()
    if winner != "ongoing":
        emit_signal("game_over", winner)

func execute_ai_turn() -> void:
    if enemy == null:
        return

    var action: Dictionary = ai_controller.choose_action(enemy, player, catalog)
    if action["type"] == "play":
        var card: CardInstance = action["card"]
        enemy.hand.erase(card)
        enemy.energy -= card.card_data.cost
        card.set_zone("FIELD")
        var synergy_result: Dictionary = archetype_manager.activate_champion_synergy(enemy, card, player, catalog)
        enemy.field.append(card)
        if synergy_result["activated"]:
            log_messages.append(synergy_result["message"])
    elif action["type"] == "attack":
        var attacker: CardInstance = action["attacker"]
        combat_manager.resolve_attack(attacker, player, {"enemy": enemy, "player": player})
    else:
        end_turn()
