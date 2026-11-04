extends GutTest
## Test della fila degli ospiti, dei turni e dei compensi.
##
## COMPORTAMENTO PROTETTO: gli ospiti arrivano uno alla volta. Ospitare o rifiutare conclude il
## turno; a ogni turno chi è in camera paga secondo come sta in quel momento e, finita la
## permanenza, parte (D-026). Un turno è una giornata con più arrivi, in base alle camere (D-029). Stare comodi rende più che stare stipati (D-019). Le monete comprano
## nuove camere a prezzo crescente, senza consumare il turno (D-028).
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per avviarli è scritto
## in docs/STATO.md.
## PERCHÉ È SEPARATO: prova un'intera partita senza scene né grafica.
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di GUT.
## COORDINATE: tutto è in celle; Rect2i(x, y, larghezza, altezza) è un rettangolo di celle.

## Seme fisso, per avere sempre lo stesso ordine di arrivo.
const TEST_SEED: int = 42
## Sacchetti controllati nel test sull'equilibrio delle specie.
const BAGS_TO_CHECK: int = 5
## Ospiti usati nei test.
const GIRAFFE: Guest = preload("res://data/guests/giraffe.tres")
const DORMOUSE: Guest = preload("res://data/guests/dormouse.tres")

## Griglia ricreata prima di ogni test.
var _grid: Grid
## Una camera alta 3 e larga 1: la giraffa ci entra, ma è stipata.
var _narrow_room: Room


## GUT chiama questa funzione prima di ogni test.
func before_each() -> void:
	_grid = Grid.new(Envelope.new())
	_narrow_room = Room.new(Rect2i(0, 0, 1, 3))
	assert_true(_grid.add_room(_narrow_room))


## Crea una partita in cui arrivano solo ospiti della specie indicata.
func _make_session(guest: Guest) -> HotelSession:
	return HotelSession.new(_grid, GuestQueue.new([guest], TEST_SEED))


## Ogni sacchetto contiene tutte le specie: nessuna manca a lungo.
func test_queue_uses_every_species_in_each_bag() -> void:
	var species: Array[Guest] = GuestQueue.PROTOTYPE_GUESTS
	var line: Array[Guest] = GuestQueue.new(species, TEST_SEED).peek(species.size() * BAGS_TO_CHECK)

	for bag: int in BAGS_TO_CHECK:
		var bag_guests: Array[Guest] = line.slice(bag * species.size(), (bag + 1) * species.size())
		for guest: Guest in species:
			assert_true(bag_guests.has(guest))


## Lo stesso seme dà lo stesso ordine: è ciò che rende provabile la fila.
func test_same_seed_gives_same_order() -> void:
	var species: Array[Guest] = GuestQueue.PROTOTYPE_GUESTS
	var count: int = species.size() * BAGS_TO_CHECK

	assert_eq(GuestQueue.new(species, TEST_SEED).peek(count), GuestQueue.new(species, TEST_SEED).peek(count))


## Guardare la fila non la fa avanzare; avanzare sposta tutti di un posto.
func test_queue_peek_does_not_advance() -> void:
	var queue: GuestQueue = GuestQueue.new(GuestQueue.PROTOTYPE_GUESTS, TEST_SEED)
	var line: Array[Guest] = queue.peek(4)

	assert_eq(queue.peek(4), line)

	queue.advance()
	assert_eq(queue.peek(3), line.slice(1, 4))


## Si vedono l'ospite di turno e quelli in fila, senza ripetere quello di turno.
func test_session_shows_current_and_upcoming_guests() -> void:
	var queue: GuestQueue = GuestQueue.new(GuestQueue.PROTOTYPE_GUESTS, TEST_SEED)
	var line: Array[Guest] = queue.peek(HotelSession.VISIBLE_UPCOMING_GUESTS + 1)
	var session: HotelSession = HotelSession.new(_grid, queue)

	assert_eq(session.get_current_guest(), line[0])
	assert_eq(session.get_upcoming_guests(), line.slice(1))


## Un ospite che non può entrare non consuma il turno: il giocatore può adattare la camera.
func test_failed_hosting_keeps_turn() -> void:
	var small_room: Room = Room.new(Rect2i(3, 0, 1, 1))
	assert_true(_grid.add_room(small_room))
	var session: HotelSession = _make_session(GIRAFFE)

	assert_null(session.host_current_guest(small_room))
	assert_eq(session.turns_played, 0)
	assert_eq(session.coins, 0)


## Un ospite paga già nel turno in cui arriva, secondo come sta.
func test_guest_pays_on_arrival_according_to_fit() -> void:
	var session: HotelSession = _make_session(GIRAFFE)

	var report: TurnReport = session.host_current_guest(_narrow_room)

	assert_eq(report.earnings[_narrow_room], GIRAFFE.uncomfortable_pay)
	assert_eq(session.coins, GIRAFFE.uncomfortable_pay)
	assert_eq(session.turns_played, 1)


## Stare comodi deve rendere di più, per ogni ospite: è il principio di D-019.
func test_comfort_always_pays_more() -> void:
	for guest: Guest in GuestQueue.PROTOTYPE_GUESTS:
		assert_gt(guest.comfortable_pay, guest.uncomfortable_pay)


## Allargare la camera durante la permanenza alza il compenso dei turni successivi.
func test_widening_room_during_stay_raises_pay() -> void:
	var session: HotelSession = _make_session(GIRAFFE)
	session.host_current_guest(_narrow_room)

	assert_true(_grid.resize_room(_narrow_room, Room.MovableSide.RIGHT_WALL, 1).is_valid())
	var report: TurnReport = session.refuse_current_guest()

	assert_eq(report.earnings[_narrow_room], GIRAFFE.comfortable_pay)


## Dopo i turni di permanenza l'ospite parte e la camera torna libera.
func test_guest_leaves_after_stay() -> void:
	var session: HotelSession = _make_session(GIRAFFE)
	session.host_current_guest(_narrow_room)
	var report: TurnReport = null

	for turn: int in GIRAFFE.stay_turns - 1:
		assert_eq(_narrow_room.guest, GIRAFFE, "non deve partire prima del tempo")
		report = session.refuse_current_guest()

	assert_null(_narrow_room.guest)
	assert_eq(_narrow_room.turns_left, 0)
	assert_true(report.departed_rooms.has(_narrow_room))
	assert_eq(session.coins, GIRAFFE.uncomfortable_pay * GIRAFFE.stay_turns)


## Rifiutare fa avanzare la fila e non fa pagare nessuno, se le camere sono vuote.
func test_refusing_advances_queue_without_income() -> void:
	var queue: GuestQueue = GuestQueue.new(GuestQueue.PROTOTYPE_GUESTS, TEST_SEED)
	var line: Array[Guest] = queue.peek(2)
	var session: HotelSession = HotelSession.new(_grid, queue)

	var report: TurnReport = session.refuse_current_guest()

	assert_eq(session.get_current_guest(), line[1])
	assert_eq(report.get_total_earnings(), 0)
	assert_eq(session.coins, 0)


## Tutte le camere occupate pagano nello stesso turno, e il totale le somma.
func test_every_occupied_room_pays() -> void:
	var second_room: Room = Room.new(Rect2i(3, 0, 2, 2))
	assert_true(_grid.add_room(second_room))
	assert_true(_grid.assign_guest(DORMOUSE, second_room))
	var session: HotelSession = _make_session(GIRAFFE)

	var report: TurnReport = session.host_current_guest(_narrow_room)

	assert_eq(report.get_total_earnings(), GIRAFFE.uncomfortable_pay + DORMOUSE.comfortable_pay)


## Un ospite non comodo non fa guadagnare come uno comodo anche se la camera è troppo grande.
func test_too_big_room_pays_as_uncomfortable() -> void:
	assert_eq(DORMOUSE.get_pay(Need.Fit.TOO_BIG), DORMOUSE.uncomfortable_pay)
	assert_eq(DORMOUSE.get_pay(Need.Fit.CRAMPED), DORMOUSE.uncomfortable_pay)


## Crea una partita con due camere iniziali e le monete indicate, come all'avvio del gioco.
func _make_session_with_coins(coins: int) -> HotelSession:
	var grid: Grid = Grid.new(Envelope.new())
	assert_true(grid.add_room(Room.new(Rect2i(2, 4, 2, 2))))
	assert_true(grid.add_room(Room.new(Rect2i(4, 4, 2, 2))))
	var session: HotelSession = HotelSession.new(grid, GuestQueue.new([GIRAFFE], TEST_SEED))
	session.coins = coins
	return session


## Il prezzo parte da 30 e sale di 20 per ogni camera costruita (D-028).
func test_room_price_rises_with_each_room() -> void:
	var session: HotelSession = _make_session_with_coins(1000)

	assert_eq(session.get_new_room_price(), 30)
	assert_not_null(session.build_room(Vector2i(0, 0)))
	assert_eq(session.get_new_room_price(), 50)
	assert_not_null(session.build_room(Vector2i(1, 0)))
	assert_eq(session.get_new_room_price(), 70)
	assert_eq(session.coins, 1000 - 30 - 50)


## La camera nasce da 1 cella nel punto scelto, e la griglia la conosce.
func test_built_room_is_one_cell_in_grid() -> void:
	var session: HotelSession = _make_session_with_coins(30)

	var room: Room = session.build_room(Vector2i(0, 7))

	assert_eq(room.cells, Rect2i(0, 7, 1, 1))
	assert_true(session.get_grid().get_rooms().has(room))
	assert_null(room.guest)


## Costruire non consuma il turno: l'ospite di turno resta e nessuno paga (D-028).
func test_building_does_not_end_turn() -> void:
	var session: HotelSession = _make_session_with_coins(30)
	var guest: Guest = session.get_current_guest()

	session.build_room(Vector2i(0, 0))

	assert_eq(session.turns_played, 0)
	assert_eq(session.get_current_guest(), guest)


## Con un'unica moneta in meno non si costruisce, e non cambia nulla.
func test_cannot_build_without_enough_coins() -> void:
	var session: HotelSession = _make_session_with_coins(29)

	assert_false(session.can_build_room())
	assert_null(session.build_room(Vector2i(0, 0)))
	assert_eq(session.coins, 29)
	assert_eq(session.get_grid().get_rooms().size(), HotelSession.STARTING_ROOMS)


## Una cella occupata o fuori dall'involucro non si può comprare, e le monete restano.
func test_cannot_build_on_occupied_or_outside_cells() -> void:
	var session: HotelSession = _make_session_with_coins(30)

	for cell: Vector2i in [Vector2i(2, 4), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(6, 0), Vector2i(0, 8)]:
		assert_null(session.build_room(cell), "Cella %s" % cell)

	assert_eq(session.coins, 30)
	assert_eq(session.get_grid().get_rooms().size(), HotelSession.STARTING_ROOMS)


## Con l'hotel pieno le monete non bastano a creare spazio: non si può costruire.
func test_cannot_build_when_no_cell_is_free() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	assert_true(grid.add_room(Room.new(Rect2i(0, 0, Envelope.PROTOTYPE_WIDTH_CELLS, Envelope.PROTOTYPE_HEIGHT_CELLS))))
	var session: HotelSession = HotelSession.new(grid, GuestQueue.new([GIRAFFE], TEST_SEED))
	session.coins = 1000

	assert_false(session.can_build_room())


## Una camera costruita funziona come le altre: si allarga gratis e ospita, e chi ospita paga.
func test_built_room_works_like_any_other() -> void:
	var session: HotelSession = _make_session_with_coins(30)
	var room: Room = session.build_room(Vector2i(0, 0))

	assert_true(session.get_grid().resize_room(room, Room.MovableSide.FLOOR, 2).is_valid())
	assert_eq(session.coins, 0)
	assert_not_null(session.host_current_guest(room))
	assert_eq(session.coins, GIRAFFE.uncomfortable_pay)


## Crea una partita con camere da 1 cella e la specie indicata: il ghiro entra in tutte.
func _make_session_with_small_rooms(room_count: int, guest: Guest) -> HotelSession:
	var grid: Grid = Grid.new(Envelope.new())
	for index: int in room_count:
		assert_true(grid.add_room(Room.new(Rect2i(index, 0, 1, 1))))
	return HotelSession.new(grid, GuestQueue.new([guest], TEST_SEED))


## Conta le camere occupate di una partita.
func _count_occupied(session: HotelSession) -> int:
	var occupied: int = 0
	for room: Room in session.get_grid().get_rooms():
		if room.guest != null:
			occupied += 1
	return occupied


## Il difetto che ha portato a D-029: con un ospite al giorno e permanenze di 3 turni, le camere
## occupate non potevano superare 3, per quante se ne comprassero. Con più camere devono riempirsi.
func test_more_rooms_can_be_occupied_than_a_guest_stay() -> void:
	var session: HotelSession = _make_session_with_small_rooms(6, DORMOUSE)
	assert_eq(DORMOUSE.stay_turns, 3)
	var most_occupied: int = 0

	for arrival: int in 12:
		var free_rooms: Array[Room] = session.get_grid().get_rooms().filter(func(room: Room) -> bool: return room.guest == null)
		if free_rooms.is_empty():
			session.refuse_current_guest()
		else:
			session.host_current_guest(free_rooms[0])
		most_occupied = maxi(most_occupied, _count_occupied(session))

	assert_eq(most_occupied, 6)


## Gli arrivi al giorno sono la metà delle camere, per eccesso.
func test_daily_arrivals_grow_with_rooms() -> void:
	var expected_arrivals: Dictionary[int, int] = {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3}

	for room_count: int in expected_arrivals:
		assert_eq(_make_session_with_small_rooms(room_count, DORMOUSE).get_daily_arrivals(), expected_arrivals[room_count])


## Con più arrivi la giornata continua: nessuno paga e il tempo non passa fino all'ultimo.
func test_day_ends_only_after_last_arrival() -> void:
	var session: HotelSession = _make_session_with_small_rooms(4, DORMOUSE)
	var rooms: Array[Room] = session.get_grid().get_rooms()
	assert_eq(session.arrivals_left, 2)

	var first_report: TurnReport = session.host_current_guest(rooms[0])

	assert_true(first_report.earnings.is_empty())
	assert_eq(session.turns_played, 0)
	assert_eq(session.arrivals_left, 1)
	assert_eq(session.coins, 0)
	assert_eq(rooms[0].turns_left, DORMOUSE.stay_turns)

	var last_report: TurnReport = session.host_current_guest(rooms[1])

	assert_eq(last_report.earnings.size(), 2)
	assert_eq(session.turns_played, 1)
	assert_eq(session.arrivals_left, 2)
	assert_eq(rooms[0].turns_left, DORMOUSE.stay_turns - 1)
	assert_eq(session.coins, 2 * DORMOUSE.comfortable_pay)


## Anche rifiutare consuma un arrivo, e l'ultimo rifiuto conclude la giornata.
func test_refusing_consumes_an_arrival() -> void:
	var session: HotelSession = _make_session_with_small_rooms(4, DORMOUSE)

	session.refuse_current_guest()

	assert_eq(session.arrivals_left, 1)
	assert_eq(session.turns_played, 0)

	session.refuse_current_guest()

	assert_eq(session.turns_played, 1)


## Un ospite che non entra non consuma l'arrivo: resta di turno.
func test_guest_who_does_not_fit_keeps_arrival() -> void:
	var session: HotelSession = _make_session_with_small_rooms(4, GIRAFFE)

	assert_null(session.host_current_guest(session.get_grid().get_rooms()[0]))

	assert_eq(session.arrivals_left, 2)


## Una camera costruita durante la giornata fa crescere gli arrivi solo da quella dopo.
func test_room_built_during_day_counts_from_next_day() -> void:
	var session: HotelSession = _make_session_with_coins(30)
	assert_eq(session.arrivals_left, 1)

	session.build_room(Vector2i(0, 0))

	assert_eq(session.arrivals_left, 1)
	session.refuse_current_guest()
	assert_eq(session.arrivals_left, 2)
