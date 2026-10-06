extends RefCounted
class_name TurnManager

var current_turn: int = 1
var active_player_index: int = 0
var phase: String = "START"
var phases: Array[String] = GameRules.TURN_PHASES

func begin_turn() -> void:
    phase = "START"
    current_turn = max(1, current_turn)

func advance_phase() -> void:
    var idx: int = phases.find(phase)
    if idx == -1:
        phase = "START"
        return
    if idx < phases.size() - 1:
        phase = phases[idx + 1]
    else:
        phase = "START"
        current_turn += 1

func end_turn() -> void:
    active_player_index = 1 - active_player_index
    phase = "START"
    current_turn += 1

func start_next_turn() -> void:
    active_player_index = 1 - active_player_index
    phase = "START"
    current_turn += 1

func get_active_player_name(player_names: Array[String]) -> String:
    if player_names.is_empty():
        return "player"
    return player_names[active_player_index]
