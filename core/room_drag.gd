class_name RoomDrag
extends RoomGesture
## Un singolo trascinamento di un lato di una camera, dal tocco al rilascio.
##
## COSA FA: traduce i pixel percorsi dal dito in due risultati distinti. Il primo è
## una modifica a celle intere, controllata da Grid. Il secondo è la posizione
## morbida in pixel in cui disegnare il lato, che segue il dito e fa resistenza
## quando non c'è più spazio.
## CHI LA USA: la scena RoomEditor, che ne crea una a ogni trascinamento.
## PERCHÉ È SEPARATA: non usa nodi né disegno, quindi i test automatici possono
## provare il gesto senza avviare il gioco. Non decide le regole: le chiede a Grid.
## NOTA GDSCRIPT: «extends RoomGesture» eredita da quella classe la griglia, l'anteprima e la
## resistenza. super() chiama la funzione con lo stesso nome nella classe da cui si eredita.
## COORDINATE: i pixel sono quelli dell'area di gioco di riferimento (720×1280). X
## cresce verso destra e Y verso il basso, quindi trascinare in su è negativo.

## Di quanti pixel va disegnato spostato il lato, con la resistenza già applicata.
## Positivo verso destra o verso il basso.
var offset_pixels: float = 0.0
## Il lato che si sta trascinando.
var side: Room.MovableSide

## Lo spostamento in celle che il dito sta chiedendo in questo momento.
var _attempted_offset_cells: int = 0
## Ultimo spostamento permesso verso sinistra o verso l'alto, in celle (zero o meno).
var _lowest_valid_offset_cells: int
## Ultimo spostamento permesso verso destra o verso il basso, in celle (zero o più).
var _highest_valid_offset_cells: int


## Prepara il trascinamento di un lato della camera. _init() è la funzione che Godot
## chiama automaticamente con RoomDrag.new(). cell_size_pixels è il lato di una cella.
func _init(grid: Grid, room: Room, dragged_side: Room.MovableSide, cell_size_pixels: float) -> void:
	super(grid, room, cell_size_pixels)
	side = dragged_side

	# Il contenuto della griglia non cambia durante un trascinamento, quindi basta
	# calcolare i due limiti una volta sola.
	_lowest_valid_offset_cells = _find_last_valid_offset(-1)
	_highest_valid_offset_cells = _find_last_valid_offset(1)

	# Finché il dito non si muove, l'anteprima descrive la camera così com'è.
	preview = _grid.preview_resize(_room, side, 0)


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

	offset_pixels = _apply_resistance(distance_pixels, _lowest_valid_offset_cells, _highest_valid_offset_cells)


## Conclude il trascinamento: applica la modifica se è permessa, anche alle camere vicine,
## altrimenti tutto resta com'era. Restituisce l'anteprima usata per decidere.
func commit() -> ResizePreview:
	return _grid.resize_room(_room, side, _attempted_offset_cells)


## Restituisce il rettangolo in pixel in cui disegnare la camera ora, misurato
## dall'angolo in alto a sinistra dell'involucro.
func get_visual_rect() -> Rect2:
	return _move_rect_side(_cells_to_pixels(_room.cells), side, offset_pixels)


## Restituisce il rettangolo in pixel in cui disegnare un'altra camera ora. Il suo lato segue la
## parete trascinata solo da quando la parete lo raggiunge e lo spinge: così le due modifiche si
## vedono insieme e il muro resta unico. Non decide nulla: è solo il disegno.
func get_neighbor_visual_rect(other_room: Room) -> Rect2:
	var other_rect: Rect2 = _cells_to_pixels(other_room.cells)

	# Se non può coprirne tutto il lato, la parete non sposta mai quella camera.
	if not Room.side_span_covers(_room.cells, side, other_room.cells):
		return other_rect

	var facing_side: Room.MovableSide = Room.opposite_side(side)
	var wall_cells: int = Room.side_coordinate(_room.cells, side)
	var other_wall_cells: int = Room.side_coordinate(other_room.cells, facing_side)

	# Il verso in cui il lato si allontana dalla camera: +1 verso destra o il basso, -1 verso
	# sinistra o l'alto. Una distanza moltiplicata per questo verso è positiva «davanti».
	var outward: int = 1 if side == Room.MovableSide.RIGHT_WALL or side == Room.MovableSide.FLOOR else -1
	if (other_wall_cells - wall_cells) * outward < 0:
		# Quella camera sta dietro la parete: non c'entra.
		return other_rect

	var gap_to_wall_pixels: float = (other_wall_cells * _cell_size_pixels) - (wall_cells * _cell_size_pixels + offset_pixels)
	if gap_to_wall_pixels * outward >= 0.0:
		# La parete non l'ha ancora raggiunta, oppure si sta allontanando.
		return other_rect

	return _move_rect_side(other_rect, facing_side, -gap_to_wall_pixels)


## Restituisce il rettangolo con un lato spostato di distance_pixels. Stessa logica di
## Room.cells_after_moving(), ma con i pixel: sinistra e soffitto spostano anche l'angolo in
## alto a sinistra. Positivo verso destra o verso il basso.
func _move_rect_side(rect: Rect2, moved_side: Room.MovableSide, distance_pixels: float) -> Rect2:
	match moved_side:
		Room.MovableSide.LEFT_WALL:
			rect.position.x += distance_pixels
			rect.size.x -= distance_pixels
		Room.MovableSide.RIGHT_WALL:
			rect.size.x += distance_pixels
		Room.MovableSide.CEILING:
			rect.position.y += distance_pixels
			rect.size.y -= distance_pixels
		Room.MovableSide.FLOOR:
			rect.size.y += distance_pixels

	return rect


## Cerca, una cella alla volta, l'ultimo spostamento permesso in una direzione.
## direction vale -1 (sinistra o alto) oppure 1 (destra o basso). Il ciclo finisce
## sempre, perché prima o poi il lato raggiunge il bordo dell'involucro o il lato opposto.
func _find_last_valid_offset(direction: int) -> int:
	var offset_cells: int = 0

	while _grid.preview_resize(_room, side, offset_cells + direction).is_valid():
		offset_cells += direction

	return offset_cells
