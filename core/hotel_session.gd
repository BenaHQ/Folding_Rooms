class_name HotelSession
extends RefCounted
## Una partita: la fila degli ospiti, i turni, le monete e la costruzione di nuove camere.
##
## COSA FA: applica il ciclo di gioco deciso con D-026. Ospitare o rifiutare l'ospite di turno
## conclude il turno: chi è in camera paga secondo come sta in quel momento, poi resta un turno in
## meno, e chi ha finito parte. Spostare le pareti è gratis e non consuma turni.
## CHI LA USA: la scena RoomEditor, che le passa le azioni del giocatore.
## PERCHÉ È SEPARATA: non usa nodi né disegno, quindi i test automatici possono provare un'intera
## partita. Non decide chi entra dove: lo chiede a Grid.
## NUOVE CAMERE (D-028): una camera nuova nasce da 1 cella e si allarga gratis con il gesto. Costa
## monete, sempre di più, e non consuma il turno. Il prezzo si ricava da quante camere esistono.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena.

## Quanti ospiti in fila si vedono oltre a quello di turno.
const VISIBLE_UPCOMING_GUESTS: int = 2
## Camere con cui inizia ogni partita: non si pagano e non fanno salire il prezzo.
const STARTING_ROOMS: int = 2
## Prezzo della prima camera costruita, in monete. Vale circa un soggiorno comodo della giraffa.
const FIRST_NEW_ROOM_PRICE: int = 30
## Di quante monete sale il prezzo per ogni camera già costruita.
const NEW_ROOM_PRICE_STEP: int = 20
## Misure di una camera appena costruita, in celle.
const NEW_ROOM_SIZE_CELLS: Vector2i = Vector2i.ONE
## Nomi dei campi nel salvataggio.
const COINS_KEY: String = "coins"
const TURNS_PLAYED_KEY: String = "turns_played"
const ROOMS_KEY: String = "rooms"
const QUEUE_KEY: String = "queue"
const ROOM_X_KEY: String = "x"
const ROOM_Y_KEY: String = "y"
const ROOM_WIDTH_KEY: String = "width"
const ROOM_HEIGHT_KEY: String = "height"
const GUEST_KEY: String = "guest"
const TURNS_LEFT_KEY: String = "turns_left"
## Valore di «numero non valido» durante la lettura: i numeri salvati non sono mai negativi.
const INVALID_COUNT: int = -1
## Il numero più grande che si accetta da un file: 2^53, l'ultimo che un numero con la virgola
## rappresenta ancora senza perdere precisione.
const MAX_SAVED_COUNT: float = 9007199254740992.0

## Le monete guadagnate finora.
var coins: int = 0
## I turni conclusi finora.
var turns_played: int = 0

## La griglia con camere e regole.
var _grid: Grid
## La fila degli ospiti in arrivo.
var _queue: GuestQueue


## Crea una partita sulla griglia indicata. _init() è la funzione che Godot chiama con .new().
func _init(grid: Grid, queue: GuestQueue) -> void:
	_grid = grid
	_queue = queue


## Restituisce l'ospite di turno.
func get_current_guest() -> Guest:
	return _queue.peek(1)[0]


## Restituisce gli ospiti visibili in fila dietro quello di turno.
func get_upcoming_guests() -> Array[Guest]:
	return _queue.peek(VISIBLE_UPCOMING_GUESTS + 1).slice(1)


## Prova a far entrare l'ospite di turno in una camera. Se riesce conclude il turno e ne restituisce
## il resoconto; se non può entrare restituisce null, e il turno continua.
func host_current_guest(room: Room) -> TurnReport:
	if not _grid.assign_guest(get_current_guest(), room):
		return null

	return _end_turn()


## Rifiuta l'ospite di turno: se ne va senza pagare e il turno si conclude (D-026).
func refuse_current_guest() -> TurnReport:
	return _end_turn()


## Restituisce il prezzo della prossima camera, in monete: FIRST_NEW_ROOM_PRICE per la prima, poi
## NEW_ROOM_PRICE_STEP in più per ogni camera già costruita. Non modifica nulla.
func get_new_room_price() -> int:
	# maxi() sceglie il maggiore: una griglia con meno camere iniziali non dà uno sconto.
	var built_rooms: int = maxi(_grid.get_rooms().size() - STARTING_ROOMS, 0)
	return FIRST_NEW_ROOM_PRICE + NEW_ROOM_PRICE_STEP * built_rooms


## Restituisce true se ora si può costruire: le monete bastano e c'è almeno una cella libera.
func can_build_room() -> bool:
	return coins >= get_new_room_price() and not _grid.get_free_cells().is_empty()


## Costruisce una camera nella cella indicata, in celle, e ne sottrae il prezzo. Il turno continua.
## Restituisce la camera, oppure null se le monete non bastano o la cella non è libera: in quel caso
## non cambia nulla.
func build_room(cell: Vector2i) -> Room:
	var price: int = get_new_room_price()
	if coins < price:
		return null

	var new_room: Room = Room.new(Rect2i(cell, NEW_ROOM_SIZE_CELLS))
	if not _grid.add_room(new_room):
		return null

	coins -= price
	return new_room


## Restituisce la griglia della partita, con le sue camere.
func get_grid() -> Grid:
	return _grid


## Restituisce lo stato della partita in valori semplici, adatti a un file di salvataggio. Non
## modifica nulla. Una modifica ancora in corso con il dito non è compresa: le camere cambiano solo
## al rilascio.
func to_data() -> Dictionary:
	var room_entries: Array[Dictionary] = []
	for room: Room in _grid.get_rooms():
		room_entries.append(_room_to_data(room))

	return {
		COINS_KEY: coins,
		TURNS_PLAYED_KEY: turns_played,
		ROOMS_KEY: room_entries,
		QUEUE_KEY: _queue.to_data(),
	}


## Ricrea una partita dai valori di to_data(), ripassando dalle regole di Grid: un file modificato
## o danneggiato non può creare camere sovrapposte o ospiti che non entrano. species elenca gli
## ospiti possibili. Restituisce null se qualcosa non è valido.
static func from_data(data: Dictionary, species: Array[Guest]) -> HotelSession:
	var room_entries: Variant = data.get(ROOMS_KEY)
	var queue_data: Variant = data.get(QUEUE_KEY)
	# Una partita ha sempre almeno una camera: la scena conta su questo per scegliere quella attiva.
	if not room_entries is Array or (room_entries as Array).is_empty() or not queue_data is Dictionary:
		return null

	var grid: Grid = Grid.new(Envelope.new())
	for entry: Variant in room_entries:
		if not entry is Dictionary or not _add_room_from_data(grid, entry, species):
			return null

	var queue: GuestQueue = GuestQueue.from_data(queue_data, species)
	var saved_coins: int = _read_count(data, COINS_KEY)
	var saved_turns: int = _read_count(data, TURNS_PLAYED_KEY)
	if queue == null or saved_coins == INVALID_COUNT or saved_turns == INVALID_COUNT:
		return null

	var session: HotelSession = HotelSession.new(grid, queue)
	session.coins = saved_coins
	session.turns_played = saved_turns
	return session


## Restituisce una camera in valori semplici. Una camera libera non ha il campo dell'ospite.
func _room_to_data(room: Room) -> Dictionary:
	var entry: Dictionary = {
		ROOM_X_KEY: room.cells.position.x,
		ROOM_Y_KEY: room.cells.position.y,
		ROOM_WIDTH_KEY: room.cells.size.x,
		ROOM_HEIGHT_KEY: room.cells.size.y,
	}

	if room.guest != null:
		entry[GUEST_KEY] = room.guest.id
		entry[TURNS_LEFT_KEY] = room.turns_left

	return entry


## Aggiunge alla griglia la camera descritta da entry, con il suo eventuale ospite. Restituisce
## false se i valori non sono validi o se Grid rifiuta la camera o l'ospite.
static func _add_room_from_data(grid: Grid, entry: Dictionary, species: Array[Guest]) -> bool:
	var x: int = _read_count(entry, ROOM_X_KEY)
	var y: int = _read_count(entry, ROOM_Y_KEY)
	var width: int = _read_count(entry, ROOM_WIDTH_KEY)
	var height: int = _read_count(entry, ROOM_HEIGHT_KEY)
	if INVALID_COUNT in [x, y, width, height]:
		return false

	var room: Room = Room.new(Rect2i(x, y, width, height))
	if not grid.add_room(room):
		return false

	# Una camera senza il campo dell'ospite è semplicemente libera.
	if not entry.has(GUEST_KEY):
		return true

	var guest: Guest = GuestQueue.find_guest(species, entry[GUEST_KEY])
	var turns_left: int = _read_count(entry, TURNS_LEFT_KEY)
	# Un ospite senza turni rimasti sarebbe già partito: un salvataggio valido non lo contiene.
	if guest == null or turns_left < 1 or not grid.assign_guest(guest, room):
		return false

	room.turns_left = turns_left
	return true


## Legge da un Dictionary un numero intero non negativo, oppure INVALID_COUNT se manca o non è
## valido. Il file può contenere qualsiasi cosa: JSON dà ogni numero come float, quindi si controlla
## che sia intero e abbastanza piccolo da restare preciso.
static func _read_count(data: Dictionary, key: String) -> int:
	var value: Variant = data.get(key)
	if not value is float or value < 0.0 or value > MAX_SAVED_COUNT or value != floorf(value):
		return INVALID_COUNT

	return int(value)


## Conclude il turno: incassa, fa passare il tempo, fa partire chi ha finito e fa avanzare la fila.
func _end_turn() -> TurnReport:
	var report: TurnReport = TurnReport.new()

	for room: Room in _grid.get_rooms():
		if room.guest == null:
			continue

		# Il compenso dipende da come sta ora: allargare una camera conviene anche dopo (D-026).
		var fit: Need.Fit = room.guest.need.evaluate(room.cells.size)
		var amount: int = room.guest.get_pay(fit)
		report.earnings[room] = amount
		coins += amount

		room.turns_left -= 1
		if room.turns_left <= 0:
			_grid.remove_guest(room)
			report.departed_rooms.append(room)

	turns_played += 1
	_queue.advance()
	return report
