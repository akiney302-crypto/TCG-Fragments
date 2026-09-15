# Fragmenta Animae - Documento maestro de continuidad

Fecha de revision: 2026-09-13
Motor: Godot 4.7.x
Proyecto: TCG Fragmenta Animae - Fragmentos de Almas
Plataformas objetivo: PC y Android
Estado: prototipo tecnico jugable, todavia no listo para produccion ni multijugador

Este documento resume el estado real del proyecto despues del trabajo realizado hoy. Sirve como contexto para otra conversacion con ChatGPT, Copilot o cualquier asistente de programacion. Debe entregarse junto con el repositorio Godot para continuar sin reconstruir el contexto.

---

## 1. Instruccion para el siguiente asistente

Antes de modificar nada:

1. Revisar este documento y compararlo con el repositorio real.
2. Ejecutar el analizador de errores de Godot y cargar `scenes/game/game.tscn`.
3. Ejecutar las dos pruebas:
   - `res://tests/smoke_test.gd`
   - `res://tests/opponent_smoke_test.gd`
4. No sustituir la arquitectura actual por la arquitectura antigua descrita en bloques historicos de Notion.
5. Mantener esta frontera:

```text
CardData/CardInstance -> datos
RuleManager -> validacion
DeckManager -> movimiento entre zonas
TurnManager -> fases y preparacion de turno
CombatManager -> dano y combate
EffectManager -> efectos declarativos
GameManager -> coordinacion
scripts/ui/game.gd -> presentacion e input
CardView -> representacion de una carta
OpponentController -> decisiones del rival
```

6. No crear un script individual por carta.
7. No crear un `ZoneManager` paralelo: `DeckManager` es la autoridad de las zonas.
8. No añadir IA avanzada, multijugador, guardado complejo o efectos masivos hasta cerrar los criterios de la seccion 10.

---

## 2. Objetivo actual

La primera demo debe demostrar un bucle completo y entendible:

```text
Menu -> Nueva partida -> Mazos -> Mano inicial -> Robo
-> Fases -> Energia -> Jugar cartas -> Combate
-> Dano -> Cementerio -> Victoria/derrota -> Reiniciar
```

La demo no necesita todavia reglamento definitivo, arte final, red, coleccion persistente ni IA sofisticada. La prioridad es que el bucle sea estable, legible y repetible.

---

## 3. Arquitectura real del proyecto

### Datos

- `scripts/data/card_data.gd`
  - Recurso editable de una carta.
  - Tipos actuales: `TROOP`, `CHAMPION`, `TRUTH`, `SECRETS`.
  - Coste, ataque, vida, texto, arte y campos de efectos.
  - No mueve cartas ni conoce nodos de la escena.

- `scripts/data/card_instance.gd`
  - Copia mutable de una carta durante la partida.
  - Guarda zona, ataque/vida actuales, `has_attacked` y `face_down`.
  - Zonas actuales: `DECK`, `HAND`, `FIELD`, `TRUTH`, `SECRETS`, `GRAVEYARD`.

- `scripts/data/deck_data.gd`
  - Recurso de mazo.
  - Contiene un array de `CardData`.

- `scripts/data/player_state.gd`
  - Vida, energia y referencia al `DeckManager` del jugador.

### Sistemas

- `scripts/systems/deck_manager.gd`
  - Unica autoridad para mover cartas.
  - Zonas: deck, hand, field, truths, secrets y graveyard.
  - Carga copias desde `DeckData`.
  - Aplica maximo de 3 copias para cartas normales y 1 para `CHAMPION`.
  - Roba, juega unidades, coloca Truth/Secrets y envia cartas al cementerio.
  - `send_secret_to_graveyard()` centraliza la revelacion y salida de Secrets.

- `scripts/systems/turn_manager.gd`
  - Alterna jugador activo.
  - Incrementa energia hasta 10.
  - Roba al comenzar turno.
  - Restablece `has_attacked` de las unidades del jugador activo.

- `scripts/systems/rule_manager.gd`
  - Decide si jugar una carta o atacar es legal.
  - Campo de unidades: maximo 5.
  - Truth: maximo 3.
  - Secrets: maximo 2.
  - Bloquea ataques durante el primer turno.
  - Valida que una carta pertenezca a la zona del jugador.

- `scripts/systems/combat_manager.gd`
  - Ataque directo a vida.
  - Combate entre unidades con dano simultaneo.
  - Las unidades con vida menor o igual que 0 se envian al cementerio.

- `scripts/systems/effect_manager.gd`
  - Ejecuta efectos declarados en `CardData`.
  - Acciones actuales: dano al jugador, curacion, robo y dano a unidad.
  - Disparadores de cartas: `ON_PLAY`, `ON_DEATH`, `ON_REVEAL`.
  - Eventos de Secrets: `OPPONENT_PLAY`, `OPPONENT_SUMMON`, `OPPONENT_ATTACK`, `OPPONENT_TRUTH`.
  - Es una base declarativa, no un sistema completo de objetivos o pila de efectos.

- `scripts/systems/game_manager.gd`
  - Coordina jugadores, fases, reglas, combate, efectos e IA.
  - No debe contener la logica especifica de cada carta.

- `scripts/systems/opponent_controller.gd`
  - IA heuristica inicial.
  - Juega cartas por valor aproximado.
  - Prioriza efectos ofensivos y campeones.
  - Busca destruir unidades si el atacante sobrevive.
  - Si no encuentra intercambio rentable, ataca directamente.
  - Juega antes y despues de combate del rival.

### Presentacion

- `scripts/ui/game.gd`
  - Conecta botones y seleccion de cartas.
  - Reconstruye la interfaz a partir del estado del juego.
  - Muestra campos, mano, Truth, Secrets, mazo, cementerio y campo rival.
  - Gestiona seleccion, preview ampliado, opacidad de cartas y menu de pausa.

- `scripts/cards/card_view.gd`
  - Presenta una carta.
  - Tiene seleccion, animacion de entrada, contorno, carta boca abajo y estado opaco.

- `scripts/cards/card_back.gd`
  - Representa cartas no reveladas.

- `scripts/ui/deck_builder.gd`
  - Editor de deck inicial en memoria.
  - Limite de 20 cartas.
  - Maximo 3 copias normales y 1 Champion.
  - Todavia no guarda el deck en disco.

- `scripts/ui/zone_frame.gd`
  - Dibuja marcos simples para zonas.

---

## 4. Escenas y recursos importantes

### Escenas

- `scenes/main/main_menu.tscn`
- `scenes/main/deck_builder.tscn`
- `scenes/game/game.tscn`
- `scenes/cards/card_view.tscn`
- `scenes/cards/card_back.tscn`
- `scenes/ui/card_inspector.tscn`
- `scenes/zones/*.tscn`

La escena principal de juego contiene:

```text
Game
├── SafeArea/MainLayout/TopBar
├── SafeArea/MainLayout/Board
│   ├── OpponentArea
│   │   ├── HandContainer (dorsos)
│   │   └── CardContainer (unidades rivales)
│   ├── SelectedPreview
│   ├── PlayerArea
│   │   ├── FieldZone (unidades)
│   │   ├── SpecialZones
│   │   │   ├── TruthZone
│   │   │   └── SecretsZone
│   │   ├── LowerZones/DeckStack/DeckZone
│   │   ├── LowerZones/DeckStack/GraveyardZone
│   │   └── HandZone
│   └── GameOverLabel
├── ActionBar
├── PausePanel
└── GameManager
    ├── PlayerDeckManager
    ├── EnemyDeckManager
    ├── RuleManager
    ├── TurnManager
    ├── CombatManager
    ├── OpponentController
    └── EffectManager
```

### Recursos de cartas

Hay cartas de prueba antiguas y una coleccion nueva. La demo usa `resources/decks/demo_deck.tres`.

El mazo provisional tiene 20 entradas y mezcla cartas repetidas. Debe revisarse una vez que el editor de deck tenga persistencia.

La nomenclatura de tipos actual es:

- `TROOP`: unidad comun, hasta 3 copias.
- `CHAMPION`: unidad poderosa, 1 copia.
- `TRUTH`: carta que se juega desde mano y resuelve efecto al entrar.
- `SECRETS`: carta que queda boca abajo y se revela por condicion rival.

---

## 5. Reglas jugables actuales

- Vida inicial: 20.
- Mano inicial: 5 cartas.
- Energia creciente: empieza en 1 y sube hasta 10.
- Mazo provisional: 20 cartas.
- Campo de unidades: maximo 5.
- Truth en zona propia: maximo 3.
- Secrets en zona propia: maximo 2.
- El primer turno no permite atacar.
- Una unidad puede atacar una vez por turno.
- Las unidades que llegan a vida 0 o menos van al cementerio.
- Se puede atacar directamente al jugador rival.
- Se puede atacar una unidad rival mediante modo `ATACAR UNIDAD`.
- El turno puede terminar desde fase principal o combate.
- Las cartas de mano se atenuan visualmente durante combate.
- Las unidades que ya atacaron se atenuan visualmente.
- Secrets se colocan boca abajo y se activan mediante eventos configurables.
- Hay menu de pausa para continuar o abandonar al menu principal.

### Fases

```text
DRAW       -> preparacion automatica y robo
MAIN_1     -> jugar cartas
COMBAT     -> atacar directo o atacar unidades
MAIN_2     -> jugar cartas restantes
END        -> entrega el control al siguiente jugador
```

La fase `DRAW` se prepara internamente al iniciar el turno y `MAIN_1` es la primera fase interactiva.

---

## 6. Trabajo realizado hoy

### Correcciones y robustez

- Se reviso el proyecto completo y se comprobo la carga de Godot.
- Se mantuvo la arquitectura basada en datos y sistemas separados.
- Se corrigio el movimiento de Secrets para que pase por `DeckManager` y emita `zones_changed`.
- Se mantuvo el envio de unidades destruidas desde `FIELD` a `GRAVEYARD`.
- Se añadieron comentarios de orientacion en sistemas de combate, efectos, fases y UI.
- Se comprobo que las clases globales cargan en Godot.
- Se conecto `CombatManager.unit_destroyed` con `EffectManager.resolve_death_effect`, por lo que `ON_DEATH` ya se dispara al morir una unidad en combate o por dano de efecto.

### Contenido y reglas

- Se añadieron 10 unidades de prueba y un mazo provisional de 20 cartas.
- Se cambiaron los nombres de tipo a `TROOP`, `CHAMPION`, `TRUTH` y `SECRETS`.
- Se añadieron limites de copias y limites de zonas.
- Se implementaron efectos declarativos basicos.
- Se implementaron condiciones simples para Secrets.
- Se implemento IA rival heuristica.

### Interfaz

- Se amplio el viewport a 1440x900.
- Se crearon marcos de zonas.
- Se reorganizaron mazo y cementerio en el bloque inferior derecho.
- El cementerio muestra solo la ultima carta.
- La mano rival muestra dorsos, no informacion oculta numerica.
- La carta seleccionada tiene preview ampliado.
- Las cartas tienen animacion de entrada y seleccion.
- Se ajustaron tamaños y recortes de texto.
- Se añadieron simbolos de vida y energia.
- Se añadio mensaje de victoria, derrota o empate.
- Se añadio menu de pausa y abandono.
- Se añadio un editor de deck basico en memoria.

### Pruebas ejecutadas

```text
SMOKE TEST PASSED
OPPONENT SMOKE TEST PASSED
```

La prueba base cubre robo, zonas, cartas, limites de Champion, efectos y destruccion. La prueba rival cubre carga de partida, primer turno sin ataque, fases, IA y seleccion de objetivos.

---

## 7. Evaluacion tecnica actual

### Lo que esta bien

1. La separacion `datos -> reglas -> ejecucion -> presentacion` es apropiada para un TCG.
2. Las cartas son recursos y no clases especiales por carta.
3. `DeckManager` es la autoridad unica de zonas.
4. La IA usa las mismas operaciones del juego que el jugador.
5. Los efectos se expresan como datos en lugar de condicionales por nombre.
6. El proyecto ya tiene pruebas headless reproducibles.
7. La UI soporta raton y toque desde el mismo `CardView`.
8. El limite de campo, energia y copias se puede validar centralmente.

### Lo que debe mejorarse antes de ampliar el juego

1. **Persistencia del Deck Builder**
   - Actualmente el deck builder trabaja en memoria.
   - Debe guardar y cargar un `DeckData` propio del jugador.
   - Debe validar tamaño exacto, duplicados y cartas disponibles.

2. **Sistema de objetivos de efectos**
   - Ahora `DAMAGE_UNIT` elige la unidad mas debil automaticamente.
   - Para produccion se necesita un modelo de objetivo: jugador, unidad propia, unidad rival, zona o global.
   - La UI debe pedir objetivo cuando el efecto lo requiera.

3. **Eventos de juego tipados**
   - Los Secrets usan strings como `OPPONENT_ATTACK`.
   - Antes de crecer conviene centralizar eventos en un enum o recurso para evitar errores de escritura.

4. **Efectos de muerte**
  - `ON_DEATH` ya esta conectado para combate y dano de efectos.
  - Deben añadirse pruebas especificas para cartas con efecto de muerte y comprobar interacciones encadenadas.

5. **Senales de zonas**
   - Existe `zones_changed`, pero la UI reconstruye muchas zonas completas cada vez.
   - Para la demo es aceptable; despues conviene actualizar solo la zona afectada.

6. **IA por fases**
   - La IA actual actua sin pausas y puede jugar varias acciones seguidas en el mismo frame.
   - Antes de probar sensacion de juego debe añadirse una cola de acciones con pequeños tiempos de espera y decision visible.

7. **Estado de partida**
   - La derrota por mazo vacio, empate por reglas especiales y condiciones de victoria alternativas aun no estan modeladas.
   - Debe definirse antes de crear cartas que dependan de ellas.

8. **Presentacion responsive**
   - El viewport es amplio y legible en escritorio.
   - Debe probarse en 1280x720, 1024x768, movil horizontal y movil con touch.
   - La escena actual ha acumulado offsets manuales y necesita una pasada de layout con containers/anchors mas estrictos.

9. **Limpieza de recursos historicos**
   - Hay cartas de prueba antiguas y escenas de zonas que ya no son el camino visual principal.
   - No borrarlas sin confirmacion, pero marcarlas como legacy o moverlas a una carpeta de pruebas.

10. **Codificacion y texto**
   - Algunos textos usan acentos y simbolos Unicode y otros scripts conservan ASCII.
   - Elegir UTF-8 de forma consistente antes de localizar el juego.

---

## 8. Recomendaciones inspiradas en otros TCG digitales

Estas recomendaciones son principios de diseño, no codigo copiado.

### Hearthstone

La pagina oficial destaca una entrada sencilla, cartas de unidades y hechizos, mazos prediseñados y una experiencia que permite profundizar progresivamente. Para Fragmenta Animae conviene conservar:

- Un mazo de demo listo para jugar.
- Pocas decisiones visibles por fase.
- Coste y resultado claros antes de confirmar.
- Un flujo que permita empezar una partida sin configurar todo.

Fuente publica: https://hearthstone.blizzard.com/en-us/how-to-play

### Magic: The Gathering

La pagina oficial de reglas separa reglas basicas y reglas completas, y presenta el documento completo como referencia para casos concretos. Para este proyecto conviene adoptar:

- Un reglamento corto para la demo.
- Un documento de referencia separado para excepciones.
- Eventos y prioridades explicitos cuando el juego crezca.
- No mezclar explicaciones de diseño con reglas ejecutables.

Fuente publica: https://magic.wizards.com/en/rules

### Legends of Runeterra

Su historial publico de actualizaciones muestra un modelo basado en rondas, ataques y cambios de cartas que se pueden ajustar sin reescribir todo el juego. La idea aprovechable aqui es:

- Tratar cada accion como una transicion comprobable.
- Mantener una ventana clara de quien puede actuar.
- Hacer visibles los eventos que cambian prioridad.
- Diseñar efectos reactivos alrededor de eventos, no de referencias directas a botones.

Fuente publica: https://playruneterra.com/en-us/news/game-updates/

### Aplicacion concreta a Fragmenta Animae

- Mantener fases simples para la Demo v0.1.
- Añadir un registro de eventos antes de crear una pila compleja.
- Mostrar siempre fase, jugador activo, coste y objetivo.
- Resolver efectos de forma determinista y testeable.
- No añadir velocidad de hechizos, respuestas encadenadas o prioridad avanzada hasta que el modelo de objetivos este estable.

---

## 9. Siguientes pasos recomendados

### Paso 1 - Cerrar la Demo v0.1

Objetivo: que el jugador pueda completar una partida manual sin errores visuales ni reglas ambiguas.

Tareas:

- Probar una partida completa con el mazo demo.
- Confirmar jugar unidades, Truth y Secrets.
- Confirmar atacar directo y atacar unidades.
- Confirmar destruccion y cementerio.
- Confirmar primer turno sin ataque.
- Confirmar reinicio y abandono.
- Confirmar mensaje de victoria y derrota.
- Probar el juego con teclado, raton y touch emulado.

Criterio de salida: dos partidas completas sin errores en Debugger.

### Paso 2 - Cerrar el modelo de cartas

- Renombrar campos y categorias a español o mantenerlos todos en ingles, pero no mezclar.
- Definir objetivo de efecto.
- Definir duracion de modificadores.
- Definir eventos en un enum.
- Añadir efectos de muerte de forma uniforme.

Criterio de salida: cinco efectos distintos cubiertos por pruebas.

### Paso 3 - Persistir el Deck Builder

- Crear `user_deck.tres` o un recurso equivalente.
- Cargarlo al iniciar la partida.
- Guardar cambios al abandonar el editor.
- Mostrar cartas disponibles y cartas seleccionadas.
- Validar 20 cartas y limites por tipo.

Criterio de salida: cambiar el deck sin tocar scripts y jugar con el deck guardado.

### Paso 4 - Pulir UI y UX

- Revisar cuatro resoluciones.
- Reducir reconstrucciones completas de UI.
- Añadir feedback de carta no jugable y motivo.
- Añadir animacion de robo, juego, ataque, destruccion y revelacion.
- Añadir log de acciones opcional para depuracion.

Criterio de salida: un usuario puede entender por que una accion no esta disponible sin abrir el debugger.

### Paso 5 - Mejorar IA

- Convertir decisiones en una cola con tiempos.
- Evaluar letalidad.
- Evaluar valor de intercambio.
- Priorizar Secrets activables y Truths por contexto.
- Evitar jugar una carta si deja energia sin sentido.
- Añadir pruebas de escenarios, no solo una prueba de turno.

Criterio de salida: la IA completa 10 partidas simuladas sin errores y toma decisiones legibles.

### Paso 6 - Preparar versus local

- Separar `OpponentController` de la autoridad de turno.
- Crear un controlador de jugador humano para ambos lados.
- Sustituir `player_id == 1` por una interfaz de participante.
- Añadir seleccion de jugador local y orden de prioridad.
- No iniciar red hasta que dos controladores locales puedan jugar una partida completa.

Criterio de salida: dos jugadores locales pueden alternar turnos con la misma logica.

---

## 10. Lo que no se debe añadir todavia

No avanzar aun con:

- Multijugador online.
- Deck Builder avanzado con coleccion persistente completa.
- Efectos con pila y respuestas encadenadas.
- IA avanzada basada en simulacion.
- Cientos de cartas.
- Animaciones finales y arte definitivo.
- Economia, sobres o tienda.
- Guardado de replay.

Primero deben cumplirse los criterios de salida de las secciones 9.1 a 9.3.

---

## 11. Comandos de validacion

Desde la carpeta del proyecto:

```powershell
$godot = Get-Process | Where-Object { $_.ProcessName -match 'Godot' } | Select-Object -First 1 -ExpandProperty Path
& $godot --headless --path . --editor --quit
& $godot --headless --path . --script 'res://tests/smoke_test.gd'
& $godot --headless --path . --script 'res://tests/opponent_smoke_test.gd'
```

Resultado esperado:

```text
SMOKE TEST PASSED
OPPONENT SMOKE TEST PASSED
```

Los procesos headless pueden mostrar avisos de recursos/texturas liberados al salir. Deben distinguirse de errores de carga o errores de GDScript.

---

## 12. Resumen para continuar en otra conversacion

Fragmenta Animae tiene una Demo v0.1 funcional en Godot 4 con datos de cartas, mazos, fases, combate, efectos simples, Secrets reactivos, IA rival, UI de mesa, deck builder en memoria, pausa, reinicio y pruebas headless. La arquitectura actual es adecuada para seguir creciendo.

La prioridad inmediata no es añadir mas contenido. Es cerrar la demo con persistencia del deck, objetivos de efectos, eventos tipados, efectos de muerte uniformes, feedback de reglas, pruebas de resoluciones y una pasada responsive de la interfaz.

La regla principal de continuidad es:

```text
Primero estabilidad y legibilidad de la Demo v0.1.
Despues persistencia y contenido.
Luego IA refinada y versus local.
Solo despues red, economia y produccion.
```
