extends GutTest
## Test della fila degli ospiti, dei turni e dei compensi.
##
## COMPORTAMENTO PROTETTO: gli ospiti arrivano uno alla volta. Ospitare o rifiutare conclude il
## turno; a ogni turno chi è in camera paga secondo come sta in quel momento e, finita la
## permanenza, parte (D-026). Stare comodi rende più che stare stipati (D-019).
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
