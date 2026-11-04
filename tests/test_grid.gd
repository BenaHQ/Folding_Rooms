extends GutTest
## Test delle regole di modifica di una camera.
##
## COMPORTAMENTO PROTETTO: una camera può occupare spazio libero, ma non può uscire
## dall'involucro né scendere sotto le misure minime. Una parete condivisa cambia entrambe le
## camere, che restano rettangolari, e nessuna viene mai cancellata (D-021). L'anteprima
## spiega il motivo del rifiuto e non cambia mai nulla.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per
## avviarli è scritto in docs/STATO.md.
## PERCHÉ È SEPARATO: prova solo le regole di core/, senza scene né grafica.
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di
## GUT, come assert_eq(). GUT esegue da solo ogni funzione il cui nome inizia con
## «test_». assert_eq(a, b) segna il test come fallito se a e b sono diversi.
## COORDINATE: tutto è in celle; (0, 0) è in alto a sinistra e la Y cresce verso il
## basso. Rect2i(x, y, larghezza, altezza) descrive un rettangolo di celle.

## Camera usata nella maggior parte dei test: al centro dell'involucro 6×8 e con
## spazio libero su ogni lato.
const CENTER_ROOM_CELLS: Rect2i = Rect2i(2, 3, 2, 2)


## Crea una griglia con l'involucro del prototipo e una camera già inserita. Il test
## recupera la griglia e la camera dalle due voci del dizionario restituito.
func _make_grid_with_room(room_cells: Rect2i) -> Dictionary:
	var grid: Grid = Grid.new(Envelope.new())
	var room: Room = Room.new(room_cells)
	assert_true(grid.add_room(room), "la camera di partenza deve essere valida")
	return {"grid": grid, "room": room}


## Controlla il risultato di un'anteprima: motivo del rifiuto e celle previste.
func _assert_preview(preview: ResizePreview, rejection: ResizePreview.Rejection, cells: Rect2i) -> void:
	assert_eq(preview.rejection, rejection)
	assert_eq(preview.resulting_cells, cells)


## L'involucro senza parametri deve essere quello deciso per il prototipo.
func test_default_envelope_is_6_by_8() -> void:
	var envelope: Envelope = Envelope.new()
	assert_true(envelope.contains(Rect2i(0, 0, 6, 8)))
	assert_false(envelope.contains(Rect2i(0, 0, 7, 8)))
	assert_false(envelope.contains(Rect2i(0, 0, 6, 9)))


## Ogni lato deve poter crescere nello spazio libero, nella direzione giusta.
func test_each_side_grows_into_free_space() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var no_rejection: ResizePreview.Rejection = ResizePreview.Rejection.NONE

	_assert_preview(grid.preview_resize(room, Room.MovableSide.CEILING, -1), no_rejection, Rect2i(2, 2, 2, 3))
	_assert_preview(grid.preview_resize(room, Room.MovableSide.FLOOR, 1), no_rejection, Rect2i(2, 3, 2, 3))
	_assert_preview(grid.preview_resize(room, Room.MovableSide.LEFT_WALL, -1), no_rejection, Rect2i(1, 3, 3, 2))
	_assert_preview(grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, 1), no_rejection, Rect2i(2, 3, 3, 2))


## Ogni lato deve poter anche rientrare, rimpicciolendo la camera.
func test_each_side_shrinks() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var no_rejection: ResizePreview.Rejection = ResizePreview.Rejection.NONE

	_assert_preview(grid.preview_resize(room, Room.MovableSide.CEILING, 1), no_rejection, Rect2i(2, 4, 2, 1))
	_assert_preview(grid.preview_resize(room, Room.MovableSide.FLOOR, -1), no_rejection, Rect2i(2, 3, 2, 1))
	_assert_preview(grid.preview_resize(room, Room.MovableSide.LEFT_WALL, 1), no_rejection, Rect2i(3, 3, 1, 2))
	_assert_preview(grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, -1), no_rejection, Rect2i(2, 3, 1, 2))


## Uno spostamento nullo non cambia la camera e non è un errore.
func test_zero_offset_keeps_room_unchanged() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]

	_assert_preview(grid.preview_resize(room, Room.MovableSide.CEILING, 0), ResizePreview.Rejection.NONE, CENTER_ROOM_CELLS)


## La camera può arrivare esattamente al bordo dell'involucro, su tutti i lati.
func test_room_can_reach_envelope_edges() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]

	assert_true(grid.preview_resize(room, Room.MovableSide.CEILING, -3).is_valid())
	assert_true(grid.preview_resize(room, Room.MovableSide.FLOOR, 3).is_valid())
	assert_true(grid.preview_resize(room, Room.MovableSide.LEFT_WALL, -2).is_valid())
	assert_true(grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, 2).is_valid())


## Una cella oltre il bordo è già fuori dall'involucro, su tutti i lati.
func test_room_cannot_leave_envelope() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var outside: ResizePreview.Rejection = ResizePreview.Rejection.OUTSIDE_ENVELOPE

	_assert_preview(grid.preview_resize(room, Room.MovableSide.CEILING, -4), outside, Rect2i(2, -1, 2, 6))
	_assert_preview(grid.preview_resize(room, Room.MovableSide.FLOOR, 4), outside, Rect2i(2, 3, 2, 6))
	_assert_preview(grid.preview_resize(room, Room.MovableSide.LEFT_WALL, -3), outside, Rect2i(-1, 3, 5, 2))
	_assert_preview(grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, 3), outside, Rect2i(2, 3, 5, 2))


## Una camera da 1×1 è permessa (decisione D-010), una senza celle no.
func test_room_cannot_go_below_minimum_size() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var too_small: ResizePreview.Rejection = ResizePreview.Rejection.TOO_SMALL

	# Il minimo esatto è ancora valido.
	assert_true(grid.preview_resize(room, Room.MovableSide.FLOOR, -1).is_valid())
	assert_true(grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, -1).is_valid())

	# Arrivando a zero celle la modifica è rifiutata.
	assert_eq(grid.preview_resize(room, Room.MovableSide.FLOOR, -2).rejection, too_small)
	assert_eq(grid.preview_resize(room, Room.MovableSide.CEILING, 2).rejection, too_small)
	assert_eq(grid.preview_resize(room, Room.MovableSide.LEFT_WALL, 2).rejection, too_small)
	assert_eq(grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, -2).rejection, too_small)

	# Caso limite: un lato che oltrepassa quello opposto dà misure negative.
	assert_eq(grid.preview_resize(room, Room.MovableSide.FLOOR, -5).rejection, too_small)


## Se ci sono più motivi di rifiuto, le misure troppo piccole vengono prima: il
## rettangolo non descrive più una forma vera, anche se esce dall'involucro.
func test_too_small_wins_over_outside_envelope() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]

	# Il soffitto scende di 20 celle: oltrepassa il pavimento e finisce sotto il
	# bordo dell'involucro.
	assert_eq(grid.preview_resize(room, Room.MovableSide.CEILING, 20).rejection, ResizePreview.Rejection.TOO_SMALL)


## Una camera non può finire sopra una più lunga di lei, che resterebbe con una tacca, ma può
## toccarla lungo la parete.
func test_room_can_touch_but_not_notch_a_longer_room() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]

	# Camera vicina al piano di sopra, più larga: occupa le righe 0 e 1 e lascia libera la 2.
	var blocker: Room = Room.new(Rect2i(1, 0, 4, 2))
	assert_true(grid.add_room(blocker))

	assert_true(grid.preview_resize(room, Room.MovableSide.CEILING, -1).is_valid())
	var preview: ResizePreview = grid.preview_resize(room, Room.MovableSide.CEILING, -2)
	_assert_preview(preview, ResizePreview.Rejection.OVERLAPS_ROOM, Rect2i(2, 1, 2, 4))
	assert_eq(preview.blocking_room, blocker)


## Uno spostamento lungo non può scavalcare o cancellare una camera in un colpo solo.
func test_room_cannot_jump_over_another_room() -> void:
	var setup: Dictionary = _make_grid_with_room(Rect2i(0, 3, 1, 2))
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]

	# La camera ostacolo sta tra la parete destra e il bordo dell'involucro.
	assert_true(grid.add_room(Room.new(Rect2i(2, 3, 1, 2))))

	assert_eq(grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, 4).rejection, ResizePreview.Rejection.NEIGHBOR_TOO_SMALL)


## Una camera non è un ostacolo per sé stessa quando cresce.
func test_room_is_not_an_obstacle_for_itself() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]

	assert_ne(grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, 1).rejection, ResizePreview.Rejection.OVERLAPS_ROOM)


## Spingendo una parete condivisa, la camera vicina si restringe di altrettanto.
func test_pushing_shared_wall_shrinks_neighbor() -> void:
	var setup: Dictionary = _make_grid_with_room(Rect2i(0, 3, 2, 2))
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var neighbor: Room = Room.new(Rect2i(2, 3, 3, 2))
	assert_true(grid.add_room(neighbor))

	var preview: ResizePreview = grid.resize_room(room, Room.MovableSide.RIGHT_WALL, 2)

	assert_true(preview.is_valid())
	assert_eq(room.cells, Rect2i(0, 3, 4, 2))
	assert_eq(neighbor.cells, Rect2i(4, 3, 1, 2))


## Tirando indietro una parete, la camera vicina resta ferma: così due camere attaccate possono
## separarsi e si crea spazio libero (D-022).
func test_pulling_wall_leaves_touching_neighbor_alone() -> void:
	var setup: Dictionary = _make_grid_with_room(Rect2i(0, 3, 3, 2))
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var neighbor: Room = Room.new(Rect2i(3, 3, 2, 2))
	assert_true(grid.add_room(neighbor))

	var preview: ResizePreview = grid.resize_room(room, Room.MovableSide.RIGHT_WALL, -2)

	assert_true(preview.is_valid())
	assert_eq(preview.neighbor_changes.size(), 0)
	assert_eq(room.cells, Rect2i(0, 3, 1, 2))
	assert_eq(neighbor.cells, Rect2i(3, 3, 2, 2))


## La regola vale anche in verticale: un soffitto è il pavimento della camera di sopra.
func test_shared_ceiling_moves_both_rooms() -> void:
	var setup: Dictionary = _make_grid_with_room(Rect2i(1, 4, 2, 2))
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var upstairs: Room = Room.new(Rect2i(1, 1, 2, 3))
	assert_true(grid.add_room(upstairs))

	assert_true(grid.resize_room(room, Room.MovableSide.CEILING, -1).is_valid())

	assert_eq(room.cells, Rect2i(1, 3, 2, 3))
	assert_eq(upstairs.cells, Rect2i(1, 1, 2, 2))


## Una camera vicina non può scendere sotto il minimo: si rifiuta e non cambia niente. La spinta
## non si trasmette nemmeno a una terza camera dietro.
func test_neighbor_cannot_become_unusable() -> void:
	var setup: Dictionary = _make_grid_with_room(Rect2i(0, 3, 2, 2))
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var neighbor: Room = Room.new(Rect2i(2, 3, 2, 2))
	assert_true(grid.add_room(neighbor))

	# Una cella è il minimo esatto: è valido.
	assert_true(grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, 1).is_valid())

	var preview: ResizePreview = grid.resize_room(room, Room.MovableSide.RIGHT_WALL, 2)
	assert_eq(preview.rejection, ResizePreview.Rejection.NEIGHBOR_TOO_SMALL)
	assert_eq(preview.blocking_room, neighbor)
	assert_eq(preview.neighbor_changes.size(), 0)
	assert_eq(room.cells, Rect2i(0, 3, 2, 2))
	assert_eq(neighbor.cells, Rect2i(2, 3, 2, 2))


## Se la parete viene da lontano, la vicina cambia solo da quando viene raggiunta.
func test_wall_pushes_neighbor_only_after_reaching_it() -> void:
	var setup: Dictionary = _make_grid_with_room(Rect2i(0, 3, 1, 2))
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var neighbor: Room = Room.new(Rect2i(2, 3, 2, 2))
	assert_true(grid.add_room(neighbor))

	assert_eq(grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, 1).neighbor_changes.size(), 0)

	var preview: ResizePreview = grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, 2)
	assert_eq(preview.neighbor_changes.size(), 1)
	assert_eq(preview.neighbor_changes[0].room, neighbor)
	assert_eq(preview.neighbor_changes[0].resulting_cells, Rect2i(3, 3, 1, 2))


## Una parete lunga può spostare insieme due camere più corte che ha di fronte.
func test_long_wall_moves_two_neighbors() -> void:
	var setup: Dictionary = _make_grid_with_room(Rect2i(0, 2, 2, 4))
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var upper: Room = Room.new(Rect2i(2, 2, 2, 2))
	var lower: Room = Room.new(Rect2i(2, 4, 3, 2))
	assert_true(grid.add_room(upper))
	assert_true(grid.add_room(lower))

	assert_true(grid.resize_room(room, Room.MovableSide.RIGHT_WALL, 1).is_valid())

	assert_eq(upper.cells, Rect2i(3, 2, 1, 2))
	assert_eq(lower.cells, Rect2i(3, 4, 2, 2))


## Con due vicine, una che può spostarsi e una troppo piccola, non deve cambiare nessuna.
func test_one_blocked_neighbor_blocks_the_whole_change() -> void:
	var setup: Dictionary = _make_grid_with_room(Rect2i(0, 2, 2, 4))
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var upper: Room = Room.new(Rect2i(2, 2, 3, 2))
	var lower: Room = Room.new(Rect2i(2, 4, 1, 2))
	assert_true(grid.add_room(upper))
	assert_true(grid.add_room(lower))

	var preview: ResizePreview = grid.resize_room(room, Room.MovableSide.RIGHT_WALL, 1)

	assert_eq(preview.rejection, ResizePreview.Rejection.NEIGHBOR_TOO_SMALL)
	assert_eq(upper.cells, Rect2i(2, 2, 3, 2))
	assert_eq(lower.cells, Rect2i(2, 4, 1, 2))


## L'anteprima non deve cambiare nemmeno la camera vicina.
func test_preview_does_not_modify_neighbor() -> void:
	var setup: Dictionary = _make_grid_with_room(Rect2i(0, 3, 2, 2))
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]
	var neighbor: Room = Room.new(Rect2i(2, 3, 2, 2))
	assert_true(grid.add_room(neighbor))

	grid.preview_resize(room, Room.MovableSide.RIGHT_WALL, 1)

	assert_eq(neighbor.cells, Rect2i(2, 3, 2, 2))


## Il lato opposto deve essere sempre quello di fronte: la regola della parete condivisa
## dipende da questo abbinamento.
func test_opposite_sides_are_paired() -> void:
	assert_eq(Room.opposite_side(Room.MovableSide.LEFT_WALL), Room.MovableSide.RIGHT_WALL)
	assert_eq(Room.opposite_side(Room.MovableSide.RIGHT_WALL), Room.MovableSide.LEFT_WALL)
	assert_eq(Room.opposite_side(Room.MovableSide.CEILING), Room.MovableSide.FLOOR)
	assert_eq(Room.opposite_side(Room.MovableSide.FLOOR), Room.MovableSide.CEILING)


## L'anteprima viene ricalcolata di continuo durante il gesto: non deve cambiare nulla.
func test_preview_does_not_modify_room() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]

	grid.preview_resize(room, Room.MovableSide.CEILING, -1)
	assert_eq(room.cells, CENTER_ROOM_CELLS)


## Una modifica permessa cambia davvero la camera.
func test_resize_applies_valid_change() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]

	var preview: ResizePreview = grid.resize_room(room, Room.MovableSide.CEILING, -1)

	assert_true(preview.is_valid())
	assert_eq(room.cells, Rect2i(2, 2, 2, 3))


## Una modifica rifiutata lascia la camera com'era e riporta il motivo.
func test_resize_keeps_room_when_rejected() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]
	var room: Room = setup["room"]

	var preview: ResizePreview = grid.resize_room(room, Room.MovableSide.CEILING, -4)

	assert_eq(preview.rejection, ResizePreview.Rejection.OUTSIDE_ENVELOPE)
	assert_eq(room.cells, CENTER_ROOM_CELLS)


## La griglia deve rifiutare anche le camere iniziali non valide.
func test_add_room_rejects_invalid_rooms() -> void:
	var setup: Dictionary = _make_grid_with_room(CENTER_ROOM_CELLS)
	var grid: Grid = setup["grid"]

	assert_false(grid.add_room(Room.new(Rect2i(5, 0, 2, 2))), "esce dall'involucro")
	assert_false(grid.add_room(Room.new(Rect2i(3, 4, 2, 2))), "si sovrappone a un'altra camera")
	assert_false(grid.add_room(Room.new(Rect2i(0, 0, 0, 2))), "non ha celle")
	assert_true(grid.add_room(Room.new(Rect2i(0, 0, 1, 1))), "occupa spazio libero con le misure minime")
