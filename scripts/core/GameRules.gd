extends RefCounted
class_name GameRules

const CARD_TYPES: Array[String] = ["TROOP", "CHAMPION", "TRUTH", "SECRETS"]
const DEFAULT_COPY_LIMITS: Dictionary = {
    "TROOP": 3,
    "CHAMPION": 1,
    "TRUTH": 3,
    "SECRETS": 3,
}

const STARTING_HP: int = 20
const MAX_HP: int = 20
const STARTING_ENERGY: int = 1
const MAX_ENERGY: int = 10
const STARTING_HAND_SIZE: int = 5
const STARTING_DECK_SIZE: int = 20
const MAX_DECK_SIZE: int = 20
const MAX_FIELD_SIZE: int = 5
const MAX_HAND_SIZE: int = 10
const TURN_PHASES: Array[String] = ["DRAW", "PLACEMENT_1", "ATTACK", "PLACEMENT_2", "END_TURN"]
const TURN_START_ENERGY_GAIN: int = 1
const TURN_START_DRAW_COUNT: int = 1
const OPENING_HAND_SIZE: int = 5
const ARCHETYPES: Array[String] = ["KNIGHT", "DRAGON", "PIRATE", "MECH", "EMBER", "SOLAR", "VOID", "AETHER", "WARDEN", "NATURE", "NONE"]
const SYNERGY_THRESHOLD: int = 2
const SYNERGY_BONUS: int = 1

static func get_copy_limit(card_type: String) -> int:
    return int(DEFAULT_COPY_LIMITS.get(card_type, 3))

static func get_valid_target_types() -> Array[String]:
    return ["PLAYER", "CARD"]

static func is_valid_card_type(type_name: String) -> bool:
    return CARD_TYPES.has(type_name.to_upper())

static func get_faction_label(type_name: String) -> String:
    return type_name.to_upper()
