extends Control

const CARD_VIEW_SCENE: PackedScene = preload("res://scenes/cards/card_view.tscn")
const CARD_BACK_SCENE: PackedScene = preload("res://scenes/cards/card_back.tscn")

var selecting_attack_target: bool = false

@onready var game_manager: GameManager = $GameManager
@onready var hand_container: HBoxContainer = $SafeArea/MainLayout/Board/PlayerArea/HandZone/ScrollContainer/CardContainer
@onready var field_container: HBoxContainer = $SafeArea/MainLayout/Board/PlayerArea/FieldZone/CardContainer
@onready var truth_container: HBoxContainer = $SafeArea/MainLayout/Board/PlayerArea/FieldZone/SpecialZones/TruthZone/CardContainer
@onready var secret_container: HBoxContainer = $SafeArea/MainLayout/Board/PlayerArea/FieldZone/SpecialZones/SecretsZone/CardContainer
@onready var graveyard_container: HBoxContainer = $SafeArea/MainLayout/Board/PlayerArea/LowerZones/DeckStack/GraveyardZone/CardContainer
@onready var deck_visual_container: HBoxContainer = $SafeArea/MainLayout/Board/PlayerArea/LowerZones/DeckStack/DeckZone/CardBackContainer
@onready var opponent_field_container: HBoxContainer = $SafeArea/MainLayout/Board/OpponentArea/CardContainer
@onready var opponent_hand_container: HBoxContainer = $SafeArea/MainLayout/Board/OpponentArea/HandContainer
@onready var selected_preview: Control = $SafeArea/MainLayout/Board/SelectedPreview

@onready var deck_count_label: Label = $SafeArea/MainLayout/Board/PlayerArea/LowerZones/DeckStack/DeckZone/DeckCountLabel
@onready var hand_count_label: Label = $SafeArea/MainLayout/Board/PlayerArea/HandZone/HandCountLabel
@onready var field_count_label: Label = $SafeArea/MainLayout/Board/PlayerArea/FieldZone/FieldCountLabel
@onready var graveyard_count_label: Label = $SafeArea/MainLayout/Board/PlayerArea/LowerZones/DeckStack/GraveyardZone/GraveyardCountLabel
@onready var turn_label: Label = $SafeArea/MainLayout/TopBar/TurnLabel
@onready var life_label: Label = $SafeArea/MainLayout/TopBar/LifeLabel
@onready var opponent_life_label: Label = $SafeArea/MainLayout/TopBar/OpponentLifeLabel
@onready var energy_label: Label = $SafeArea/MainLayout/TopBar/EnergyLabel
@onready var status_label: Label = $SafeArea/MainLayout/TopBar/StatusLabel
@onready var phase_label: Label = $SafeArea/MainLayout/TopBar/PhaseLabel
@onready var opponent_hand_label: Label = $SafeArea/MainLayout/TopBar/OpponentHandLabel
@onready var play_button: Button = $SafeArea/MainLayout/ActionBar/PlayButton
@onready var attack_button: Button = $SafeArea/MainLayout/ActionBar/AttackButton
@onready var attack_unit_button: Button = $SafeArea/MainLayout/ActionBar/AttackUnitButton
@onready var discard_button: Button = $SafeArea/MainLayout/ActionBar/DiscardButton
@onready var end_turn_button: Button = $SafeArea/MainLayout/ActionBar/EndTunButton
@onready var restart_button: Button = $SafeArea/MainLayout/ActionBar/RestartButton
@onready var phase_button: Button = $SafeArea/MainLayout/ActionBar/PhaseButton
@onready var pause_button: Button = $SafeArea/MainLayout/TopBar/PauseButton
@onready var pause_panel: Control = $PausePanel
@onready var resume_button: Button = $PausePanel/Panel/Margin/Buttons/ResumeButton
@onready var menu_button: Button = $PausePanel/Panel/Margin/Buttons/MenuButton

func _ready() -> void:
	# El manager crea la partida; la UI solo refleja sus cambios.
	game_manager.state_changed.connect(_refresh_board)
	play_button.pressed.connect(game_manager.try_play_selected)
	attack_button.pressed.connect(game_manager.try_attack_direct)
	attack_unit_button.pressed.connect(_on_attack_unit_pressed)
	discard_button.pressed.connect(game_manager.try_discard_selected)
	end_turn_button.pressed.connect(game_manager.end_turn)
	restart_button.pressed.connect(game_manager.start_match)
	game_manager.game_over.connect(_on_game_over)
	game_manager.damage_dealt.connect(_on_damage_dealt)
	phase_button.pressed.connect(game_manager.advance_phase)
	pause_button.pressed.connect(_toggle_pause_menu)
	resume_button.pressed.connect(_toggle_pause_menu)
	menu_button.pressed.connect(_leave_to_menu)
	pause_panel.visible = false
	_refresh_board()


func _refresh_board() -> void:
	# La vista se reconstruye desde el estado; ninguna zona visual mueve cartas.
	if game_manager.players.is_empty():
		return

	var player: PlayerState = game_manager.players[0]
	var active_player: PlayerState = game_manager.get_active_player()
	var opponent: PlayerState = game_manager.get_opponent_player()
	turn_label.text = "Turno %d" % game_manager.turn_manager.turn_number
	phase_label.text = "Fase: %s" % _phase_name(game_manager.phase)
	life_label.text = "♥ Vida: %d" % player.life
	opponent_life_label.text = "♥ Rival: %d" % opponent.life
	opponent_hand_label.text = ""
	energy_label.text = "◆ Energia: %d / %d" % [player.energy, player.max_energy]
	deck_count_label.text = "Mazo: %d" % player.deck_manager.deck.size()
	hand_count_label.text = "Mano: %d" % player.deck_manager.hand.size()
	field_count_label.text = "Campo: %d" % player.deck_manager.field.size()
	graveyard_count_label.text = "Cementerio: %d" % player.deck_manager.graveyard.size()
	$SafeArea/MainLayout/Board/GameOverLabel.visible = game_manager.match_finished
	$SafeArea/MainLayout/Board/PlayerArea/FieldZone/SpecialZones/TruthZone/CountLabel.text = "Truth: %d / 3" % player.deck_manager.truths.size()
	$SafeArea/MainLayout/Board/PlayerArea/FieldZone/SpecialZones/SecretsZone/CountLabel.text = "Secrets: %d / 2" % player.deck_manager.secrets.size()
	var player_turn: bool = active_player.player_id == player.player_id and not game_manager.match_finished
	status_label.text = "Selecciona una unidad rival" if selecting_attack_target else ("TU TURNO" if player_turn else "TURNO DEL OPONENTE")
	play_button.disabled = not player_turn or (game_manager.phase != GameManager.Phase.MAIN_1 and game_manager.phase != GameManager.Phase.MAIN_2)
	var attack_locked: bool = game_manager.turn_manager.turn_number <= 1
	attack_button.disabled = not player_turn or game_manager.phase != GameManager.Phase.COMBAT or attack_locked
	attack_unit_button.disabled = not player_turn or game_manager.phase != GameManager.Phase.COMBAT or game_manager.selected_card == null or attack_locked
	attack_unit_button.text = "SELECCIONA OBJETIVO" if selecting_attack_target else "ATACAR UNIDAD"
	discard_button.disabled = not player_turn or game_manager.selected_card == null or game_manager.selected_card.zone != CardInstance.Zone.HAND
	end_turn_button.disabled = not player_turn or game_manager.phase == GameManager.Phase.DRAW or game_manager.phase == GameManager.Phase.END
	phase_button.disabled = not player_turn or game_manager.phase == GameManager.Phase.DRAW or game_manager.phase == GameManager.Phase.END
	phase_button.text = "PASAR A COMBATE" if game_manager.phase == GameManager.Phase.MAIN_1 else "PASAR FASE"
	_clear_container(hand_container)
	_clear_container(field_container)
	_clear_container(truth_container)
	_clear_container(secret_container)
	_clear_container(graveyard_container)
	_clear_container(deck_visual_container)
	_clear_container(opponent_field_container)
	_clear_container(opponent_hand_container)
	_clear_preview()
	_add_cards(hand_container, player.deck_manager.hand)
	_add_cards(field_container, player.deck_manager.field)
	_add_cards(truth_container, player.deck_manager.truths)
	_add_cards(secret_container, player.deck_manager.secrets)
	if not player.deck_manager.graveyard.is_empty():
		_add_cards(graveyard_container, [player.deck_manager.graveyard.back()])
	if player.deck_manager.deck.size() > 0:
		var card_back: Control = CARD_BACK_SCENE.instantiate() as Control
		deck_visual_container.add_child(card_back)
	_add_opponent_cards(opponent_field_container, opponent.deck_manager.field)
	for card: CardInstance in opponent.deck_manager.hand:
		var back: Control = CARD_BACK_SCENE.instantiate() as Control
		opponent_hand_container.add_child(back)


func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		child.queue_free()


func _add_cards(container: Container, cards: Array[CardInstance]) -> void:
	for card: CardInstance in cards:
		var card_view: CardView = CARD_VIEW_SCENE.instantiate() as CardView
		container.add_child(card_view)
		card_view.setup(card)
		card_view.selected.connect(_on_card_selected)
		card_view.set_selected(card == game_manager.selected_card)
		if card.zone == CardInstance.Zone.HAND:
			card_view.set_dimmed(game_manager.phase == GameManager.Phase.COMBAT)
		elif card.zone == CardInstance.Zone.FIELD:
			card_view.set_dimmed(game_manager.phase == GameManager.Phase.COMBAT and card.has_attacked)


func _on_card_selected(card_view: CardView) -> void:
	for child: Node in hand_container.get_children():
		if child is CardView:
			child.set_selected(child == card_view)
	for child: Node in field_container.get_children():
		if child is CardView:
			child.set_selected(child == card_view)
	game_manager.select_card(card_view.card_instance)
	_show_preview(card_view.card_instance)


func _on_attack_unit_pressed() -> void:
	selecting_attack_target = true
	status_label.text = "Selecciona una unidad rival"
	_refresh_board()


func _show_preview(card: CardInstance) -> void:
	_clear_preview()
	if card == null:
		return
	var preview: CardView = CARD_VIEW_SCENE.instantiate() as CardView
	selected_preview.add_child(preview)
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.position = Vector2(10, 24)
	preview.scale = Vector2(0.9, 0.9)
	preview.setup(card)
	preview.set_selected(true)


func _clear_preview() -> void:
	for child: Node in selected_preview.get_children():
		if child is CardView:
			child.queue_free()


func _add_opponent_cards(container: Container, cards: Array[CardInstance]) -> void:
	for card: CardInstance in cards:
		var card_view: CardView = CARD_VIEW_SCENE.instantiate() as CardView
		container.add_child(card_view)
		card_view.scale = Vector2(0.55, 0.55)
		card_view.setup(card)
		card_view.selected.connect(_on_opponent_card_selected)


func _on_opponent_card_selected(card_view: CardView) -> void:
	if selecting_attack_target and game_manager.selected_card != null and game_manager.phase == GameManager.Phase.COMBAT:
		game_manager.try_attack_unit(card_view.card_instance)
		selecting_attack_target = false


func _phase_name(current_phase: GameManager.Phase) -> String:
	match current_phase:
		GameManager.Phase.DRAW:
			return "ROBO"
		GameManager.Phase.MAIN_1:
			return "PRINCIPAL"
		GameManager.Phase.COMBAT:
			return "COMBATE"
		GameManager.Phase.MAIN_2:
			return "PRINCIPAL 2"
		GameManager.Phase.END:
			return "FIN"
	return "-"


func _on_damage_dealt(player_id: int, amount: int) -> void:
	var damage_label: Label = Label.new()
	damage_label.text = "-%d" % amount
	damage_label.position = Vector2(920 if player_id == 1 else 220, 72)
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
	damage_label.add_theme_font_size_override("font_size", 28)
	add_child(damage_label)
	var tween: Tween = create_tween()
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 35.0, 0.65)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.65)
	tween.tween_callback(damage_label.queue_free)


func _on_game_over(winner_id: int) -> void:
	var game_over_label: Label = $SafeArea/MainLayout/Board/GameOverLabel
	game_over_label.visible = true
	if winner_id == 0:
		status_label.text = "VICTORIA"
		game_over_label.text = "VICTORIA\nHas ganado la partida"
	elif winner_id == 1:
		status_label.text = "DERROTA"
		game_over_label.text = "DERROTA\nEl oponente ha ganado"
	else:
		status_label.text = "EMPATE"
		game_over_label.text = "EMPATE\nLa partida termina igualada"


func _toggle_pause_menu() -> void:
	pause_panel.visible = not pause_panel.visible
	get_tree().paused = pause_panel.visible
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS


func _leave_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
