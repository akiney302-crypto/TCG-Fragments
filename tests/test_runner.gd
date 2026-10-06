extends SceneTree

func _init() -> void:
    var catalog := CatalogManager.new()
    catalog.load_catalog("res://resources/cards/catalog.json")

    var validator := DeckValidator.new()
    var presets_file := FileAccess.open("res://resources/decks/starter_decks.json", FileAccess.READ)
    if presets_file == null:
        push_error("Starter deck data could not be opened.")
        quit()
        return
    var presets_payload: Dictionary = JSON.parse_string(presets_file.get_as_text())
    presets_file.close()
    for preset in presets_payload.get("decks", []):
        var deck := DeckData.new(String(preset["id"]), String(preset["name"]))
        deck.card_quantities = preset["card_quantities"].duplicate(true)
        deck.family_name = String(preset["archetype"])
        var validation := validator.validate(deck, catalog)
        if not validation["valid"]:
            push_error("Deck validation failed for %s: %s" % [deck.id, validation["errors"]])
            quit()
            return

    var dragon_player := PlayerState.new("Dragon test")
    dragon_player.field.append(CardInstance.new(catalog.get_card_by_id("dragon_hatchling"), "player"))
    dragon_player.field.append(CardInstance.new(catalog.get_card_by_id("dragon_scaleguard"), "player"))
    var dragon_champion_data: CardData = catalog.get_card_by_id("dragon_primarch")
    var dragon_champion := CardInstance.new(dragon_champion_data, "player")
    var synergy_result := ArchetypeManager.new().activate_champion_synergy(dragon_player, dragon_champion)
    if not synergy_result["activated"] or dragon_champion.get_attack() != 6 or dragon_champion_data.attack != 4:
        push_error("Champion synergy should modify the instance without changing catalog stats.")
        quit()
        return

    var archetypes := ArchetypeManager.new()
    var skybreaker_player := _make_family_player(catalog, "DRAGON")
    var skybreaker := CardInstance.new(catalog.get_card_by_id("dragon_skybreaker"), "player")
    archetypes.activate_champion_synergy(skybreaker_player, skybreaker)
    if not _assert_test(skybreaker.attacks_remaining == 2, "Skybreaker should gain one extra attack this turn."):
        quit()
        return

    var destroy_player := _make_family_player(catalog, "DRAGON")
    var dragon_opponent := PlayerState.new("Rival", true)
    dragon_opponent.field.append(CardInstance.new(catalog.get_card_by_id("knight_veteran"), "enemy"))
    dragon_opponent.field.append(CardInstance.new(catalog.get_card_by_id("knight_squire"), "enemy"))
    archetypes.activate_champion_synergy(destroy_player, CardInstance.new(catalog.get_card_by_id("dragon_ash_devourer"), "player"), dragon_opponent, catalog)
    if not _assert_test(dragon_opponent.graveyard.size() == 1 and dragon_opponent.graveyard[0].card_data.id == "knight_squire", "Ash Devourer should destroy the weakest enemy unit."):
        quit()
        return

    var pirate_player := _make_family_player(catalog, "PIRATE")
    var pirate_opponent := PlayerState.new("Rival", true)
    pirate_opponent.hand.append(CardInstance.new(catalog.get_card_by_id("knight_squire"), "enemy"))
    archetypes.activate_champion_synergy(pirate_player, CardInstance.new(catalog.get_card_by_id("pirate_blackwake"), "player"), pirate_opponent, catalog)
    if not _assert_test(pirate_player.hand.size() == 1 and pirate_opponent.hand.is_empty(), "Blackwake should steal one enemy hand card."):
        quit()
        return

    var discard_player := _make_family_player(catalog, "PIRATE")
    var discard_opponent := PlayerState.new("Rival", true)
    discard_opponent.hand.append(CardInstance.new(catalog.get_card_by_id("knight_squire"), "enemy"))
    archetypes.activate_champion_synergy(discard_player, CardInstance.new(catalog.get_card_by_id("pirate_dreadcorsair"), "player"), discard_opponent, catalog)
    if not _assert_test(discard_opponent.hand.is_empty() and discard_opponent.graveyard.size() == 1, "Dread Corsair should discard one enemy hand card."):
        quit()
        return

    var mech_player := _make_family_player(catalog, "MECH")
    archetypes.activate_champion_synergy(mech_player, CardInstance.new(catalog.get_card_by_id("mech_scrapcaller"), "player"), null, catalog)
    if not _assert_test(mech_player.field.size() == 3 and mech_player.field.back().card_data.id == "mech_scrapling", "Scrapcaller should summon a Scrapling token."):
        quit()
        return

    var forge_player := _make_family_player(catalog, "MECH")
    archetypes.activate_champion_synergy(forge_player, CardInstance.new(catalog.get_card_by_id("mech_forge_mother"), "player"), null, catalog)
    if not _assert_test(forge_player.field.size() == 4, "Forge-Mother should summon two Scrapling tokens."):
        quit()
        return

    var manager := GameManager.new()
    manager.catalog = catalog
	manager.start_new_game(DeckSaveManager.load_starter_deck("knight_starter"), 0)

    if manager.player.hand.size() != GameRules.STARTING_HAND_SIZE:
        push_error("Opening hand size mismatch.")
        quit()
        return

    if manager.enemy.hp != GameRules.STARTING_HP:
        push_error("Enemy HP mismatch.")
        quit()
        return

    print("Test runner completed successfully.")
    quit()

func _make_family_player(catalog: CatalogManager, family: String) -> PlayerState:
    var player := PlayerState.new("Family test")
    for card in catalog.get_all_cards():
        if card.archetype == family and card.type != "CHAMPION":
            player.field.append(CardInstance.new(card, "player"))
            if player.field.size() == 2:
                break
    return player

func _assert_test(condition: bool, message: String) -> bool:
    if not condition:
        push_error(message)
    return condition
