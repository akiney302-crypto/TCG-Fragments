extends RefCounted
class_name TurnManager

var current_turn: int = 1
var active_player_index: int = 0
var phase: String = "DRAW"
var phases: Array[String] = GameRules.TURN_PHASES

func begin_turn() -> void:
    phase = "DRAW"
    current_turn = max(1, current_turn)

func advance_phase() -> String:
    var idx: int = phases.find(phase)
    if idx == -1:
        phase = "DRAW"
        return phase
    if idx < phases.size() - 1:
        phase = phases[idx + 1]
    return phase

func end_turn() -> void:
    start_next_turn()

func start_next_turn() -> void:
    active_player_index = 1 - active_player_index
    phase = "DRAW"
    current_turn += 1

func get_active_player_name(player_names: Array[String]) -> String:
    if player_names.is_empty():
        return "player"
    return player_names[active_player_index]
