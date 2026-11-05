extends GutTest
## Test del comportamento della scena del gesto, con tocchi simulati.
##
## COMPORTAMENTO PROTETTO: toccare una camera mostra le sue maniglie; trascinare una maniglia e
## rilasciare applica la modifica, anche alla camera vicina; un secondo dito viene ignorato; un
## tocco interrotto non cambia le camere. Dal centro la camera si sposta intera (D-030). Ricominciare riporta tutto all'inizio (D-031). La luce si cambia solo a gesto fermo (D-032). In modalità costruzione un tocco su una cella libera compra una camera (D-028). La sensazione del gesto non è giudicabile da un test: va provata a mano.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per avviarli è
## scritto in docs/STATO.md.
## PERCHÉ È SEPARATO: prova la scena completa, mentre test_room_drag.gd prova il calcolo.
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di GUT. Un
## nodo aggiunto con add_child_autofree() entra nella scena di prova e viene eliminato da
## solo a fine test.

## Percorso della scena provata. «res://» indica la cartella principale del progetto.
const SCENE_PATH: String = "res://scenes/room_editor/room_editor.tscn"
## Area sensibile minima di un comando, in pixel: vale 48 dp su un telefono largo 360 dp.
const MIN_TOUCH_PIXELS: float = 96.0
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
const GIRAFFE: Guest = preload("res://tests/data/fixed_giraffe.tres")
## Seme fisso della fila usata nei test: con una sola specie l'ordine è comunque sempre lo stesso.
const TEST_SEED: int = 1
## Punti di prova sulla parte interna delle quattro maniglie, come frazioni delle misure della camera.
const UPPER_HANDLE: Vector2 = Vector2(0.5, 0.08)
const LOWER_HANDLE: Vector2 = Vector2(0.5, 0.92)
const LEFT_HANDLE: Vector2 = Vector2(0.08, 0.5)
const RIGHT_HANDLE: Vector2 = Vector2(0.92, 0.5)
## Il centro della camera, da cui la si sposta intera.
const ROOM_CENTER: Vector2 = Vector2(0.5, 0.5)

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


## Esegue un intero gesto iniziato dentro la camera: tocca, si muove e rilascia.
func _perform_inner_gesture(start: Vector2, movement: Vector2) -> void:
	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, start + movement)
	_touch(FIRST_FINGER, start + movement, false)


## Anche dalla parte interna di una maniglia si muove il suo lato, sia per crescere sia per
## rimpicciolire: la camera non si sposta (D-030).
func test_inner_part_of_handle_moves_its_side() -> void:
	var cell: float = RoomEditor.CELL_SIZE_PIXELS
	var cases: Array[Dictionary] = [
		{"point": UPPER_HANDLE, "move": Vector2(0.0, -cell), "cells": Rect2i(2, 3, 2, 3)},
		{"point": UPPER_HANDLE, "move": Vector2(0.0, cell), "cells": Rect2i(2, 5, 2, 1)},
		{"point": LOWER_HANDLE, "move": Vector2(0.0, cell), "cells": Rect2i(2, 4, 2, 3)},
		{"point": LOWER_HANDLE, "move": Vector2(0.0, -cell), "cells": Rect2i(2, 4, 2, 1)},
		{"point": LEFT_HANDLE, "move": Vector2(-cell, 0.0), "cells": Rect2i(1, 4, 3, 2)},
		{"point": LEFT_HANDLE, "move": Vector2(cell, 0.0), "cells": Rect2i(3, 4, 1, 2)},
		{"point": RIGHT_HANDLE, "move": Vector2(cell, 0.0), "cells": Rect2i(2, 4, 3, 2)},
		{"point": RIGHT_HANDLE, "move": Vector2(-cell, 0.0), "cells": Rect2i(2, 4, 1, 2)},
	]

	_select_room()
	for test_case: Dictionary in cases:
		_perform_inner_gesture(_point_in_room(test_case["point"]), test_case["move"])
		assert_eq(_editor.room.cells, test_case["cells"])
		_set_room_shape(RoomEditor.INITIAL_ROOM_CELLS)


## Finché il dito non si muove abbastanza non deve succedere nulla: tremare non è un gesto.
func test_small_movement_does_not_start_drag() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(UPPER_HANDLE)
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
	var start: Vector2 = _point_in_room(UPPER_HANDLE)

	_touch(FIRST_FINGER, start, true)
	_touch(FIRST_FINGER, start, false)
	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)

	assert_false(_editor.is_dragging())


## Senza selezione il gesto non parte: il primo tocco serve solo a selezionare.
func test_inner_gesture_needs_selected_room() -> void:
	var start: Vector2 = _point_in_room(UPPER_HANDLE)

	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)

	assert_false(_editor.is_dragging())


## Un secondo dito non deve avviare né disturbare il riconoscimento del primo.
func test_second_finger_is_ignored_during_recognition() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(UPPER_HANDLE)
	_touch(FIRST_FINGER, start, true)

	_move_finger(SECOND_FINGER, start + FAR_ABOVE_ENVELOPE)
	assert_false(_editor.is_dragging())

	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)
	_touch(FIRST_FINGER, start + ONE_CELL_UP, false)
	assert_eq(_editor.room.cells, Rect2i(2, 3, 2, 3))


## Se l'app va in pausa durante il riconoscimento, il gesto viene dimenticato.
func test_app_pause_cancels_recognition() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(UPPER_HANDLE)
	_touch(FIRST_FINGER, start, true)

	_editor._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)

	assert_false(_editor.is_dragging())


## Deve funzionare anche sulla camera più piccola, dove le maniglie sono vicine tra loro.
func test_inner_part_of_handle_works_on_smallest_room() -> void:
	_set_room_shape(Rect2i(2, 4, 1, 1))
	_select_room_at_current_shape()

	_perform_inner_gesture(_point_in_room(UPPER_HANDLE), ONE_CELL_UP)

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
	_perform_inner_gesture(_point_in_room(UPPER_HANDLE), ONE_CELL_UP)
	_tap_center_of_active_room()

	assert_eq(_editor.room.guest, GIRAFFE)


## Un trascinamento è gratis: non fa entrare nessuno e non consuma turni (D-026).
func test_drag_does_not_host_guest_or_use_turn() -> void:
	_select_room()

	_perform_inner_gesture(_point_in_room(UPPER_HANDLE), ONE_CELL_UP)

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
	var start: Vector2 = _point_in_room(UPPER_HANDLE)
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
	var start: Vector2 = _point_in_room(RIGHT_HANDLE)
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
	_perform_inner_gesture(_point_in_room(RIGHT_HANDLE), Vector2(-RoomEditor.CELL_SIZE_PIXELS, 0.0))

	assert_eq(_editor.room.cells, Rect2i(2, 4, 1, 2))
	assert_eq(_second_room().cells, RoomEditor.SECOND_ROOM_CELLS)


## Se la vicina diventerebbe inutilizzabile si rifiuta tutto e nessuna delle due cambia.
func test_rejected_push_keeps_both_rooms() -> void:
	_select_room()
	_perform_inner_gesture(_point_in_room(RIGHT_HANDLE), Vector2(2.0 * RoomEditor.CELL_SIZE_PIXELS, 0.0))

	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)
	assert_eq(_second_room().cells, RoomEditor.SECOND_ROOM_CELLS)


## Un tocco interrotto riporta entrambe le camere alla forma vera.
func test_canceled_touch_keeps_both_rooms() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(RIGHT_HANDLE)
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


## Trascinando il centro la camera si sposta intera e la forma resta uguale (D-030).
func test_dragging_center_moves_whole_room() -> void:
	_select_room()

	_perform_inner_gesture(_point_in_room(ROOM_CENTER), Vector2(-2.0, -1.0) * RoomEditor.CELL_SIZE_PIXELS)

	assert_eq(_editor.room.cells, Rect2i(0, 3, 2, 2))
	assert_true(_editor.is_room_selected())


## Spostare è gratis e non consuma il turno, come allargare.
func test_moving_room_costs_nothing() -> void:
	_select_room()
	_editor.session.coins = 7

	_perform_inner_gesture(_point_in_room(ROOM_CENTER), ONE_CELL_UP)

	assert_eq(_editor.session.coins, 7)
	assert_eq(_editor.session.turns_played, 0)


## Un tocco sul centro, senza trascinare, continua a far entrare l'ospite.
func test_tapping_center_still_hosts_guest() -> void:
	_set_room_shape(Rect2i(2, 3, 2, 3))
	_select_room_at_current_shape()

	_tap_center_of_active_room()

	assert_eq(_editor.room.guest, GIRAFFE)


## Sopra un'altra camera lo spostamento è rifiutato: al rilascio torna dov'era, e l'altra non cambia.
func test_move_onto_neighbor_returns_room() -> void:
	_select_room()

	_perform_inner_gesture(_point_in_room(ROOM_CENTER), Vector2(RoomEditor.CELL_SIZE_PIXELS, 0.0))

	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)
	assert_eq(_editor.rooms[1].cells, RoomEditor.SECOND_ROOM_CELLS)


## Durante lo spostamento la vicina resta ferma e l'anteprima segnala chi blocca.
func test_move_preview_shows_blocking_room() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(ROOM_CENTER)
	_touch(FIRST_FINGER, start, true)

	_move_finger(FIRST_FINGER, start + Vector2(RoomEditor.CELL_SIZE_PIXELS, 0.0))

	assert_true(_editor.is_dragging())
	assert_eq(_editor._drag.preview.blocking_room, _editor.rooms[1])
	assert_eq(_editor._visual_rects[_editor.rooms[1]], _editor._cells_to_pixels(RoomEditor.SECOND_ROOM_CELLS))


## Un tocco annullato dal sistema o la pausa dell'app non spostano la camera.
func test_interrupted_move_keeps_room() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(ROOM_CENTER)
	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)

	_touch(FIRST_FINGER, start + ONE_CELL_UP, false, true)

	assert_false(_editor.is_dragging())
	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)

	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)
	_editor._notification(Node.NOTIFICATION_APPLICATION_PAUSED)

	assert_false(_editor.is_dragging())
	assert_eq(_editor.room.cells, RoomEditor.INITIAL_ROOM_CELLS)


## Un secondo dito non deve disturbare lo spostamento.
func test_second_finger_is_ignored_during_move() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(ROOM_CENTER)
	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, start + ONE_CELL_UP)

	_touch(SECOND_FINGER, start, true)
	_move_finger(SECOND_FINGER, start + FAR_ABOVE_ENVELOPE)
	_touch(SECOND_FINGER, start, false)
	_touch(FIRST_FINGER, start + ONE_CELL_UP, false)

	assert_eq(_editor.room.cells, Rect2i(2, 3, 2, 2))


## Durante lo spostamento nessun lato si incurva: la camera resta un rettangolo.
func test_move_does_not_bend_room() -> void:
	_select_room()
	var start: Vector2 = _point_in_room(ROOM_CENTER)
	_touch(FIRST_FINGER, start, true)

	_move_finger(FIRST_FINGER, start + ONE_CELL_UP * NEAR_HALF_CELL_FRACTION)

	assert_true(_editor.is_dragging())
	assert_eq(_editor._bend, Vector2.ZERO)


## La camera da 1 cella deve avere un centro da cui spostarla, nonostante le quattro maniglie.
func test_smallest_room_has_center_for_moving() -> void:
	_set_room_shape(Rect2i(2, 4, 1, 1))
	_select_room_at_current_shape()
	assert_eq(_editor._find_handle_at(_point_in_room(ROOM_CENTER)), RoomEditor.NONE)

	_perform_inner_gesture(_point_in_room(ROOM_CENTER), ONE_CELL_UP)

	assert_eq(_editor.room.cells, Rect2i(2, 3, 1, 1))


## L'area sensibile di ogni maniglia deve restare comoda per un dito: almeno 96 pixel per lato.
func test_handle_touch_area_is_large_enough() -> void:
	assert_gte(RoomEditor.HANDLE_TOUCH_OUTSIDE_PIXELS + RoomEditor.HANDLE_TOUCH_INSIDE_PIXELS, MIN_TOUCH_PIXELS)
	assert_gte(2.0 * RoomEditor.HANDLE_TOUCH_HALF_LENGTH_PIXELS, MIN_TOUCH_PIXELS)


## Ricominciare riporta camere, monete, turni e arrivi all'inizio.
func test_new_game_restores_initial_state() -> void:
	_editor.session.coins = HotelSession.FIRST_NEW_ROOM_PRICE
	_editor.session.build_room(Vector2i(0, 0))
	_editor.refuse_current_guest()
	_editor.session.get_grid().move_room(_editor.rooms[0], Vector2i(0, -1))

	_editor.start_new_game()

	assert_eq(_editor.rooms.size(), HotelSession.STARTING_ROOMS)
	assert_eq(_editor.rooms[0].cells, RoomEditor.INITIAL_ROOM_CELLS)
	assert_eq(_editor.rooms[1].cells, RoomEditor.SECOND_ROOM_CELLS)
	assert_eq(_editor.session.coins, 0)
	assert_eq(_editor.session.turns_played, 0)
	assert_eq(_editor.session.arrivals_left, 1)
	# I gesti devono lavorare sulla griglia nuova, altrimenti le camere non risponderebbero.
	assert_eq(_editor.session.get_grid().get_rooms(), _editor.rooms)
	assert_eq(_editor.room, _editor.rooms[0])


## Ricominciare a metà di un gesto o di una costruzione non lascia niente in sospeso.
func test_new_game_clears_gesture_selection_and_build_mode() -> void:
	_begin_ceiling_drag()
	_move_finger(FIRST_FINGER, _editor.get_handle_position(Room.MovableSide.CEILING) + ONE_CELL_UP)

	_editor.start_new_game()

	assert_false(_editor.is_dragging())
	assert_false(_editor.is_room_selected())
	assert_eq(_editor.rooms[0].cells, RoomEditor.INITIAL_ROOM_CELLS)

	_enter_build_mode()
	_editor.start_new_game()
	assert_false(_editor.is_building())


## Un guadagno ancora sullo schermo non deve far cadere il disegno: le sue camere non esistono più.
func test_new_game_survives_earnings_on_screen() -> void:
	_set_room_shape(Rect2i(2, 3, 2, 3))
	_select_room_at_current_shape()
	_tap_center_of_active_room()

	_editor.start_new_game()
	_editor.queue_redraw()
	await wait_process_frames(2)

	assert_true(_editor._shown_earnings.is_empty())


## Dopo aver ricominciato si gioca normalmente.
func test_new_game_can_be_played() -> void:
	_editor.start_new_game()
	_editor.start_session(GuestQueue.new([GIRAFFE], TEST_SEED))
	_select_room()

	_perform_inner_gesture(_point_in_room(ROOM_CENTER), ONE_CELL_UP)

	assert_eq(_editor.room.cells, Rect2i(2, 3, 2, 2))


## Un secondo dito sul pannello della luce non cambia nulla durante un gesto.
func test_lighting_action_ignored_during_drag() -> void:
	_editor.session.coins = HotelSession.SPECIAL_ROOM_PRICE
	_begin_ceiling_drag()

	_editor.apply_lighting_action(HotelSession.LightingAction.MAKE_DARK)

	assert_eq(_editor.room.lighting, Need.Lighting.NORMAL)
	assert_eq(_editor.session.coins, HotelSession.SPECIAL_ROOM_PRICE)


## Le camere speciali e in lavori devono potersi disegnare, durante un gesto e fuori.
func test_special_rooms_can_be_drawn() -> void:
	_editor.session.coins = 100
	_select_room()
	_editor.apply_lighting_action(HotelSession.LightingAction.MAKE_DARK)
	await wait_process_frames(2)

	_editor.apply_lighting_action(HotelSession.LightingAction.RESTORE_WAIT)
	await wait_process_frames(2)

	assert_true(_editor.room.is_under_works)


## Toccare una camera in lavori non fa entrare l'ospite.
func test_room_under_works_refuses_guest() -> void:
	_editor.session.coins = 100
	_set_room_shape(Rect2i(2, 3, 2, 3))
	_select_room_at_current_shape()
	_editor.apply_lighting_action(HotelSession.LightingAction.MAKE_DARK)
	_editor.apply_lighting_action(HotelSession.LightingAction.RESTORE_WAIT)

	_tap_center_of_active_room()

	assert_null(_editor.room.guest)
	assert_eq(_editor.session.turns_played, 0)


## Dà le monete per la piscina e la costruisce nella cella indicata, con il tocco vero.
func _build_pool_at(cell: Vector2i) -> Room:
	_editor.session.coins = HotelSession.POOL_PRICE
	_editor.toggle_pool_build_mode()
	assert_true(_editor.is_building_pool())
	_touch(FIRST_FINGER, _cell_center(cell), true)
	_touch(FIRST_FINGER, _cell_center(cell), false)
	return _editor.session.get_grid().get_pool()


## Si compra la piscina come una camera: un tocco sul pulsante, uno sulla cella. Nasce selezionata, così
## si può allargare subito.
func test_tap_on_free_cell_builds_pool() -> void:
	var pool: Room = _build_pool_at(Vector2i(0, 7))

	assert_not_null(pool)
	assert_false(_editor.is_building())
	assert_eq(_editor.room, pool)
	assert_true(_editor.is_room_selected())
	assert_true(_editor._painters[pool] is PoolPainter)
	assert_eq(_editor.session.coins, 0)
	await wait_seconds(RoomEditor.SETTLE_SECONDS + ANIMATION_MARGIN_SECONDS)


## Passando da una costruzione all'altra resta attiva l'ultima scelta, senza spendere nulla.
func test_build_mode_switches_between_room_and_pool() -> void:
	_editor.session.coins = HotelSession.POOL_PRICE
	_editor.toggle_build_mode()
	assert_false(_editor.is_building_pool())

	_editor.toggle_pool_build_mode()
	assert_true(_editor.is_building_pool())

	_editor.toggle_pool_build_mode()
	assert_false(_editor.is_building())
	assert_eq(_editor.session.coins, HotelSession.POOL_PRICE)


## Senza monete la piscina non si può scegliere.
func test_pool_build_mode_needs_coins() -> void:
	_editor.toggle_pool_build_mode()

	assert_false(_editor.is_building())


## Toccando la piscina non entra nessuno e l'ospite di turno non vi compare in anteprima.
func test_tap_on_pool_hosts_nobody() -> void:
	var pool: Room = _build_pool_at(Vector2i(0, 7))
	await wait_seconds(RoomEditor.SETTLE_SECONDS + ANIMATION_MARGIN_SECONDS)
	var guest_before: Guest = _editor.session.get_current_guest()

	assert_null(_editor._get_shown_guest(pool))
	_tap_center_of_active_room()

	assert_null(pool.guest)
	assert_eq(_editor.session.get_current_guest(), guest_before)


## La piscina si sposta dal centro con lo stesso gesto delle camere.
func test_pool_moves_with_the_room_gesture() -> void:
	var pool: Room = _build_pool_at(Vector2i(0, 7))
	await wait_seconds(RoomEditor.SETTLE_SECONDS + ANIMATION_MARGIN_SECONDS)
	var start: Vector2 = _cell_center(Vector2i(0, 7))
	var target: Vector2 = _cell_center(Vector2i(0, 5))

	_touch(FIRST_FINGER, start, true)
	_move_finger(FIRST_FINGER, target)
	_touch(FIRST_FINGER, target, false)

	assert_eq(pool.cells, Rect2i(0, 5, 1, 1))
	await wait_seconds(RoomEditor.SETTLE_SECONDS + ANIMATION_MARGIN_SECONDS)


## Una partita nuova parte con i piani iniziali, e il pulsante del prossimo piano sta sopra il tetto,
## senza coprire le celle aperte. È abbastanza grande per il dito.
func test_new_game_shows_storey_button_above_roof() -> void:
	var grid: Grid = _editor.session.get_grid()
	var button: BuildButton = _editor._storey_button
	assert_eq(grid.get_open_storeys(), HotelSession.STARTING_STOREYS)
	assert_true(button.visible)
	assert_eq(button.icon, BuildButton.Icon.STOREY)
	assert_gte(button.size.y, MIN_TOUCH_PIXELS)
	assert_gte(button.size.x, MIN_TOUCH_PIXELS)

	var roof_y: float = _editor.get_envelope_origin().y + grid.get_envelope_cells().position.y * RoomEditor.CELL_SIZE_PIXELS
	assert_lte(button.position.y + button.size.y, roof_y)
	assert_gte(button.position.y, roof_y - RoomEditor.CELL_SIZE_PIXELS)


## Il pulsante compra il piano; senza monete non fa nulla. Il pulsante sale con il tetto.
func test_storey_button_buys_storey_and_moves_up() -> void:
	var grid: Grid = _editor.session.get_grid()
	var button: BuildButton = _editor._storey_button
	var start_y: float = button.position.y
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true

	button._gui_input(touch)
	assert_eq(grid.get_open_storeys(), HotelSession.STARTING_STOREYS)

	_editor.session.coins = HotelSession.FIRST_NEW_STOREY_PRICE
	button._gui_input(touch)

	assert_eq(grid.get_open_storeys(), HotelSession.STARTING_STOREYS + 1)
	assert_eq(_editor.session.coins, 0)
	assert_eq(button.position.y, start_y - RoomEditor.CELL_SIZE_PIXELS)


## Aperti tutti i piani, il pulsante sparisce.
func test_storey_button_hidden_when_all_open() -> void:
	_editor.session.coins = 1000
	while _editor.session.can_build_storey():
		_editor._buy_storey()

	assert_eq(_editor.session.get_grid().get_closed_storeys(), 0)
	assert_false(_editor._storey_button.visible)


## Il pulsante non deve coprire la maniglia di una camera attaccata al tetto; riappare deselezionandola.
func test_storey_button_hidden_when_selected_room_touches_roof() -> void:
	var button: BuildButton = _editor._storey_button
	_select_room()
	assert_true(button.visible, "una riga libera sopra la camera: la maniglia non arriva al pulsante")

	_set_room_shape(Rect2i(2, _editor.session.get_grid().get_envelope_cells().position.y, 2, 3))
	_editor._set_room_selected(false)
	_select_room_at_current_shape()
	assert_false(button.visible)

	_editor._set_room_selected(false)
	assert_true(button.visible)


## Durante un gesto o una costruzione il pulsante non c'è, e chiamarlo non compra nulla.
func test_storey_not_bought_during_gesture_or_build_mode() -> void:
	_editor.session.coins = HotelSession.FIRST_NEW_STOREY_PRICE + HotelSession.FIRST_NEW_ROOM_PRICE
	_editor.toggle_build_mode()
	assert_false(_editor._storey_button.visible)
	_editor.toggle_build_mode()
	assert_true(_editor._storey_button.visible)

	_begin_ceiling_drag()
	assert_false(_editor._storey_button.visible)
	_editor._buy_storey()

	assert_eq(_editor.session.get_grid().get_open_storeys(), HotelSession.STARTING_STOREYS)


## In modalità costruzione una cella di un piano chiuso non si può comprare: il tocco annulla soltanto.
func test_cannot_build_in_closed_storey() -> void:
	_enter_build_mode()

	var cell: Vector2i = Vector2i(0, 0)
	_touch(FIRST_FINGER, _cell_center(cell), true)
	_touch(FIRST_FINGER, _cell_center(cell), false)

	assert_false(_editor.is_building())
	assert_eq(_editor.rooms.size(), HotelSession.STARTING_ROOMS)
	assert_eq(_editor.session.coins, HotelSession.FIRST_NEW_ROOM_PRICE)
