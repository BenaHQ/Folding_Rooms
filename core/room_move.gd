class_name RoomMove
extends RoomGesture
## Un singolo spostamento di una camera intera, dal tocco al rilascio.
##
## COSA FA: traduce i pixel percorsi dal dito in due risultati distinti. Il primo è lo spostamento a
## celle intere, controllato da Grid. Il secondo è il punto morbido in cui disegnare la camera, che
## segue il dito e fa resistenza sui bordi dell'involucro (D-030).
## CHI LA USA: la scena RoomEditor, che ne crea una quando un dito trascina il centro della camera.
## PERCHÉ È SEPARATA: non usa nodi né disegno, quindi i test automatici possono provare il gesto senza
## avviare il gioco. Le altre camere non contano per il disegno: quella spostata passa sopra di loro.
## NOTA GDSCRIPT: «extends RoomGesture» eredita da quella classe. super() chiama la funzione con lo
## stesso nome nella classe da cui si eredita.
## COORDINATE: i pixel sono quelli dell'area di gioco di riferimento (720×1280). X cresce verso destra
## e Y verso il basso, quindi trascinare in su è negativo.

## Lo spostamento in celle che il dito sta chiedendo in questo momento.
var _attempted_offset_cells: Vector2i = Vector2i.ZERO
## Di quanti pixel va disegnata spostata la camera, con la resistenza già applicata.
var _offset_pixels: Vector2 = Vector2.ZERO


## Prepara lo spostamento. Finché il dito non si muove, l'anteprima descrive la camera così com'è.
func _init(grid: Grid, room: Room, cell_size_pixels: float) -> void:
	super(grid, room, cell_size_pixels)
	preview = _grid.preview_move(_room, Vector2i.ZERO)


## Aggiorna lo spostamento. pointer_offset è in pixel, dal punto in cui il dito ha toccato lo schermo.
func update(pointer_offset: Vector2) -> void:
	# La regola scatta a metà cella: round() arrotonda ogni asse all'intero più vicino.
	_attempted_offset_cells = Vector2i((pointer_offset / _cell_size_pixels).round())
	preview = _grid.preview_move(_room, _attempted_offset_cells)

	# I limiti sono la distanza dai bordi dell'involucro: per sinistra e alto sono zero o negativi.
	var envelope: Rect2i = _grid.get_envelope_cells()
	_offset_pixels = Vector2(
		_apply_resistance(pointer_offset.x, envelope.position.x - _room.cells.position.x, envelope.end.x - _room.cells.end.x),
		_apply_resistance(pointer_offset.y, envelope.position.y - _room.cells.position.y, envelope.end.y - _room.cells.end.y)
	)


## Conclude lo spostamento: lo applica se è permesso, altrimenti la camera resta dov'era.
func commit() -> ResizePreview:
	return _grid.move_room(_room, _attempted_offset_cells)


## Restituisce il rettangolo in pixel in cui disegnare ora la camera.
func get_visual_rect() -> Rect2:
	var rect: Rect2 = _cells_to_pixels(_room.cells)
	rect.position += _offset_pixels
	return rect
