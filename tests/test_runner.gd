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

    var expected_start_hand: int = GameRules.STARTING_HAND_SIZE + GameRules.TURN_START_DRAW_COUNT
    if not _assert_test(manager.player.hand.size() == expected_start_hand, "Opening hand plus turn draw mismatch."):
        quit()
        return
    if not _assert_test(manager.turn_manager.phase == "PLACEMENT_1" and manager.player.energy == GameRules.STARTING_ENERGY, "The opening draw should automatically advance to placement with starting energy."):
        quit()
        return

    var test_card := CardInstance.new(catalog.get_card_by_id("knight_squire"), "player")
    test_card.set_zone("HAND")
    manager.player.hand.append(test_card)
    manager.player.energy = manager.player.max_energy
    if not _assert_test(manager.play_card_from_hand(test_card)["ok"], "The automatic draw should leave the player ready to place cards."):
        quit()
        return

    manager.advance_game_phase()
    if not _assert_test(manager.turn_manager.phase == "ATTACK", "PLACEMENT_1 should advance to ATTACK."):
        quit()
        return
    if not _assert_test(not manager.attack(test_card, manager.enemy)["ok"], "A unit summoned this turn must not attack during ATTACK."):
        quit()
        return
    var enemy_target := CardInstance.new(catalog.get_card_by_id("knight_squire"), "enemy")
    enemy_target.set_zone("FIELD")
    manager.enemy.field.append(enemy_target)
    var eligible_attacker := CardInstance.new(catalog.get_card_by_id("knight_veteran"), "player")
    eligible_attacker.set_zone("FIELD")
    eligible_attacker.summoned_this_turn = false
    manager.player.field.append(eligible_attacker)
    if not _assert_test(manager.turn_manager.phase == "ATTACK" and test_card.summoned_this_turn and not manager.attack(test_card, manager.enemy)["ok"], "A unit summoned this turn must not attack."):
        quit()
        return
    if not _assert_test(manager.attack(eligible_attacker, enemy_target)["ok"] and manager.enemy.graveyard.has(enemy_target), "An eligible unit should attack and destroy a selected enemy unit."):
        quit()
        return
    manager.advance_game_phase()
    if not _assert_test(manager.turn_manager.phase == "PLACEMENT_2", "The second placement phase should follow combat."):
        quit()
        return

    var spell := CardInstance.new(catalog.get_card_by_id("lunar_truth"), "player")
    spell.set_zone("HAND")
    manager.player.hand.append(spell)
    var spell_result: Dictionary = manager.play_card_from_hand(spell)
    if not _assert_test(spell_result["ok"] and spell.zone == "GRAVEYARD" and not manager.player.field.has(spell), "TRUTH cards should resolve and go to graveyard, not FIELD."):
        quit()
        return

    var secret_target := CardInstance.new(catalog.get_card_by_id("knight_guard"), "enemy")
    secret_target.set_zone("FIELD")
    manager.enemy.field.append(secret_target)
    var secret := CardInstance.new(catalog.get_card_by_id("whisper_secret"), "player")
    secret.set_zone("HAND")
    manager.player.hand.append(secret)
    var secret_result: Dictionary = manager.play_card_from_hand(secret, secret_target)
    if not _assert_test(secret_result["ok"] and secret.zone == "GRAVEYARD" and not manager.enemy.field.has(secret_target), "SECRETS should resolve their selected target and go to graveyard."):
        quit()
        return

    manager.advance_game_phase()
    if not _assert_test(manager.turn_manager.phase == "END_TURN", "The turn should reach END_TURN after the second placement phase."):
        quit()
        return
    if not _assert_test(manager.end_turn(0) and manager.turn_manager.active_player_index == 1 and manager.turn_manager.phase == "DRAW", "End Turn should switch directly to the next player's draw phase."):
        quit()
        return
    if not _assert_test(not manager.end_turn(0), "The inactive player must not end the opponent's turn."):
        quit()
        return

    if manager.enemy.hp != GameRules.STARTING_HP:
        push_error("A newly summoned unit must not deal attack damage.")
        quit()
        return

    if manager.enemy.hand.size() != GameRules.OPENING_HAND_SIZE + GameRules.TURN_START_DRAW_COUNT or manager.enemy.energy != 2:
        push_error("The incoming active player should draw and refill energy at turn start.")
        quit()
        return

    if not _assert_test(manager.end_turn(1) and not test_card.summoned_this_turn and RuleManager.can_attack(test_card, manager.player), "Summon sickness should expire at the owner's next turn."):
        quit()
        return

    var capped_hand := PlayerState.new("Hand cap test")
    for index in range(GameRules.MAX_HAND_SIZE):
        var held_card := CardInstance.new(catalog.get_card_by_id("knight_squire"), "player")
        held_card.set_zone("HAND")
        capped_hand.hand.append(held_card)
    capped_hand.deck.append(CardInstance.new(catalog.get_card_by_id("knight_squire"), "player"))
    if not _assert_test(capped_hand.draw_cards(1).is_empty() and capped_hand.hand.size() == GameRules.MAX_HAND_SIZE, "Drawing must respect MAX_HAND_SIZE."):
        quit()
        return

    var direct_end_manager := GameManager.new()
    direct_end_manager.catalog = catalog
    direct_end_manager.start_new_game(DeckSaveManager.load_starter_deck("knight_starter"), 0)
    if not _assert_test(direct_end_manager.end_turn(0) and direct_end_manager.turn_manager.active_player_index == 1, "End Turn should work directly without walking through phases."):
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
