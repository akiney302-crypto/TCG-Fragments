extends Resource
class_name CardData

@export var id: String = ""
@export var name: String = "Card"
@export var type: String = "TROOP"
@export var cost: int = 1
@export var attack: int = 1
@export var hp: int = 1
@export var text: String = ""
@export var max_copies: int = 3
@export var effect: Dictionary = {}
@export var art_path: String = ""
@export var archetype: String = "NONE"
@export var archetype_tags: Array[String] = []
@export var champion_synergy: Dictionary = {}

func _init(p_id: String = "", p_name: String = "Card", p_type: String = "TROOP", p_cost: int = 1, p_attack: int = 1, p_hp: int = 1):
    id = p_id
    name = p_name
    type = p_type
    cost = p_cost
    attack = p_attack
    hp = p_hp
    max_copies = GameRules.get_copy_limit(p_type)
    archetype = "NONE"
    archetype_tags = []
    champion_synergy = {}

static func from_dictionary(data: Dictionary) -> CardData:
    var card := CardData.new()
    card.id = String(data.get("id", ""))
    card.name = String(data.get("name", "Card"))
    card.type = String(data.get("type", "TROOP")).to_upper()
    card.cost = int(data.get("cost", 1))
    card.attack = int(data.get("attack", 1))
    card.hp = int(data.get("hp", 1))
    card.text = String(data.get("text", ""))
    card.max_copies = int(data.get("max_copies", GameRules.get_copy_limit(card.type)))
    card.effect = data.get("effect", {})
    card.art_path = String(data.get("art_path", ""))
    card.archetype = String(data.get("archetype", "NONE")).to_upper()
    card.archetype_tags = []
    var tag_list: Array = data.get("archetype_tags", [])
    for tag in tag_list:
        card.archetype_tags.append(String(tag).to_upper())
    card.champion_synergy = data.get("champion_synergy", {}).duplicate(true)
    return card

func clone() -> CardData:
    var copy := CardData.new(id, name, type, cost, attack, hp)
    copy.text = text
    copy.max_copies = max_copies
    copy.effect = effect.duplicate(true)
    copy.art_path = art_path
    copy.archetype = archetype
    copy.archetype_tags = archetype_tags.duplicate()
    copy.champion_synergy = champion_synergy.duplicate(true)
    return copy

func to_dictionary() -> Dictionary:
    return {
        "id": id,
        "name": name,
        "type": type,
        "cost": cost,
        "attack": attack,
        "hp": hp,
        "text": text,
        "max_copies": max_copies,
        "effect": effect,
        "art_path": art_path,
        "archetype": archetype,
        "archetype_tags": archetype_tags,
        "champion_synergy": champion_synergy.duplicate(true),
    }
