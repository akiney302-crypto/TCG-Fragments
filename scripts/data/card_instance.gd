class_name CardInstance
extends RefCounted

## Copia de CardData que posee estado mutable durante una partida.

enum Zone { DECK, HAND, FIELD, TRUTH, SECRETS, GRAVEYARD }

var data: CardData
var zone: int = Zone.DECK
var current_attack: int
var current_life: int
var can_attack: bool = false
var has_attacked: bool = false
var face_down: bool = false

func _init(card_data:CardData) -> void:
	# Los atributos actuales empiezan con los valores impresos en la carta.
	data = card_data
	current_attack = card_data.attack
	current_life = card_data.life
