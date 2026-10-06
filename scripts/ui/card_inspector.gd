extends PanelContainer

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var detail_label: Label = $MarginContainer/VBoxContainer/DetailLabel
@onready var effect_label: Label = $MarginContainer/VBoxContainer/EffectLabel

func set_card(card: CardData) -> void:
	if card == null:
		title_label.text = "No card"
		detail_label.text = ""
		effect_label.text = ""
		return

	title_label.text = card.name
	detail_label.text = "Type: %s | Cost: %d | ATK: %d | HP: %d" % [card.type, card.cost, card.attack, card.hp]
	effect_label.text = card.text
