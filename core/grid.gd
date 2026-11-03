class_name Grid
extends RefCounted
## Griglia dell'hotel: l'involucro con le camere che contiene, e le regole.
##
## COSA FA: risponde alla domanda «questa modifica è permessa, e se no perché?» e
## applica soltanto le modifiche permesse.
## CHI LA USA: la scena dell'hotel, dalla fase 2 della scaletta, mentre il giocatore
## trascina una maniglia. L'animazione elastica non decide mai le regole: le decide
## questa classe.
## PERCHÉ È SEPARATA: non usa nodi né grafica, quindi i test automatici possono
## provare le regole senza avviare il gioco.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena e
## che Godot elimina da solo quando nessuno lo usa più.
## LIMITE ATTUALE: una camera vicina blocca sempre la modifica. La parete condivisa
## tra due camere arriverà nella fase 4 della scaletta.

## L'involucro dentro cui devono stare tutte le camere.
var _envelope: Envelope
## Le camere presenti nella griglia. Array[Room] è un elenco che accetta solo camere.
var _rooms: Array[Room] = []


## Crea una griglia vuota con l'involucro indicato. _init() è la funzione che Godot
## chiama automaticamente con Grid.new().
func _init(envelope: Envelope) -> void:
	_envelope = envelope


## Aggiunge una camera alla griglia, se la sua posizione rispetta le regole.
## Restituisce true se l'ha aggiunta, false se la camera non è valida: in quel caso
## la griglia non cambia.
func add_room(room: Room) -> bool:
	# La camera non è ancora nell'elenco, quindi non c'è nessuna camera da ignorare.
	if _find_rejection(room.cells, null) != ResizePreview.Rejection.NONE:
		return false

	_rooms.append(room)
	return true


## Calcola il risultato dello spostamento di un lato, senza modificare nulla. Serve
## a mostrare l'anteprima mentre il dito si muove. offset_cells è in celle: positivo
## verso destra o verso il basso, negativo verso sinistra o verso l'alto. Restituisce
## le celle previste e il motivo di un eventuale rifiuto.
func preview_resize(room: Room, side: Room.MovableSide, offset_cells: int) -> ResizePreview:
	var new_cells: Rect2i = room.cells_after_moving(side, offset_cells)
	return ResizePreview.new(new_cells, _find_rejection(new_cells, room))


## Sposta un lato della camera, se la modifica è permessa; altrimenti la camera resta
## com'era. Parametri come preview_resize(). Restituisce l'anteprima usata per
## decidere, così chi chiama sa se è andata a buon fine.
func resize_room(room: Room, side: Room.MovableSide, offset_cells: int) -> ResizePreview:
	var preview: ResizePreview = preview_resize(room, side, offset_cells)

	if preview.is_valid():
		room.cells = preview.resulting_cells

	return preview


## Controlla un rettangolo di celle e restituisce il primo motivo di rifiuto, oppure
## Rejection.NONE. room_to_ignore è la camera che si sta modificando: non deve contare
## come ostacolo per sé stessa. Può essere null se la camera non è ancora nella griglia.
func _find_rejection(cells: Rect2i, room_to_ignore: Room) -> ResizePreview.Rejection:
	# Controlla prima le misure: con misure zero o negative il rettangolo non
	# descrive una forma vera, e i controlli seguenti non avrebbero senso.
	if not Room.has_allowed_size(cells):
		return ResizePreview.Rejection.TOO_SMALL

	if not _envelope.contains(cells):
		return ResizePreview.Rejection.OUTSIDE_ENVELOPE

	for other_room: Room in _rooms:
		# intersects() è vero solo se i rettangoli condividono almeno una cella: due
		# camere che si toccano lungo una parete non si sovrappongono.
		if other_room != room_to_ignore and other_room.cells.intersects(cells):
			return ResizePreview.Rejection.OVERLAPS_ROOM

	return ResizePreview.Rejection.NONE
