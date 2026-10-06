extends Control

@onready var player_hp_label: Label = $MarginContainer/VBoxContainer/TopBar/HBoxContainer/PlayerInfo/PlayerHP
@onready var enemy_hp_label: Label = $MarginContainer/VBoxContainer/TopBar/HBoxContainer/EnemyInfo/EnemyHP
@onready var turn_label: Label = $MarginContainer/VBoxContainer/TopBar/HBoxContainer/TurnInfo/TurnLabel
@onready var phase_label: Label = $MarginContainer/VBoxContainer/TopBar/HBoxContainer/PhaseInfo/PhaseLabel
@onready var hand_container: HBoxContainer = $MarginContainer/VBoxContainer/CenterArea/HandPanel/HandScroll/HandContainer
@onready var field_container: VBoxContainer = $MarginContainer/VBoxContainer/CenterArea/FieldPanel/FieldContainer
@onready var enemy_field_container: VBoxContainer = $MarginContainer/VBoxContainer/CenterArea/EnemyFieldPanel/EnemyFieldContainer
@onready var action_buttons: HBoxContainer = $MarginContainer/VBoxContainer/BottomBar/ActionButtons
@onready var end_turn_button: Button = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/EndTurnButton
@onready var play_button: Button = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/PlayButton
@onready var discard_button: Button = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/DiscardButton
@onready var attack_button: Button = $MarginContainer/VBoxContainer/BottomBar/ActionButtons/AttackButton
@onready var log_label: RichTextLabel = $MarginContainer/VBoxContainer/LogPanel/LogLabel
@onready var coin_flip_overlay: ColorRect = $CoinFlipOverlay
@onready var coin_flip_result: Label = $CoinFlipOverlay/CenterContainer/Panel/Content/Result
@onready var heads_button: Button = $CoinFlipOverlay/CenterContainer/Panel/Content/ChoiceButtons/HeadsButton
@onready var tails_button: Button = $CoinFlipOverlay/CenterContainer/Panel/Content/ChoiceButtons/TailsButton

var game_manager: GameManager = GameManager.new()
var selected_card: CardInstance = null

func _ready() -> void:
	add_child(game_manager)
	game_manager.turn_started.connect(_on_turn_started)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	play_button.pressed.connect(_on_play_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	heads_button.pressed.connect(_on_coin_choice.bind(0))
	tails_button.pressed.connect(_on_coin_choice.bind(1))
	_refresh_ui()

func _on_coin_choice(player_choice: int) -> void:
	heads_button.disabled = true
	tails_button.disabled = true
	coin_flip_result.text = "The coin is in the air..."
	await get_tree().create_timer(0.6).timeout
	var coin_result: int = randi_range(0, 1)
	var first_player: int = 0 if coin_result == player_choice else 1
	coin_flip_result.text = "%s. First player: %s." % ["Heads" if coin_result == 0 else "Tails", "You" if first_player == 0 else "A.I."]
	await get_tree().create_timer(0.8).timeout
	game_manager.start_new_game(DeckSaveManager.load_active_deck(), first_player)
	coin_flip_overlay.hide()
	_refresh_ui()

func _on_turn_started(turn_number: int, phase: String) -> void:
	_refresh_ui()

func _refresh_ui() -> void:
	if game_manager.player == null:
		return

	player_hp_label.text = "HP: %d/%d" % [game_manager.player.hp, game_manager.player.max_hp]
	enemy_hp_label.text = "HP: %d/%d" % [game_manager.enemy.hp, game_manager.enemy.max_hp]
	turn_label.text = "Turn: %d" % [game_manager.turn_manager.current_turn]
	phase_label.text = "Phase: %s" % [game_manager.turn_manager.phase]
	log_label.text = "\n".join(game_manager.log_messages)

	_populate_hand()
	_populate_fields()

func _populate_hand() -> void:
	for child in hand_container.get_children():
		child.queue_free()

	for card in game_manager.player.hand:
		var card_view: CardView = preload("res://scenes/card_view.tscn").instantiate()
		hand_container.add_child(card_view)
		card_view.set_compact()
		card_view.set_card_instance(card)
		card_view.selected.connect(_on_card_selected)

func _populate_fields() -> void:
	for child in field_container.get_children():
		child.queue_free()
	for child in enemy_field_container.get_children():
		child.queue_free()

	for card in game_manager.player.field:
		field_container.add_child(_create_field_row(card))

	for card in game_manager.enemy.field:
		enemy_field_container.add_child(_create_field_row(card))

func _create_field_row(card: CardInstance) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(34, 34)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = CardView.get_type_icon(card.card_data.type)
	row.add_child(icon)
	var label := Label.new()
	label.text = "%s  |  %d ATK  |  %d HP" % [card.get_name(), card.get_attack(), card.get_hp()]
	label.add_theme_color_override("font_color", CardView.get_type_color(card.card_data.type))
	row.add_child(label)
	return row

func _on_card_selected(card: CardInstance) -> void:
	selected_card = card

func _on_play_pressed() -> void:
	if selected_card == null:
		return
	var result := game_manager.play_card_from_hand(selected_card)
	if result["ok"]:
		selected_card = null
		_refresh_ui()
	else:
		print(result["message"])

func _on_discard_pressed() -> void:
	if selected_card == null:
		return
	game_manager.player.hand.erase(selected_card)
	game_manager.player.graveyard.append(selected_card)
	selected_card = null
	_refresh_ui()

func _on_attack_pressed() -> void:
	if selected_card == null:
		return
	var result := game_manager.attack(selected_card, game_manager.enemy)
	if result["ok"]:
		_refresh_ui()
	else:
		print(result["message"])

func _on_end_turn_pressed() -> void:
	game_manager.turn_manager.advance_phase()
	if game_manager.turn_manager.phase == "END":
		game_manager.end_turn()
