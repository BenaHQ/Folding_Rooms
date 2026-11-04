class_name HotelSession
extends RefCounted
## Una partita: la fila degli ospiti, i turni, le monete e la costruzione di nuove camere.
##
## COSA FA: applica il ciclo di gioco deciso con D-026 e D-029. Un turno è una giornata: arrivano più
## ospiti, uno alla volta, e ognuno va ospitato o rifiutato. Quando sono finiti, la giornata si
## conclude: chi è in camera paga secondo come sta in quel momento, poi resta un turno in meno, e chi
## ha finito parte. Spostare le pareti è gratis e non consuma turni.
## CHI LA USA: la scena RoomEditor, che le passa le azioni del giocatore.
## PERCHÉ È SEPARATA: non usa nodi né disegno, quindi i test automatici possono provare un'intera
## partita. Non decide chi entra dove: lo chiede a Grid.
## NUOVE CAMERE (D-028): una camera nuova nasce da 1 cella e si allarga gratis con il gesto. Costa
## monete, sempre di più, e non consuma il turno. Il prezzo si ricava da quante camere esistono.
## LUCE (D-032): una camera normale si può rendere buia o dotare di lampade speciali, a pagamento. Per
## tornare normale si paga, oppure è gratis ma resta in lavori fino a fine giornata.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena.

## Le modifiche alla luce di una camera che il giocatore può scegliere.
enum LightingAction {
	MAKE_DARK, ## Toglie l'illuminazione: la camera diventa buia.
	MAKE_BRIGHT, ## Aggiunge le lampade speciali.
	RESTORE_PAID, ## Torna normale subito, pagando.
	RESTORE_WAIT, ## Torna normale gratis a fine giornata, e fino ad allora resta in lavori.
}

## Quanti ospiti in fila si vedono oltre a quello di turno.
const VISIBLE_UPCOMING_GUESTS: int = 2
## Ogni quante camere arriva un ospite in più al giorno: fino a 3 camere ne arriva 1, da 4 a 6 ne
## arrivano 2. Con permanenze di circa 2 turni, chi arriva trova quasi sempre posto (D-034).
const ROOMS_PER_DAILY_ARRIVAL: int = 3
## Camere con cui inizia ogni partita: non si pagano e non fanno salire il prezzo.
const STARTING_ROOMS: int = 2
## Prezzo della prima camera costruita, in monete. Vale circa un soggiorno comodo della giraffa.
const FIRST_NEW_ROOM_PRICE: int = 30
## Di quante monete sale il prezzo per ogni camera già costruita.
const NEW_ROOM_PRICE_STEP: int = 20
## Misure di una camera appena costruita, in celle.
const NEW_ROOM_SIZE_CELLS: Vector2i = Vector2i.ONE
## Prezzo per rendere speciale una camera normale, in monete.
const SPECIAL_ROOM_PRICE: int = 10
## Prezzo per far tornare subito normale una camera speciale, in monete.
const RESTORE_ROOM_PRICE: int = 20
## Da quante camere arrivano pipistrello e ospite vegetale (D-032).
const LATE_GUESTS_MIN_ROOMS: int = 4
## Nomi dei campi nel salvataggio.
const COINS_KEY: String = "coins"
const TURNS_PLAYED_KEY: String = "turns_played"
const ARRIVALS_LEFT_KEY: String = "arrivals_left"
const ROOMS_KEY: String = "rooms"
const QUEUE_KEY: String = "queue"
const ROOM_X_KEY: String = "x"
const ROOM_Y_KEY: String = "y"
const ROOM_WIDTH_KEY: String = "width"
const ROOM_HEIGHT_KEY: String = "height"
const GUEST_KEY: String = "guest"
const TURNS_LEFT_KEY: String = "turns_left"
const LIGHTING_KEY: String = "lighting"
const UNDER_WORKS_KEY: String = "under_works"
## Come si scrive ogni luce nel salvataggio: parole e non numeri, così riordinare l'elenco delle luci
## non cambia il significato dei salvataggi esistenti.
const LIGHTING_NAMES: Dictionary[Need.Lighting, String] = {
	Need.Lighting.NORMAL: "normal",
	Need.Lighting.DARK: "dark",
	Need.Lighting.BRIGHT: "bright",
}

## Le monete guadagnate finora.
var coins: int = 0
## I turni conclusi finora.
var turns_played: int = 0
## Quanti ospiti devono ancora arrivare in questa giornata, compreso quello di turno.
var arrivals_left: int = 0

## La griglia con camere e regole.
var _grid: Grid
## La fila degli ospiti in arrivo.
var _queue: GuestQueue


## Crea una partita sulla griglia indicata. _init() è la funzione che Godot chiama con .new().
func _init(grid: Grid, queue: GuestQueue) -> void:
	_grid = grid
	_queue = queue
	arrivals_left = get_daily_arrivals()
	_unlock_late_guests_if_ready()


## Restituisce l'ospite di turno.
func get_current_guest() -> Guest:
	return _queue.peek(1)[0]


## Restituisce gli ospiti visibili in fila dietro quello di turno.
func get_upcoming_guests() -> Array[Guest]:
	return _queue.peek(VISIBLE_UPCOMING_GUESTS + 1).slice(1)


## Restituisce quanti ospiti arrivano in una giornata con le camere attuali: un terzo delle camere,
## arrotondato per eccesso, e almeno uno. Una camera costruita durante la giornata vale dalla
## giornata dopo, perché questo numero si legge solo all'inizio.
func get_daily_arrivals() -> int:
	return maxi(ceili(float(_grid.get_rooms().size()) / ROOMS_PER_DAILY_ARRIVAL), 1)


## Prova a far entrare l'ospite di turno in una camera. Se non può entrare restituisce null e non
## cambia nulla. Se entra restituisce il resoconto: è vuoto se la giornata continua.
func host_current_guest(room: Room) -> TurnReport:
	if not _grid.assign_guest(get_current_guest(), room):
		return null

	return _finish_arrival()


## Rifiuta l'ospite di turno: se ne va senza pagare (D-026). Restituisce il resoconto come sopra.
func refuse_current_guest() -> TurnReport:
	return _finish_arrival()


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
	_unlock_late_guests_if_ready()
	return new_room


## Restituisce le modifiche alla luce possibili ora per una camera, anche se le monete non bastano.
## Un ospite non impedisce di cambiare luce, per rimediare a una scelta; impedisce solo i lavori,
## perché una camera in lavori non può ospitare nessuno.
func get_lighting_actions(room: Room) -> Array[LightingAction]:
	if room.is_under_works:
		return []

	if room.lighting == Need.Lighting.NORMAL:
		return [LightingAction.MAKE_DARK, LightingAction.MAKE_BRIGHT]

	if room.guest != null:
		return [LightingAction.RESTORE_PAID]

	return [LightingAction.RESTORE_PAID, LightingAction.RESTORE_WAIT]


## Restituisce il prezzo di una modifica alla luce, in monete.
func get_lighting_action_price(action: LightingAction) -> int:
	match action:
		LightingAction.RESTORE_PAID:
			return RESTORE_ROOM_PRICE
		LightingAction.RESTORE_WAIT:
			return 0
		_:
			return SPECIAL_ROOM_PRICE


## Applica una modifica alla luce e ne sottrae il prezzo. Il turno continua. Restituisce false, senza
## cambiare nulla, se la modifica non è possibile per questa camera o le monete non bastano.
func apply_lighting_action(room: Room, action: LightingAction) -> bool:
	var price: int = get_lighting_action_price(action)
	if not get_lighting_actions(room).has(action) or coins < price:
		return false

	coins -= price
	match action:
		LightingAction.MAKE_DARK:
			room.lighting = Need.Lighting.DARK
		LightingAction.MAKE_BRIGHT:
			room.lighting = Need.Lighting.BRIGHT
		LightingAction.RESTORE_PAID:
			room.lighting = Need.Lighting.NORMAL
		LightingAction.RESTORE_WAIT:
			room.is_under_works = true

	return true


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
		ARRIVALS_LEFT_KEY: arrivals_left,
		ROOMS_KEY: room_entries,
		QUEUE_KEY: _queue.to_data(),
	}


## Ricrea una partita dai valori di to_data(), ripassando dalle regole di Grid: un file modificato
## o danneggiato non può creare camere sovrapposte o ospiti che non entrano. species e late_species
## elencano gli ospiti possibili, come in GuestQueue. Restituisce null se qualcosa non è valido.
static func from_data(data: Dictionary, species: Array[Guest], late_species: Array[Guest] = []) -> HotelSession:
	var room_entries: Variant = data.get(ROOMS_KEY)
	var queue_data: Variant = data.get(QUEUE_KEY)
	# Una partita ha sempre almeno una camera: la scena conta su questo per scegliere quella attiva.
	if not room_entries is Array or (room_entries as Array).is_empty() or not queue_data is Dictionary:
		return null

	var grid: Grid = Grid.new(Envelope.new())
	for entry: Variant in room_entries:
		if not entry is Dictionary or not _add_room_from_data(grid, entry, species + late_species):
			return null

	var queue: GuestQueue = GuestQueue.from_data(queue_data, species, late_species)
	var saved_coins: int = SaveFile.read_count(data, COINS_KEY)
	var saved_turns: int = SaveFile.read_count(data, TURNS_PLAYED_KEY)
	var saved_arrivals: int = SaveFile.read_count(data, ARRIVALS_LEFT_KEY)
	# Una giornata senza arrivi rimasti sarebbe già conclusa: un salvataggio valido non la contiene.
	if queue == null or saved_coins == SaveFile.INVALID_COUNT or saved_turns == SaveFile.INVALID_COUNT or saved_arrivals < 1:
		return null

	var session: HotelSession = HotelSession.new(grid, queue)
	session.coins = saved_coins
	session.turns_played = saved_turns
	session.arrivals_left = saved_arrivals
	return session


## Restituisce una camera in valori semplici. Una camera libera non ha il campo dell'ospite.
func _room_to_data(room: Room) -> Dictionary:
	var entry: Dictionary = {
		ROOM_X_KEY: room.cells.position.x,
		ROOM_Y_KEY: room.cells.position.y,
		ROOM_WIDTH_KEY: room.cells.size.x,
		ROOM_HEIGHT_KEY: room.cells.size.y,
		LIGHTING_KEY: LIGHTING_NAMES[room.lighting],
	}

	if room.is_under_works:
		entry[UNDER_WORKS_KEY] = true

	if room.guest != null:
		entry[GUEST_KEY] = room.guest.to_data()
		entry[TURNS_LEFT_KEY] = room.turns_left

	return entry


## Aggiunge alla griglia la camera descritta da entry, con il suo eventuale ospite. Restituisce
## false se i valori non sono validi o se Grid rifiuta la camera o l'ospite.
static func _add_room_from_data(grid: Grid, entry: Dictionary, species: Array[Guest]) -> bool:
	var x: int = SaveFile.read_count(entry, ROOM_X_KEY)
	var y: int = SaveFile.read_count(entry, ROOM_Y_KEY)
	var width: int = SaveFile.read_count(entry, ROOM_WIDTH_KEY)
	var height: int = SaveFile.read_count(entry, ROOM_HEIGHT_KEY)
	if SaveFile.INVALID_COUNT in [x, y, width, height]:
		return false

	var room: Room = Room.new(Rect2i(x, y, width, height))
	var lighting_name: Variant = entry.get(LIGHTING_KEY)
	if not lighting_name is String:
		return false

	# find_key() cerca la chiave con quel valore, e dà null se non c'è: la parola è sconosciuta. Accetta
	# solo testi, perché l'elenco è fatto di testi: per questo il tipo si controlla prima.
	var lighting: Variant = LIGHTING_NAMES.find_key(lighting_name)
	if lighting == null or not grid.add_room(room):
		return false
	room.lighting = lighting

	# Il campo dei lavori c'è solo se sono in corso, e solo una camera speciale può tornare normale.
	if entry.has(UNDER_WORKS_KEY):
		var under_works: Variant = entry[UNDER_WORKS_KEY]
		if not under_works is bool or not under_works or room.lighting == Need.Lighting.NORMAL:
			return false
		room.is_under_works = true

	# Una camera senza il campo dell'ospite è semplicemente libera.
	if not entry.has(GUEST_KEY):
		return true

	var guest: Guest = Guest.from_data(entry[GUEST_KEY], species)
	var turns_left: int = SaveFile.read_count(entry, TURNS_LEFT_KEY)
	# Un ospite senza turni rimasti sarebbe già partito: un salvataggio valido non lo contiene.
	if guest == null or turns_left < 1 or not grid.assign_guest(guest, room):
		return false

	room.turns_left = turns_left
	return true


## Fa arrivare pipistrello e ospite vegetale, se l'hotel è abbastanza grande. Nessuna camera viene mai
## demolita, quindi una volta sbloccati restano.
func _unlock_late_guests_if_ready() -> void:
	if _grid.get_rooms().size() >= LATE_GUESTS_MIN_ROOMS:
		_queue.unlock_late_species()


## Fa avanzare la fila dopo che l'ospite di turno è stato sistemato o rifiutato. Se era l'ultimo della
## giornata la conclude; altrimenti restituisce un resoconto vuoto.
func _finish_arrival() -> TurnReport:
	_queue.advance()
	arrivals_left -= 1

	if arrivals_left > 0:
		return TurnReport.new()

	return _end_turn()


## Conclude la giornata: incassa, fa passare il tempo, fa partire chi ha finito e prepara gli arrivi
## del giorno dopo, contando le camere di adesso.
func _end_turn() -> TurnReport:
	var report: TurnReport = TurnReport.new()

	for room: Room in _grid.get_rooms():
		if room.guest == null:
			continue

		# Il compenso dipende da come sta ora: allargare una camera conviene anche dopo (D-026).
		var fit: Need.Fit = room.guest.need.evaluate_in_room(room.cells.size, room.lighting)
		var amount: int = room.guest.get_pay(fit)
		report.earnings[room] = amount
		coins += amount

		room.turns_left -= 1
		if room.turns_left <= 0:
			_grid.remove_guest(room)
			report.departed_rooms.append(room)

	# I lavori finiscono con la giornata: da domani la camera è di nuovo normale.
	for room: Room in _grid.get_rooms():
		if room.is_under_works:
			room.is_under_works = false
			room.lighting = Need.Lighting.NORMAL

	turns_played += 1
	arrivals_left = get_daily_arrivals()
	_unlock_late_guests_if_ready()
	return report
