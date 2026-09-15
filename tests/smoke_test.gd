extends SceneTree

var failures: int = 0

func _init() -> void:
	_test_card_and_deck_flow()
	_test_rules_and_combat()
	_test_types_and_effects()
	if failures == 0:
		print("SMOKE TEST PASSED")
		quit(0)
	else:
		print("SMOKE TEST FAILED: %d" % failures)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_card_and_deck_flow() -> void:
	var card_data: CardData = load("res://resources/cards/test_guard.tres") as CardData
	var deck_data: DeckData = DeckData.new()
	deck_data.cards = [card_data, card_data]
	var deck_manager: DeckManager = DeckManager.new()
	deck_manager.setup_from_data(deck_data)
	_check(deck_manager.deck.size() == 2, "El mazo debe crear dos instancias")
	var drawn_card: CardInstance = deck_manager.draw_card()
	_check(drawn_card != null, "El robo debe devolver una carta")
	_check(deck_manager.hand.size() == 1, "La carta robada debe entrar en la mano")
	_check(drawn_card.zone == CardInstance.Zone.HAND, "La zona de la carta debe ser HAND")

func _test_rules_and_combat() -> void:
	var card_data: CardData = load("res://resources/cards/test_guard.tres") as CardData
	var deck_data: DeckData = DeckData.new()
	deck_data.cards = [card_data]
	var deck_manager: DeckManager = DeckManager.new()
	deck_manager.setup_from_data(deck_data)
	var player: PlayerState = PlayerState.new(0)
	player.deck_manager = deck_manager
	player.energy = 1
	var rule_manager: RuleManager = RuleManager.new()
	var card: CardInstance = deck_manager.draw_card()
	_check(rule_manager.can_play_card(player, card), "Una unidad asequible debe poder jugarse")
	_check(deck_manager.play_card(card), "La carta debe poder pasar al campo")
	_check(not rule_manager.can_play_card(player, card), "Una carta en campo no debe poder jugarse otra vez")
	_check(rule_manager.can_attack(player, card), "Una unidad en campo debe poder atacar")
	card.current_life = 0
	_check(deck_manager.send_to_graveyard(card), "Una unidad destruida debe ir al cementerio")
	_check(deck_manager.graveyard.has(card), "La unidad destruida debe quedar registrada en el cementerio")
	card = CardInstance.new(card_data)
	deck_manager.field.append(card)
	card.zone = CardInstance.Zone.FIELD
	var opponent: PlayerState = PlayerState.new(1)
	var combat_manager: CombatManager = CombatManager.new()
	_check(combat_manager.attack_direct(player, opponent, card), "El ataque directo debe resolverse")
	_check(opponent.life == 18, "El ataque debe restar el ataque de la carta")
	_check(not rule_manager.can_attack(player, card), "Una carta no debe atacar dos veces en el mismo turno")

	var demo_deck: DeckData = load("res://resources/decks/demo_deck.tres") as DeckData
	_check(demo_deck.cards.size() == 20, "El mazo de demo debe tener 20 cartas")


func _test_types_and_effects() -> void:
	var champion_data: CardData = load("res://resources/cards/test_dragon.tres") as CardData
	var champion_deck: DeckData = DeckData.new()
	champion_deck.cards = [champion_data, champion_data]
	var champion_manager: DeckManager = DeckManager.new()
	champion_manager.setup_from_data(champion_deck)
	_check(champion_manager.deck.size() == 1, "Un Champion no debe superar una copia")

	var truth_data: CardData = load("res://resources/cards/test_spell.tres") as CardData
	var truth_instance: CardInstance = CardInstance.new(truth_data)
	var owner: PlayerState = PlayerState.new(0)
	var opponent: PlayerState = PlayerState.new(1)
	var effect_manager: EffectManager = EffectManager.new()
	effect_manager.resolve_play_effect(truth_instance, owner, opponent)
	_check(opponent.life == 18, "Una Truth de dano debe reducir la vida rival")
