class_name PlayerState
extends RefCounted

var player_id: int = 0
var life: int = 20
var max_energy: int = 0
var energy: int = 0
var deck_manager: DeckManager

func _init(id:int) -> void:
	player_id = id
