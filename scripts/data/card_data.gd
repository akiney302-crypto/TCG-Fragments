class_name CardData
extends Resource

## Plantilla editable de una carta. Se guarda como .tres y no conoce la partida.

@export_category("Identify")
@export var card_id: String = ""
@export var card_name: String = "New card"
@export_multiline var description: String = ""

@export_category("Rules")
@export_enum("TROOP", "CHAMPION", "TRUTH", "SECRETS") var card_type: String = "TROOP"
@export var subtype: String = ""
@export var cost: int = 1
@export var attack: int = 1
@export var life: int = 1

@export_category("Effect")
@export_enum("NONE", "ON_PLAY", "ON_DEATH", "ON_REVEAL") var effect_trigger: String = "NONE"
@export_enum("NONE", "DAMAGE_PLAYER", "HEAL_PLAYER", "DRAW_CARD", "DAMAGE_UNIT") var effect_action: String = "NONE"
@export var effect_value: int = 0
@export_enum("NONE", "OPPONENT_PLAY", "OPPONENT_SUMMON", "OPPONENT_ATTACK", "OPPONENT_TRUTH") var secret_trigger: String = "NONE"

@export_category("Art")
@export var artwork: Texture2D
