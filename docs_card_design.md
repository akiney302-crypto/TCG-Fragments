# Guia visual de cartas

La escena `scenes/cards/card_view.tscn` es la plantilla comun de todas las cartas.

## Marco

- Mantener un panel base de 160 x 224 px.
- Usar un `StyleBoxFlat` comun para fondo, esquinas y borde.
- Cambiar solo el color de borde o acento segun `TROOP`, `CHAMPION`, `TRUTH` o `SECRETS`.
- No crear una escena nueva por carta.

## Dorso

`scenes/cards/card_back.tscn` representa cualquier carta no revelada. El dorso no recibe `CardData`; solo comunica que existe una carta oculta.

## Etiquetas

- Nombre: una linea, con elipsis si es largo.
- Tipo: una linea compacta.
- Coste: esquina superior izquierda.
- Texto de efecto: rectangulo de altura fija, con ajuste de palabras y recorte.
- Ataque y vida: fila inferior.

Los textos de reglas nunca deben estar dibujados dentro del arte. Asi el mismo marco puede reutilizarse en PC, movil y futuras traducciones.

## Nuevas cartas

1. Crear un recurso `CardData` en `resources/cards/`.
2. Elegir `card_type` y configurar coste, atributos y efecto.
3. Reutilizar un arte compatible.
4. Añadir el recurso a un `DeckData`.
5. No añadir condicionales por nombre de carta en los scripts.
