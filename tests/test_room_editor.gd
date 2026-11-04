extends GutTest
## Test del comportamento della scena del gesto, con tocchi simulati.
##
## COMPORTAMENTO PROTETTO: toccare una camera mostra le sue maniglie; trascinare una maniglia e
## rilasciare applica la modifica, anche alla camera vicina; un secondo dito viene ignorato; un
## tocco interrotto non cambia le camere. In modalità costruzione un tocco su una cella libera compra una camera (D-028). La sensazione del gesto non è giudicabile da un test: va provata a mano.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per avviarli è
## scritto in docs/STATO.md.
## PERCHÉ È SEPARATO: prova la scena completa, mentre test_room_drag.gd prova il calcolo.
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di GUT. Un
## nodo aggiunto con add_child_autofree() entra nella scena di prova e viene eliminato da
## solo a fine test.

## Percorso della scena provata. «res://» indica la cartella principale del progetto.
const SCENE_PATH: String = "res://scenes/room_editor/room_editor.tscn"
## Indice del primo dito.
const FIRST_FINGER: int = 0
## Indice del secondo dito.
const SECOND_FINGER: int = 1
## Spostamento di una cella verso l'alto, in pixel.
const ONE_CELL_UP: Vector2 = Vector2(0.0, -RoomEditor.CELL_SIZE_PIXELS)
## Spostamento molto oltre il bordo superiore dell'involucro, in pixel.
const FAR_ABOVE_ENVELOPE: Vector2 = Vector2(0.0, -2000.0)
## Spostamento dal centro di una maniglia del soffitto alla sua parte fuori dalla camera.
const OUTSIDE_ROOM_UP: Vector2 = Vector2(0.0, -10.0)
## Frazione di cella poco sotto la metà: il lato è molto incurvato ma la regola non scatta.
const NEAR_HALF_CELL_FRACTION: float = 0.45
## Tempo di margine concesso all'animazione oltre la sua durata, in secondi.
const ANIMATION_MARGIN_SECONDS: float = 0.1
## Scarto accettato sulla curvatura a fine animazione, in pixel.
const BEND_TOLERANCE_PIXELS: float = 0.01
## Ospite usato nei test.
const GIRAFFE: Guest = preload("res://data/guests/giraffe.tres")
## Seme fisso della fila usata nei test: con una sola specie l'ordine è comunque sempre lo stesso.
const TEST_SEED: int = 1
## Punti di prova nelle quattro metà della camera, come frazioni delle sue misure.
const UPPER_HALF: Vector2 = Vector2(0.5, 0.25)
const LOWER_HALF: Vector2 = Vector2(0.5, 0.75)
const LEFT_HALF: Vector2 = Vector2(0.25, 0.5)
const RIGHT_HALF: Vector2 = Vector2(0.75, 0.5)

## La scena provata, ricreata prima di ogni test.
var _editor: RoomEditor


## GUT chiama questa funzione prima di ogni test.
func before_each() -> void:
	var scene: PackedScene = load(SCENE_PATH)
	_editor = add_child_autofree(scene.instantiate())
	# La giraffa non entra nelle camere iniziali: un tocco non fa partire turni per caso.
	_editor.start_session(GuestQueue.new([GIRAFFE], TEST_SEED))


## Simula un dito che tocca o lascia lo schermo.
func _touch(finger: int, position: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = finger
	event.position = position
	event.pressed = pressed
	event.canceled = canceled
	_editor._gui_input(event)


## Simula un dito che si sposta sullo schermo.
func _move_finger(finger: int, position: Vector2) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = finger
	event.position = position
	_editor._gui_input(event)


## Tocca e rilascia il centro della camera attiva nella sua forma attuale.
func _tap_center_of_active_room() -> void:
	var center: Vector2 = _point_in_room(Vector2(0.5, 0.5))
	_touch(FIRST_FINGER, center, true)
	_touch(FIRST_FINGER, center, false)


## Tocca il centro della camera, per selezionarla, e alza il dito.
func _select_room() -> void:
	var center: Vector2 = _editor.get_envelope_origin() + RoomEditor.CELL_SIZE_PIXELS * Vector2(RoomEditor.INITIAL_ROOM_CELLS.get_center())
	_touch(FIRST_FINGER, center, true)
	_touch(FIRST_FINGER, center, false)


## Seleziona la camera e afferra la maniglia del soffitto dalla parte che sporge fuori dalla
## camera, dove il trascinamento parte subito. Restituisce il punto toccato.
func _begin_ceiling_drag() -> Vector2:
	_select_room()
	var handle: Vector2 = _editor.get_handle_position(Room.MovableSide.CEILING) + OUTSIDE_ROOM_UP
	_touch(FIRST_FINGER, handle, true)
	return handle


## Restituisce un punto della camera: fraction indica la posizione da (0, 0), l'angolo in
## alto a sinistra, a (1, 1), l'angolo in basso a destra.
func _point_in_room(fraction: Vector2) -> Vector2:
	var cells: Rect2i = _editor.room.cells
	var room_size: Vector2 = Vector2(cells.size) * RoomEditor.CELL_SIZE_PIXELS
	return _editor.get_envelope_origin() + Vector2(cells.position) * RoomEditor.CELL_SIZE_PIXELS + room_size * fraction


## Dà alla camera una forma di prova, aggiornando sia la regola sia il disegno. Ferma anche
## l'assestamento in corso, che altrimenti continuerebbe a cambiare il disegno. Se il disegno
## restasse quello vecchio, un punto della forma nuova potrebbe risultare fuori dalla camera.
func _set_room_shape(cells: Rect2i) -> void:
	_editor._stop_settle_animation()
	_editor.room.cells = cells
	_editor._set_visual_rect(_editor._cells_to_pixels(cells), _editor.room)


## Esegue un intero gesto dall'interno: tocca, si muove e rilascia.
func _perform_inner_gesture(start: Vector2, movement: Vector2) -> void:
	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, start + movement)
	_touch(FIRST_FINGER, start + movement, false)


## Dalla metà alta o bassa si muove il lato di quella metà, sia per crescere sia per
## rimpicciolire: è la regola scelta con la decisione D-012.
func test_inner_gesture_moves_side_of_touched_half() -> void:
	var cell: float = RoomEditor.CELL_SIZE_PIXELS
	var cases: Array[Dictionary] = [
		{"point": UPPER_HALF, "move": Vector2(0.0, -cell), "cells": Rect2i(2, 3, 2, 3)},
		{"point": UPPER_HALF, "move": Vector2(0.0, cell), "cells": Rect2i(2, 5, 2, 1)},
		{"point": LOWER_HALF, "move": Vector2(0.0, cell), "cells": Rect2i(2, 4, 2, 3)},
		{"point": LOWER_HALF, "move": Vector2(0.0, -cell), "cells": Rect2i(2, 4, 2, 1)},
		{"point": LEFT_HALF, "move": Vector2(-cell, 0.0), "cells": Rect2i(1, 4, 3, 2)},
		{"point": LEFT_HALF, "move": Vector2(cell, 0.0), "cells": Rect2i(3, 4, 1, 2)},
		{"point": RIGHT_HALF, "move": Vector2(cell, 0.0), "cells": Rect2i(2, 4, 3, 2)},
		{"point": RIGHT_HALF, "move": Vector2(-cell, 0.0), "cells": Rect2i(2, 4, 1, 2)},
	]

	_select_room()
	for test_case: Dictionary in cases:
		_perform_inner_gesture(_point_in_room(test_case["point"]), test_case["move"])
		assert_eq(_editor.room.cells, test_case["cells"])
		_set_room_shape(RoomEditor.INITIAL_ROOM_CELLS)


## Finché il dito non si muove abbastanza non deve succedere nulla: tremare non è un gesto.
func test_small_movement_does_not_start_drag() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(UPPER_HALF)
	var below_threshold: Vector2 = Vector2(0.0, -RoomEditor.GESTURE_RECOGNITION_PIXELS / 2.0)

	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, start + below_threshold)
	assert_false(_editor.is_dragging())

	_touch(FIRST_FINGER, start + below_threshold, false)
	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)
	assert_true(_editor.is_room_selected(), "un semplice tocco non toglie la selezione")


## Il dito che era in attesa di riconoscimento non deve più contare dopo il rilascio.
func test_finger_movement_after_tap_is_ignored() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(UPPER_HALF)

	_touch(FIRST_FINGER, start, true)
	_touch(FIRST_FINGER, start, false)
	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)

	assert_false(_editor.is_dragging())


## Senza selezione il gesto non parte: il primo tocco serve solo a selezionare.
func test_inner_gesture_needs_selected_room() -> void:
	var start: Vector2 = _point_in_room(UPPER_HALF)

	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)

	assert_false(_editor.is_dragging())


## Un secondo dito non deve avviare né disturbare il riconoscimento del primo.
func test_second_finger_is_ignored_during_recognition() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(UPPER_HALF)
	_touch(FIRST_FINGER, start, true)

	_move_finger(SECOND_FINGER, start + FAR_ABOVE_ENVELOPE)
	assert_false(_editor.is_dragging())

	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)
	_touch(FIRST_FINGER, start + ONE_CELL_UP, false)
	assert_eq(_editor.room.cells, Rect2i(2, 3, 2, 3))


## Se l'app va in pausa durante il riconoscimento, il gesto viene dimenticato.
func test_app_pause_cancels_recognition() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(UPPER_HALF)
	_touch(FIRST_FINGER, start, true)

	_editor._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)

	assert_false(_editor.is_dragging())


## Deve funzionare anche sulla camera più piccola, dove ogni metà è larga mezza cella.
func test_inner_gesture_works_on_smallest_room() -> void:
	_set_room_shape(Rect2i(2, 4, 1, 1))
	_select_room_at_current_shape()

	_perform_inner_gesture(_point_in_room(UPPER_HALF), ONE_CELL_UP)

	assert_eq(_editor.room.cells, Rect2i(2, 3, 1, 2))


## Le maniglie compaiono solo dopo aver toccato la camera.
func test_touching_room_selects_it() -> void:
	assert_false(_editor.is_room_selected())
	_select_room()
	assert_true(_editor.is_room_selected())


## Toccare fuori dalla camera nasconde le maniglie.
func test_touching_outside_deselects_room() -> void:
	_select_room()
	_touch(FIRST_FINGER, Vector2(1.0, 1.0), true)
	assert_false(_editor.is_room_selected())


## Senza selezione la maniglia non esiste: quel punto non deve iniziare un trascinamento.
func test_handle_works_only_when_selected() -> void:
	_touch(FIRST_FINGER, _editor.get_handle_position(Room.MovableSide.CEILING), true)
	assert_false(_editor.is_dragging())


## Il percorso principale: trascinare il soffitto in su allunga la camera.
func test_dragging_ceiling_up_grows_room() -> void:
	var handle: Vector2 = _begin_ceiling_drag()
	assert_true(_editor.is_dragging())

	_move_finger(FIRST_FINGER, handle + ONE_CELL_UP)
	# La camera vera cambia solo al rilascio, non mentre il dito si muove.
	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)

	_touch(FIRST_FINGER, handle + ONE_CELL_UP, false)
	assert_false(_editor.is_dragging())
	assert_eq(_editor.room.cells, Rect2i(2, 3, 2, 3))


## Tutte e quattro le maniglie devono essere raggiungibili e muovere il lato giusto.
func test_every_handle_moves_its_side() -> void:
	var cases: Array[Dictionary] = [
		{"side": Room.MovableSide.LEFT_WALL, "move": Vector2(-RoomEditor.CELL_SIZE_PIXELS, 0.0), "cells": Rect2i(1, 4, 3, 2)},
		{"side": Room.MovableSide.RIGHT_WALL, "move": Vector2(RoomEditor.CELL_SIZE_PIXELS, 0.0), "cells": Rect2i(2, 4, 3, 2)},
		{"side": Room.MovableSide.CEILING, "move": ONE_CELL_UP, "cells": Rect2i(2, 3, 2, 3)},
		{"side": Room.MovableSide.FLOOR, "move": -ONE_CELL_UP, "cells": Rect2i(2, 4, 2, 3)},
	]

	_select_room()
	for test_case: Dictionary in cases:
		var side: Room.MovableSide = test_case["side"]
		var move: Vector2 = test_case["move"]

		# Afferra la maniglia dalla parte che sporge fuori dalla camera: nella direzione del
		# movimento, perché i casi di prova allontanano sempre il lato dalla camera.
		var handle: Vector2 = _editor.get_handle_position(side) + move.normalized() * 10.0
		_touch(FIRST_FINGER, handle, true)
		assert_true(_editor.is_dragging(), "fuori dalla camera la maniglia parte subito")
		_move_finger(FIRST_FINGER, handle + move)
		_touch(FIRST_FINGER, handle + move, false)
		assert_eq(_editor.room.cells, test_case["cells"])
		_set_room_shape(RoomEditor.INITIAL_ROOM_CELLS)


## Rilasciando oltre il limite la modifica è rifiutata e la camera resta com'era.
func test_rejected_drag_keeps_room() -> void:
	var handle: Vector2 = _begin_ceiling_drag()

	_move_finger(FIRST_FINGER, handle + FAR_ABOVE_ENVELOPE)
	_touch(FIRST_FINGER, handle + FAR_ABOVE_ENVELOPE, false)

	assert_false(_editor.is_dragging())
	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)


## Un secondo dito non deve spostare il lato né concludere il trascinamento.
func test_second_finger_is_ignored_during_drag() -> void:
	var handle: Vector2 = _begin_ceiling_drag()
	_move_finger(FIRST_FINGER, handle + ONE_CELL_UP)

	# Il secondo dito tocca, si muove lontano e si alza.
	_touch(SECOND_FINGER, Vector2(50.0, 50.0), true)
	_move_finger(SECOND_FINGER, handle + FAR_ABOVE_ENVELOPE)
	_touch(SECOND_FINGER, Vector2(50.0, 50.0), false)
	assert_true(_editor.is_dragging())

	# Il primo dito conclude il gesto come se il secondo non ci fosse stato.
	_touch(FIRST_FINGER, handle + ONE_CELL_UP, false)
	assert_eq(_editor.room.cells, Rect2i(2, 3, 2, 3))


## Un tocco annullato dal sistema non deve applicare la modifica.
func test_canceled_touch_keeps_room() -> void:
	var handle: Vector2 = _begin_ceiling_drag()
	_move_finger(FIRST_FINGER, handle + ONE_CELL_UP)

	_touch(FIRST_FINGER, handle + ONE_CELL_UP, false, true)

	assert_false(_editor.is_dragging())
	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)


## Se l'app va in pausa durante il gesto, la modifica va annullata senza dati a metà.
func test_app_pause_cancels_drag() -> void:
	var handle: Vector2 = _begin_ceiling_drag()
	_move_finger(FIRST_FINGER, handle + ONE_CELL_UP)

	_editor._notification(Node.NOTIFICATION_APPLICATION_PAUSED)

	assert_false(_editor.is_dragging())
	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)


## Al rilascio il lato incurvato deve raddrizzarsi con l'animazione, non di colpo: un salto
## improvviso rovinerebbe proprio la sensazione elastica del gesto.
## NOTA GDSCRIPT: «await» sospende il test finché il tempo indicato non è passato, mentre
## Godot continua a far avanzare l'animazione.
func test_bend_straightens_gradually_after_release() -> void:
	var handle: Vector2 = _begin_ceiling_drag()
	var below_half_cell: Vector2 = ONE_CELL_UP * NEAR_HALF_CELL_FRACTION
	_move_finger(FIRST_FINGER, handle + below_half_cell)
	var bend_while_dragging: Vector2 = _editor._bend
	assert_ne(bend_while_dragging, Vector2.ZERO, "tra due celle il lato deve essere incurvato")

	_touch(FIRST_FINGER, handle + below_half_cell, false)
	# L'animazione non ha ancora fatto nessun passo: la curvatura deve essere ancora tutta lì.
	assert_eq(_editor._bend, bend_while_dragging)

	await wait_seconds(RoomEditor.SETTLE_SECONDS + ANIMATION_MARGIN_SECONDS)
	assert_almost_eq(_editor._bend, Vector2.ZERO, Vector2.ONE * BEND_TOLERANCE_PIXELS)


## Un nuovo trascinamento deve partire con il lato dritto, anche se l'assestamento precedente
## era ancora in corso.
func test_new_drag_clears_bend_of_previous_settle() -> void:
	var handle: Vector2 = _begin_ceiling_drag()
	var below_half_cell: Vector2 = ONE_CELL_UP * NEAR_HALF_CELL_FRACTION
	_move_finger(FIRST_FINGER, handle + below_half_cell)
	_touch(FIRST_FINGER, handle + below_half_cell, false)

	_touch(FIRST_FINGER, _editor.get_handle_position(Room.MovableSide.CEILING) + OUTSIDE_ROOM_UP, true)

	assert_true(_editor.is_dragging())
	assert_eq(_editor._bend, Vector2.ZERO)


## Nelle camere da 1×1 le aree delle maniglie si sovrappongono: deve vincere la più vicina.
func test_smallest_room_keeps_handles_separate() -> void:
	_set_room_shape(Rect2i(2, 4, 1, 1))
	_select_room_at_current_shape()

	for side: Room.MovableSide in Room.MovableSide.values():
		assert_eq(_editor._find_handle_at(_editor.get_handle_position(side)), side)


## Toccare la camera selezionata fa entrare l'ospite di turno e conclude il turno.
func test_tapping_selected_room_hosts_current_guest() -> void:
	_set_room_shape(Rect2i(2, 2, 2, 3))
	_select_room_at_current_shape()
	_tap_center_of_active_room()

	assert_eq(_editor.room.guest, GIRAFFE)
	assert_eq(_editor.session.turns_played, 1)
	assert_eq(_editor.session.coins, GIRAFFE.comfortable_pay)


## Se la camera non basta, l'ospite resta di turno: il giocatore può allungarla e riprovare.
func test_guest_that_does_not_fit_stays_current() -> void:
	_select_room()
	_tap_center_of_active_room()

	assert_null(_editor.room.guest)
	assert_eq(_editor.session.turns_played, 0, "un tentativo fallito non consuma il turno")


## La scena del concept: la giraffa non entra, si alza il soffitto e allora entra.
func test_raising_ceiling_lets_guest_in() -> void:
	_select_room()
	_perform_inner_gesture(_point_in_room(UPPER_HALF), ONE_CELL_UP)
	_tap_center_of_active_room()

	assert_eq(_editor.room.guest, GIRAFFE)


## Un trascinamento è gratis: non fa entrare nessuno e non consuma turni (D-026).
func test_drag_does_not_host_guest_or_use_turn() -> void:
	_select_room()

	_perform_inner_gesture(_point_in_room(UPPER_HALF), ONE_CELL_UP)

	assert_null(_editor.room.guest)
	assert_eq(_editor.session.turns_played, 0)


## Un tocco interrotto dal sistema non è una scelta del giocatore.
func test_canceled_tap_does_not_host_guest() -> void:
	_set_room_shape(Rect2i(2, 2, 2, 3))
	_select_room_at_current_shape()

	var center: Vector2 = _point_in_room(Vector2(0.5, 0.5))
	_touch(FIRST_FINGER, center, true)
	_touch(FIRST_FINGER, center, false, true)

	assert_null(_editor.room.guest)


## Rifiutare conclude il turno senza far entrare nessuno.
func test_refusing_ends_turn() -> void:
	_editor.refuse_current_guest()

	assert_eq(_editor.session.turns_played, 1)
	assert_null(_editor.room.guest)


## Un secondo dito sul pulsante non deve cambiare la partita durante un trascinamento.
func test_refusing_is_ignored_during_drag() -> void:
	_begin_ceiling_drag()

	_editor.refuse_current_guest()

	assert_eq(_editor.session.turns_played, 0)


## Durante un gesto valido l'ospite viene giudicato sulla forma prevista.
func test_displayed_cells_follow_valid_preview() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(UPPER_HALF)
	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)

	assert_eq(_editor._get_displayed_cells(_editor.room), Rect2i(2, 3, 2, 3))


## Restituisce la seconda camera, quella che all'avvio condivide una parete con la prima.
func _second_room() -> Room:
	return _editor.rooms[1]


## Restituisce il punto al centro di un rettangolo di celle, in pixel del nodo.
func _center_of_cells(cells: Rect2i) -> Vector2:
	return _editor.get_envelope_origin() + (Vector2(cells.position) + Vector2(cells.size) / 2.0) * RoomEditor.CELL_SIZE_PIXELS


## Le due camere iniziali devono esistere e condividere una parete.
func test_scene_starts_with_two_touching_rooms() -> void:
	assert_eq(_editor.rooms.size(), 2)
	assert_eq(_editor.rooms[0].cells.end.x, _second_room().cells.position.x)


## Toccando l'altra camera diventa attiva quella, senza far partire un gesto.
func test_touching_other_room_switches_selection() -> void:
	_select_room()
	var other_center: Vector2 = _center_of_cells(RoomEditor.SECOND_ROOM_CELLS)

	_touch(FIRST_FINGER, other_center, true)

	assert_eq(_editor.room, _second_room())
	assert_true(_editor.is_room_selected())
	assert_false(_editor.is_dragging())


## Il primo tocco sulla seconda camera, senza selezioni, deve selezionare proprio lei.
func test_first_touch_can_select_second_room() -> void:
	_touch(FIRST_FINGER, _center_of_cells(RoomEditor.SECOND_ROOM_CELLS), true)

	assert_eq(_editor.room, _second_room())
	assert_true(_editor.is_room_selected())


## La maniglia che sporge sopra la camera vicina ha la precedenza: non deve cambiare selezione.
func test_handle_over_neighbor_wins_over_selecting_it() -> void:
	_select_room()
	var first_room: Room = _editor.room
	var handle: Vector2 = _editor.get_handle_position(Room.MovableSide.RIGHT_WALL) + Vector2(10.0, 0.0)

	_touch(FIRST_FINGER, handle, true)

	assert_eq(_editor.room, first_room)
	assert_true(_editor.is_dragging())


## Spingendo la parete condivisa cambiano entrambe le camere, ma solo al rilascio.
func test_pushing_shared_wall_changes_both_rooms_on_release() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(RIGHT_HALF)
	var end: Vector2 = start + Vector2(RoomEditor.CELL_SIZE_PIXELS, 0.0)

	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, end)
	assert_eq(_second_room().cells, RoomEditor.SECOND_ROOM_CELLS)
	assert_eq(_editor._visual_rects[_second_room()].position.x, _editor._visual_rects[_editor.room].end.x, "il muro disegnato è uno solo")

	_touch(FIRST_FINGER, end, false)
	assert_eq(_editor.room.cells, Rect2i(2, 4, 3, 2))
	assert_eq(_second_room().cells, Rect2i(5, 4, 1, 2))


## Rientrando, la camera vicina resta ferma e tra le due si crea spazio libero (D-022).
func test_pulling_wall_leaves_neighbor_alone() -> void:
	_select_room()
	_perform_inner_gesture(_point_in_room(RIGHT_HALF), Vector2(-RoomEditor.CELL_SIZE_PIXELS, 0.0))

	assert_eq(_editor.room.cells, Rect2i(2, 4, 1, 2))
	assert_eq(_second_room().cells, RoomEditor.SECOND_ROOM_CELLS)


## Se la vicina diventerebbe inutilizzabile si rifiuta tutto e nessuna delle due cambia.
func test_rejected_push_keeps_both_rooms() -> void:
	_select_room()
	_perform_inner_gesture(_point_in_room(RIGHT_HALF), Vector2(2.0 * RoomEditor.CELL_SIZE_PIXELS, 0.0))

	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)
	assert_eq(_second_room().cells, RoomEditor.SECOND_ROOM_CELLS)


## Un tocco interrotto riporta entrambe le camere alla forma vera.
func test_canceled_touch_keeps_both_rooms() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(RIGHT_HALF)
	var end: Vector2 = start + Vector2(RoomEditor.CELL_SIZE_PIXELS, 0.0)

	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, end)
	_touch(FIRST_FINGER, end, false, true)

	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)
	assert_eq(_second_room().cells, RoomEditor.SECOND_ROOM_CELLS)


## Seleziona la camera toccando il centro della sua forma attuale.
func _select_room_at_current_shape() -> void:
	var center: Vector2 = _point_in_room(Vector2(0.5, 0.5))
	_touch(FIRST_FINGER, center, true)
	_touch(FIRST_FINGER, center, false)


## Restituisce il centro di una cella, in pixel del nodo.
func _cell_center(cell: Vector2i) -> Vector2:
	return _editor.get_envelope_origin() + (Vector2(cell) + Vector2(0.5, 0.5)) * RoomEditor.CELL_SIZE_PIXELS


## Dà le monete per una camera e attiva la modalità costruzione.
func _enter_build_mode() -> void:
	_editor.session.coins = HotelSession.FIRST_NEW_ROOM_PRICE
	_editor.toggle_build_mode()
	assert_true(_editor.is_building())


## Senza monete la modalità costruzione non si attiva.
func test_build_mode_needs_coins() -> void:
	_editor.toggle_build_mode()

	assert_false(_editor.is_building())


## Attivando la costruzione la selezione sparisce, così le maniglie non coprono le celle libere.
func test_build_mode_deselects_room() -> void:
	_select_room()

	_enter_build_mode()

	assert_false(_editor.is_room_selected())


## Il pulsante premuto di nuovo annulla, senza spendere nulla.
func test_toggle_again_cancels_build_mode() -> void:
	_enter_build_mode()

	_editor.toggle_build_mode()

	assert_false(_editor.is_building())
	assert_eq(_editor.session.coins, HotelSession.FIRST_NEW_ROOM_PRICE)


## Toccando una cella libera si compra la camera, che diventa subito quella selezionata per poterla
## allargare. Il turno non cambia.
func test_tap_on_free_cell_builds_room() -> void:
	_enter_build_mode()

	var cell: Vector2i = Vector2i(0, 7)
	_touch(FIRST_FINGER, _cell_center(cell), true)
	_touch(FIRST_FINGER, _cell_center(cell), false)

	assert_false(_editor.is_building())
	assert_eq(_editor.rooms.size(), 3)
	assert_eq(_editor.room, _editor.rooms[2])
	assert_eq(_editor.room.cells, Rect2i(cell, Vector2i.ONE))
	assert_true(_editor.is_room_selected())
	assert_eq(_editor.session.coins, 0)
	assert_eq(_editor.session.turns_played, 0)


## Dopo l'animazione la camera nuova è disegnata alla sua misura vera.
func test_new_room_grows_to_its_real_size() -> void:
	_enter_build_mode()
	_touch(FIRST_FINGER, _cell_center(Vector2i(0, 7)), true)
	var new_room: Room = _editor.rooms[2]
	var final_rect: Rect2 = _editor._cells_to_pixels(new_room.cells)
	assert_lt(_editor._visual_rects[new_room].size.x, final_rect.size.x)

	await wait_seconds(RoomEditor.SETTLE_SECONDS + ANIMATION_MARGIN_SECONDS)

	assert_eq(_editor._visual_rects[new_room], final_rect)


## La camera nuova si allarga con il gesto normale, gratis.
func test_new_room_can_be_widened_with_gesture() -> void:
	_enter_build_mode()
	_touch(FIRST_FINGER, _cell_center(Vector2i(0, 7)), true)
	_touch(FIRST_FINGER, _cell_center(Vector2i(0, 7)), false)

	var handle: Vector2 = _editor.get_handle_position(Room.MovableSide.RIGHT_WALL) + Vector2(10.0, 0.0)
	_touch(FIRST_FINGER, handle, true)
	assert_true(_editor.is_dragging())
	_move_finger(FIRST_FINGER, handle + Vector2(RoomEditor.CELL_SIZE_PIXELS, 0.0))
	_touch(FIRST_FINGER, handle + Vector2(RoomEditor.CELL_SIZE_PIXELS, 0.0), false)

	assert_eq(_editor.rooms[2].cells, Rect2i(0, 7, 2, 1))
	assert_eq(_editor.session.coins, 0)


## Toccare una camera o fuori dall'involucro annulla soltanto: non si spende nulla.
func test_tap_elsewhere_cancels_build_mode() -> void:
	var points: Array[Vector2] = [_cell_center(RoomEditor.INITIAL_ROOM_CELLS.position), _editor.get_envelope_origin() - Vector2.ONE]

	for point: Vector2 in points:
		_enter_build_mode()
		_touch(FIRST_FINGER, point, true)
		_touch(FIRST_FINGER, point, false)

		assert_false(_editor.is_building())
		assert_eq(_editor.rooms.size(), 2)
		assert_eq(_editor.session.coins, HotelSession.FIRST_NEW_ROOM_PRICE)


## Il tasto Indietro annulla la costruzione prima di tutto il resto.
func test_back_cancels_build_mode() -> void:
	_enter_build_mode()

	assert_true(_editor.handle_back())

	assert_false(_editor.is_building())


## Rifiutare un ospite chiude la costruzione: il turno è andato avanti.
func test_refusing_guest_leaves_build_mode() -> void:
	_enter_build_mode()

	_editor.refuse_current_guest()

	assert_false(_editor.is_building())


## Durante un trascinamento il pulsante Costruisci non fa nulla.
func test_build_button_ignored_during_drag() -> void:
	_editor.session.coins = HotelSession.FIRST_NEW_ROOM_PRICE
	_begin_ceiling_drag()

	_editor.toggle_build_mode()

	assert_false(_editor.is_building())
	assert_true(_editor.is_dragging())


## Allargare una camera deve avvisare l'interfaccia: può occupare l'ultima cella libera.
func test_applied_drag_notifies_session_changed() -> void:
	watch_signals(_editor)
	var handle: Vector2 = _begin_ceiling_drag()
	_move_finger(FIRST_FINGER, handle + ONE_CELL_UP)

	_touch(FIRST_FINGER, handle + ONE_CELL_UP, false)

	assert_signal_emitted(_editor, "session_changed")
