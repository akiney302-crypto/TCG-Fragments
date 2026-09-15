class_name CombatManager
extends Node

## Resuelve dano; no decide si el ataque es legal, esa responsabilidad es de RuleManager.

signal unit_destroyed(owner: PlayerState, card: CardInstance)

func attack_direct(attacker: PlayerState, defender: PlayerState, card: CardInstance) -> bool:
	if attacker == null or defender == null or card == null:
		return false
	
	if card.has_attacked:
		return false
	
	card.has_attacked = true
	defender.life = maxi(0, defender.life - card.current_attack)
	return true

func resolve_unit_combat(attacker_owner: PlayerState, defender_owner: PlayerState, attacker: CardInstance, defender: CardInstance) -> bool:
	# El dano se resuelve simultaneamente. Las cartas que quedan a 0 de vida
	# abandonan el campo y DeckManager las coloca en el cementerio.
	if attacker_owner == null or defender_owner == null:
		return false
	if attacker == null or defender == null:
		return false
	if attacker.has_attacked:
		return false
	
	attacker.has_attacked = true
	
	defender.current_life -= attacker.current_attack
	attacker.current_life -= defender.current_attack
	
	if defender.current_life <= 0:
		if defender_owner.deck_manager.send_to_graveyard(defender):
			unit_destroyed.emit(defender_owner, defender)
	
	if attacker.current_life <= 0:
		if attacker_owner.deck_manager.send_to_graveyard(attacker):
			unit_destroyed.emit(attacker_owner, attacker)
	
	return true


func attack_unit(attacker_owner: PlayerState, defender_owner: PlayerState, attacker: CardInstance, defender: CardInstance) -> bool:
	if attacker_owner == null or defender_owner == null or attacker == null or defender == null:
		return false
	if attacker.has_attacked or attacker_owner.deck_manager.field.find(attacker) == -1:
		return false
	if defender_owner.deck_manager.field.find(defender) == -1:
		return false
	return resolve_unit_combat(attacker_owner, defender_owner, attacker, defender)
