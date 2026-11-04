extends GutTest
## Test del trascinamento di un lato, senza scene né grafica.
##
## COMPORTAMENTO PROTETTO: il lato segue il dito finché c'è spazio e poi fa resistenza;
## la regola scatta a metà cella; la camera cambia solo alla conferma e solo se la
## modifica è permessa.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per avviarli
## è scritto in docs/STATO.md.
## PERCHÉ È SEPARATO: controlla il calcolo del gesto, mentre le regole della griglia
## sono in test_grid.gd e il comportamento della scena in test_room_editor.gd.
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di GUT.
## GUT esegue da solo ogni funzione il cui nome inizia con «test_».
## COORDINATE: pixel dell'area di riferimento; trascinare in su è negativo.

## Lato di una cella usato nei test, in pixel.
const CELL_PIXELS: float = 100.0
## Camera di partenza: spazio libero su ogni lato, 3 celle sopra il soffitto.
const ROOM_CELLS: Rect2i = Rect2i(2, 3, 2, 2)
## Scarto accettato nei confronti tra numeri decimali, in pixel.
const TOLERANCE_PIXELS: float = 0.01

## Griglia ricreata prima di ogni test, così i test non si influenzano tra loro.
var _grid: Grid
## Camera ricreata prima di ogni test.
var _room: Room


## GUT chiama questa funzione prima di ogni test.
func before_each() -> void:
	_grid = Grid.new(Envelope.new())
	_room = Room.new(ROOM_CELLS)
	assert_true(_grid.add_room(_room))


## Crea il trascinamento di un lato della camera di prova.
func _make_drag(side: Room.MovableSide) -> RoomDrag:
	return RoomDrag.new(_grid, _room, side, CELL_PIXELS)


## Il gesto dall'interno sceglie il lato dalla metà toccata, non dal verso del dito: è ciò
## che permette di rimpicciolire la camera anche senza maniglie (decisione D-012).
func test_choose_side_uses_touched_half_and_axis() -> void:
	var center: Vector2 = Vector2(300.0, 400.0)
	var upper_left: Vector2 = Vector2(280.0, 380.0)
	var lower_right: Vector2 = Vector2(320.0, 420.0)
	var move_up: Vector2 = Vector2(0.0, -30.0)
	var move_down: Vector2 = Vector2(0.0, 30.0)
	var move_left: Vector2 = Vector2(-30.0, 0.0)
	var move_right: Vector2 = Vector2(30.0, 0.0)

	# Nella metà alta si muove il soffitto, in entrambi i versi; lo stesso per le altre metà.
	assert_eq(RoomDrag.choose_side(upper_left, move_up, center), Room.MovableSide.CEILING)
	assert_eq(RoomDrag.choose_side(upper_left, move_down, center), Room.MovableSide.CEILING)
	assert_eq(RoomDrag.choose_side(lower_right, move_up, center), Room.MovableSide.FLOOR)
	assert_eq(RoomDrag.choose_side(lower_right, move_down, center), Room.MovableSide.FLOOR)
	assert_eq(RoomDrag.choose_side(upper_left, move_left, center), Room.MovableSide.LEFT_WALL)
	assert_eq(RoomDrag.choose_side(upper_left, move_right, center), Room.MovableSide.LEFT_WALL)
	assert_eq(RoomDrag.choose_side(lower_right, move_left, center), Room.MovableSide.RIGHT_WALL)
	assert_eq(RoomDrag.choose_side(lower_right, move_right, center), Room.MovableSide.RIGHT_WALL)


## In un movimento obliquo conta l'asse prevalente; a parità vince quello verticale.
func test_choose_side_uses_dominant_axis() -> void:
	var center: Vector2 = Vector2(300.0, 400.0)
	var upper_left: Vector2 = Vector2(280.0, 380.0)

	assert_eq(RoomDrag.choose_side(upper_left, Vector2(30.0, 10.0), center), Room.MovableSide.LEFT_WALL)
	assert_eq(RoomDrag.choose_side(upper_left, Vector2(10.0, 30.0), center), Room.MovableSide.CEILING)
	assert_eq(RoomDrag.choose_side(upper_left, Vector2(20.0, 20.0), center), Room.MovableSide.CEILING)


## Il centro esatto deve dare sempre lo stesso risultato: metà bassa e metà destra.
func test_choose_side_at_exact_center() -> void:
	var center: Vector2 = Vector2(300.0, 400.0)

	assert_eq(RoomDrag.choose_side(center, Vector2(0.0, -30.0), center), Room.MovableSide.FLOOR)
	assert_eq(RoomDrag.choose_side(center, Vector2(-30.0, 0.0), center), Room.MovableSide.RIGHT_WALL)


## La regola scatta solo oltre la metà della cella.
func test_rule_snaps_at_half_cell() -> void:
	var drag: RoomDrag = _make_drag(Room.MovableSide.CEILING)

	drag.update(Vector2(0.0, -49.0))
	assert_eq(drag.preview.resulting_cells, ROOM_CELLS)

	drag.update(Vector2(0.0, -51.0))
	assert_eq(drag.preview.resulting_cells, Rect2i(2, 2, 2, 3))


## Entro i limiti, il lato disegnato segue esattamente il dito.
func test_side_follows_finger_inside_limits() -> void:
	var drag: RoomDrag = _make_drag(Room.MovableSide.CEILING)

	drag.update(Vector2(0.0, -130.0))

	assert_almost_eq(drag.offset_pixels, -130.0, TOLERANCE_PIXELS)
	assert_almost_eq(drag.get_visual_rect().position.y, 170.0, TOLERANCE_PIXELS)
	assert_almost_eq(drag.get_visual_rect().size.y, 330.0, TOLERANCE_PIXELS)


## Ogni lato usa solo l'asse giusto: il movimento sull'altro asse non conta.
func test_side_uses_only_its_axis() -> void:
	var wall_drag: RoomDrag = _make_drag(Room.MovableSide.RIGHT_WALL)
	wall_drag.update(Vector2(100.0, -300.0))
	assert_eq(wall_drag.preview.resulting_cells, Rect2i(2, 3, 3, 2))

	var floor_drag: RoomDrag = _make_drag(Room.MovableSide.FLOOR)
	floor_drag.update(Vector2(300.0, 100.0))
	assert_eq(floor_drag.preview.resulting_cells, Rect2i(2, 3, 2, 3))


## Tutti i lati devono muovere il rettangolo disegnato nel modo giusto.
func test_visual_rect_moves_each_side() -> void:
	var left_drag: RoomDrag = _make_drag(Room.MovableSide.LEFT_WALL)
	left_drag.update(Vector2(-60.0, 0.0))
	assert_eq(left_drag.get_visual_rect(), Rect2(140.0, 300.0, 260.0, 200.0))

	var right_drag: RoomDrag = _make_drag(Room.MovableSide.RIGHT_WALL)
	right_drag.update(Vector2(60.0, 0.0))
	assert_eq(right_drag.get_visual_rect(), Rect2(200.0, 300.0, 260.0, 200.0))

	var ceiling_drag: RoomDrag = _make_drag(Room.MovableSide.CEILING)
	ceiling_drag.update(Vector2(0.0, -60.0))
	assert_eq(ceiling_drag.get_visual_rect(), Rect2(200.0, 240.0, 200.0, 260.0))

	var floor_drag: RoomDrag = _make_drag(Room.MovableSide.FLOOR)
	floor_drag.update(Vector2(0.0, 60.0))
	assert_eq(floor_drag.get_visual_rect(), Rect2(200.0, 300.0, 200.0, 260.0))


## Oltre il limite il lato fa resistenza e non supera mai la resistenza massima.
func test_side_resists_beyond_envelope() -> void:
	var drag: RoomDrag = _make_drag(Room.MovableSide.CEILING)
	# Il soffitto ha 3 celle libere sopra: il limite è a 300 pixel.
	var limit_pixels: float = 300.0

	drag.update(Vector2(0.0, -320.0))
	var small_excess_offset: float = absf(drag.offset_pixels)
	assert_gt(small_excess_offset, limit_pixels)

	drag.update(Vector2(0.0, -2000.0))
	var large_excess_offset: float = absf(drag.offset_pixels)
	assert_gt(large_excess_offset, small_excess_offset, "tirando di più si muove ancora un po'")
	assert_lt(large_excess_offset, limit_pixels + RoomDrag.MAX_RESISTANCE_PIXELS)


## Anche rimpicciolendo c'è un limite, dato dalla misura minima della camera.
func test_side_resists_at_minimum_size() -> void:
	var drag: RoomDrag = _make_drag(Room.MovableSide.FLOOR)

	# La camera è alta 2 celle e il minimo è 1: il pavimento può salire di 100 pixel.
	drag.update(Vector2(0.0, -1000.0))

	assert_eq(drag.preview.rejection, ResizePreview.Rejection.TOO_SMALL)
	assert_lt(absf(drag.offset_pixels), 100.0 + RoomDrag.MAX_RESISTANCE_PIXELS)
	assert_gt(drag.get_visual_rect().size.y, 0.0, "la camera disegnata non deve sparire")


## Un'altra camera ferma il lato come il bordo dell'involucro.
func test_side_resists_against_another_room() -> void:
	# Camera ostacolo più larga, con una riga libera tra sé e il soffitto: spingerla la
	# lascerebbe con una tacca, quindi la parete si deve fermare.
	assert_true(_grid.add_room(Room.new(Rect2i(1, 0, 4, 2))))
	var drag: RoomDrag = _make_drag(Room.MovableSide.CEILING)

	# Due celle in su: il soffitto finirebbe dentro l'altra camera, ma ancora nell'involucro.
	drag.update(Vector2(0.0, -200.0))

	assert_eq(drag.preview.rejection, ResizePreview.Rejection.OVERLAPS_ROOM)
	assert_lt(absf(drag.offset_pixels), 100.0 + RoomDrag.MAX_RESISTANCE_PIXELS)


## Il lato della vicina segue il dito solo se la parete lo spinge: se rientra, resta fermo (D-022).
func test_touching_neighbor_moves_only_when_pushed() -> void:
	var neighbor: Room = Room.new(Rect2i(4, 3, 2, 2))
	assert_true(_grid.add_room(neighbor))
	var drag: RoomDrag = _make_drag(Room.MovableSide.RIGHT_WALL)

	drag.update(Vector2(30.0, 0.0))
	assert_eq(drag.get_neighbor_visual_rect(neighbor), Rect2(430.0, 300.0, 170.0, 200.0))

	drag.update(Vector2(-30.0, 0.0))
	assert_eq(drag.get_neighbor_visual_rect(neighbor), Rect2(400.0, 300.0, 200.0, 200.0))


## Una vicina distante resta ferma finché la parete non la raggiunge.
func test_distant_neighbor_moves_only_once_reached() -> void:
	var neighbor: Room = Room.new(Rect2i(5, 3, 1, 2))
	var wide_room: Room = _room
	assert_true(_grid.add_room(neighbor))
	var drag: RoomDrag = RoomDrag.new(_grid, wide_room, Room.MovableSide.RIGHT_WALL, CELL_PIXELS)

	drag.update(Vector2(60.0, 0.0))
	assert_eq(drag.get_neighbor_visual_rect(neighbor), Rect2(500.0, 300.0, 100.0, 200.0))


## Una vicina più lunga della parete non viene mai spostata.
func test_longer_neighbor_is_not_moved() -> void:
	var neighbor: Room = Room.new(Rect2i(4, 1, 2, 6))
	assert_true(_grid.add_room(neighbor))
	var drag: RoomDrag = _make_drag(Room.MovableSide.RIGHT_WALL)

	drag.update(Vector2(-30.0, 0.0))

	assert_eq(drag.get_neighbor_visual_rect(neighbor), Rect2(400.0, 100.0, 200.0, 600.0))


## Una camera dietro la parete trascinata non c'entra, anche se è allineata.
func test_room_behind_wall_is_not_moved() -> void:
	var behind: Room = Room.new(Rect2i(0, 3, 2, 2))
	assert_true(_grid.add_room(behind))
	var drag: RoomDrag = _make_drag(Room.MovableSide.RIGHT_WALL)

	drag.update(Vector2(60.0, 0.0))

	assert_eq(drag.get_neighbor_visual_rect(behind), Rect2(0.0, 300.0, 200.0, 200.0))


## Quando la regola rifiuta, la vicina non resta schiacciata sotto la camera: il suo lato resta
## attaccato alla parete, che fa resistenza.
func test_neighbor_follows_wall_resistance() -> void:
	var neighbor: Room = Room.new(Rect2i(4, 3, 2, 2))
	assert_true(_grid.add_room(neighbor))
	var drag: RoomDrag = _make_drag(Room.MovableSide.RIGHT_WALL)

	# Due celle: la camera resta nell'involucro, ma la vicina resterebbe senza celle.
	drag.update(Vector2(200.0, 0.0))

	assert_eq(drag.preview.rejection, ResizePreview.Rejection.NEIGHBOR_TOO_SMALL)
	assert_almost_eq(drag.get_neighbor_visual_rect(neighbor).position.x, drag.get_visual_rect().end.x, TOLERANCE_PIXELS)
	assert_gt(drag.get_neighbor_visual_rect(neighbor).size.x, 0.0)


## Durante il trascinamento la camera vera non cambia: cambia solo alla conferma.
func test_room_changes_only_on_commit() -> void:
	var drag: RoomDrag = _make_drag(Room.MovableSide.CEILING)

	drag.update(Vector2(0.0, -100.0))
	assert_eq(_room.cells, ROOM_CELLS)

	assert_true(drag.commit().is_valid())
	assert_eq(_room.cells, Rect2i(2, 2, 2, 3))


## Se alla conferma la modifica è rifiutata, la camera resta com'era.
func test_rejected_commit_keeps_room() -> void:
	var drag: RoomDrag = _make_drag(Room.MovableSide.CEILING)

	drag.update(Vector2(0.0, -500.0))

	assert_false(drag.commit().is_valid())
	assert_eq(_room.cells, ROOM_CELLS)


## Un tocco senza movimento non cambia nulla ed è una modifica valida.
func test_commit_without_movement_keeps_room() -> void:
	var drag: RoomDrag = _make_drag(Room.MovableSide.LEFT_WALL)

	assert_true(drag.commit().is_valid())
	assert_eq(_room.cells, ROOM_CELLS)
