# Prompt della proposta grafica v1

Data: 2026-11-04. Strumento: image_gen integrato in Codex, senza CLI/API separata.

Risultato selezionato: `immagini/folding_rooms_main_ui_style_v1.png`.
Il testo inglese seguente è l'input esatto fornito al generatore, conservato per riprodurre e modificare la proposta. Le specifiche operative in italiano sono in `docs/STILE.md`.

## Generazione iniziale

```text
Use case: ui-mockup.
Asset type: a polished art direction proposal for the actual MAIN GAMEPLAY SCREEN of the mobile game "Folding Rooms", a cozy hotel room reshaping puzzle. Create ONE complete edge-to-edge portrait 9:16 screen, straight-on, no device frame, no presentation board, no callout annotations.
Primary request: a beautiful, usable, highly legible mobile game interface showing a modular dollhouse hotel front-on inside an editable rectangular grid. Emphasize reshaping rooms for animal guests. Boutique Mediterranean warmth, sophisticated storybook 2D illustration, crisp hand-shaped silhouettes, lightly textured matte paper, restrained tactile depth and soft shadows. Premium indie cozy game, not photorealistic, not shiny 3D, not generic dashboard. Charming yet extremely clear at phone size.
Palette: warm ivory #F5EDDD, pale cream #FFF9EE, dark espresso ink #342F2A, deep teal #245D56 for interaction, muted mint #BED5C2, terracotta #C46D50, honey gold #D8A348; plum #383044 for a dark room. Keep backgrounds quiet and low contrast, UI labels dark and sharp.
Composition: top 12% clear compact header; middle 66% dominant play area; lower 22% current guest card and queue. Leave safe blank breathing room near top and bottom edges.
Header: small refined title "Folding Rooms", then an economical row with a gold coin icon and "86", calendar icon and "Giorno 8", arrival icon and "2 arrivi". One clear deep teal build button with a room-plus icon, label "Costruisci" and gold coin "70". A small separate undo-arrow icon button belongs at the extreme top right; it means reset and must remain secondary. No hearts, gems, energy, currencies besides coins or extra progression meters.
Game board: tall rectangular 6 columns by 8 rows of equal square cells, fully visible with subtle dotted grid only in unused space, a pale sand backing, slender cream architectural framing. Orthographic front section, absolutely no isometric perspective. The board feels like a flexible hotel under construction, with a slim terracotta roof cap and subtle ivory outer walls. Not a rigid stack of identical storeys. All rooms align to this invisible modular grid. Room arrangement from upper-left of board, zero indexed:
- vacant 2x2 space at columns 0-1 rows 0-1, visibly pale and available for expansion.
- Selected empty tall bedroom at columns 0-1 rows 2-4, exactly 2 cells wide and 3 tall, muted mint wallpaper, a tiny mustard armchair and low side table, a simple patterned rug, clear empty space for an arriving giraffe. Thick clean deep teal selection outline. Four LARGE light ivory pill-shaped handles with deep teal double-headed arrow glyphs at the midpoints of the four edges. Only this room has handles. A discreet ghost of one extra row above its ceiling with a dotted teal border indicates that its ceiling can be pulled up into the free cells; show a compact upward arrow. This is the visual focal point. No finger or hand covering it.
- upper-right bedroom 2x2 at columns 2-3 rows 0-1: soft terracotta walls, cute tiny sleepy dormouse beside a small bed, very few furnishings.
- upper-right dark room 2x2 at columns 4-5 rows 0-1: muted deep plum wallpaper with a cozy smiling bat hanging, small moon icon. Darkness comes from the room light mode, not from its position.
- mid-right room 2x2 at columns 2-3 rows 2-3: cream wallpaper and a small plant creature under a clearly illustrated special grow lamp, warm pool of light.
- long low snake bedroom 4x1 at columns 2-5 row 4: warm terracotta with a relaxed green snake lying horizontally on a low cushion, generous horizontal shape.
- leave remaining middle gaps and rows 5-7 mostly unused, quiet ivory building grid, allowing future rooms and free rearrangement; no extra room features, corridors or stairs. Restrained empty cells make the editable puzzle space understandable, not a spreadsheet. Minimal climbing plant at OUTSIDE edge only.
Inside occupied rooms, one tiny cream badge in the top-left shows calendar icon "2" or "3", indicating days remaining. Animals stay entirely inside room boundaries. Furniture never covers the room walls or handles. Shapes and portraits must read at a small phone size. Only 2-3 decorative objects per room.
A small cream contextual strip just below the board and above guest card says "Camera normale", plus two compact moon and lamp outlined controls with "10" coin labels. These are light mode purchases for the selected room. Keep them visually secondary and outside the editable board.
Bottom current guest panel: a single generous ivory rounded card, subtle dark warm border, on the left an adorable expressive giraffe portrait with folded green scarf and small suitcase, in middle bold text "Giraffa" then "Sta bene in 2 × 3 celle". Beneath, explicit compact values "2 giorni" and two distinct mood icons with "10 / giorno" happy and "4 / giorno" uncomfortable, each associated with a coin symbol. Use simple dark humanist sans serif for functional labels, not handwritten. A short instruction "Tocca la camera per accogliere" below. A separate outlined secondary button with an X and exact label "Rifiuta" aligned at the right or lower right; no fake "Accogli" button because arrival happens by tapping the selected room. Below this panel, a small "In fila" strip with just two compact upcoming portraits: snake and dormouse, and their width / cozy need symbols. Do not state whether they arrive today or tomorrow.
Typographic hierarchy: title in a friendly restrained serif, all functional labels in a substantial clean rounded sans, generous readable sizes and spacing, no tiny microcopy. Maintain dark ink and quiet light surfaces. Action handles clear through shape, not just color.
Constraints: ONE convincing production-quality illustrated game screenshot with high art quality and disciplined mobile interaction design. Preserve 6x8 playable grid concept, realistic amount of interface, room reshaping emphasis, five existing species only (giraffe waiting, snake, bat, plant, dormouse). Exact short Italian labels above, no gibberish. No navigation tabs for unimplemented sections, no shop, no task card, no progress stars, no costs for dragging, no extra invented species, no staircases, no decorative skyline competing with gameplay, no luminous neon outline, no heavy paper noise, no excessive trim.
```

## Rifinitura selezionata

Immagine in ingresso: risultato della generazione iniziale, non l'immagine storica del concept. La prima variante non è inclusa nei file del progetto.

```text
Use case: precise-object-edit / ui-mockup.
Refine this exact Folding Rooms main gameplay screen, preserving the lovely illustrated hotel style, palette, room arrangement, animals, main giraffe panel, tactile cream UI and readable text. Keep all correct Italian wording and numbers. This is an interface proposal for a phone.
Required changes:
1. Output an actual taller 9:16 portrait image, ideally 1152 pixels wide by 2048 pixels high. Do not simply squeeze or stretch the existing artwork. Recompose and extend vertically so the central board is EXACTLY 6 columns by 8 rows of SQUARE cells, with the header and bottom panels remaining compact. The central grid must have width:height = 6:8 = 3:4, not a nearly square board. Selected mint room occupies 2 columns by 3 rows. Keep all room boundaries aligned to the equal square cell grid. Keep the top empty two rows to the left, dormouse 2x2 and bat 2x2 at the top, plant 2x2 below dormouse, snake 4x1 below plant and empty space at bottom. Keep clean white-ivory double arrow handles. The vacant grid should be faint, not dark. Reserve some empty top and bottom safe margins.
2. Correct the bottom queue. Keep exact heading "In fila". Under snake portrait use exact label "Serpente" with horizontal double-headed arrow and "4 × 1". Under dormouse portrait use exact label "Ghiro" with small cozy-room rectangle icon and "2 × 2". Remove the sun/lamp icon beside the snake and the moon icon beside the dormouse: these animals require normal lighting. Do NOT invent additional guest needs.
3. Make the lower card and queue fit comfortably within screen edges; all labels readable, ample touch space for "Rifiuta" and the two lighting buttons. Keep "Giraffa", "Sta bene in 2 × 3 celle", "2 giorni", happy "10 / giorno", uncomfortable "4 / giorno", and "Tocca la camera per accogliere".
4. Keep side foliage sparse and outside editable board. Preserve enough breathing room so this feels like a playable cozy indie game, not a decorative poster.
Do not add any new features, tabs, species, words, or visual indicators. No device frame. The actual file must have a tall 9:16 aspect ratio.
```


## Adattamento intermedio alle proporzioni iPhone

Richiesta intermedia, poi superata dalla scelta esplicita di Riccardo di usare 9:16. Immagine in ingresso: rifinitura precedente.

```text
Edit the attached illustration by CHANGING THE CANVAS ASPECT RATIO. This is the single most important requirement.
The final image is a FULL SCREEN IPHONE PORTRAIT game interface, width 1179 pixels, height 2556 pixels, width:height approximately 9:19.5. This is a very tall and narrow image. It MUST NOT be 3:4 or 2:3. No phone body or frame. Make the actual output canvas 1179x2556.
Keep the same Folding Rooms cozy Mediterranean storybook artwork and Italian labels. Recompose the image into that tall narrow canvas, do not stretch existing characters or controls. Header occupies top 13%, hotel play board middle 61%, bottom light controls and guest panels bottom 22%, with clear safe margins of 3% at the very top and bottom for the iPhone camera island and gesture area.
Make the hotel editing board SIX columns by EIGHT rows of SQUARE cells, centered, with slender architecture. Board occupies about 86% of screen width. Keep the five rooms: dormouse top middle, bat top right, plant middle, selected empty mint room 2x3 on left with four large white arrow handles, long snake room 4x1. Keep the ghost extension above the mint room. Empty cells subtle.
Compact top UI: "Folding Rooms", coin "126", "Giorno 8", "2 arrivi", "Costruisci" with coin "90", small reset icon. Five existing rooms justify next price 90.
Bottom cream controls: "Camera normale", moon with coin "10", special lamp with coin "10". Main giraffe card: giraffe portrait and "Giraffa", "Sta bene in 2 × 3 celle", "2 giorni", happy icon "10 / giorno", sad icon "4 / giorno", "Tocca la camera per accogliere", outlined "Rifiuta". Wrap these into more rows as needed for narrow phone width. Lowest compact queue: "In fila", snake portrait "Serpente" and "4 × 1", dormouse portrait "Ghiro" and "2 × 2"; no lighting symbols in queue.
Extend and rearrange whitespace and foliage to suit tall iPhone proportions. Preserve all text spelling, warm ivory/terracotta/mint/deep teal palette, and charming animal designs. Prioritize a REAL TALL IPHONE CANVAS over ornamental detail. Output 1179 wide by 2556 tall.
```

## Formato finale scelto dall'utente: 9:16

Immagine in ingresso: risultato dell'adattamento intermedio, ri-allegato da Riccardo alla richiesta di formato 9:16.

```text
Imposta il rapporto d'aspetto dell'immagine allegata su 9:16 verticale, con una tela di 1152×2048 pixel. Allarga la composizione ai lati e adatta la spaziatura senza deformare personaggi, testi o pulsanti e senza tagliare alcuna parte dell'interfaccia. Mantieni esattamente lo stesso stile grafico, gli stessi elementi, i colori, i testi italiani e le illustrazioni. Nessuna cornice di telefono. Il file finale deve avere larghezza:altezza esattamente 9:16.
```

## Esportazione verificata

L'ultima immagine generata misura 941×1672 pixel, con un piccolo arrotondamento del rapporto. Esportazione tecnica con `sips -z 2048 1152`, dopo la ricomposizione con image_gen: file finale `immagini/folding_rooms_main_ui_style_v1.png`, 1152×2048 pixel. Verificato con `sips -g pixelWidth -g pixelHeight`; 1152×16 = 2048×9. Nessun ritaglio dell'interfaccia. Il formato finale scelto è 9:16, non le proporzioni native dell'iPhone 15.

La griglia illustrata rimane approssimativa. Il file serve come riferimento artistico; non è una texture da stendere sul gioco. Proporzioni delle celle, aree sensibili e comportamento sono descritti in `docs/STILE.md`.


