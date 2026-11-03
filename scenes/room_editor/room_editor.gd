class_name RoomEditor
extends Control
## Scena del gesto: si tocca una camera e se ne trascinano i lati.
##
## COSA FA: disegna involucro, griglia e camera con forme segnaposto, riceve i tocchi
## e mostra in tempo reale il risultato previsto. Al rilascio conferma la modifica e
## anima l'assestamento.
## CHI LA USA: la scena principale main.tscn, che la contiene come nodo figlio.
## PERCHÉ È SEPARATA: tiene insieme disegno e tocco. Le regole stanno in Grid e il
## calcolo del gesto in RoomDrag, così si possono provare senza grafica. Questa scena
## non decide mai se una modifica è permessa: lo chiede sempre a loro.
## NOTA GDSCRIPT: «extends Control» indica un nodo adatto all'interfaccia, che riceve i
## tocchi nella funzione _gui_input(). Un nodo è un mattone della scena; la scena è un
## albero di nodi. _draw() è la funzione in cui un nodo disegna sé stesso: Godot la
## richiama solo dopo queue_redraw(), quindi quando nulla cambia non si consuma
## batteria. Un Tween è un oggetto che fa cambiare un valore gradualmente nel tempo.
## COORDINATE: l'origine del nodo è in alto a sinistra; X cresce verso destra e Y verso
## il basso. Le misure della camera sono in pixel a partire dall'angolo in alto a
## sinistra dell'involucro, così non dipendono dalla forma dello schermo.

## Valore di «nessun dito» e di «nessuna maniglia»: gli indici veri partono da zero.
const NONE: int = -1

## Lato di una cella, in pixel dell'area di riferimento. Con 6 colonne lascia 30 pixel
## di margine per lato sui 720 di larghezza.
const CELL_SIZE_PIXELS: float = 110.0
## Celle occupate dalla camera all'avvio: lasciano spazio libero intorno per provare.
const INITIAL_ROOM_CELLS: Rect2i = Rect2i(2, 4, 2, 2)

## Quanti pixel deve percorrere il dito prima che il gesto dall'interno della camera venga
## riconosciuto: sotto questa distanza la direzione non è ancora affidabile.
const GESTURE_RECOGNITION_PIXELS: float = 20.0

## Metà del lato dell'area sensibile di una maniglia, in pixel. L'area totale è 112
## pixel, più dei 96 che valgono 48 dp su un telefono largo circa 360 dp. È più grande
## del disegno, come chiede AGENTS.md, sezione 7. Le maniglie si afferrano solo dalla parte
## fuori dalla camera, perché dentro vale il gesto riconosciuto. Le aree di due maniglie
## vicine possono sovrapporsi: vince quella col centro più vicino al dito.
const HANDLE_TOUCH_HALF_SIZE_PIXELS: float = 56.0
## Lunghezza del disegno della maniglia, in pixel.
const HANDLE_LENGTH_PIXELS: float = 72.0
## Spessore del disegno della maniglia, in pixel.
const HANDLE_THICKNESS_PIXELS: float = 24.0
## Di quanto si ingrandisce la maniglia mentre il dito la tiene: 1 è la misura normale.
const ACTIVE_HANDLE_SCALE: float = 1.25

## Di quanti pixel al massimo si incurva il lato trascinato, tra una cella e l'altra.
const MAX_BEND_PIXELS: float = 18.0
## Quanti tratti dritti compongono ogni lato disegnato: abbastanza da sembrare curvo.
const SEGMENTS_PER_SIDE: int = 12

## Larghezza della sagoma di prova, in celle. Serve a giudicare il gesto: è un ospite
## finto, senza regole; quelli veri arrivano nella fase 5 della scaletta.
const SILHOUETTE_WIDTH_CELLS: float = 0.5
## Altezza della sagoma di prova, in celle: più alta della camera iniziale, così si vede
## la testa uscire dal soffitto finché la camera non viene allungata.
const SILHOUETTE_HEIGHT_CELLS: float = 2.8

## Raggio dell'icona del risultato, in pixel.
const STATUS_RADIUS_PIXELS: float = 36.0
## Distanza dell'icona sopra il dito, in pixel: il dito e la mano arrivano dal basso e
## non devono coprire l'informazione (AGENTS.md, sezione 7).
const STATUS_DISTANCE_ABOVE_FINGER_PIXELS: float = 140.0

## Durata dell'assestamento dopo una modifica valida, in secondi.
const SETTLE_SECONDS: float = 0.55
## Durata del ritorno dopo un rifiuto o un tocco interrotto, in secondi.
const RETURN_SECONDS: float = 0.4
## Durata della comparsa delle maniglie, in secondi.
const HANDLES_APPEAR_SECONDS: float = 0.18

## Colori segnaposto, dalla palette del concept (sezione 9): crema, terracotta e menta.
const ENVELOPE_COLOR: Color = Color(1.0, 0.98, 0.93)
const ENVELOPE_BORDER_COLOR: Color = Color(0.62, 0.55, 0.47)
const GRID_LINE_COLOR: Color = Color(0.62, 0.55, 0.47, 0.25)
const GRID_LINE_DRAG_COLOR: Color = Color(0.62, 0.55, 0.47, 0.55)
const ROOM_COLOR: Color = Color(0.56, 0.82, 0.72)
const ROOM_BORDER_COLOR: Color = Color(0.17, 0.36, 0.32)
const SILHOUETTE_COLOR: Color = Color(0.77, 0.42, 0.28)
const HANDLE_COLOR: Color = Color(0.17, 0.36, 0.32)
const VALID_COLOR: Color = Color(0.09, 0.47, 0.36)
const INVALID_COLOR: Color = Color(0.72, 0.13, 0.13)
const STATUS_BACKGROUND_COLOR: Color = Color(1.0, 1.0, 1.0)

## Spessore delle linee principali, in pixel.
const THICK_LINE_PIXELS: float = 5.0
## Spessore delle linee della griglia, in pixel.
const THIN_LINE_PIXELS: float = 1.5

## La camera mostrata. Gli altri script la leggono soltanto: le modifiche passano da Grid.
var room: Room

## La griglia con le regole.
var _grid: Grid
## true se la camera è selezionata e mostra le maniglie.
var _is_room_selected: bool = false
## Il trascinamento in corso, oppure null se non ce n'è nessuno.
var _drag: RoomDrag = null
## true se un dito ha toccato l'interno della camera e la direzione non è ancora chiara.
var _is_recognizing_gesture: bool = false
## Indice del dito che trascina o di cui si riconosce il gesto, oppure NONE. Ogni dito ha
## un indice diverso.
var _drag_finger_index: int = NONE
## Punto in cui quel dito ha toccato lo schermo, in pixel del nodo.
var _drag_start_position: Vector2 = Vector2.ZERO
## Ultima posizione di quel dito, in pixel del nodo.
var _finger_position: Vector2 = Vector2.ZERO
## Il rettangolo in cui si disegna ora la camera, in pixel dall'angolo dell'involucro.
var _visual_rect: Rect2 = Rect2()
## Curvatura attuale del lato trascinato: direzione e ampiezza, in pixel.
var _bend: Vector2 = Vector2.ZERO
## Il lato che si incurva: resta valido anche durante l'assestamento dopo il rilascio.
var _bent_side: Room.MovableSide = Room.MovableSide.CEILING
## Scala delle maniglie, da 0 (invisibili) a 1 (dimensione piena).
var _handles_scale: float = 0.0
## L'animazione di assestamento in corso, per poterla fermare a un nuovo tocco.
var _settle_tween: Tween = null


## Godot chiama _ready() una sola volta, quando il nodo entra nella scena: qui si crea
## lo stato iniziale.
func _ready() -> void:
	_grid = Grid.new(Envelope.new())
	room = Room.new(INITIAL_ROOM_CELLS)

	# La camera iniziale rispetta le regole per costruzione: se non fosse così sarebbe
	# un errore di programmazione da far notare subito.
	if not _grid.add_room(room):
		push_error("La camera iniziale non rispetta le regole della griglia.")

	_visual_rect = _cells_to_pixels(room.cells)


## Godot chiama _gui_input() per ogni evento di tocco che arriva a questo nodo.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
		accept_event()
	elif event is InputEventScreenDrag:
		_handle_finger_move(event as InputEventScreenDrag)
		accept_event()


## Godot chiama _notification() per gli avvisi di sistema. Se l'app perde il primo piano,
## per una telefonata per esempio, il dito può sparire senza alcun evento di rilascio.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_cancel_drag()
	elif what == NOTIFICATION_RESIZED:
		# La forma dello schermo è cambiata: l'involucro va ricentrato.
		queue_redraw()


## Godot chiama _draw() per disegnare il nodo. L'ordine conta: ciò che è disegnato dopo
## sta sopra.
func _draw() -> void:
	var origin: Vector2 = get_envelope_origin()
	_draw_envelope(origin)
	_draw_room(origin)
	_draw_handles()
	if _drag != null:
		_draw_target_outline(origin)
		_draw_status_icon()


## Restituisce true se un dito sta trascinando un lato.
func is_dragging() -> bool:
	return _drag != null


## Restituisce true se la camera è selezionata.
func is_room_selected() -> bool:
	return _is_room_selected


## Restituisce l'angolo in alto a sinistra dell'involucro, in pixel del nodo: l'involucro
## resta al centro su schermi di forma diversa.
func get_envelope_origin() -> Vector2:
	return (size - _get_envelope_size()) / 2.0


## Restituisce il centro di una maniglia, in pixel del nodo. Con il lato incurvato il
## centro segue la curva, così la maniglia resta attaccata alla parete.
func get_handle_position(side: Room.MovableSide) -> Vector2:
	var center: Vector2 = get_envelope_origin() + _visual_rect.get_center()
	var half_size: Vector2 = _visual_rect.size / 2.0
	var bend: Vector2 = _bend if side == _bent_side else Vector2.ZERO

	match side:
		Room.MovableSide.LEFT_WALL:
			return center + Vector2(-half_size.x, 0.0) + bend
		Room.MovableSide.RIGHT_WALL:
			return center + Vector2(half_size.x, 0.0) + bend
		Room.MovableSide.CEILING:
			return center + Vector2(0.0, -half_size.y) + bend
		_:
			return center + Vector2(0.0, half_size.y) + bend


## Gestisce un dito che tocca o lascia lo schermo.
func _handle_touch(touch: InputEventScreenTouch) -> void:
	# Durante un gesto conta solo il dito che l'ha iniziato: un secondo dito, per esempio
	# quello che regge il telefono, non deve fare nulla.
	if _drag_finger_index != NONE and touch.index != _drag_finger_index:
		return

	if touch.pressed:
		_handle_press(touch)
	elif _drag == null:
		# Il dito si è alzato prima che il gesto fosse riconosciuto: era un semplice tocco.
		_clear_drag()
	elif touch.canceled:
		# Un tocco annullato dal sistema non è una scelta del giocatore: non si conferma.
		_cancel_drag()
	else:
		_finish_drag()


## Decide che cosa significa un dito appena appoggiato.
func _handle_press(touch: InputEventScreenTouch) -> void:
	var room_rect: Rect2 = Rect2(get_envelope_origin() + _visual_rect.position, _visual_rect.size)
	var is_on_room: bool = room_rect.has_point(touch.position)

	# Il primo tocco serve solo a selezionare. Il gesto non parte subito, così in futuro un
	# trascinamento su una camera non selezionata potrà far scorrere l'edificio.
	if not _is_room_selected:
		_set_room_selected(is_on_room)
		return

	# Dentro la camera non si conosce ancora il lato: lo dirà il primo movimento del dito.
	if is_on_room:
		_is_recognizing_gesture = true
		_drag_finger_index = touch.index
		_drag_start_position = touch.position
		return

	var handle: int = _find_handle_at(touch.position)
	if handle == NONE:
		_set_room_selected(false)
	else:
		_begin_drag(handle, touch.index, touch.position)


## Mostra o nasconde le maniglie con una breve animazione.
func _set_room_selected(selected: bool) -> void:
	if selected == _is_room_selected:
		return

	_is_room_selected = selected

	# create_tween() crea un'animazione legata a questo nodo; tween_method() chiama più
	# volte la funzione indicata con un valore che va da quello iniziale a quello finale.
	# TRANS_BACK supera un po' il valore finale e torna indietro, dando un piccolo rimbalzo.
	var target_scale: float = 1.0 if selected else 0.0
	create_tween().tween_method(_set_handles_scale, _handles_scale, target_scale, HANDLES_APPEAR_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Inizia il trascinamento di un lato. finger_index è il dito che lo esegue e start_position
## il punto, in pixel del nodo, da cui si misura lo spostamento.
func _begin_drag(side: Room.MovableSide, finger_index: int, start_position: Vector2) -> void:
	# Se la camera si sta ancora assestando, si riparte dalla sua forma vera.
	_stop_settle_animation()
	_visual_rect = _cells_to_pixels(room.cells)

	_drag = RoomDrag.new(_grid, room, side, CELL_SIZE_PIXELS)
	_is_recognizing_gesture = false
	_drag_finger_index = finger_index
	_drag_start_position = start_position
	_finger_position = start_position
	_bent_side = side
	queue_redraw()


## Aggiorna la camera disegnata mentre il dito si muove.
func _handle_finger_move(finger_move: InputEventScreenDrag) -> void:
	if finger_move.index != _drag_finger_index:
		return

	if _is_recognizing_gesture:
		var movement: Vector2 = finger_move.position - _drag_start_position
		if movement.length() < GESTURE_RECOGNITION_PIXELS:
			return

		# Lo spostamento si misura dal primo tocco, quindi i pixel percorsi durante il
		# riconoscimento non vanno persi e il lato non resta indietro rispetto al dito.
		var room_center: Vector2 = get_envelope_origin() + _cells_to_pixels(room.cells).get_center()
		var side: Room.MovableSide = RoomDrag.choose_side(_drag_start_position, movement, room_center)
		_begin_drag(side, finger_move.index, _drag_start_position)

	_finger_position = finger_move.position
	_drag.update(_finger_position - _drag_start_position)
	_visual_rect = _drag.get_visual_rect()
	_bend = _compute_bend(_drag.offset_pixels, _drag.side)
	queue_redraw()


## Conclude il trascinamento dopo il rilascio del dito: conferma e anima il risultato.
func _finish_drag() -> void:
	var was_applied: bool = _drag.commit().is_valid()
	_clear_drag()

	# TRANS_ELASTIC oscilla come una molla prima di fermarsi; TRANS_BACK torna indietro con
	# un piccolo rimbalzo. La differenza fa sentire se la modifica è stata accettata.
	if was_applied:
		_animate_to_room_shape(SETTLE_SECONDS, Tween.TRANS_ELASTIC)
	else:
		_animate_to_room_shape(RETURN_SECONDS, Tween.TRANS_BACK)


## Annulla il gesto in corso senza modificare la camera. Se il trascinamento non era ancora
## iniziato non c'è nulla da animare.
func _cancel_drag() -> void:
	var was_dragging: bool = _drag != null
	_clear_drag()

	if was_dragging:
		_animate_to_room_shape(RETURN_SECONDS, Tween.TRANS_BACK)


## Dimentica il gesto appena concluso, che fosse un trascinamento o un semplice tocco.
func _clear_drag() -> void:
	_drag = null
	_is_recognizing_gesture = false
	_drag_finger_index = NONE


## Anima il disegno dalla forma attuale alla forma vera della camera. Questa animazione è
## solo estetica: quando parte, la regola ha già deciso.
func _animate_to_room_shape(seconds: float, transition: Tween.TransitionType) -> void:
	_stop_settle_animation()

	_settle_tween = create_tween()
	# set_parallel() fa partire insieme le due animazioni, invece che una dopo l'altra.
	_settle_tween.set_parallel()
	_settle_tween.tween_method(_set_visual_rect, _visual_rect, _cells_to_pixels(room.cells), seconds).set_trans(transition).set_ease(Tween.EASE_OUT)
	_settle_tween.tween_method(_set_bend, _bend, Vector2.ZERO, seconds).set_trans(transition).set_ease(Tween.EASE_OUT)


## Ferma l'assestamento in corso, se c'è, e toglie la curvatura rimasta.
func _stop_settle_animation() -> void:
	if _settle_tween != null:
		_settle_tween.kill()
		_settle_tween = null

	_bend = Vector2.ZERO


## Imposta il rettangolo disegnato. La chiama il Tween durante l'animazione.
func _set_visual_rect(rect: Rect2) -> void:
	_visual_rect = rect
	queue_redraw()


## Imposta la curvatura del lato. La chiama il Tween durante l'animazione.
func _set_bend(bend: Vector2) -> void:
	_bend = bend
	queue_redraw()


## Imposta la scala delle maniglie. La chiama il Tween durante l'animazione.
func _set_handles_scale(handles_scale: float) -> void:
	_handles_scale = handles_scale
	queue_redraw()


## Restituisce il lato della maniglia sotto il dito, oppure NONE. Se le aree di più
## maniglie contengono il punto, sceglie quella con il centro più vicino.
func _find_handle_at(point: Vector2) -> int:
	var best_side: int = NONE
	var best_distance: float = INF

	for side: Room.MovableSide in Room.MovableSide.values():
		var offset: Vector2 = (point - get_handle_position(side)).abs()
		var is_inside: bool = offset.x <= HANDLE_TOUCH_HALF_SIZE_PIXELS and offset.y <= HANDLE_TOUCH_HALF_SIZE_PIXELS

		if is_inside and offset.length() < best_distance:
			best_side = side
			best_distance = offset.length()

	return best_side


## Calcola la curvatura del lato trascinato. Con sin(π × frazione di cella) il lato è
## dritto quando cade esattamente su una cella (seno di 0 e di π) e più incurvato a metà
## strada, senza salti. Si incurva verso la direzione in cui viene tirato.
func _compute_bend(offset_pixels: float, side: Room.MovableSide) -> Vector2:
	var cell_fraction: float = fposmod(absf(offset_pixels), CELL_SIZE_PIXELS) / CELL_SIZE_PIXELS
	var amount: float = MAX_BEND_PIXELS * sin(PI * cell_fraction) * signf(offset_pixels)

	if side == Room.MovableSide.LEFT_WALL or side == Room.MovableSide.RIGHT_WALL:
		return Vector2(amount, 0.0)
	return Vector2(0.0, amount)


## Converte un rettangolo di celle in pixel, misurati dall'angolo dell'involucro.
func _cells_to_pixels(cells: Rect2i) -> Rect2:
	return Rect2(Vector2(cells.position) * CELL_SIZE_PIXELS, Vector2(cells.size) * CELL_SIZE_PIXELS)


## Restituisce le misure dell'involucro in pixel.
func _get_envelope_size() -> Vector2:
	return Vector2(Envelope.PROTOTYPE_WIDTH_CELLS, Envelope.PROTOTYPE_HEIGHT_CELLS) * CELL_SIZE_PIXELS


## Disegna l'involucro e le linee della griglia. Se il dito tenta di uscire, il bordo
## cambia colore e diventa più spesso, per mostrare qual è il limite.
func _draw_envelope(origin: Vector2) -> void:
	var envelope_size: Vector2 = _get_envelope_size()
	draw_rect(Rect2(origin, envelope_size), ENVELOPE_COLOR)

	# Durante il trascinamento le celle si vedono meglio, per aiutare la precisione.
	var line_color: Color = GRID_LINE_DRAG_COLOR if _drag != null else GRID_LINE_COLOR
	for column: int in range(1, Envelope.PROTOTYPE_WIDTH_CELLS):
		var x: float = origin.x + column * CELL_SIZE_PIXELS
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + envelope_size.y), line_color, THIN_LINE_PIXELS)
	for row: int in range(1, Envelope.PROTOTYPE_HEIGHT_CELLS):
		var y: float = origin.y + row * CELL_SIZE_PIXELS
		draw_line(Vector2(origin.x, y), Vector2(origin.x + envelope_size.x, y), line_color, THIN_LINE_PIXELS)

	var is_leaving: bool = _drag != null and _drag.preview.rejection == ResizePreview.Rejection.OUTSIDE_ENVELOPE
	var border_color: Color = INVALID_COLOR if is_leaving else ENVELOPE_BORDER_COLOR
	var border_width: float = THICK_LINE_PIXELS if is_leaving else THIN_LINE_PIXELS
	draw_rect(Rect2(origin, envelope_size), border_color, false, border_width)


## Disegna la camera con il lato incurvato e la sagoma di prova.
func _draw_room(origin: Vector2) -> void:
	var rect: Rect2 = Rect2(origin + _visual_rect.position, _visual_rect.size)
	var outline: PackedVector2Array = _build_room_outline(rect)

	draw_colored_polygon(outline, ROOM_COLOR)
	_draw_silhouette(rect)

	# draw_polyline() non chiude la forma da solo: si ripete il primo punto alla fine.
	outline.append(outline[0])
	draw_polyline(outline, ROOM_BORDER_COLOR, THICK_LINE_PIXELS, true)


## Costruisce il contorno della camera in senso orario, a partire dall'angolo in alto a
## sinistra. Solo il lato trascinato si incurva.
func _build_room_outline(rect: Rect2) -> PackedVector2Array:
	var top_left: Vector2 = rect.position
	var top_right: Vector2 = rect.position + Vector2(rect.size.x, 0.0)
	var bottom_right: Vector2 = rect.end
	var bottom_left: Vector2 = rect.position + Vector2(0.0, rect.size.y)

	var points: PackedVector2Array = PackedVector2Array()
	_append_side_points(points, top_left, top_right, Room.MovableSide.CEILING)
	_append_side_points(points, top_right, bottom_right, Room.MovableSide.RIGHT_WALL)
	_append_side_points(points, bottom_right, bottom_left, Room.MovableSide.FLOOR)
	_append_side_points(points, bottom_left, top_left, Room.MovableSide.LEFT_WALL)
	return points


## Aggiunge i punti di un lato, escluso l'ultimo: è il primo del lato successivo. La
## formula 4 × t × (1 - t) vale 0 agli estremi (t = 0 e t = 1) e 1 a metà: gli angoli
## restano fermi e il centro si sposta di tutta la curvatura.
func _append_side_points(points: PackedVector2Array, from: Vector2, to: Vector2, side: Room.MovableSide) -> void:
	var bend: Vector2 = _bend if side == _bent_side else Vector2.ZERO

	for segment: int in SEGMENTS_PER_SIDE:
		var t: float = float(segment) / SEGMENTS_PER_SIDE
		points.append(from.lerp(to, t) + bend * 4.0 * t * (1.0 - t))


## Disegna la sagoma di prova appoggiata al pavimento: un corpo e una testa rotonda. Non
## viene tagliata dal soffitto, così si vede subito se la camera è troppo bassa.
func _draw_silhouette(room_rect: Rect2) -> void:
	var width: float = SILHOUETTE_WIDTH_CELLS * CELL_SIZE_PIXELS
	var height: float = SILHOUETTE_HEIGHT_CELLS * CELL_SIZE_PIXELS
	var radius: float = width / 2.0
	var center_x: float = room_rect.get_center().x
	var floor_y: float = room_rect.end.y

	draw_rect(Rect2(center_x - radius, floor_y - height + radius, width, height - radius), SILHOUETTE_COLOR)
	draw_circle(Vector2(center_x, floor_y - height + radius), radius, SILHOUETTE_COLOR)


## Disegna le maniglie: tutte se la camera è solo selezionata, solo quella in uso durante
## il trascinamento, perché in quel momento contano contorno, maniglia e risultato.
func _draw_handles() -> void:
	if _drag != null:
		_draw_handle(_drag.side, ACTIVE_HANDLE_SCALE)
		return

	if _handles_scale <= 0.0:
		return

	for side: Room.MovableSide in Room.MovableSide.values():
		_draw_handle(side, _handles_scale)


## Disegna una maniglia con la scala indicata: orizzontale su soffitto e pavimento,
## verticale sulle pareti.
func _draw_handle(side: Room.MovableSide, handle_scale: float) -> void:
	var handle_size: Vector2 = Vector2(HANDLE_LENGTH_PIXELS, HANDLE_THICKNESS_PIXELS) * handle_scale
	if side == Room.MovableSide.LEFT_WALL or side == Room.MovableSide.RIGHT_WALL:
		handle_size = Vector2(handle_size.y, handle_size.x)

	var center: Vector2 = get_handle_position(side)
	draw_rect(Rect2(center - handle_size / 2.0, handle_size), HANDLE_COLOR)


## Disegna il contorno del risultato: dove finirà la camera se la modifica è valida, oppure
## dove tornerà se è rifiutata. Il colore aiuta, ma l'icona dice lo stesso con una forma.
func _draw_target_outline(origin: Vector2) -> void:
	var is_valid: bool = _drag.preview.is_valid()
	var target_cells: Rect2i = _drag.preview.resulting_cells if is_valid else room.cells
	var target_rect: Rect2 = _cells_to_pixels(target_cells)
	target_rect.position += origin

	draw_rect(target_rect, VALID_COLOR if is_valid else INVALID_COLOR, false, THICK_LINE_PIXELS)


## Disegna sopra il dito l'icona del risultato: un segno di spunta se la modifica è
## permessa, una X se è rifiutata. La forma dice l'esito anche a chi non distingue i colori.
func _draw_status_icon() -> void:
	var center: Vector2 = _finger_position + Vector2(0.0, -STATUS_DISTANCE_ABOVE_FINGER_PIXELS)

	# Vicino ai bordi l'icona deve restare dentro lo schermo. clamp() limita un valore
	# tra un minimo e un massimo.
	center.x = clampf(center.x, STATUS_RADIUS_PIXELS, size.x - STATUS_RADIUS_PIXELS)
	center.y = clampf(center.y, STATUS_RADIUS_PIXELS, size.y - STATUS_RADIUS_PIXELS)

	var is_valid: bool = _drag.preview.is_valid()
	var color: Color = VALID_COLOR if is_valid else INVALID_COLOR

	draw_circle(center, STATUS_RADIUS_PIXELS, STATUS_BACKGROUND_COLOR)
	draw_arc(center, STATUS_RADIUS_PIXELS, 0.0, TAU, 32, color, THICK_LINE_PIXELS, true)

	# I punti del simbolo sono frazioni del raggio, così il simbolo cresce con l'icona.
	var unit: float = STATUS_RADIUS_PIXELS
	if is_valid:
		var check: PackedVector2Array = PackedVector2Array([
			center + Vector2(-0.45, 0.0) * unit,
			center + Vector2(-0.1, 0.35) * unit,
			center + Vector2(0.5, -0.35) * unit,
		])
		draw_polyline(check, color, THICK_LINE_PIXELS, true)
	else:
		draw_line(center + Vector2(-0.4, -0.4) * unit, center + Vector2(0.4, 0.4) * unit, color, THICK_LINE_PIXELS, true)
		draw_line(center + Vector2(0.4, -0.4) * unit, center + Vector2(-0.4, 0.4) * unit, color, THICK_LINE_PIXELS, true)
