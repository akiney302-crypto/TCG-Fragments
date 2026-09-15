class_name OpponentController
extends Node

## Controlador provisional de la plaza del oponente.
##
## Esta clase es deliberadamente sencilla: sirve como primer agente que toma
## decisiones y deja libre la puerta a sustituirlo por un jugador humano,
## una IA mas avanzada o una conexion de red sin cambiar las reglas.

func take_turn(game_manager: GameManager) -> void:
	if game_manager == null or game_manager.match_finished:
		return

	var opponent: PlayerState = game_manager.get_active_player()
	if opponent.player_id != 1:
		return

	_play_affordable_units(game_manager, opponent)
	game_manager.phase = GameManager.Phase.COMBAT
	_attack_best_targets(game_manager, opponent)
	game_manager.phase = GameManager.Phase.MAIN_2
	_play_affordable_units(game_manager, opponent)
	game_manager.finish_opponent_turn()


func _play_affordable_units(game_manager: GameManager, opponent: PlayerState) -> void:
	# Prioriza valor de mesa y efectos ofensivos, no solo el coste.
	while opponent.energy > 0 and opponent.deck_manager.field.size() < RuleManager.MAX_FIELD_CARDS:
		var candidate: CardInstance = _find_best_playable(opponent)
		if candidate == null:
			return

		game_manager.select_card(candidate)
		if not game_manager.try_play_selected():
			return


func _find_best_playable(opponent: PlayerState) -> CardInstance:
	var selected: CardInstance = null
	var selected_score: int = -1
	for card: CardInstance in opponent.deck_manager.hand:
		if card.data.cost > opponent.energy:
			continue
		var is_unit: bool = card.data.card_type == "TROOP" or card.data.card_type == "CHAMPION"
		if is_unit and opponent.deck_manager.field.size() >= RuleManager.MAX_FIELD_CARDS:
			continue
		var score: int = _card_value(card)
		if selected == null or score > selected_score:
			selected = card
			selected_score = score
	return selected


func _card_value(card: CardInstance) -> int:
	if card.data.effect_action == "DAMAGE_PLAYER":
		return 100 + card.data.effect_value
	if card.data.effect_action == "DAMAGE_UNIT":
		return 90 + card.data.effect_value
	if card.data.card_type == "CHAMPION":
		return 70 + card.data.attack + card.data.life
	return 30 + card.data.attack + card.data.life - card.data.cost


func _attack_best_targets(game_manager: GameManager, opponent: PlayerState) -> void:
	# Busca primero intercambios favorables. Si no puede destruir una unidad sin
	# perder la atacante, cambia a dano directo para presionar la vida rival.
	var defender: PlayerState = game_manager.get_opponent_player()
	var attackers: Array[CardInstance] = opponent.deck_manager.field.duplicate()
	for card: CardInstance in attackers:
		if game_manager.match_finished:
			return
		game_manager.select_card(card)
		var target: CardInstance = _find_profitable_target(card, defender.deck_manager.field)
		if target != null:
			if not game_manager.try_attack_unit(target):
				game_manager.clear_selection()
		else:
			game_manager.try_attack_direct()


func _find_profitable_target(attacker: CardInstance, defenders: Array[CardInstance]) -> CardInstance:
	var best_target: CardInstance = null
	var best_score: int = -1
	for defender: CardInstance in defenders:
		var can_destroy: bool = attacker.current_attack >= defender.current_life
		var survives: bool = attacker.current_life > defender.current_attack
		if not can_destroy or not survives:
			continue
		var score: int = defender.current_attack + defender.current_life
		if score > best_score:
			best_score = score
			best_target = defender
	return best_target
