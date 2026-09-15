class_name DeckManager
extends Node

## Unico sistema autorizado a mover cartas entre deck, hand, field y graveyard.

signal zones_changed

var deck: Array [CardInstance] = []
var hand: Array [CardInstance] = []
var field: Array [CardInstance] = []
var truths: Array [CardInstance] = []
var secrets: Array [CardInstance] = []
var graveyard: Array [CardInstance] = []

func setup_from_data(deck_data: DeckData) -> void:
	clear_zones()
	
	if deck_data == null:
		push_error("DeckManager: falta asignar un DeckData")
		return
		
	var copies_by_id: Dictionary = {}
	for card_data: CardData in deck_data.cards:
		if card_data == null:
			continue
		var copies: int = copies_by_id.get(card_data.card_id, 0)
		var copy_limit: int = 1 if card_data.card_type == "CHAMPION" else 3
		if copies >= copy_limit:
			push_warning("DeckManager: se omitio una copia ilegal de %s" % card_data.card_name)
			continue
		copies_by_id[card_data.card_id] = copies + 1
		
		var instance: CardInstance = CardInstance.new(card_data)
		instance.zone = CardInstance.Zone.DECK
		deck.append(instance)

	shuffle_deck()
	zones_changed.emit()

func clear_zones() -> void:
	deck.clear()
	hand.clear()
	field.clear()
	truths.clear()
	secrets.clear()
	graveyard.clear()

func shuffle_deck() -> void:
	deck.shuffle()

func draw_card() -> CardInstance:
	if deck.is_empty():
		return null
	
	var card:CardInstance = deck.pop_back()
	card.zone = CardInstance.Zone.HAND
	hand.append(card)
	zones_changed.emit()
	return card

func move_card(card: CardInstance, from_zone: Array[CardInstance], to_zone: Array[CardInstance], destination: int) -> bool:
	# El movimiento es atomico: si la carta no esta en el origen, no se modifica nada.
	if card == null:
		return false
		
	var index: int = from_zone.find(card)
	if index == -1:
		return false
	
	from_zone.remove_at(index)
	card.zone = destination
	to_zone.append(card)
	zones_changed.emit()
	return true

func play_card(card: CardInstance) -> bool:
	var success: bool = move_card(card, hand, field, CardInstance.Zone.FIELD)
	if success:
		card.has_attacked = false
	return success

func play_truth(card: CardInstance) -> bool:
	return move_card(card, hand, truths, CardInstance.Zone.TRUTH)

func play_secret(card: CardInstance) -> bool:
	var success: bool = move_card(card, hand, secrets, CardInstance.Zone.SECRETS)
	if success:
		card.face_down = true
	return success


func send_secret_to_graveyard(card: CardInstance) -> bool:
	if card == null or card.zone != CardInstance.Zone.SECRETS:
		return false
	var index: int = secrets.find(card)
	if index == -1:
		return false
	secrets.remove_at(index)
	card.face_down = false
	card.zone = CardInstance.Zone.GRAVEYARD
	graveyard.append(card)
	zones_changed.emit()
	return true

func send_to_graveyard(card: CardInstance) -> bool:
	if card == null:
		return false

	if card.zone == CardInstance.Zone.HAND:
		return move_card(card, hand, graveyard, CardInstance.Zone.GRAVEYARD)

	if card.zone == CardInstance.Zone.FIELD:
		return move_card(card, field, graveyard, CardInstance.Zone.GRAVEYARD)
	
	return false
