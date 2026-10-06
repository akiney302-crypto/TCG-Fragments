# Cartas, arquetipos y mazos

Inventario de diseno del catalogo y los mazos iniciales. C = coste; ATK = ataque base; HP = vida base; copias = limite permitido por mazo. El HP actual y los bonus de ataque pertenecen a cada instancia durante la partida. Salvo que se indique lo contrario, `effect` es `none`.

## Lenguaje visual

La direccion Soulglass mezcla planos y aristas de cristal con trazos interiores translucidos. Los fondos usan facetas angulares y lineas de fractura; los marcos no dependen de una imagen de personaje, por lo que se pueden usar con ilustraciones futuras sin taparlas. `CardVisualTheme.gd` selecciona los recursos por tipo; no se crean escenas por carta.

| Tipo | Acento | Sigilo |
| --- | --- | --- |
| TROOP | Crystal Cyan `#43C7D9` | Faceta / escudo de tropa |
| CHAMPION | Champion Gold `#E6B95A` | Corona facetada |
| TRUTH | Truth Violet `#8E63D7` | Ojo de cristal |
| SECRETS | Arcane Blue `#4C78E7` sobre World Dark | Mascara fragmentada |

El recurso compartido esta en `art/ui/fragmenta_theme.tres`; fondo, marcos, iconos, placeholder del nucleo y reverso viven en `art/ui/`. Menu, partida, constructor y opciones comparten fondo/tema. El constructor y la mano de juego usan la carta enmarcada; el catalogo y el campo usan sus sigilos por tipo. CardView mide 160x224 en preview y reduce de forma uniforme en la mano.

## Modelo de carta

- `id`, `name`, `type`, `cost`, `attack`, `hp`, `text`, `max_copies`, `effect`, `art_path`: identidad, reglas base y presentacion.
- `archetype`: familia principal, por ejemplo `DRAGON`, `PIRATE` o `MECH`.
- `archetype_tags`: etiquetas secundarias para futuras reglas, busqueda y sinergias (no tienen efecto automatico por ahora).
- `champion_synergy`: configuracion opcional exclusiva de un Champion: `archetype`, `min_allies`, `attack_bonus`, `extra_attacks`, `draw`, `heal`, `destroy_weakest_enemy`, `opponent_hand_action`, `token_id`, `spawn_token_count`.
- La sinergia se evalua al jugar al Champion (tanto jugador como IA) y cuenta aliados de esa familia que ya esten en el campo. No vuelve a activarse ni se recalcula despues.
- Cada mazo legal tiene exactamente un Champion. Los tokens no son elegibles para mazos.

## Reglas actuales de sinergia

| Champion | Familia requerida | Aliados necesarios | Recompensa |
| --- | --- | ---: | --- |
| Varkesh, Primarch of Cinders | DRAGON | 2 | +2 ATK mientras esta instancia permanezca en juego |
| Mara Vane, Storm Admiral | PIRATE | 2 | +1 ATK y robar 1 carta |
| AX-9, Foundry Overseer | MECH | 2 | +1 ATK y curar 2 HP al jugador |
| Aurex, Skybreaker | DRAGON | 2 | +1 ATK y un ataque adicional este turno |
| Khalzun, Ash Devourer | DRAGON | 2 | Destruye la unidad rival con menos HP actual |
| Nyx Blackwake | PIRATE | 2 | Roba una carta aleatoria de la mano rival |
| Dread Corsair Vexa | PIRATE | 2 | Descarta una carta aleatoria de la mano rival |
| M-0 Scrapcaller | MECH | 2 | Invoca un token Scrapling 1/1 |
| Forge-Mother 7 | MECH | 2 | Invoca hasta dos tokens Scrapling 1/1 |

No hay penalizacion por combinar familias en un mazo; los presets solo usan una familia para que su plan sea claro. La bonificacion es por instancia y no altera el catalogo.

## Cartas de arquetipo nuevas

### DRAGON

| Carta | Tipo | C/ATK/HP | Copias | Etiquetas | Texto / efecto |
| --- | --- | --- | ---: | --- | --- |
| Varkesh, Primarch of Cinders | CHAMPION | 5/4/5 | 1 | ACE, FIRE, FLYING | Con 2 otros Dragons en campo: +2 ATK. |
| Cinder Hatchling | TROOP | 1/1/2 | 3 | FIRE, YOUNG | Dragon joven de la nidada. |
| Scaleguard | TROOP | 2/2/3 | 3 | DEFENDER, SCALED | Defensor con escamas acorazadas. |
| Skyhunter Drake | TROOP | 2/2/2 | 3 | FLYING, SCOUT | Explorador alado veloz. |
| Embermaw Ravager | TROOP | 3/3/2 | 3 | FIRE, AGGRESSIVE | Atacante feroz de los nidos volcanicos. |
| Ancient Cloud Drake | TROOP | 5/4/5 | 3 | FLYING, ELDER | Drake antiguo que domina los cielos. |
| Broodcaller | TROOP | 3/2/3 | 3 | SUPPORT, BROOD | Lider que reune a los dragones. |
| Hoard Warden | TROOP | 4/3/4 | 3 | DEFENDER, TREASURE | Guardian veterano del tesoro. |
| Aurex, Skybreaker | CHAMPION | 6/5/5 | 1 | ACE, FLYING, AGGRESSIVE | +1 ATK y un ataque adicional este turno con 2 aliados Dragon. |
| Khalzun, Ash Devourer | CHAMPION | 6/4/7 | 1 | ACE, FIRE, CONTROL | Con 2 aliados Dragon, destruye la unidad enemiga con menos HP actual. |

### PIRATE

| Carta | Tipo | C/ATK/HP | Copias | Etiquetas | Texto / efecto |
| --- | --- | --- | ---: | --- | --- |
| Mara Vane, Storm Admiral | CHAMPION | 4/3/4 | 1 | ACE, CAPTAIN, NAVAL | Con 2 otros Pirates en campo: +1 ATK y roba 1. |
| Cabin Runner | TROOP | 1/1/2 | 3 | CREW, SWIFT | Grumete veloz que mantiene a la tripulacion en marcha. |
| Galehook Corsair | TROOP | 2/2/2 | 3 | RAIDER, NAVAL | Asaltante de la costa de tormentas. |
| Cannonhand | TROOP | 3/3/3 | 3 | GUNNER, NAVAL | Artillero de andanada. |
| Reef Raider | TROOP | 3/3/2 | 3 | RAIDER, SWIFT | Atacante que conoce las calas ocultas. |
| First Mate Rook | TROOP | 4/3/4 | 3 | CREW, OFFICER | Mano derecha de la Almirante. |
| Powder Gunner | TROOP | 3/3/3 | 3 | GUNNER, CREW | Tirador firme incluso en cubierta agitada. |
| Tidebreaker Buccaneer | TROOP | 4/4/4 | 3 | VETERAN, RAIDER | Veterano que rompe las lineas enemigas. |
| Nyx Blackwake | CHAMPION | 5/4/4 | 1 | ACE, THIEF, NAVAL | Con 2 aliados Pirate, roba una carta aleatoria de la mano rival. |
| Dread Corsair Vexa | CHAMPION | 5/3/6 | 1 | ACE, CONTROL, NAVAL | Con 2 aliados Pirate, descarta una carta aleatoria de la mano rival. |

### MECH

| Carta | Tipo | C/ATK/HP | Copias | Etiquetas | Texto / efecto |
| --- | --- | --- | ---: | --- | --- |
| AX-9, Foundry Overseer | CHAMPION | 5/3/6 | 1 | ACE, SYNTHETIC, COMMAND | Con 2 otros Mechs en campo: +1 ATK y cura 2. |
| Scout Drone K-1 | TROOP | 1/1/2 | 3 | DRONE, SCOUT | Maquina compacta de reconocimiento. |
| Alloy Sentinel | TROOP | 2/2/4 | 3 | AUTOMATON, DEFENDER | Automata acorazado para sostener la linea. |
| Gearstriker | TROOP | 2/3/2 | 3 | AUTOMATON, AGGRESSIVE | Unidad mecanica rapida de impacto fuerte. |
| Field Artificer | TROOP | 3/2/3 | 3 | SUPPORT, ENGINEER | Artifice de campo que mantiene la maquinaria. |
| Bastion Frame | TROOP | 4/3/5 | 3 | MECH, DEFENDER | Chasis pesado para anclar la formacion. |
| Rail Lancer | TROOP | 4/4/3 | 3 | RANGED, AGGRESSIVE | Chasis de precision con lanza de largo alcance. |
| Colossus Platform | TROOP | 5/4/6 | 3 | MECH, HEAVY | Fortaleza andante de gran tamano. |
| M-0 Scrapcaller | CHAMPION | 5/3/5 | 1 | ACE, COMMAND, TOKEN | Con 2 aliados Mech, invoca un Scrapling 1/1. |
| Forge-Mother 7 | CHAMPION | 6/3/7 | 1 | ACE, ENGINEER, TOKEN | Con 2 aliados Mech, invoca hasta dos Scrapling 1/1. |
| Scrapling | TROOP / TOKEN | 0/1/1 | 0 | TOKEN, AUTOMATON | Refuerzo fragil; generado por Champions, no se puede agregar al deck. |

### KNIGHT (mazo de aprendizaje)

| Carta | Tipo | C/ATK/HP | Copias | Etiquetas | Texto / efecto |
| --- | --- | --- | ---: | --- | --- |
| Knight Captain | CHAMPION | 4/3/5 | 1 | ACE, BASIC | Champion sencillo, sin habilidad especial. |
| Knight Squire | TROOP | 1/1/2 | 3 | BASIC, SOLDIER | Unidad inicial sencilla. |
| Knight Guard | TROOP | 2/2/3 | 3 | BASIC, DEFENDER | Defensor equilibrado, sin reglas extra. |
| Knight Archer | TROOP | 2/2/2 | 3 | BASIC, RANGED | Atacante directo. |
| Knight Veteran | TROOP | 3/3/3 | 3 | BASIC, SOLDIER | Luchador de coste medio. |
| Knight Lancer | TROOP | 4/4/3 | 3 | BASIC, ATTACKER | Atacante fuerte, sin habilidad especial. |
| Knight Bulwark | TROOP | 4/2/5 | 3 | BASIC, DEFENDER | Unidad resistente para aprender intercambios. |
| Knight Page | TROOP | 1/1/2 | 3 | BASIC, SOLDIER | Refuerzo modesto. |

## Cartas genericas anteriores

| Carta | Tipo | C/ATK/HP | Copias | Arquetipo / etiquetas | Texto / efecto |
| --- | --- | --- | ---: | --- | --- |
| Ember Knight | TROOP | 2/2/3 | 3 | EMBER: FIRE, WARRIOR | Unidad fiable de primera linea. Sin efecto. |
| Sunwisp | TROOP | 1/1/2 | 3 | SOLAR: LIGHT, HEALER | Al jugar, cura 1 HP al jugador. |
| Spire Guard | CHAMPION | 4/3/5 | 1 | WARDEN: PROTECTOR, TANK | Al jugar, aumenta HP maximo del jugador en 1. |
| Lunar Truth | TRUTH | 2/0/0 | 3 | SOLAR: LIGHT, SUPPORT | Restaura 2 HP al jugador. |
| Whisper Secret | SECRETS | 3/0/0 | 3 | VOID: SECRET, STEALTH | `destroy_on_destroy` esta preparado, pero es un marcador sin resolucion completa. |
| Stone Sentinel | TROOP | 3/3/4 | 3 | WARDEN: STONE, DEFENDER | Guardian resistente. Sin efecto. |
| Glass Rusher | TROOP | 2/4/1 | 3 | EMBER: FIRE, AGGRESSIVE | Atacante explosivo y fragil. Sin efecto. |
| Sacred Bloom | TRUTH | 1/0/0 | 3 | SOLAR: LIGHT, RECOVERY | Cura 1 HP al jugador. |
| Mire Tide | SECRETS | 2/0/0 | 3 | VOID: DARK, CONTROL | El texto promete retrasar al enemigo; el efecto actual es solo marcador `destroy_on_destroy`. |
| Radiant Guardian | CHAMPION | 5/4/6 | 1 | SOLAR: LIGHT, DEFENDER | Al jugar, aumenta HP maximo del jugador en 2. |
| Drift Scout | TROOP | 1/2/2 | 3 | AETHER: SWIFT, RANGED | Unidad rapida de apoyo. Sin efecto. |
| Moonlit Oath | TRUTH | 3/0/0 | 3 | AETHER: RITUAL, SUPPORT | Aumenta HP maximo del jugador en 2. |

## Mazos preconstruidos

Los cuatro datos viven en `resources/decks/starter_decks.json`. Cada lista tiene 20 cartas y un unico Champion. Las seis alternativas de Dragon/Pirate/Mech no estan incluidas automaticamente: para usarlas, quita el Champion actual y agrega el elegido en el constructor. El coste medio incluye los 20 espacios; las medias de ATK/HP suman los valores base de las cartas.

| Mazo | Familia | Champion | Coste medio | ATK medio base | HP medio base | Plan |
| --- | --- | --- | ---: | ---: | ---: | --- |
| Dragon Brood | DRAGON | Varkesh, Primarch of Cinders | 2.85 | 2.45 | 3.00 | Desplegar aliados y cerrar con un Champion de gran pegada. |
| Storm Freebooters | PIRATE | Mara Vane, Storm Admiral | 2.80 | 2.60 | 2.80 | Presion temprana; el Champion recupera una carta si la tripulacion esta establecida. |
| Foundry Colossi | MECH | AX-9, Foundry Overseer | 2.90 | 2.60 | 3.45 | Unidades resistentes y curacion del Champion para alargar la partida. |
| Knight Training Deck | KNIGHT | Knight Captain | 2.65 | 2.30 | 3.05 | Curva directa y unidades equilibradas para aprender las reglas basicas. |

### Lista exacta por mazo

- **Dragon Brood:** Varkesh x1; Cinder Hatchling x3; Scaleguard x3; Skyhunter Drake x3; Embermaw Ravager x3; Ancient Cloud Drake x3; Broodcaller x3; Hoard Warden x1.
- **Storm Freebooters:** Mara Vane x1; Cabin Runner x3; Galehook Corsair x3; Cannonhand x3; Reef Raider x3; First Mate Rook x3; Powder Gunner x3; Tidebreaker Buccaneer x1.
- **Foundry Colossi:** AX-9 x1; Scout Drone K-1 x3; Alloy Sentinel x3; Gearstriker x3; Field Artificer x3; Bastion Frame x3; Rail Lancer x3; Colossus Platform x1.
- **Knight Training Deck:** Knight Captain x1; Knight Squire x3; Knight Guard x3; Knight Archer x3; Knight Veteran x3; Knight Lancer x3; Knight Bulwark x3; Knight Page x1.

## Alcance y pendientes conocidos

- `archetype_tags` son metadatos; aun no activan reglas.
- El constructor carga presets o mazos guardados; guardar activa el mazo para la siguiente partida. Si no existe una seleccion valida, se usa Knight Training Deck.
- Al iniciar una partida se elige cara o cruz; el resultado establece quien juega la accion de apertura.
- Los seis Champions alternativos solo se agregan manualmente y cada lista debe conservar exactamente un Champion.
- Las sinergias se comprueban solo al jugar Champion; no son auras dinamicas ni vuelven a comprobarse al cambiar el campo.
- No existe todavia ejecucion completa de Secrets/Truth por zona, selector de Champion o arte asociado.
- Cualquier ajuste de datos debe reflejarse aqui y en `CHANGELOG_DECISIONS.md` en el mismo cambio.
