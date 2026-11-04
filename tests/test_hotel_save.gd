extends GutTest
## Test del contenuto del salvataggio: partita, camere, luce, ospiti e fila.
##
## COMPORTAMENTO PROTETTO: una partita ricaricata prosegue esattamente come quella originale, fino
## all'ordine dei prossimi ospiti. Un file modificato o danneggiato non può creare una partita
## che le regole non permetterebbero: viene rifiutato per intero.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per avviarli è scritto
## in docs/STATO.md.
## PERCHÉ È SEPARATO: non tocca il disco (test_save_file.gd) né le scene (test_main_save.gd).
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di GUT.
## duplicate(true) crea una copia di un Dictionary comprese le parti al suo interno.
## COORDINATE: tutto è in celle.

## Ospiti usati nei test.
const SPECIES: Array[Guest] = GuestQueue.PROTOTYPE_GUESTS
const GIRAFFE: Guest = preload("res://tests/data/fixed_giraffe.tres")
## Seme fisso, per avere sempre lo stesso ordine di arrivo.
const TEST_SEED: int = 42
## Semi provati per lo stato del generatore: alcuni danno uno stato che, scritto, è negativo.
const SEEDS_TO_CHECK: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
## Quanti ospiti futuri si confrontano: più di un sacchetto.
const FUTURE_GUESTS_TO_CHECK: int = 30
## Quanti turni si giocano dopo il caricamento.
const TURNS_TO_PLAY: int = 12
## Valori che non sono mai un numero valido in un salvataggio. Il numero enorme perderebbe precisione.
const BAD_COUNTS: Array = [-1.0, 1.5, "3", null, [], 1e300]
## I dati di una partita valida, come arrivano da un file: i numeri sono float.
const VALID_DATA: Dictionary = {
	"coins": 17.0,
	"turns_played": 5.0,
	"arrivals_left": 1.0,
	"rooms": [
		{"x": 2.0, "y": 4.0, "width": 2.0, "height": 2.0, "lighting": "normal"},
		{"x": 4.0, "y": 4.0, "width": 2.0, "height": 3.0, "lighting": "normal", "guest": {"id": "giraffe", "stay_turns": 3.0, "comfortable_pay": 11.0, "uncomfortable_pay": 4.0}, "turns_left": 2.0},
	],
	"queue": {
		"line": [
			{"id": "snake", "stay_turns": 2.0, "comfortable_pay": 12.0, "uncomfortable_pay": 5.0},
			{"id": "dormouse", "stay_turns": 3.0, "comfortable_pay": 6.0, "uncomfortable_pay": 3.0},
		],
		"random_state": "12345",
	},
}


## Descrive una serie di ospiti con specie e valori, per confrontarla con un'altra.
func _describe(guests: Array[Guest]) -> Array:
	return guests.map(func(guest: Guest) -> Dictionary: return guest.to_data())


## Restituisce una copia dei dati validi, da modificare per il singolo test.
func _valid_data() -> Dictionary:
	return VALID_DATA.duplicate(true)


## Fa passare i dati attraverso il testo JSON, come avviene sul disco: è lì che i numeri cambiano
## tipo e che gli interi molto grandi perderebbero precisione.
func _through_json(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))


## Crea una partita con una camera alta 3 e larga 2 e una libera, con la fila indicata.
func _make_session(queue: GuestQueue) -> HotelSession:
	var grid: Grid = Grid.new(Envelope.new())
	grid.add_room(Room.new(Rect2i(0, 0, 2, 3)))
	grid.add_room(Room.new(Rect2i(2, 0, 2, 2)))
	return HotelSession.new(grid, queue)


## Controlla che i dati vengano rifiutati.
func _assert_rejected(data: Dictionary, message: String) -> void:
	assert_null(HotelSession.from_data(data, SPECIES), message)


## I dati validi di questo file devono essere accettati: altrimenti i rifiuti qui sotto non
## dimostrerebbero nulla.
func test_valid_data_is_accepted() -> void:
	var session: HotelSession = HotelSession.from_data(_valid_data(), SPECIES)

	assert_not_null(session)
	assert_eq(session.coins, 17)
	assert_eq(session.turns_played, 5)
	assert_eq(session.arrivals_left, 1)
	var rooms: Array[Room] = session.get_grid().get_rooms()
	assert_eq(rooms[0].cells, Rect2i(2, 4, 2, 2))
	assert_null(rooms[0].guest)
	assert_eq(rooms[1].guest.id, "giraffe")
	assert_eq(rooms[1].guest.comfortable_pay, 11)
	assert_eq(rooms[1].turns_left, 2)
	assert_eq(session.get_current_guest().id, "snake")


## Monete, turni, camere, ospiti e turni rimasti tornano come prima.
func test_round_trip_restores_game_state() -> void:
	var session: HotelSession = _make_session(GuestQueue.new([GIRAFFE], TEST_SEED))
	var room: Room = session.get_grid().get_rooms()[0]
	session.host_current_guest(room)
	session.refuse_current_guest()

	var loaded: HotelSession = HotelSession.from_data(_through_json(session.to_data()), SPECIES)
	assert_not_null(loaded)
	if loaded == null:
		return

	assert_eq(loaded.coins, session.coins)
	assert_eq(loaded.turns_played, session.turns_played)
	var loaded_rooms: Array[Room] = loaded.get_grid().get_rooms()
	assert_eq(loaded_rooms.size(), 2)
	assert_eq(loaded_rooms[0].cells, room.cells)
	assert_eq(loaded_rooms[0].guest.id, GIRAFFE.id)
	assert_eq(loaded_rooms[0].turns_left, room.turns_left)
	assert_null(loaded_rooms[1].guest)
	assert_eq(loaded_rooms[1].turns_left, 0)


## La fila ricaricata prosegue con gli stessi ospiti, anche oltre quelli già pescati. Con molti semi,
## perché lo stato del generatore è un intero enorme che JSON da solo non conserverebbe.
func test_queue_resumes_same_order_after_loading() -> void:
	var found_negative_state: bool = false

	for rng_seed: int in SEEDS_TO_CHECK:
		var queue: GuestQueue = GuestQueue.new(SPECIES, rng_seed)
		queue.peek(2)
		queue.advance()

		var data: Dictionary = _through_json(queue.to_data())
		found_negative_state = found_negative_state or (data[GuestQueue.RANDOM_STATE_KEY] as String).begins_with("-")
		var loaded: GuestQueue = GuestQueue.from_data(data, SPECIES)
		# Senza questo controllo, un errore su null fermerebbe l'intera esecuzione dei test.
		assert_not_null(loaded)
		if loaded == null:
			return

		assert_eq(_describe(loaded.peek(FUTURE_GUESTS_TO_CHECK)), _describe(queue.peek(FUTURE_GUESTS_TO_CHECK)))

	# Il valore negativo è il caso più delicato: i semi scelti devono metterlo alla prova.
	assert_true(found_negative_state)


## Una partita ricaricata e l'originale, giocate allo stesso modo, restano identiche.
func test_loaded_game_plays_on_identically() -> void:
	var session: HotelSession = _make_session(GuestQueue.new(SPECIES, TEST_SEED))
	session.get_upcoming_guests()
	var loaded: HotelSession = HotelSession.from_data(_through_json(session.to_data()), SPECIES)
	assert_not_null(loaded)
	if loaded == null:
		return

	for turn: int in TURNS_TO_PLAY:
		assert_eq(loaded.get_current_guest().to_data(), session.get_current_guest().to_data())
		# Prova a sistemare ogni ospite nella prima camera, altrimenti lo rifiuta.
		if session.host_current_guest(session.get_grid().get_rooms()[0]) == null:
			session.refuse_current_guest()
		if loaded.host_current_guest(loaded.get_grid().get_rooms()[0]) == null:
			loaded.refuse_current_guest()

	assert_eq(loaded.coins, session.coins)
	assert_eq(loaded.turns_played, session.turns_played)


## Ogni parte obbligatoria che manca rende il salvataggio non valido.
func test_missing_fields_are_rejected() -> void:
	for key: String in VALID_DATA:
		var data: Dictionary = _valid_data()
		data.erase(key)
		_assert_rejected(data, "Manca «%s»" % key)

	for key: String in ["x", "y", "width", "height", "lighting"]:
		var data: Dictionary = _valid_data()
		data["rooms"][0].erase(key)
		_assert_rejected(data, "Manca «%s» nella camera" % key)


## I numeri devono essere interi non negativi e precisi, ovunque si trovino.
func test_bad_numbers_are_rejected() -> void:
	for bad_count: Variant in BAD_COUNTS:
		for key: String in ["coins", "turns_played", "arrivals_left"]:
			var data: Dictionary = _valid_data()
			data[key] = bad_count
			_assert_rejected(data, "%s = %s" % [key, bad_count])

		for key: String in ["x", "y", "width", "height", "turns_left"]:
			var data: Dictionary = _valid_data()
			data["rooms"][1][key] = bad_count
			_assert_rejected(data, "%s = %s nella camera" % [key, bad_count])


## Parti del tipo sbagliato non devono causare errori: vengono rifiutate.
func test_wrong_types_are_rejected() -> void:
	var data: Dictionary = _valid_data()
	data["rooms"] = "camere"
	_assert_rejected(data, "Camere non in elenco")

	data = _valid_data()
	data["rooms"] = [1.0]
	_assert_rejected(data, "Camera non è un Dictionary")

	data = _valid_data()
	data["queue"] = []
	_assert_rejected(data, "Fila non è un Dictionary")

	data = _valid_data()
	data["queue"]["line"] = "snake"
	_assert_rejected(data, "Fila non in elenco")

	data = _valid_data()
	data["queue"]["line"] = [3.0]
	_assert_rejected(data, "Ospite in fila non è un testo")

	data = _valid_data()
	data["rooms"][1]["guest"] = 3.0
	_assert_rejected(data, "Ospite in camera non è un testo")


## Una partita senza camere non esiste: la scena avrebbe bisogno di almeno una camera attiva.
func test_game_without_rooms_is_rejected() -> void:
	var data: Dictionary = _valid_data()
	data["rooms"] = []
	_assert_rejected(data, "Nessuna camera")


## Le regole di Grid valgono anche per il file: niente camere fuori posto o sovrapposte.
func test_rooms_breaking_grid_rules_are_rejected() -> void:
	var data: Dictionary = _valid_data()
	data["rooms"][0]["x"] = 3.0
	_assert_rejected(data, "Camere sovrapposte")

	data = _valid_data()
	data["rooms"][0]["x"] = 5.0
	_assert_rejected(data, "Camera fuori dall'involucro")

	data = _valid_data()
	data["rooms"][0]["width"] = 0.0
	_assert_rejected(data, "Camera senza larghezza")


## Gli ospiti devono esistere, entrare nella camera e avere ancora turni da passare.
func test_invalid_guests_are_rejected() -> void:
	var data: Dictionary = _valid_data()
	data["rooms"][1]["guest"]["id"] = "unicorno"
	_assert_rejected(data, "Specie inesistente")

	data = _valid_data()
	data["rooms"][1]["turns_left"] = 0.0
	_assert_rejected(data, "Ospite senza turni")

	data = _valid_data()
	data["rooms"][1].erase("turns_left")
	_assert_rejected(data, "Turni mancanti")

	# La giraffa ha bisogno di un'altezza di almeno 3 celle: questa camera ne ha 2.
	data = _valid_data()
	data["rooms"][0]["guest"] = data["rooms"][1]["guest"]
	data["rooms"][0]["turns_left"] = 1.0
	_assert_rejected(data, "L'ospite non entra")


## La fila deve contenere solo specie note e uno stato del generatore leggibile.
func test_invalid_queue_is_rejected() -> void:
	var data: Dictionary = _valid_data()
	data["queue"]["line"][1]["id"] = "unicorno"
	_assert_rejected(data, "Specie inesistente in fila")

	data = _valid_data()
	data["queue"]["random_state"] = "non è un numero"
	_assert_rejected(data, "Stato non numerico")

	data = _valid_data()
	data["queue"]["random_state"] = 12345.0
	_assert_rejected(data, "Stato non scritto come testo")


## Ogni specie deve avere un nome proprio: il salvataggio riconosce gli ospiti da quello.
func test_every_species_has_a_unique_id() -> void:
	var ids: Dictionary[String, bool] = {}
	for guest: Guest in SPECIES:
		assert_ne(guest.id, "")
		ids[guest.id] = true

	assert_eq(ids.size(), SPECIES.size())


## Le camere costruite restano nel salvataggio, e il prezzo riparte da dove era.
func test_built_rooms_and_price_survive_saving() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	grid.add_room(Room.new(Rect2i(2, 4, 2, 2)))
	grid.add_room(Room.new(Rect2i(4, 4, 2, 2)))
	var session: HotelSession = HotelSession.new(grid, GuestQueue.new(SPECIES, TEST_SEED))
	session.coins = 100
	session.build_room(Vector2i(0, 0))

	var loaded: HotelSession = HotelSession.from_data(_through_json(session.to_data()), SPECIES)
	assert_not_null(loaded)
	if loaded == null:
		return

	assert_eq(loaded.get_grid().get_rooms().size(), 3)
	assert_eq(loaded.get_grid().get_rooms()[2].cells, Rect2i(0, 0, 1, 1))
	assert_eq(loaded.coins, 70)
	assert_eq(loaded.get_new_room_price(), 50)


## Gli arrivi rimasti tornano come prima: chiudere a metà giornata non la fa ripartire.
func test_day_in_progress_survives_saving() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	for index: int in 4:
		grid.add_room(Room.new(Rect2i(index, 0, 1, 1)))
	var session: HotelSession = HotelSession.new(grid, GuestQueue.new(SPECIES, TEST_SEED))
	session.refuse_current_guest()
	assert_eq(session.arrivals_left, 1)

	var loaded: HotelSession = HotelSession.from_data(_through_json(session.to_data()), SPECIES)
	assert_not_null(loaded)
	if loaded == null:
		return

	assert_eq(loaded.arrivals_left, 1)


## Una giornata senza arrivi rimasti non esiste.
func test_zero_arrivals_left_is_rejected() -> void:
	var data: Dictionary = _valid_data()
	data["arrivals_left"] = 0.0
	_assert_rejected(data, "Nessun arrivo rimasto")


## Luce e lavori tornano come prima, e i lavori finiscono a fine giornata anche dopo il caricamento.
func test_lighting_and_works_survive_saving() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	var dark_room: Room = Room.new(Rect2i(0, 0, 1, 1))
	var bright_room: Room = Room.new(Rect2i(1, 0, 1, 1))
	grid.add_room(dark_room)
	grid.add_room(bright_room)
	var session: HotelSession = HotelSession.new(grid, GuestQueue.new(SPECIES, TEST_SEED))
	session.coins = 100
	session.apply_lighting_action(dark_room, HotelSession.LightingAction.MAKE_DARK)
	session.apply_lighting_action(bright_room, HotelSession.LightingAction.MAKE_BRIGHT)
	session.apply_lighting_action(bright_room, HotelSession.LightingAction.RESTORE_WAIT)

	var loaded: HotelSession = HotelSession.from_data(_through_json(session.to_data()), SPECIES)
	assert_not_null(loaded)
	if loaded == null:
		return

	var rooms: Array[Room] = loaded.get_grid().get_rooms()
	assert_eq(rooms[0].lighting, Need.Lighting.DARK)
	assert_false(rooms[0].is_under_works)
	assert_eq(rooms[1].lighting, Need.Lighting.BRIGHT)
	assert_true(rooms[1].is_under_works)

	loaded.refuse_current_guest()

	assert_eq(rooms[0].lighting, Need.Lighting.DARK)
	assert_eq(rooms[1].lighting, Need.Lighting.NORMAL)


## Ospiti e fila possono contenere le specie arrivate dopo, e con 4 camere il sacchetto le include.
func test_late_guests_survive_saving() -> void:
	var bat: Guest = GuestQueue.LIGHT_GUESTS[0]
	var grid: Grid = Grid.new(Envelope.new())
	for index: int in HotelSession.LATE_GUESTS_MIN_ROOMS:
		grid.add_room(Room.new(Rect2i(index, 0, 1, 1)))
	var session: HotelSession = HotelSession.new(grid, GuestQueue.new(SPECIES, TEST_SEED, GuestQueue.LIGHT_GUESTS))
	session.get_grid().assign_guest(bat, grid.get_rooms()[0])
	session.get_upcoming_guests()

	var loaded: HotelSession = HotelSession.from_data(_through_json(session.to_data()), SPECIES, GuestQueue.LIGHT_GUESTS)
	assert_not_null(loaded)
	if loaded == null:
		return

	assert_eq(loaded.get_grid().get_rooms()[0].guest.id, bat.id)
	for arrival: int in FUTURE_GUESTS_TO_CHECK:
		assert_eq(loaded.get_current_guest().to_data(), session.get_current_guest().to_data())
		loaded.refuse_current_guest()
		session.refuse_current_guest()


## Una luce sconosciuta, o di tipo sbagliato, rende il salvataggio non valido.
func test_invalid_lighting_is_rejected() -> void:
	for bad_lighting: Variant in ["viola", 1.0, null, []]:
		var data: Dictionary = _valid_data()
		data["rooms"][0]["lighting"] = bad_lighting
		_assert_rejected(data, "Luce: %s" % [bad_lighting])


## I lavori hanno senso solo in una camera speciale e libera.
func test_invalid_works_are_rejected() -> void:
	var data: Dictionary = _valid_data()
	data["rooms"][0]["under_works"] = true
	_assert_rejected(data, "Lavori in una camera normale")

	data = _valid_data()
	data["rooms"][0]["lighting"] = "dark"
	data["rooms"][0]["under_works"] = "sì"
	_assert_rejected(data, "Lavori non booleani")

	data = _valid_data()
	data["rooms"][1]["lighting"] = "dark"
	data["rooms"][1]["under_works"] = true
	_assert_rejected(data, "Lavori in una camera occupata")


## Anche le specie arrivate dopo devono avere un nome proprio, diverso da tutte le altre.
func test_late_species_have_unique_ids() -> void:
	var ids: Dictionary[String, bool] = {}
	for guest: Guest in SPECIES + GuestQueue.LIGHT_GUESTS:
		assert_ne(guest.id, "")
		ids[guest.id] = true

	assert_eq(ids.size(), SPECIES.size() + GuestQueue.LIGHT_GUESTS.size())


## I valori propri di ogni ospite, in camera e in fila, restano quelli estratti (D-033).
func test_rolled_values_survive_saving() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	grid.add_room(Room.new(Rect2i(0, 0, 2, 2)))
	grid.add_room(Room.new(Rect2i(2, 0, 2, 2)))
	var session: HotelSession = HotelSession.new(grid, GuestQueue.new([SPECIES[2]], TEST_SEED))
	var hosted: Dictionary = session.get_current_guest().to_data()
	session.host_current_guest(grid.get_rooms()[0])
	var next: Dictionary = session.get_current_guest().to_data()

	var loaded: HotelSession = HotelSession.from_data(_through_json(session.to_data()), SPECIES)
	assert_not_null(loaded)
	if loaded == null:
		return

	assert_eq(loaded.get_grid().get_rooms()[0].guest.to_data(), hosted)
	assert_eq(loaded.get_current_guest().to_data(), next)


## Valori dell'ospite mancanti o sbagliati rendono il salvataggio non valido, in camera e in fila.
func test_invalid_guest_values_are_rejected() -> void:
	for key: String in ["id", "stay_turns", "comfortable_pay", "uncomfortable_pay"]:
		var data: Dictionary = _valid_data()
		data["rooms"][1]["guest"].erase(key)
		_assert_rejected(data, "Manca «%s» nell'ospite in camera" % key)

		data = _valid_data()
		data["queue"]["line"][0].erase(key)
		_assert_rejected(data, "Manca «%s» nell'ospite in fila" % key)

	for bad_count: Variant in BAD_COUNTS:
		for key: String in ["stay_turns", "comfortable_pay", "uncomfortable_pay"]:
			var data: Dictionary = _valid_data()
			data["rooms"][1]["guest"][key] = bad_count
			_assert_rejected(data, "%s = %s" % [key, bad_count])

	var zero_stay: Dictionary = _valid_data()
	zero_stay["queue"]["line"][0]["stay_turns"] = 0.0
	_assert_rejected(zero_stay, "Permanenza di zero turni")


## Restituisce una copia dei dati validi con in più una camera descritta da entry.
func _data_with_room(entry: Dictionary) -> Dictionary:
	var data: Dictionary = VALID_DATA.duplicate(true)
	(data["rooms"] as Array).append(entry)
	return data


## La piscina torna uguale, con forma e posizione, e continua a dare il bonus (D-036).
func test_pool_survives_saving() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	var room: Room = Room.new(Rect2i(0, 0, 2, 3))
	assert_true(grid.add_room(room))
	var session: HotelSession = HotelSession.new(grid, GuestQueue.new([GIRAFFE] as Array[Guest], TEST_SEED))
	session.coins = HotelSession.POOL_PRICE
	var pool: Room = session.build_pool(Vector2i(2, 0))
	assert_true(grid.resize_room(pool, Room.MovableSide.FLOOR, 1).is_valid())

	var data: Dictionary = JSON.parse_string(JSON.stringify(session.to_data()))
	var restored: HotelSession = HotelSession.from_data(data, [GIRAFFE] as Array[Guest])

	assert_not_null(restored)
	if restored == null:
		return

	var restored_grid: Grid = restored.get_grid()
	assert_eq(restored_grid.get_pool().cells, Rect2i(2, 0, 1, 2))
	assert_false(restored.can_build_pool())
	var restored_room: Room = restored_grid.get_guest_rooms()[0]
	var report: TurnReport = restored.host_current_guest(restored_room)
	assert_eq(report.earnings[restored_room], GIRAFFE.comfortable_pay + HotelSession.POOL_DAILY_BONUS)


## Una camera normale non ha il campo del servizio: il file resta semplice.
func test_normal_room_has_no_facility_field() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	assert_true(grid.add_room(Room.new(Rect2i(0, 0, 1, 1))))
	var session: HotelSession = HotelSession.new(grid, GuestQueue.new(SPECIES, TEST_SEED))

	assert_false((session.to_data()["rooms"][0] as Dictionary).has(HotelSession.FACILITY_KEY))


## Un servizio scritto male, una seconda piscina o una piscina che le regole non permetterebbero rendono
## il file non valido.
func test_invalid_pool_is_rejected() -> void:
	var pool: Dictionary = {"x": 0.0, "y": 0.0, "width": 1.0, "height": 1.0, "lighting": "normal", "facility": "pool"}
	assert_not_null(HotelSession.from_data(_data_with_room(pool), SPECIES), "una piscina valida è accettata")

	for bad_name: Variant in ["spa", 1.0, null, true, []]:
		var unknown: Dictionary = pool.duplicate()
		unknown["facility"] = bad_name
		assert_null(HotelSession.from_data(_data_with_room(unknown), SPECIES), str(bad_name))

	var dark: Dictionary = pool.duplicate()
	dark["lighting"] = "dark"
	assert_null(HotelSession.from_data(_data_with_room(dark), SPECIES), "la piscina non ha luce speciale")

	var with_guest: Dictionary = pool.duplicate()
	with_guest["guest"] = {"id": "dormouse", "stay_turns": 2.0, "comfortable_pay": 6.0, "uncomfortable_pay": 3.0}
	with_guest["turns_left"] = 1.0
	assert_null(HotelSession.from_data(_data_with_room(with_guest), SPECIES), "la piscina non ospita")

	var two_pools: Dictionary = _data_with_room(pool)
	var second: Dictionary = pool.duplicate()
	second["x"] = 1.0
	(two_pools["rooms"] as Array).append(second)
	assert_null(HotelSession.from_data(two_pools, SPECIES), "una piscina sola")


## Un hotel con la sola piscina non potrebbe accogliere nessuno.
func test_game_with_only_a_pool_is_rejected() -> void:
	var data: Dictionary = VALID_DATA.duplicate(true)
	data["rooms"] = [{"x": 0.0, "y": 0.0, "width": 1.0, "height": 1.0, "lighting": "normal", "facility": "pool"}]

	assert_null(HotelSession.from_data(data, SPECIES))
