extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var game_scene: Control = preload("res://scenes/game/game.tscn").instantiate() as Control
	root.add_child(game_scene)
	await process_frame

	var game_manager: GameManager = game_scene.get_node("GameManager") as GameManager
	_check(game_manager.players.size() == 2, "La partida debe crear jugador y oponente")
	_check(game_manager.get_active_player().player_id == 0, "El primer turno debe ser del jugador")
	_check(game_manager.phase == GameManager.Phase.MAIN_1, "El turno debe comenzar en fase principal")
	var first_turn_card: CardInstance = CardInstance.new(load("res://resources/cards/test_guard.tres") as CardData)
	var first_turn_player: PlayerState = game_manager.get_active_player()
	first_turn_player.deck_manager.field.append(first_turn_card)
	first_turn_card.zone = CardInstance.Zone.FIELD
	_check(not game_manager.rule_manager.can_attack(first_turn_player, first_turn_card, 1), "No se puede atacar durante el primer turno")
	first_turn_player.deck_manager.field.erase(first_turn_card)
	game_manager.advance_phase()
	_check(game_manager.phase == GameManager.Phase.COMBAT, "La primera fase principal debe llevar a combate")
	game_manager.advance_phase()
	_check(game_manager.phase == GameManager.Phase.MAIN_2, "Combate debe llevar a la segunda fase principal")
	game_manager.advance_phase()
	await process_frame
	_check(game_manager.get_active_player().player_id == 0, "La IA debe terminar su turno y devolver el control")
	_check(game_manager.turn_manager.turn_number == 3, "El turno debe avanzar por jugador y oponente")

	var attacker: CardInstance = CardInstance.new(load("res://resources/cards/test_dragon.tres") as CardData)
	var defender: CardInstance = CardInstance.new(load("res://resources/cards/test_guard.tres") as CardData)
	var controller: OpponentController = OpponentController.new()
	_check(controller._find_profitable_target(attacker, [defender]) == defender, "La IA debe detectar un intercambio favorable")

	if failures == 0:
		print("OPPONENT SMOKE TEST PASSED")
		quit(0)
	else:
		print("OPPONENT SMOKE TEST FAILED: %d" % failures)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
