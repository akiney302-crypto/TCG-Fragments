# Bitacora de cambios y decisiones

Este documento registra las etapas implementadas en el prototipo, el motivo de cada una y su resultado verificable. Las entradas nuevas van arriba. En cada cambio futuro del proyecto se agregara una entrada con fecha, archivos/areas tocadas, razon de diseno, resultado y validacion. Tambien se revisara `CARD_ARCHETYPES_DECKS.md`; si cambia cualquier carta, arquetipo, regla de sinergia o mazo, se actualizara su inventario en ese mismo cambio.

## 2026-10-06 - Biblia visual y reparacion de escenas

### Integracion de la Biblia
1. Se tomo la Biblia visual adjunta como guia semantica sin descartar Soulglass: se conservaron paneles oscuros y facetas, cambiando los acentos a TROOP cyan, CHAMPION oro, TRUTH violeta y SECRETS azul-violeta oscuro.
2. Se centralizo el mapeo tipo -> color/marco/sigilo/tier en `CardVisualTheme.gd`.
3. Se ajusto el CardView compartido a 160x224 con arte superior, coste en esquina, nombre, tipo, reglas, familia y ataque/HP abajo. `art_path` admite ilustracion final y el SVG del nucleo funciona como placeholder neutro.
4. La carta seleccionada recibe elevacion/pulso local; el feedback no toca el estado de juego.

### Reparacion del error al iniciar
1. Se revisaron las rutas `parent=` en todas las escenas. `game.tscn` y `deck_builder.tscn` tenian numerosos padres parciales como `TopBar`, `BottomBar`, `LeftPanel` y `RightPanel` que no correspondian a rutas desde la raiz de la escena.
2. Se corrigieron las rutas completas. Los nodos de boton y controles ahora pertenecen al arbol donde los scripts esperan encontrarlos; esto resolvia referencias `@onready` nulas que producian errores al acceder a `.pressed`.
3. Se verificaron todos los padres declarados y los `@onready` de scripts enlazados a escenas; no quedaron rutas pendientes.

### Validacion
- Analisis estatico global: sin errores.
- Verificador de escenas: padres completos y todas las rutas `@onready` resueltas.
- SVG: parseo XML valido para los once recursos.
- No hay ejecutable Godot en PATH; no se pudo realizar import ni ejecucion del proyecto con el motor 4.7.

## 2026-10-06 - Direccion visual Soulglass

### Cambios realizados
1. Se creo `art/ui/fragmenta_theme.tres`, un tema compartido de paneles oscuros translucidos, bordes jade, esquinas facetadas discretas y botones con estados normal, hover y pressed.
2. Se creo `art/ui/soulglass_backdrop.svg`, con planos geométricos de cristal y líneas de fractura para el fondo común de menú, partida, constructor y opciones.
3. Se crearon marcos y sigilos SVG originales para TROOP, CHAMPION, TRUTH y SECRETS, cada tipo con color, figura y lectura visual propia.
4. Se redisenyo CardView para mostrar marco, sigilo, familia, texto y estadisticas; se usa como preview en el constructor y como carta compacta seleccionable en la mano.
5. Se reemplazaron las filas de texto del catálogo por entradas con icono, y el campo muestra iconos, estadísticas actuales y color de tipo. La mano usa scroll horizontal y conserva los controles de juego existentes.
6. Se añadió un reverso de carta con un cristal central grabado y el mismo lenguaje de facetas.
7. Se centralizaron colores, paneles y controles en el Theme para que las vistas compartan materiales y estados coherentes.

### Motivo y resultado
La materia principal se representa con poligonos, planos y aristas; la cualidad eterea aparece en sus lineas translucidas y tonos internos. Los colores siguen la Biblia visual: cyan para tropas, oro para Champions, violeta para Truth y azul-violeta oscuro para Secrets. La identidad familiar queda como metadato, no compite con el color de tipo.

### Validacion
- El editor no reporta errores en las escenas y scripts visuales revisados.
- El recurso Theme se carga sin errores; la integracion actual suma once SVG originales parseables como XML.
- No se pudieron revisar capturas en runtime: Godot no esta disponible en el entorno.

## 2026-10-06 - Seleccion de mazo e iniciativa

### Cambios realizados
1. Se agrego `KNIGHT` y el preset Knight Training Deck: un Champion sin sinergia especial y tropas sencillas. Se usa como mazo seguro al abrir el editor o si no hay mazo activo valido.
2. El editor ahora permite cargar presets y mazos guardados, iniciar un mazo nuevo, limitar copias al agregar y guardar/activar el mazo para la siguiente partida. La validacion exige exactamente un Champion como As; el ID derivado del nombre se sanea antes de guardarse.
3. Se almacena el ID de mazo activo en `user://profile.cfg`; GameManager carga ese mazo al iniciar la partida y usa Knight Training Deck si no hay seleccion valida. La carpeta `user://decks` se crea desde su ruta absoluta globalizada.
4. Se agregaron dos Champions opcionales adicionales por familia (Dragon, Pirate y Mech). No se insertan en los presets: el jugador debe sustituir el Champion actual desde el editor.
5. Se implementaron habilidades de Champion para destruir la unidad enemiga mas debil, atacar una vez extra, robar/descartar una carta aleatoria de la mano rival y generar tokens mecanicos. El token no es elegible para mazos.
6. Se completo el estado de combate por instancia (`current_hp`, bonus de ataque y ataques restantes); los ataques extra se reinician al siguiente turno. La IA y el jugador comparten estas reglas.
7. Se agrego una pantalla de cara/cruz antes de crear la partida. La eleccion del jugador compite contra una cara aleatoria; si empieza la IA, realiza su accion de apertura antes de ceder el control.
8. Se ampliaron las pruebas de humo para presets, Champion unico y efectos de las seis variantes.

### Motivo y resultado
El deck seleccionado debe sobrevivir al cambio de escena y ser exactamente el que se usa en partida. Un As por lista mantiene clara la identidad del mazo y hace que los seis Champions alternativos sean elecciones reales, no cartas adicionales automáticas. Cara/cruz decide iniciativa antes de repartir y ejecutar acciones; el Training Deck ofrece una ruta de aprendizaje sin efectos de sinergia.

### Validacion
- Analisis estatico focalizado realizado tras cambios de scripts y escenas.
- Pendiente ejecutar pruebas de humo y revisar interfaz en Godot: no hay runtime del motor disponible en este entorno.
- Los presets Dragon/Pirate/Mech conservan sus Champions principales; Knight Training Deck es el preset por defecto.

## 2026-10-06 - Champions como Ases de arquetipo

### Necesidad
La primera version de las sinergias aplicaba un bonus general a cualquier carta del mismo arquetipo y modificaba `CardData.attack`, que es la definicion compartida entre copias. Ademas, el arquetipo de una carta del mazo enemigo se alteraba manualmente como prueba. Eso no expresaba la idea de los Champions como Ases y podia contaminar otras copias.

### Cambios realizados
1. Se agrego `champion_synergy` a `CardData`, con datos serializables en el catalogo: arquetipo requerido, numero minimo de aliados y recompensas de ataque, robo o curacion.
2. `ArchetypeManager` ahora activa la sinergia solo si la carta jugada es `CHAMPION` y ya hay suficientes aliados de la familia requerida en el campo. Los aliados requeridos no incluyen al Champion que acaba de entrar.
3. El bonus de ataque se guarda en `CardInstance.attack_bonus`, no en la definicion del catalogo. El combate, el registro de daño y el campo consultan el ataque efectivo de la instancia.
4. La vida actual se guarda como `CardInstance.current_hp`; el combate y la curacion de tropas ya no cambian el HP base de la carta compartida.
5. Se retiro la mutacion manual del arquetipo de la primera carta enemiga.
6. Se agregaron `DRAGON`, `PIRATE` y `MECH` como familias distintas, con un Champion y siete apoyos para cada una.
7. Se agrego `resources/decks/starter_decks.json` con tres listas de 20 cartas, cada una con un Champion unico, cartas de una sola familia y cantidades dentro del limite de tres copias por carta.
8. Se creo `CARD_ARCHETYPES_DECKS.md` con las propiedades, estadisticas, etiquetas, efectos y composiciones de los mazos.
9. Se actualizo `tests/test_runner.gd` para validar los tres presets y comprobar que el bonus de Dragon pertenece solo a la instancia del Champion.
10. Se conecto la misma activacion de Champion en la ruta de juego de la IA para que la regla aplique a ambos jugadores.

### Motivo de diseno
El arquetipo vive en los datos de cada carta; el Champion determina como convierte la presencia de su familia en una ventaja. Los apoyos pueden ser variados sin que todas las cartas reciban automaticamente el mismo bonus. Los efectos configurables elegidos para la primera prueba son ataque, robo y curacion, ya soportados por el estado de juego actual.

### Resultado
- Varkesh, Primarch of Cinders: 2 aliados DRAGON => +2 ATK.
- Mara Vane, Storm Admiral: 2 aliados PIRATE => +1 ATK y roba 1 carta.
- AX-9, Foundry Overseer: 2 aliados MECH => +1 ATK y cura 2 HP al jugador.
- Los tres mazos preconstruidos tienen exactamente 20 cartas, 1 Champion, 19 apoyos, maximo 3 copias por carta y 100% de su familia principal.
- La UI muestra los valores de ataque/vida actuales de la instancia, incluidos bonus y daño recibido.

### Validacion
- El analisis estatico del editor reporto que no hay errores en los scripts centrales modificados ni en `catalog.json`.
- Se comprobaron ambos JSON y las tres listas con PowerShell: 20 cartas, referencias validas, Champion/familia coherentes, IDs unicos y limites de copias respetados.
- El smoke test ampliado esta preparado, pero no se pudo ejecutar sin el runtime de Godot.
- Pendiente: ejecutar el proyecto con Godot y verificar partidas reales; el runtime de Godot no esta disponible en este entorno.
- Los presets son datos y aun no hay selector de mazo en el menu de inicio; no reemplazan todavia el mazo predeterminado de partida.

## Etapas anteriores conocidas

### Estructura del prototipo
Se creo un proyecto Godot con configuracion, escenas de menu/partida/mazo, scripts de datos y gestores de reglas, turnos, combate, efectos y una IA inicial. La separacion buscada fue datos -> estado -> reglas -> ejecucion -> presentacion, para que la UI no sea la autoridad del juego.

### Catalogo y cartas genericas
Se incorporo `resources/cards/catalog.json` con doce cartas iniciales (tropas, Champions, Truth y Secrets), estadisticas, textos, limites de copias y efectos base. Esto dio material suficiente para probar el constructor y el bucle de partida.

### Constructor y persistencia
Se agregaron `DeckData`, `DeckValidator`, el constructor visual y guardado/carga JSON en `user://decks`. Las reglas actuales esperan 20 cartas, maximo 3 copias para TROOP/TRUTH/SECRETS y 1 para CHAMPION.

### Identidad de arquetipo inicial
Se extendieron las cartas con `archetype` y `archetype_tags`, y los mazos con `family_name`. Inicialmente la sinergia era una bonificacion general de ataque; esta etapa se reemplazo por la activacion especifica de Champions descrita arriba.

## Formato requerido para futuras entradas

Para cada cambio, registrar:
- Fecha y objetivo.
- Archivos o sistemas modificados.
- Por que se eligio esa solucion y que alternativa se descarto, si importa.
- Resultado observable y cualquier limitacion.
- Validacion ejecutada y pendientes.
