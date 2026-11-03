extends GutTest
## Test del comportamento della scena del gesto, con tocchi simulati.
##
## COMPORTAMENTO PROTETTO: toccare la camera mostra le maniglie; trascinare una maniglia e
## rilasciare applica la modifica; un secondo dito viene ignorato; un tocco interrotto non
## cambia la camera. La sensazione del gesto non è giudicabile da un test: va provata a mano.
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
	_editor._set_visual_rect(_editor._cells_to_pixels(cells))


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


## Nelle camere da 1×1 le aree delle maniglie si sovrappongono: deve vincere la più vicina.
func test_smallest_room_keeps_handles_separate() -> void:
	_set_room_shape(Rect2i(2, 4, 1, 1))
	_select_room_at_current_shape()

	for side: Room.MovableSide in Room.MovableSide.values():
		assert_eq(_editor._find_handle_at(_editor.get_handle_position(side)), side)


## Seleziona la camera toccando il centro della sua forma attuale.
func _select_room_at_current_shape() -> void:
	var center: Vector2 = _point_in_room(Vector2(0.5, 0.5))
	_touch(FIRST_FINGER, center, true)
	_touch(FIRST_FINGER, center, false)
