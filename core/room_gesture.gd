class_name RoomGesture
extends RefCounted
## Ciò che hanno in comune i due gesti su una camera: allargarla da una maniglia e spostarla intera.
##
## COSA FA: conserva il risultato previsto e calcola la resistenza oltre i limiti. Le funzioni vuote
## vengono riempite da RoomDrag e RoomMove, ognuna a modo suo.
## CHI LA USA: la scena RoomEditor, che così tratta i due gesti allo stesso modo.
## PERCHÉ È SEPARATA: senza una base comune la scena dovrebbe ripetere ogni controllo due volte. Non
## usa nodi né disegno, e non decide le regole: le chiede a Grid.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena. Una classe che
## scrive «extends RoomGesture» eredita variabili e funzioni di questa e può sostituirne alcune.
## COORDINATE: i pixel sono quelli dell'area di gioco di riferimento (720×1280), misurati
## dall'angolo in alto a sinistra dell'involucro. X cresce verso destra e Y verso il basso.

## Di quanti pixel al massimo il disegno può superare l'ultima posizione permessa. È la resistenza
## che fa capire al giocatore che lì non c'è più spazio.
const MAX_RESISTANCE_PIXELS: float = 40.0

## Il risultato previsto, aggiornato a ogni movimento del dito: celle e motivo di un eventuale
## rifiuto.
var preview: ResizePreview

## La griglia che decide se la modifica è permessa.
var _grid: Grid
## La camera su cui si sta agendo.
var _room: Room
## Lato di una cella, in pixel.
var _cell_size_pixels: float


## Prepara il gesto. _init() è la funzione che Godot chiama con .new(). cell_size_pixels è il lato
## di una cella.
func _init(grid: Grid, room: Room, cell_size_pixels: float) -> void:
	_grid = grid
	_room = room
	_cell_size_pixels = cell_size_pixels


## Aggiorna il gesto. pointer_offset è di quanti pixel si è spostato il dito rispetto al punto in cui
## ha toccato lo schermo. Non modifica la camera. La riempiono le classi figlie.
func update(_pointer_offset: Vector2) -> void:
	pass


## Conclude il gesto: applica la modifica se è permessa, altrimenti tutto resta com'era. Restituisce
## l'anteprima usata per decidere. La riempiono le classi figlie.
func commit() -> ResizePreview:
	return preview


## Restituisce il rettangolo in pixel in cui disegnare ora la camera. La riempiono le classi figlie.
func get_visual_rect() -> Rect2:
	return _cells_to_pixels(_room.cells)


## Restituisce il rettangolo in pixel in cui disegnare ora un'altra camera. Di base resta ferma.
func get_neighbor_visual_rect(other_room: Room) -> Rect2:
	return _cells_to_pixels(other_room.cells)


## Converte un rettangolo di celle in pixel, misurati dall'angolo dell'involucro.
func _cells_to_pixels(cells: Rect2i) -> Rect2:
	return Rect2(Vector2(cells.position) * _cell_size_pixels, Vector2(cells.size) * _cell_size_pixels)


## Restituisce di quanti pixel spostare il disegno, dato quanto si è spostato il dito lungo un asse.
## lowest_cells e highest_cells sono gli ultimi spostamenti permessi nei due versi, in celle: entro
## i limiti il disegno segue esattamente il dito; oltre, si muove sempre meno.
func _apply_resistance(distance_pixels: float, lowest_cells: int, highest_cells: int) -> float:
	var limit_cells: int = highest_cells if distance_pixels > 0.0 else lowest_cells
	var limit_pixels: float = absf(limit_cells * _cell_size_pixels)
	var excess_pixels: float = absf(distance_pixels) - limit_pixels

	if excess_pixels <= 0.0:
		return distance_pixels

	# Formula: e × M / (e + M), con e = pixel oltre il limite e M = resistenza massima.
	# Per e piccolo il risultato è quasi e; per e molto grande si avvicina a M senza
	# superarlo, come un elastico che si tende sempre di più.
	var resisted_pixels: float = excess_pixels * MAX_RESISTANCE_PIXELS / (excess_pixels + MAX_RESISTANCE_PIXELS)
	return signf(distance_pixels) * (limit_pixels + resisted_pixels)
