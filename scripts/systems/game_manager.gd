class_name GameManager
extends Node

signal state_changed
signal game_over(winner_id: int)
signal damage_dealt(player_id: int, amount: int)

enum Phase { DRAW, MAIN_1, COMBAT, MAIN_2, END }

@export var player_deck_data: DeckData
@export var enemy_deck_data: DeckData

@onready var player_deck_manager: DeckManager = $PlayerDeckManager
@onready var enemy_deck_manager: DeckManager = $EnemyDeckManager
@onready var turn_manager: TurnManager = $TurnManager
@onready var rule_manager: RuleManager = $RuleManager
@onready var combat_manager: CombatManager = $CombatManager
@onready var opponent_controller: OpponentController = $OpponentController
@onready var effect_manager: EffectManager = $EffectManager

var players: Array[PlayerState] = []
var selected_card: CardInstance = null
var match_finished: bool = false
var phase: Phase = Phase.DRAW

func _ready() -> void:
	# GameManager coordina la partida; los sistemas hijos hacen el trabajo concreto.
	combat_manager.unit_destroyed.connect(_on_unit_destroyed)
	start_match()


func _on_unit_destroyed(owner: PlayerState, card: CardInstance) -> void:
	var opponent: PlayerState = players[1 - owner.player_id]
	effect_manager.resolve_death_effect(card, owner, opponent)
	state_changed.emit()

func start_match() -> void:
	# Inicializa ambos jugadores y reparte una mano inicial antes del primer turno.
	match_finished = false
	selected_card = null
	players.clear()
	
	var player: PlayerState = PlayerState.new(0)
	var enemy: PlayerState = PlayerState.new(1)
	
	players.append(player)
	players.append(enemy)
	
	_setup_player(player, _resolve_deck_data(player_deck_data))
	_setup_player(enemy, _resolve_deck_data(enemy_deck_data))
	
	for i: int in range(5):
		player.deck_manager.draw_card()
		enemy.deck_manager.draw_card()
	
	turn_manager.start_first_turn(players)
	phase = Phase.MAIN_1
	state_changed.emit()


func _resolve_deck_data(deck_data: DeckData) -> DeckData:
	if deck_data != null:
		return deck_data

	# El contenido vive en DeckData (.tres), no en una lista codificada aqui.
	return load("res://resources/decks/demo_deck.tres") as DeckData

func _setup_player(player: PlayerState, data: DeckData) -> void:
	var manager: DeckManager
	
	if player.player_id == 0:
		manager = player_deck_manager
	else:
		manager = enemy_deck_manager
	
	player.deck_manager = manager
	manager.setup_from_data(data)

func get_active_player() -> PlayerState:
	return players[turn_manager.active_player]

func get_opponent_player() -> PlayerState:
	return players[1 - turn_manager.active_player]

func select_card(card: CardInstance) -> void:
	selected_card = card
	state_changed.emit()

func clear_selection() -> void:
	selected_card = null
	state_changed.emit()

func try_play_selected() -> bool:
	# Las reglas validan primero; el coste solo se descuenta si la carta entra al campo.
	if selected_card == null or match_finished:
		return false
	if phase != Phase.MAIN_1 and phase != Phase.MAIN_2:
		return false
	
	var player: PlayerState = get_active_player()
	
	if not rule_manager.can_play_card(player, selected_card):
		return false
	
	player.energy -= selected_card.data.cost
	
	var is_unit: bool = selected_card.data.card_type == "TROOP" or selected_card.data.card_type == "CHAMPION"
	var success: bool
	if is_unit:
		success = player.deck_manager.play_card(selected_card)
	elif selected_card.data.card_type == "TRUTH":
		success = player.deck_manager.play_truth(selected_card)
	elif selected_card.data.card_type == "SECRETS":
		success = player.deck_manager.play_secret(selected_card)
	else:
		success = false
	if not success:
		player.energy += selected_card.data.cost
		return false
	if selected_card.data.card_type != "SECRETS":
		effect_manager.resolve_play_effect(selected_card, player, get_opponent_player())
	if player.player_id == 1 and selected_card.data.card_type != "SECRETS":
		effect_manager.resolve_secret_event("OPPONENT_PLAY", player, get_opponent_player())
		if is_unit:
			effect_manager.resolve_secret_event("OPPONENT_SUMMON", player, get_opponent_player())
	
	selected_card = null
	state_changed.emit()
	return true

func try_discard_selected() -> bool:
	if selected_card == null or match_finished:
		return false
	if phase != Phase.MAIN_1 and phase != Phase.MAIN_2:
		return false
	if selected_card.zone != CardInstance.Zone.HAND:
		return false
	
	var player: PlayerState = get_active_player()
	var success: bool = player.deck_manager.send_to_graveyard(selected_card)
	
	if success:
		selected_card = null
		state_changed.emit()
	
	return success


func try_attack_unit(target: CardInstance) -> bool:
	if selected_card == null or target == null or match_finished:
		return false
	if phase != Phase.COMBAT:
		return false
	var player: PlayerState = get_active_player()
	var opponent: PlayerState = get_opponent_player()
	if not rule_manager.can_attack_target(player, selected_card, target, turn_manager.turn_number):
		return false
	var success: bool = combat_manager.attack_unit(player, opponent, selected_card, target)
	if success:
		effect_manager.resolve_secret_event("OPPONENT_ATTACK", player, opponent)
		selected_card = null
		_check_game_over()
		state_changed.emit()
	return success

func try_attack_direct() -> bool:
	if selected_card == null or match_finished:
		return false
	if phase != Phase.COMBAT:
		return false
	
	var player: PlayerState = get_active_player()
	var opponent: PlayerState = get_opponent_player()
	
	if not rule_manager.can_attack(player, selected_card, turn_manager.turn_number):
		return false
	
	var success: bool = combat_manager.attack_direct(player, opponent, selected_card)
	
	if success:
		damage_dealt.emit(opponent.player_id, selected_card.current_attack)
		effect_manager.resolve_secret_event("OPPONENT_ATTACK", player, opponent)
		selected_card = null
		_check_game_over()
		state_changed.emit()
	
	return success

func end_turn() -> void:
	# En el futuro, esta misma transicion podra entregar el control a otro jugador.
	if match_finished or get_active_player().player_id != 0:
		return
	if phase != Phase.MAIN_1 and phase != Phase.COMBAT and phase != Phase.MAIN_2:
		return
	_advance_to_next_turn()


func advance_phase() -> void:
	# La UI solo solicita el cambio; GameManager conserva el orden oficial de fases.
	if match_finished or get_active_player().player_id != 0:
		return
	if phase == Phase.MAIN_1:
		phase = Phase.COMBAT
	elif phase == Phase.COMBAT:
		phase = Phase.MAIN_2
	elif phase == Phase.MAIN_2:
		_advance_to_next_turn()
	state_changed.emit()


func _advance_to_next_turn() -> void:
	selected_card = null
	phase = Phase.END
	turn_manager.end_turn(players)
	_check_game_over()
	if not match_finished:
		phase = Phase.MAIN_1
		if get_active_player().player_id == 1:
			opponent_controller.take_turn(self)
	state_changed.emit()


func finish_opponent_turn() -> void:
	# El controlador enemigo llama a este metodo cuando termina sus acciones.
	if match_finished or get_active_player().player_id != 1:
		return
	phase = Phase.END
	turn_manager.end_turn(players)
	_check_game_over()
	if not match_finished:
		phase = Phase.MAIN_1
	state_changed.emit()

func _check_game_over() -> void:
	if players.size() < 2:
		return
	
	if players[0].life <= 0 and players[1].life <= 0:
		match_finished = true
		game_over.emit(-1)
	elif players[0].life <= 0:
		match_finished = true
		game_over.emit(1)
	elif players[1].life <= 0:
		match_finished = true
		game_over.emit(0)
