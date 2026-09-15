class_name RuleManager
extends Node

## Reglas puras de la demo: decide si una accion esta permitida, pero no la ejecuta.

const MAX_FIELD_CARDS: int = 5
const MAX_TRUTH_CARDS: int = 3
const MAX_SECRET_CARDS: int = 2

func can_play_card(player: PlayerState, card: CardInstance) -> bool:
	if player == null or card == null:
		return false
	
	if card.zone != CardInstance.Zone.HAND:
		return false

	if player.deck_manager.hand.find(card) == -1:
		return false
	
	if card.data.cost > player.energy:
		return false
	
	var is_unit: bool = card.data.card_type == "TROOP" or card.data.card_type == "CHAMPION"
	if is_unit and player.deck_manager.field.size() >= MAX_FIELD_CARDS:
		return false
	if card.data.card_type == "TRUTH" and player.deck_manager.truths.size() >= MAX_TRUTH_CARDS:
		return false
	if card.data.card_type == "SECRETS" and player.deck_manager.secrets.size() >= MAX_SECRET_CARDS:
		return false
	
	return true


func can_attack_target(player: PlayerState, card: CardInstance, target: CardInstance, turn_number: int = 2) -> bool:
	if not can_attack(player, card, turn_number):
		return false
	if target == null or target.zone != CardInstance.Zone.FIELD:
		return false
	return true

func can_attack(player: PlayerState, card: CardInstance, turn_number: int = 2) -> bool:
	if player == null or card == null:
		return false
	if turn_number <= 1:
		return false
	
	if card.zone != CardInstance.Zone.FIELD:
		return false
	
	if card.has_attacked:
		return false
	
	return player.deck_manager.field.find(card) != -1
