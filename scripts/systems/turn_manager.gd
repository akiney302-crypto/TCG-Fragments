class_name TurnManager
extends Node

## Controla el jugador activo y prepara energia, robo y ataques disponibles.

signal turn_started(player_id: int)
signal turn_ended(player_id: int)

var active_player: int = 0
var turn_number: int = 0

func start_first_turn(players: Array[PlayerState]) -> void:
	active_player = 0
	turn_number = 1
	_start_turn(players)

func end_turn(players: Array[PlayerState]) -> void:
	if players.is_empty():
		return
	
	var previous_player: int = active_player
	turn_ended.emit(previous_player)
	
	active_player = 1 if active_player == 0 else 0
	turn_number += 1
	_start_turn(players)

func _start_turn(players: Array[PlayerState]) -> void:
	# Todas las preparaciones de turno quedan centralizadas aqui.
	var player: PlayerState = players[active_player]
	
	player.max_energy = mini(10, player.max_energy +1)
	player.energy = player.max_energy
	player.deck_manager.draw_card()
	
	for card: CardInstance in player.deck_manager.field:
		card.has_attacked = false
	
	turn_started.emit(active_player)
