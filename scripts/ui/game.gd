extends Control

const CARD_VIEW_SCENE: PackedScene = preload("res://scenes/card_view.tscn")
const CARD_BACK_TEXTURE: Texture2D = preload("res://art/ui/card_back.svg")

@onready var opponent_hp_label: Label = $MarginContainer/VBoxContainer/TopBar/HBoxContainer/PlayerInfo/PlayerHP
@onready var opponent_energy_label: Label = $MarginContainer/VBoxContainer/TopBar/HBoxContainer/PlayerInfo/OpponentEnergy
@onready var opponent_hand_label: Label = $MarginContainer/VBoxContainer/TopBar/HBoxContainer/EnemyInfo/OpponentHand
@onready var player_hp_label: Label = $MarginContainer/VBoxContainer/PlayerResources/ResourcesRow/PlayerHealth
@onready var player_energy_label: Label = $MarginContainer/VBoxContainer/PlayerResources/ResourcesRow/PlayerEnergyCurrent
@onready var turn_label: Label = $MarginContainer/VBoxContainer/TopBar/HBoxContainer/TurnInfo/TurnLabel
@onready var phase_label: Label = $MarginContainer/VBoxContainer/TopBar/HBoxContainer/PhaseInfo/PhaseLabel
@onready var hand_container: HBoxContainer = $MarginContainer/VBoxContainer/CenterArea/HandPanel/HandScroll/HandContainer
@onready var field_container: HBoxContainer = $MarginContainer/VBoxContainer/CenterArea/FieldPanel/FieldContainer
@onready var enemy_field_container: HBoxContainer = $MarginContainer/VBoxContainer/CenterArea/EnemyFieldPanel/EnemyFieldContainer
@onready var play_button: Button = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/PlayButton
@onready var discard_button: Button = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/DiscardButton
@onready var attack_button: Button = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/AttackButton
@onready var advance_button: Button = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/EndTurnButton
@onready var finish_turn_button: Button = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/FinishTurnButton
@onready var pause_button: Button = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/PauseButton
@onready var deck_count_label: Label = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/DeckCount
@onready var graveyard_count_label: Label = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/GraveyardCount
@onready var log_label: RichTextLabel = $MarginContainer/VBoxContainer/LogPanel/LogLabel
@onready var animation_layer: Control = $AnimationLayer
@onready var coin_flip_overlay: ColorRect = $CoinFlipOverlay
@onready var coin_flip_result: Label = $CoinFlipOverlay/CenterContainer/Panel/Content/Result
@onready var coin_visual: TextureRect = $CoinFlipOverlay/CenterContainer/Panel/Content/CoinVisual
@onready var heads_button: Button = $CoinFlipOverlay/CenterContainer/Panel/Content/ChoiceButtons/HeadsButton
@onready var tails_button: Button = $CoinFlipOverlay/CenterContainer/Panel/Content/ChoiceButtons/TailsButton
@onready var pause_overlay: ColorRect = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/PauseCenter/PausePanel/PauseContent/ResumeButton
@onready var abandon_button: Button = $PauseOverlay/PauseCenter/PausePanel/PauseContent/AbandonButton
@onready var abandon_confirm: ConfirmationDialog = $AbandonConfirm

var game_manager: GameManager = GameManager.new()
var sound_manager: SoulAudio = SoulAudio.new()
var selected_card: CardInstance = null
var selected_target_card: CardInstance = null
var movement_queue: Array[Dictionary] = []
var movement_running: bool = false
var active_moving_cards: Dictionary = {}
var coin_heads_texture: Texture2D = preload("res://art/ui/coin_heads.svg")
var coin_tails_texture: Texture2D = preload("res://art/ui/coin_tails.svg")

func _ready() -> void:
	add_child(game_manager)
	add_child(sound_manager)
	game_manager.turn_started.connect(_on_turn_started)
	game_manager.card_moved.connect(_on_card_moved)
	game_manager.sound_requested.connect(_on_sound_requested)
	game_manager.game_over.connect(_on_game_over)
	play_button.pressed.connect(_on_play_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	advance_button.pressed.connect(_on_advance_pressed)
	finish_turn_button.pressed.connect(_on_finish_turn_pressed)
	pause_button.pressed.connect(_open_pause_menu)
	resume_button.pressed.connect(_close_pause_menu)
	abandon_button.pressed.connect(_on_abandon_pressed)
	abandon_confirm.confirmed.connect(_abandon_match)
	heads_button.pressed.connect(_on_coin_choice.bind(0))
	tails_button.pressed.connect(_on_coin_choice.bind(1))
	coin_visual.texture = coin_heads_texture
	_refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not coin_flip_overlay.visible:
		if pause_overlay.visible:
			_close_pause_menu()
		else:
			_open_pause_menu()
		get_viewport().set_input_as_handled()

func _on_coin_choice(player_choice: int) -> void:
	heads_button.disabled = true
	tails_button.disabled = true
	_play_sound("coin_flip")
	coin_flip_result.text = "Lanzando..."
	var coin_result: int = randi_range(0, 1)
	coin_visual.hide()
	var flying_coin := TextureRect.new()
	flying_coin.texture = coin_heads_texture
	flying_coin.custom_minimum_size = coin_visual.size
	flying_coin.size = coin_visual.size
	flying_coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flying_coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	animation_layer.add_child(flying_coin)
	var coin_start: Vector2 = _to_animation_position(coin_visual.get_global_rect().get_center())
	flying_coin.position = coin_start - flying_coin.size * 0.5
	var tween: Tween = create_tween()
	for flip_index in range(8):
		tween.tween_property(flying_coin, "scale:x", 0.08, 0.07)
		tween.tween_callback(_set_coin_face.bind(flying_coin, flip_index % 2))
		tween.tween_property(flying_coin, "scale:x", 1.0, 0.07)
		tween.tween_property(flying_coin, "rotation", PI * float(flip_index + 1), 0.14)
	tween.tween_property(flying_coin, "position:y", coin_start.y - 88.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flying_coin, "position:y", coin_start.y - flying_coin.size.y * 0.5, 0.24).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_set_coin_face.bind(flying_coin, coin_result))
	await tween.finished
	flying_coin.queue_free()
	coin_visual.texture = coin_heads_texture if coin_result == 0 else coin_tails_texture
	coin_visual.show()
	_play_sound("coin_land")
	var first_player: int = 0 if coin_result == player_choice else 1
	coin_flip_result.text = "%s. Sale primero: %s." % ["CARA" if coin_result == 0 else "CRUZ", "TU" if first_player == 0 else "IA"]
	await get_tree().create_timer(0.65).timeout
	game_manager.start_new_game(DeckSaveManager.load_active_deck(), first_player)
	coin_flip_overlay.hide()
	_refresh_ui()
	if game_manager.turn_manager.active_player_index == 1:
		await _run_ai_turn()

func _set_coin_face(target: TextureRect, face_index: int) -> void:
	if is_instance_valid(target):
		target.texture = coin_heads_texture if face_index == 0 else coin_tails_texture

func _to_animation_position(global_position: Vector2) -> Vector2:
	return animation_layer.get_global_transform_with_canvas().affine_inverse() * global_position

func _on_turn_started(_turn_number: int, _phase: String) -> void:
	selected_card = null
	selected_target_card = null
	_refresh_ui()

func _refresh_ui() -> void:
	if game_manager.player == null or game_manager.enemy == null:
		return
	opponent_hp_label.text = "RIVAL  |  VIDA %d/%d" % [game_manager.enemy.hp, game_manager.enemy.max_hp]
	opponent_energy_label.text = "ENERGIA %d/%d" % [game_manager.enemy.energy, game_manager.enemy.max_energy]
	opponent_hand_label.text = "MANO %d" % game_manager.enemy.hand.size()
	player_hp_label.text = "VIDA  %d/%d" % [game_manager.player.hp, game_manager.player.max_hp]
	player_energy_label.text = "ENERGIA  %d/%d" % [game_manager.player.energy, game_manager.player.max_energy]
	turn_label.text = "TURNO %d" % game_manager.turn_manager.current_turn
	phase_label.text = _get_phase_label(game_manager.turn_manager.phase)
	deck_count_label.text = "MAZO  %d" % game_manager.player.deck.size()
	graveyard_count_label.text = "DESCARTE  %d" % game_manager.player.graveyard.size()
	log_label.text = "\n".join(game_manager.log_messages.slice(maxi(0, game_manager.log_messages.size() - 2)))
	_populate_hand()
	_populate_fields()
	_update_action_buttons()

func _get_phase_label(phase: String) -> String:
	match phase:
		"DRAW":
			return "ROBO"
		"PLACEMENT_1":
			return "COLOCACION I"
		"ATTACK":
			return "ATAQUE"
		"PLACEMENT_2":
			return "COLOCACION II"
		"END_TURN":
			return "FIN DE TURNO"
		_:
			return phase

func _populate_hand() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	for card in game_manager.player.hand:
		if active_moving_cards.has(card.instance_id):
			continue
		var card_view: CardView = CARD_VIEW_SCENE.instantiate()
		hand_container.add_child(card_view)
		card_view.set_compact()
		card_view.set_card_instance(card)
		card_view.selected.connect(_on_card_selected)
		card_view.set_selected(card == selected_card)

func _populate_fields() -> void:
	for child in field_container.get_children():
		child.queue_free()
	for child in enemy_field_container.get_children():
		child.queue_free()
	for card in game_manager.player.field:
		if active_moving_cards.has(card.instance_id):
			continue
		var card_view: CardView = _make_field_card(card)
		field_container.add_child(card_view)
		_configure_field_card(card_view, card)
	for card in game_manager.enemy.field:
		if active_moving_cards.has(card.instance_id):
			continue
		var card_view: CardView = _make_field_card(card)
		enemy_field_container.add_child(card_view)
		_configure_field_card(card_view, card)

func _make_field_card(card: CardInstance) -> CardView:
	return CARD_VIEW_SCENE.instantiate()

func _configure_field_card(card_view: CardView, card: CardInstance) -> void:
	card_view.set_compact()
	card_view.set_card_instance(card)
	card_view.selected.connect(_on_card_selected)

func _update_action_buttons() -> void:
	var is_player_turn: bool = game_manager.turn_manager.active_player_index == 0
	var can_place: bool = is_player_turn and game_manager.turn_manager.phase in ["PLACEMENT_1", "PLACEMENT_2"]
	var can_attack: bool = is_player_turn and game_manager.turn_manager.phase == "ATTACK"
	var target_is_required: bool = selected_card != null and selected_card.zone == "HAND" and game_manager.card_requires_target(selected_card.card_data)
	var target_is_valid: bool = selected_card != null and game_manager.is_valid_effect_target(game_manager.player, game_manager.enemy, selected_card.card_data, selected_target_card)
	play_button.disabled = not can_place or selected_card == null or selected_card.zone != "HAND" or (target_is_required and not target_is_valid)
	discard_button.disabled = not can_place or selected_card == null or selected_card.zone != "HAND"
	attack_button.disabled = not can_attack or selected_card == null or not game_manager.player.field.has(selected_card) or not RuleManager.can_attack(selected_card, game_manager.player)
	if game_manager.turn_manager.phase == "END_TURN":
		advance_button.text = "FASE FINAL"
	else:
		advance_button.text = "SIGUIENTE FASE"
	advance_button.disabled = not is_player_turn or game_manager.turn_manager.phase == "END_TURN"
	finish_turn_button.disabled = not is_player_turn
	for button in [play_button, discard_button, attack_button, advance_button, finish_turn_button]:
		button.disabled = button.disabled or pause_overlay.visible

func _on_card_selected(card: CardInstance) -> void:
	if game_manager.enemy.field.has(card):
		selected_target_card = card
	elif game_manager.player.field.has(card) and selected_card != null and selected_card.zone == "HAND" and game_manager.card_requires_target(selected_card.card_data):
		selected_target_card = card
	else:
		selected_card = card
		selected_target_card = null
	for child in hand_container.get_children() + field_container.get_children() + enemy_field_container.get_children():
		if child is CardView:
			child.set_selected(child.card_instance == selected_card or child.card_instance == selected_target_card)
	_refresh_ui_buttons_only()

func _refresh_ui_buttons_only() -> void:
	_update_action_buttons()

func _on_play_pressed() -> void:
	if selected_card == null:
		return
	var result: Dictionary = game_manager.play_card_from_hand(selected_card, selected_target_card)
	if result["ok"]:
		selected_card = null
		selected_target_card = null
		_refresh_ui()
	else:
		log_label.text = String(result["message"])

func _on_discard_pressed() -> void:
	var result: Dictionary = game_manager.discard_card_from_hand(selected_card)
	if result["ok"]:
		selected_card = null
		selected_target_card = null
		_refresh_ui()
	else:
		log_label.text = String(result["message"])

func _on_attack_pressed() -> void:
	if selected_card == null:
		return
	var attack_target: Variant = game_manager.enemy
	if selected_target_card != null and game_manager.enemy.field.has(selected_target_card):
		attack_target = selected_target_card
	var result: Dictionary = game_manager.attack(selected_card, attack_target)
	if result["ok"]:
		selected_card = null
		selected_target_card = null
		_refresh_ui()
	else:
		log_label.text = String(result["message"])

func _on_advance_pressed() -> void:
	game_manager.advance_game_phase()
	_refresh_ui()
	if game_manager.turn_manager.active_player_index == 1:
		await _run_ai_turn()

func _on_finish_turn_pressed() -> void:
	if game_manager.end_turn(0):
		_refresh_ui()
		if game_manager.turn_manager.active_player_index == 1:
			await _run_ai_turn()

func _run_ai_turn() -> void:
	await game_manager.run_ai_turn()
	_refresh_ui()
	await _wait_for_movements()


func _on_card_moved(card: CardInstance, from_zone: String, to_zone: String, owner: String, source_owner: String) -> void:
	active_moving_cards[card.instance_id] = true
	movement_queue.append({"card": card, "from": from_zone, "to": to_zone, "owner": owner, "source_owner": source_owner})
	_refresh_ui()
	if not movement_running:
		_animate_next_card()

func _animate_next_card() -> void:
	if movement_queue.is_empty():
		movement_running = false
		return
	movement_running = true
	var movement: Dictionary = movement_queue.pop_front()
	var card: CardInstance = movement["card"]
	var owner: String = movement["owner"]
	var source_owner: String = movement["source_owner"]
	var from_zone: String = movement["from"]
	var to_zone: String = movement["to"]
	var fly_card: Control
	if owner == "enemy" and to_zone == "HAND":
		var back := TextureRect.new()
		back.texture = CARD_BACK_TEXTURE
		back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fly_card = back
	else:
		var face: CardView = CARD_VIEW_SCENE.instantiate()
		animation_layer.add_child(face)
		face.set_compact()
		face.set_card_instance(card)
		fly_card = face
	fly_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fly_card.get_parent() == null:
		animation_layer.add_child(fly_card)
	var card_size: Vector2 = Vector2(126, 172)
	fly_card.custom_minimum_size = card_size
	fly_card.size = card_size
	var source_position: Vector2 = _zone_center(from_zone, source_owner)
	var target_position: Vector2 = _zone_center(to_zone, owner)
	fly_card.position = source_position - card_size * 0.5
	fly_card.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fly_card, "position", target_position - card_size * 0.5, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fly_card, "modulate:a", 1.0, 0.1)
	tween.tween_property(fly_card, "rotation", 0.04 if to_zone == "FIELD" else 0.0, 0.38)
	tween.set_parallel(false)
	tween.tween_interval(0.08)
	tween.tween_callback(func():
		active_moving_cards.erase(card.instance_id)
		fly_card.queue_free()
		movement_running = false
		_refresh_ui()
		_animate_next_card()
	)

func _zone_center(zone: String, owner: String) -> Vector2:
	var target: Control = hand_container
	var offset: Vector2 = Vector2.ZERO
	match zone:
		"DECK":
			target = deck_count_label
		"GRAVEYARD":
			target = graveyard_count_label
		"FIELD":
			target = enemy_field_container if owner == "enemy" else field_container
		"SUMMON":
			target = enemy_field_container if owner == "enemy" else field_container
			offset = Vector2(0, 78)
		"HAND":
			if owner == "enemy":
				target = opponent_hand_label
	var global_center: Vector2 = target.get_global_rect().get_center() + offset
	return animation_layer.get_global_transform_with_canvas().affine_inverse() * global_center

func _wait_for_movements() -> void:
	while movement_running or not movement_queue.is_empty():
		await get_tree().create_timer(0.08, false).timeout

func _on_sound_requested(sound_name: String) -> void:
	_play_sound(sound_name)

func _play_sound(sound_name: String) -> void:
	sound_manager.play_sfx(sound_name)

func _open_pause_menu() -> void:
	pause_overlay.show()
	get_tree().paused = true
	_update_action_buttons()

func _close_pause_menu() -> void:
	get_tree().paused = false
	pause_overlay.hide()
	_update_action_buttons()

func _on_abandon_pressed() -> void:
	get_tree().paused = false
	abandon_confirm.popup_centered()

func _abandon_match() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_game_over(winner: String) -> void:
	log_label.text = "Partida terminada. Ganador: %s" % winner