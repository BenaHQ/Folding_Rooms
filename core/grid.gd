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
## SPINTA TRA CAMERE (decisioni D-021 e D-022): una parete che incontra una camera vicina la
## restringe; quando rientra, invece, la vicina resta ferma e si crea spazio libero. Le camere
## restano rettangolari: se la parete non copre tutto il lato dell'altra camera, spingere è
## rifiutato. Una camera non viene mai cancellata e la spinta non passa a quella dietro.

## SPOSTAMENTO (decisione D-030): una camera intera si sposta solo in uno spazio libero. Non spinge
## nessuno e conta solo dove arriva, quindi può passare sopra le altre mentre è sollevata dal dito.

## OSPITI (decisione D-019): un ospite entra solo se la camera ha la misura per entrare. Una
## modifica che lascerebbe fuori un ospite già presente è rifiutata: non viene mai scacciato.

## SERVIZI COMUNI (decisione D-036): la piscina è un rettangolo come le camere. Si deforma, si sposta e
## spinge con le stesse regole, ma non accoglie ospiti.

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
	if _find_shape_rejection(room.cells) != ResizePreview.Rejection.NONE:
		return false

	# Qui non esiste una parete che si sposta: qualsiasi sovrapposizione è un errore.
	for other_room: Room in _rooms:
		# intersects() è vero solo se i rettangoli condividono almeno una cella: due
		# camere che si toccano lungo una parete non si sovrappongono.
		if other_room.cells.intersects(room.cells):
			return false

	_rooms.append(room)
	return true


## Calcola il risultato dello spostamento di un lato, senza modificare nulla. Serve
## a mostrare l'anteprima mentre il dito si muove. offset_cells è in celle: positivo
## verso destra o verso il basso, negativo verso sinistra o verso l'alto. Restituisce
## le celle previste, le camere vicine coinvolte e il motivo di un eventuale rifiuto.
func preview_resize(room: Room, side: Room.MovableSide, offset_cells: int) -> ResizePreview:
	var new_cells: Rect2i = room.cells_after_moving(side, offset_cells)
	var rejection: ResizePreview.Rejection = _find_shape_rejection(new_cells)

	if rejection != ResizePreview.Rejection.NONE:
		return ResizePreview.new(new_cells, rejection)

	if not _guest_would_fit(room, new_cells):
		return ResizePreview.new(new_cells, ResizePreview.Rejection.GUEST_WOULD_NOT_FIT)

	return _preview_with_neighbors(room, side, new_cells)


## Sposta un lato della camera, se la modifica è permessa, insieme alle camere vicine
## coinvolte; altrimenti non cambia nulla. Parametri come preview_resize(). Restituisce
## l'anteprima usata per decidere, così chi chiama sa se è andata a buon fine.
func resize_room(room: Room, side: Room.MovableSide, offset_cells: int) -> ResizePreview:
	var preview: ResizePreview = preview_resize(room, side, offset_cells)

	if preview.is_valid():
		room.cells = preview.resulting_cells
		for change: RoomChange in preview.neighbor_changes:
			change.room.cells = change.resulting_cells

	return preview


## Calcola il risultato dello spostamento di una camera intera, senza modificare nulla. offset_cells
## è in celle: X positiva verso destra, Y positiva verso il basso. La forma non cambia, quindi non
## serve controllare l'ospite. Restituisce le celle previste e il motivo di un eventuale rifiuto.
func preview_move(room: Room, offset_cells: Vector2i) -> ResizePreview:
	var new_cells: Rect2i = Rect2i(room.cells.position + offset_cells, room.cells.size)
	var rejection: ResizePreview.Rejection = _find_shape_rejection(new_cells)

	if rejection != ResizePreview.Rejection.NONE:
		return ResizePreview.new(new_cells, rejection)

	for other_room: Room in _rooms:
		if other_room != room and other_room.cells.intersects(new_cells):
			return ResizePreview.new(new_cells, ResizePreview.Rejection.OVERLAPS_ROOM, [], other_room)

	return ResizePreview.new(new_cells, ResizePreview.Rejection.NONE)


## Sposta una camera intera, con il suo ospite, se è permesso; altrimenti non cambia nulla.
## Restituisce l'anteprima usata per decidere.
func move_room(room: Room, offset_cells: Vector2i) -> ResizePreview:
	var preview: ResizePreview = preview_move(room, offset_cells)

	if preview.is_valid():
		room.cells = preview.resulting_cells

	return preview


## Fa entrare un ospite in una camera libera e non in lavori, se ci può entrare. La luce non conta: un
## ospite con la luce sbagliata entra, ma non sta bene (D-032). Un servizio comune non ospita nessuno.
## Restituisce true se è entrato.
func assign_guest(guest: Guest, room: Room) -> bool:
	if room.is_facility() or room.guest != null or room.is_under_works or guest.need.evaluate(room.cells.size) == Need.Fit.DOES_NOT_FIT:
		return false

	room.guest = guest
	room.turns_left = guest.stay_turns
	return true


## Fa uscire l'ospite da una camera. Se è già libera non succede nulla.
func remove_guest(room: Room) -> void:
	room.guest = null
	room.turns_left = 0


## Restituisce le camere della griglia. L'elenco va solo letto: si aggiunge con add_room().
func get_rooms() -> Array[Room]:
	return _rooms


## Restituisce solo le camere che possono ospitare, cioè tutte tranne i servizi comuni. È un elenco
## nuovo a ogni chiamata.
func get_guest_rooms() -> Array[Room]:
	var guest_rooms: Array[Room] = []
	for room: Room in _rooms:
		if not room.is_facility():
			guest_rooms.append(room)

	return guest_rooms


## Restituisce la piscina dell'hotel, oppure null se non è ancora stata costruita.
func get_pool() -> Room:
	for room: Room in _rooms:
		if room.facility == Room.Facility.POOL:
			return room

	return null


## Restituisce tutte le celle dell'involucro, come rettangolo in celle.
func get_envelope_cells() -> Rect2i:
	return _envelope.get_cells()


## Restituisce le celle dell'involucro non occupate da nessuna camera, riga per riga.
func get_free_cells() -> Array[Vector2i]:
	var envelope_cells: Rect2i = _envelope.get_cells()
	var free_cells: Array[Vector2i] = []

	for y: int in range(envelope_cells.position.y, envelope_cells.end.y):
		for x: int in range(envelope_cells.position.x, envelope_cells.end.x):
			if _find_room_on_cell(Vector2i(x, y)) == null:
				free_cells.append(Vector2i(x, y))

	return free_cells


## Restituisce la camera che occupa una cella, oppure null se la cella è libera.
func _find_room_on_cell(cell: Vector2i) -> Room:
	for room: Room in _rooms:
		if room.cells.has_point(cell):
			return room

	return null


## Restituisce true se l'ospite della camera, se c'è, entrerebbe ancora in cells.
func _guest_would_fit(room: Room, cells: Rect2i) -> bool:
	return room.guest == null or room.guest.need.evaluate(cells.size) != Need.Fit.DOES_NOT_FIT


## Controlla la forma di un rettangolo di celle, senza guardare le altre camere: restituisce
## il primo motivo di rifiuto, oppure Rejection.NONE.
func _find_shape_rejection(cells: Rect2i) -> ResizePreview.Rejection:
	# Controlla prima le misure: con misure zero o negative il rettangolo non
	# descrive una forma vera, e il controllo seguente non avrebbe senso.
	if not Room.has_allowed_size(cells):
		return ResizePreview.Rejection.TOO_SMALL

	if not _envelope.contains(cells):
		return ResizePreview.Rejection.OUTSIDE_ENVELOPE

	return ResizePreview.Rejection.NONE


## Applica la regola della spinta a una forma già valida per sé stessa, e restituisce
## l'anteprima completa. new_cells è la forma prevista per room, in celle.
func _preview_with_neighbors(room: Room, side: Room.MovableSide, new_cells: Rect2i) -> ResizePreview:
	var facing_side: Room.MovableSide = Room.opposite_side(side)
	var new_wall: int = Room.side_coordinate(new_cells, side)
	var changes: Array[RoomChange] = []

	for other_room: Room in _rooms:
		# Solo una camera che la nuova forma invaderebbe è coinvolta. Tutte le altre, anche quelle
		# attaccate alla parete che rientra, restano ferme.
		if other_room == room or not other_room.cells.intersects(new_cells):
			continue

		# Spingere una camera più lunga la lascerebbe con una tacca, non più rettangolare.
		if not Room.side_span_covers(room.cells, side, other_room.cells):
			return ResizePreview.new(new_cells, ResizePreview.Rejection.OVERLAPS_ROOM, [], other_room)

		# La camera vicina porta il suo lato esattamente dove arriva la parete.
		var other_wall: int = Room.side_coordinate(other_room.cells, facing_side)
		var other_cells: Rect2i = other_room.cells_after_moving(facing_side, new_wall - other_wall)
		if not Room.has_allowed_size(other_cells):
			return ResizePreview.new(new_cells, ResizePreview.Rejection.NEIGHBOR_TOO_SMALL, [], other_room)

		if not _guest_would_fit(other_room, other_cells):
			return ResizePreview.new(new_cells, ResizePreview.Rejection.GUEST_WOULD_NOT_FIT, [], other_room)

		changes.append(RoomChange.new(other_room, other_cells))

	return ResizePreview.new(new_cells, ResizePreview.Rejection.NONE, changes)
