extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var deck_button: Button = $CenterContainer/VBoxContainer/DeckBuilderButton
@onready var options_button: Button = $CenterContainer/VBoxContainer/OptionsButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_game_pressed)
	deck_button.pressed.connect(_on_deck_builder_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_deck_builder_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/deck_builder.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options_menu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
