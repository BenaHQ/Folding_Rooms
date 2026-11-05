extends GutTest
## Test dei bisogni degli ospiti e delle regole di ingresso.
##
## COMPORTAMENTO PROTETTO: entrare e stare bene sono due cose diverse (D-019): la giraffa entra
## in una camera 1×3 ma ci è stipata. Una camera troppo grande non è sempre migliore. Una
## modifica non può mai lasciare fuori un ospite già presente.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per avviarli è
## scritto in docs/STATO.md.
## PERCHÉ È SEPARATO: controlla dati e regole degli ospiti, senza scene né grafica.
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di GUT. load()
## legge un file di dati del progetto; «res://» indica la cartella principale.
## COORDINATE: tutto è in celle; Vector2i(larghezza, altezza) è la misura di una camera.

## File di dati degli ospiti.
const GIRAFFE_PATH: String = "res://data/guests/giraffe.tres"
const SNAKE_PATH: String = "res://data/guests/snake.tres"
const DORMOUSE_PATH: String = "res://data/guests/dormouse.tres"

## Gli ospiti, riletti prima di ogni test.
var _giraffe: Guest
var _snake: Guest
var _dormouse: Guest


## GUT chiama questa funzione prima di ogni test.
func before_each() -> void:
	_giraffe = load(GIRAFFE_PATH)
	_snake = load(SNAKE_PATH)
	_dormouse = load(DORMOUSE_PATH)


## Crea una griglia con due camere attaccate e la restituisce con le camere.
func _make_two_rooms() -> Dictionary:
	var grid: Grid = Grid.new(Envelope.new())
	var left: Room = Room.new(Rect2i(0, 3, 2, 3))
	var right: Room = Room.new(Rect2i(2, 3, 2, 3))
	assert_true(grid.add_room(left))
	assert_true(grid.add_room(right))
	return {"grid": grid, "left": left, "right": right}


## La giraffa: l'esempio che ha portato alla decisione D-019.
func test_giraffe_enters_tall_rooms_but_needs_width_to_be_comfortable() -> void:
	assert_eq(_giraffe.need.evaluate(Vector2i(2, 2)), Need.Fit.DOES_NOT_FIT)
	assert_eq(_giraffe.need.evaluate(Vector2i(1, 3)), Need.Fit.CRAMPED)
	assert_eq(_giraffe.need.evaluate(Vector2i(2, 3)), Need.Fit.COMFORTABLE)
	assert_eq(_giraffe.need.evaluate(Vector2i(6, 8)), Need.Fit.COMFORTABLE)


## Il serpente vuole una camera lunga e bassa: una alta non gli serve.
func test_snake_wants_long_and_low_room() -> void:
	assert_eq(_snake.need.evaluate(Vector2i(2, 1)), Need.Fit.DOES_NOT_FIT)
	assert_eq(_snake.need.evaluate(Vector2i(3, 1)), Need.Fit.CRAMPED)
	assert_eq(_snake.need.evaluate(Vector2i(4, 1)), Need.Fit.COMFORTABLE)
	assert_eq(_snake.need.evaluate(Vector2i(4, 3)), Need.Fit.TOO_BIG)


## L'ospite piccolo entra ovunque, ma in una camera grande non sta bene.
func test_dormouse_prefers_small_rooms() -> void:
	assert_eq(_dormouse.need.evaluate(Vector2i(1, 1)), Need.Fit.COMFORTABLE)
	assert_eq(_dormouse.need.evaluate(Vector2i(2, 2)), Need.Fit.COMFORTABLE)
	assert_eq(_dormouse.need.evaluate(Vector2i(3, 2)), Need.Fit.TOO_BIG)


## Nessun ospite deve avere come forma ideale il minimo per entrare, salvo chi vuole poco spazio:
## è ciò che impedisce di premiare il massimo stipamento.
func test_tall_and_long_guests_need_more_than_the_minimum() -> void:
	for guest: Guest in [_giraffe, _snake]:
		assert_ne(guest.need.enter_size, guest.need.comfortable_min_size)


## Un ospite entra in una camera libera in cui ci sta, anche se ci è stipato.
func test_guest_can_enter_even_if_cramped() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	var room: Room = Room.new(Rect2i(0, 0, 1, 3))
	assert_true(grid.add_room(room))

	assert_true(grid.assign_guest(_giraffe, room))
	assert_eq(room.guest, _giraffe)


## Un ospite non entra se la camera non basta, né se è già occupata.
func test_guest_cannot_enter_small_or_occupied_room() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	var room: Room = Room.new(Rect2i(0, 0, 2, 2))
	assert_true(grid.add_room(room))

	assert_false(grid.assign_guest(_giraffe, room))
	assert_null(room.guest)

	assert_true(grid.assign_guest(_dormouse, room))
	assert_false(grid.assign_guest(_snake, room), "la camera è già occupata")
	assert_eq(room.guest, _dormouse)


## Dopo l'uscita dell'ospite la camera torna libera.
func test_remove_guest_frees_room() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	var room: Room = Room.new(Rect2i(0, 0, 2, 2))
	assert_true(grid.add_room(room))
	assert_true(grid.assign_guest(_dormouse, room))

	grid.remove_guest(room)

	assert_null(room.guest)


## Una camera non può diventare troppo piccola per il suo ospite: non viene mai scacciato.
func test_room_cannot_shrink_below_its_guest() -> void:
	var setup: Dictionary = _make_two_rooms()
	var grid: Grid = setup["grid"]
	var left: Room = setup["left"]
	assert_true(grid.assign_guest(_giraffe, left))

	var preview: ResizePreview = grid.resize_room(left, Room.MovableSide.CEILING, 1)

	assert_eq(preview.rejection, ResizePreview.Rejection.GUEST_WOULD_NOT_FIT)
	assert_eq(left.cells, Rect2i(0, 3, 2, 3))


## La stessa protezione vale per l'ospite di una camera vicina che verrebbe spinta.
func test_wall_cannot_push_neighbor_below_its_guest() -> void:
	var grid: Grid = Grid.new(Envelope.new())
	var left: Room = Room.new(Rect2i(0, 3, 1, 1))
	var right: Room = Room.new(Rect2i(1, 3, 3, 1))
	assert_true(grid.add_room(left))
	assert_true(grid.add_room(right))
	assert_true(grid.assign_guest(_snake, right))

	var preview: ResizePreview = grid.resize_room(left, Room.MovableSide.RIGHT_WALL, 1)

	assert_eq(preview.rejection, ResizePreview.Rejection.GUEST_WOULD_NOT_FIT)
	assert_eq(preview.blocking_room, right)
	assert_eq(right.cells, Rect2i(1, 3, 3, 1))


## Stipare resta una scelta permessa: una modifica può rendere stipato un ospite.
func test_room_may_become_cramped() -> void:
	var setup: Dictionary = _make_two_rooms()
	var grid: Grid = setup["grid"]
	var left: Room = setup["left"]
	assert_true(grid.assign_guest(_giraffe, left))

	assert_true(grid.resize_room(left, Room.MovableSide.RIGHT_WALL, -1).is_valid())

	assert_eq(_giraffe.need.evaluate(left.cells.size), Need.Fit.CRAMPED)


## La luce sbagliata non impedisce di entrare, ma impedisce di stare bene (D-032).
func test_wrong_light_lets_guest_in_but_not_comfortable() -> void:
	var bat: Need = preload("res://data/guests/bat.tres").need

	assert_eq(bat.evaluate_in_room(Vector2i(1, 2), Need.Lighting.DARK), Need.Fit.COMFORTABLE)
	assert_eq(bat.evaluate_in_room(Vector2i(1, 2), Need.Lighting.NORMAL), Need.Fit.WRONG_LIGHT)
	assert_eq(bat.evaluate_in_room(Vector2i(1, 2), Need.Lighting.BRIGHT), Need.Fit.WRONG_LIGHT)


## Con la luce giusta conta di nuovo la misura, e se la misura non basta non si entra comunque.
func test_light_does_not_replace_size() -> void:
	var giraffe: Need = preload("res://data/guests/giraffe.tres").need

	assert_eq(giraffe.evaluate_in_room(Vector2i(1, 3), Need.Lighting.NORMAL), Need.Fit.CRAMPED)
	assert_eq(giraffe.evaluate_in_room(Vector2i(1, 2), Need.Lighting.DARK), Need.Fit.DOES_NOT_FIT)
	assert_eq(giraffe.evaluate_in_room(Vector2i(2, 3), Need.Lighting.DARK), Need.Fit.WRONG_LIGHT)


## Ogni ospite comune vuole la luce normale; il pipistrello il buio, la pianta le lampade.
func test_guests_want_expected_light() -> void:
	for guest: Guest in GuestQueue.PROTOTYPE_GUESTS:
		assert_eq(guest.need.lighting, Need.Lighting.NORMAL, guest.id)

	assert_eq(preload("res://data/guests/bat.tres").need.lighting, Need.Lighting.DARK)
	assert_eq(preload("res://data/guests/plant.tres").need.lighting, Need.Lighting.BRIGHT)


## Una camera con la luce giusta deve rendere più di una con la luce sbagliata (D-019).
func test_light_guests_pay_more_when_comfortable() -> void:
	for guest: Guest in GuestQueue.LIGHT_GUESTS:
		assert_gt(guest.get_pay(Need.Fit.COMFORTABLE), guest.get_pay(Need.Fit.WRONG_LIGHT), guest.id)
