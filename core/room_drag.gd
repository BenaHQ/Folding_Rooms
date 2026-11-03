class_name RoomDrag
extends RefCounted
## Un singolo trascinamento di un lato di una camera, dal tocco al rilascio.
##
## COSA FA: traduce i pixel percorsi dal dito in due risultati distinti. Il primo è
## una modifica a celle intere, controllata da Grid. Il secondo è la posizione
## morbida in pixel in cui disegnare il lato, che segue il dito e fa resistenza
## quando non c'è più spazio.
## CHI LA USA: la scena RoomEditor, che ne crea una a ogni trascinamento.
## PERCHÉ È SEPARATA: non usa nodi né disegno, quindi i test automatici possono
## provare il gesto senza avviare il gioco. Non decide le regole: le chiede a Grid.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena e
## che Godot elimina da solo quando nessuno lo usa più.
## COORDINATE: i pixel sono quelli dell'area di gioco di riferimento (720×1280). X
## cresce verso destra e Y verso il basso, quindi trascinare in su è negativo.

## Di quanti pixel al massimo il lato può superare l'ultima posizione permessa. È la
## resistenza che fa capire al giocatore che lì non c'è più spazio.
const MAX_RESISTANCE_PIXELS: float = 40.0

## Il risultato previsto, aggiornato a ogni movimento del dito: celle e motivo di un
## eventuale rifiuto.
var preview: ResizePreview
## Di quanti pixel va disegnato spostato il lato, con la resistenza già applicata.
## Positivo verso destra o verso il basso.
var offset_pixels: float = 0.0
## Il lato che si sta trascinando.
var side: Room.MovableSide

## La griglia che decide se la modifica è permessa.
var _grid: Grid
## La camera che si sta modificando.
var _room: Room
## Lato di una cella, in pixel.
var _cell_size_pixels: float
## Lo spostamento in celle che il dito sta chiedendo in questo momento.
var _attempted_offset_cells: int = 0
## Ultimo spostamento permesso verso sinistra o verso l'alto, in celle (zero o meno).
var _lowest_valid_offset_cells: int
## Ultimo spostamento permesso verso destra o verso il basso, in celle (zero o più).
var _highest_valid_offset_cells: int


## Prepara il trascinamento di un lato della camera. _init() è la funzione che Godot
## chiama automaticamente con RoomDrag.new(). cell_size_pixels è il lato di una cella.
func _init(grid: Grid, room: Room, dragged_side: Room.MovableSide, cell_size_pixels: float) -> void:
	_grid = grid
	_room = room
	side = dragged_side
	_cell_size_pixels = cell_size_pixels

	# Il contenuto della griglia non cambia durante un trascinamento, quindi basta
	# calcolare i due limiti una volta sola.
	_lowest_valid_offset_cells = _find_last_valid_offset(-1)
	_highest_valid_offset_cells = _find_last_valid_offset(1)

	# Finché il dito non si muove, l'anteprima descrive la camera così com'è.
	preview = _grid.preview_resize(_room, side, 0)


## Sceglie quale lato muove un gesto iniziato dentro la camera (decisione D-012). La
## direzione del dito dà l'asse: se si muove più in orizzontale conta una parete,
## altrimenti soffitto o pavimento. Il punto toccato dà il lato: quello della metà di
## camera in cui si trova. Così, per esempio, dalla metà alta si sposta sempre il
## soffitto: in su la camera cresce, in giù si rimpicciolisce. Il centro esatto vale
## come metà destra e metà bassa. Tutti i parametri sono in pixel e nello stesso sistema
## di riferimento. «static» significa che si chiama sulla classe, senza crearne un oggetto.
static func choose_side(press_position: Vector2, movement: Vector2, room_center: Vector2) -> Room.MovableSide:
	if absf(movement.x) > absf(movement.y):
		return Room.MovableSide.LEFT_WALL if press_position.x < room_center.x else Room.MovableSide.RIGHT_WALL

	return Room.MovableSide.CEILING if press_position.y < room_center.y else Room.MovableSide.FLOOR


## Aggiorna il trascinamento. pointer_offset è di quanti pixel si è spostato il dito
## rispetto al punto in cui ha toccato lo schermo. Non modifica la camera.
func update(pointer_offset: Vector2) -> void:
	# Le pareti si muovono solo in orizzontale, soffitto e pavimento solo in verticale.
	var distance_pixels: float = pointer_offset.y
	if side == Room.MovableSide.LEFT_WALL or side == Room.MovableSide.RIGHT_WALL:
		distance_pixels = pointer_offset.x

	# La regola scatta a metà cella: roundi() arrotonda all'intero più vicino.
	_attempted_offset_cells = roundi(distance_pixels / _cell_size_pixels)
	preview = _grid.preview_resize(_room, side, _attempted_offset_cells)

	offset_pixels = _apply_resistance(distance_pixels)


## Conclude il trascinamento: applica la modifica se è permessa, altrimenti la camera
## resta com'era. Restituisce l'anteprima usata per decidere.
func commit() -> ResizePreview:
	return _grid.resize_room(_room, side, _attempted_offset_cells)


## Restituisce il rettangolo in pixel in cui disegnare la camera ora, misurato
## dall'angolo in alto a sinistra dell'involucro.
func get_visual_rect() -> Rect2:
	var rect: Rect2 = Rect2(Vector2(_room.cells.position), Vector2(_room.cells.size))
	rect.position *= _cell_size_pixels
	rect.size *= _cell_size_pixels

	# Stessa logica di Room.cells_after_moving(), ma con i pixel invece delle celle:
	# sinistra e soffitto spostano anche l'angolo in alto a sinistra.
	match side:
		Room.MovableSide.LEFT_WALL:
			rect.position.x += offset_pixels
			rect.size.x -= offset_pixels
		Room.MovableSide.RIGHT_WALL:
			rect.size.x += offset_pixels
		Room.MovableSide.CEILING:
			rect.position.y += offset_pixels
			rect.size.y -= offset_pixels
		Room.MovableSide.FLOOR:
			rect.size.y += offset_pixels

	return rect


## Cerca, una cella alla volta, l'ultimo spostamento permesso in una direzione.
## direction vale -1 (sinistra o alto) oppure 1 (destra o basso). Il ciclo finisce
## sempre, perché prima o poi il lato raggiunge il bordo dell'involucro o il lato opposto.
func _find_last_valid_offset(direction: int) -> int:
	var offset_cells: int = 0

	while _grid.preview_resize(_room, side, offset_cells + direction).is_valid():
		offset_cells += direction

	return offset_cells


## Restituisce dove disegnare il lato, in pixel, dato quanto si è spostato il dito.
## Entro i limiti il lato segue esattamente il dito; oltre, si muove sempre meno.
func _apply_resistance(distance_pixels: float) -> float:
	var limit_cells: int = _highest_valid_offset_cells if distance_pixels > 0.0 else _lowest_valid_offset_cells
	var limit_pixels: float = absf(limit_cells * _cell_size_pixels)
	var excess_pixels: float = absf(distance_pixels) - limit_pixels

	if excess_pixels <= 0.0:
		return distance_pixels

	# Formula: e × M / (e + M), con e = pixel oltre il limite e M = resistenza massima.
	# Per e piccolo il risultato è quasi e; per e molto grande si avvicina a M senza
	# superarlo, come un elastico che si tende sempre di più.
	var resisted_pixels: float = excess_pixels * MAX_RESISTANCE_PIXELS / (excess_pixels + MAX_RESISTANCE_PIXELS)
	return signf(distance_pixels) * (limit_pixels + resisted_pixels)
