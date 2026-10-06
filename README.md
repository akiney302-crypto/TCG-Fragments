# Fragmenta Animae

Fragmenta Animae is a Godot 4.x TCG prototype built around a clean data/state/rules architecture. The project is intentionally structured so content can be expanded without hardcoding gameplay rules into the UI.

## Project structure

- `project.godot` – Godot project configuration.
- `scenes/` – main scenes and UI shells.
- `scripts/` – game logic and controllers.
- `resources/cards/` – catalog and card JSON data.
- `tests/` – smoke and logic tests.

## Core rules

- 20-card deck, 5-card opening hand plus the active player's turn-start draw
- 20 HP, energy up to 10
- energy capacity starts at 1, grows by 1 per turn, and refills at turn start
- max 5 units on field
- turn phases: DRAW, PLACEMENT_1, ATTACK, PLACEMENT_2, END_TURN
- DRAW resolves automatically into PLACEMENT_1
- summoned units cannot attack until their next turn unless tagged HASTE
- one Champion per deck; hand limit applies to normal and effect draws
- card types: TROOP, CHAMPION, TRUTH, SECRETS
- copy limits: TROOP <= 3, CHAMPION <= 1, TRUTH/SECRETS <= 3

## Fallback note

This workspace does not currently include a Godot runtime, so the project can be created and structured here, but scene execution must be validated in a machine with the Godot editor or headless runner installed.

## Quick start

1. Open the folder in Godot 4.x.
2. Import the project.
3. Run the `main_menu.tscn` scene.
4. From the main menu, start a new match or open the deck builder.

## Acceptance checklist

- [x] Base project configuration created
- [x] Central game rules object created
- [x] Data models created for cards, instances, decks, and player state
- [x] Core managers created for deck logic, combat, AI, and turn flow
- [x] Main menu, game scene, card view, and deck builder placeholders created
- [x] Deck save/load flow scaffolded
- [x] Champion-focused archetype synergy foundation and four 20-card starter lists
- [x] Active deck selection, Knight beginner deck, optional Champion variants, and coin-toss initiative
- [x] Five-phase turns, visible card transitions, opponent hand count, procedural event audio, and escape/pause flow
- [x] Phase-gated combat, summon sickness, targeted enemy-unit combat/effects, spell-to-graveyard resolution, and hand cap
- [x] Direct End Turn action, complete AI phase loop, and regression checks for turn/zone rules
- [x] Test runner scaffold created
- [ ] Full runtime verification requires a Godot 4.x binary in the environment

## Project documentation

- `CHANGELOG_DECISIONS.md` records project changes, the reasoning behind them, outcomes, and validation. Update it with every future project change.
- `CARD_ARCHETYPES_DECKS.md` inventories card stats, properties, archetypes, synergies, and deck lists. Review/update it with every future project change, especially any change to card or deck data.
- `resources/decks/starter_decks.json` contains Knight, Dragon, Pirate, and Mech starter lists. The deck editor loads presets or saved decks and saves the chosen deck as active for the next match.
- Every deck must contain one Champion. The Dragon, Pirate, and Mech families each have two extra optional Champions that the player can add from the catalog.
- Every match begins with a heads-or-tails choice to decide which side takes the opening action.
- `art/ui/` contains the shared Soulglass theme, faceted backgrounds, card frames, type sigils, coin faces, soul-core placeholder, and card back used across the interface (thirteen original SVG assets).
- `scripts/ui/SoulAudio.gd` synthesizes short procedural sounds for shuffle, summon, damage, destruction, effects, discard, and the coin toss.
