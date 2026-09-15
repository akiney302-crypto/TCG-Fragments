extends Control

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton
@onready var deck_button: Button = $CenterContainer/VBoxContainer/DeckButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	deck_button.pressed.connect(_on_deck_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_deck_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/deck_builder.tscn")
