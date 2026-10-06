extends RefCounted
class_name DeckSaveManager

const SAVE_DIRECTORY: String = "user://decks"
const PROFILE_PATH: String = "user://profile.cfg"
const ACTIVE_DECK_KEY: String = "active_deck_id"

static func ensure_directory() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIRECTORY))

static func save_deck(deck: DeckData) -> bool:
    ensure_directory()
    var path: String = SAVE_DIRECTORY + "/%s.json" % [deck.id]
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    var payload: Dictionary = deck.to_dictionary()
    file.store_string(JSON.stringify(payload, "  "))
    file.close()
    return true

static func set_active_deck(deck_id: String) -> bool:
    var profile := ConfigFile.new()
    profile.set_value("decks", ACTIVE_DECK_KEY, deck_id)
    return profile.save(PROFILE_PATH) == OK

static func get_active_deck_id() -> String:
    var profile := ConfigFile.new()
    if profile.load(PROFILE_PATH) != OK:
        return ""
    return String(profile.get_value("decks", ACTIVE_DECK_KEY, ""))

static func load_active_deck() -> DeckData:
    var deck_id: String = get_active_deck_id()
    if deck_id.is_empty():
        return null
    var saved_deck: DeckData = load_deck(SAVE_DIRECTORY + "/%s.json" % deck_id)
    if saved_deck != null:
        return saved_deck
    return load_starter_deck(deck_id)

static func load_starter_deck(deck_id: String) -> DeckData:
    var file := FileAccess.open("res://resources/decks/starter_decks.json", FileAccess.READ)
    if file == null:
        return null
    var payload: Dictionary = JSON.parse_string(file.get_as_text())
    file.close()
    for entry in payload.get("decks", []):
        if String(entry.get("id", "")) == deck_id:
            return DeckData.from_dictionary(entry)
    return null

static func load_starter_decks() -> Array[DeckData]:
    var result: Array[DeckData] = []
    var file := FileAccess.open("res://resources/decks/starter_decks.json", FileAccess.READ)
    if file == null:
        return result
    var payload: Dictionary = JSON.parse_string(file.get_as_text())
    file.close()
    for entry in payload.get("decks", []):
        result.append(DeckData.from_dictionary(entry))
    return result

static func load_deck(path: String) -> DeckData:
    if not FileAccess.file_exists(path):
        return null
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
    var data: Dictionary = JSON.parse_string(file.get_as_text())
    file.close()
    if data.is_empty():
        return null
    return DeckData.from_dictionary(data)

static func list_saved_decks() -> Array[String]:
    ensure_directory()
    var result: Array[String] = []
    var dir := DirAccess.open(SAVE_DIRECTORY)
    if dir == null:
        return result
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if file_name.ends_with(".json"):
            result.append(SAVE_DIRECTORY + "/" + file_name)
        file_name = dir.get_next()
    return result
