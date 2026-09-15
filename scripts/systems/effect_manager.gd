class_name EffectManager
extends Node

## Ejecuta efectos declarados en CardData. Las cartas siguen siendo recursos:
## para crear una carta nueva se configuran sus campos, no se crea un script.

func resolve_play_effect(card: CardInstance, owner: PlayerState, opponent: PlayerState) -> void:
	if card == null or owner == null or opponent == null:
		return
	if card.data.effect_trigger != "ON_PLAY":
		return
	_resolve(card, owner, opponent)


func resolve_death_effect(card: CardInstance, owner: PlayerState, opponent: PlayerState) -> void:
	if card == null or owner == null or opponent == null:
		return
	if card.data.effect_trigger != "ON_DEATH":
		return
	_resolve(card, owner, opponent)


func resolve_secret_event(event_name: String, acting_player: PlayerState, defending_player: PlayerState) -> void:
	if acting_player == null or defending_player == null:
		return
	for secret: CardInstance in defending_player.deck_manager.secrets.duplicate():
		if secret.data.secret_trigger != event_name:
			continue
		if not defending_player.deck_manager.send_secret_to_graveyard(secret):
			continue
		_resolve(secret, defending_player, acting_player)


func _resolve(card: CardInstance, owner: PlayerState, opponent: PlayerState) -> void:
	# La primera version usa acciones atomicas. Se puede ampliar con objetivos,
	# modificadores y duraciones sin convertir CardData en logica ejecutable.
	var value: int = maxi(0, card.data.effect_value)
	match card.data.effect_action:
		"DAMAGE_PLAYER":
			opponent.life = maxi(0, opponent.life - value)
		"HEAL_PLAYER":
			owner.life += value
		"DRAW_CARD":
			for draw_index: int in range(value):
				owner.deck_manager.draw_card()
		"DAMAGE_UNIT":
			var target: CardInstance = _find_weakest_unit(opponent.deck_manager.field)
			if target != null:
				target.current_life -= value
				if target.current_life <= 0:
					if opponent.deck_manager.send_to_graveyard(target):
						resolve_death_effect(target, opponent, owner)


func _find_weakest_unit(units: Array[CardInstance]) -> CardInstance:
	var weakest: CardInstance = null
	for unit: CardInstance in units:
		if weakest == null or unit.current_life < weakest.current_life:
			weakest = unit
	return weakest