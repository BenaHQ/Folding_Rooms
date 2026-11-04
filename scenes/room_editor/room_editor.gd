class_name RoomEditor
extends Control
## Scena del gesto: si tocca una camera, se ne trascinano i lati dalle maniglie e la si sposta intera
## dal centro (D-030).
##
## COSA FA: disegna involucro, griglia e camere, riceve i tocchi e mostra in tempo reale il
## risultato previsto, anche sulla camera vicina coinvolta. Al rilascio conferma la modifica
## e anima l'assestamento. Mostra gli ospiti: toccando la camera selezionata vi entra l'ospite di
## turno (D-026, D-029). In modalità costruzione segna le celle libere: toccandone
## una si compra una nuova camera (D-028) o la piscina (D-036). Disegna la luce di ogni camera (D-032)
## e, sulle camere attaccate alla piscina, l'icona del bonus, anche per il risultato di un gesto in corso.
## CHI LA USA: la scena principale main.tscn, che la contiene come nodo figlio.
## PERCHÉ È SEPARATA: tiene insieme disegno e tocco. Le regole stanno in Grid e il
## calcolo del gesto in RoomDrag e RoomMove, così si possono provare senza grafica. Questa scena
## non decide mai se una modifica è permessa: lo chiede sempre a loro.
## NOTA GDSCRIPT: «extends Control» indica un nodo adatto all'interfaccia, che riceve i
## tocchi nella funzione _gui_input(). Un nodo è un mattone della scena; la scena è un
## albero di nodi. _draw() è la funzione in cui un nodo disegna sé stesso: Godot la
## richiama solo dopo queue_redraw(), quindi quando nulla cambia il disegno non viene
## ricalcolato. Godot aggiorna comunque lo schermo a ogni fotogramma, salvo diversa
## impostazione del progetto. Un Tween è un oggetto che fa cambiare un valore
## gradualmente nel tempo.
## COORDINATE: l'origine del nodo è in alto a sinistra; X cresce verso destra e Y verso
## il basso. Le misure della camera sono in pixel a partire dall'angolo in alto a
## sinistra dell'involucro, così non dipendono dalla forma dello schermo.

## Lanciato quando la partita cambia: nuovo turno, monete, ospiti, camere.
signal session_changed
## Lanciato quando la modalità costruzione si attiva o si disattiva.
signal build_mode_changed
## Lanciato quando la camera selezionata cambia, o non ce n'è più una.
signal selection_changed

## Valore di «nessun dito» e di «nessuna maniglia»: gli indici veri partono da zero.
const NONE: int = -1

## Lato di una cella, in pixel dell'area di riferimento. Con 6 colonne lascia 30 pixel
## di margine per lato sui 720 di larghezza.
const CELL_SIZE_PIXELS: float = 110.0
## Celle occupate dalla prima camera all'avvio: lasciano spazio libero intorno per provare.
const INITIAL_ROOM_CELLS: Rect2i = Rect2i(2, 4, 2, 2)
## Celle della seconda camera all'avvio: tocca la prima, così le due condividono una parete.
const SECOND_ROOM_CELLS: Rect2i = Rect2i(4, 4, 2, 2)
## Misura di partenza di una camera appena costruita, come frazione di quella vera: da qui cresce
## con un rimbalzo. Non parte da zero, perché il disegno ha bisogno di una forma con un'area.
const NEW_ROOM_START_FRACTION: float = 0.5
## Scarto entro cui due lati disegnati contano come lo stesso muro, in pixel.
const SAME_WALL_TOLERANCE_PIXELS: float = 0.5

## Quanti pixel deve percorrere il dito dentro la camera prima che valga come trascinamento e non
## come semplice tocco, che fa entrare l'ospite: un dito che trema non deve spostare nulla.
const GESTURE_RECOGNITION_PIXELS: float = 20.0

## Area sensibile di una maniglia, più grande del disegno come chiede AGENTS.md, sezione 7. Misura
## 112 pixel lungo il lato e 96 di traverso: 68 fuori dalla camera e 28 dentro. I 96 pixel valgono
## 48 dp su un telefono largo circa 360 dp. La parte dentro è stretta per lasciare un centro da cui
## spostare la camera anche quando misura 1 cella (D-030). Le aree di due maniglie vicine possono
## sovrapporsi: vince quella col centro più vicino al dito.
const HANDLE_TOUCH_HALF_LENGTH_PIXELS: float = 56.0
const HANDLE_TOUCH_OUTSIDE_PIXELS: float = 68.0
const HANDLE_TOUCH_INSIDE_PIXELS: float = 28.0
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

## Raggio delle icone dell'ospite, in pixel.
const GUEST_ICON_RADIUS_PIXELS: float = 28.0
## Distanza tra il centro dell'icona del risultato e quelle dell'ospite, in pixel.
const GUEST_ICON_SPACING_PIXELS: float = 76.0
## Distanza delle icone sopra la camera o sopra la testa dell'ospite, se è più in alto, in pixel,
## quando nessun dito trascina: così le icone non coprono il viso.
const GUEST_ICON_ABOVE_ROOM_PIXELS: float = 40.0
## Durata della reazione di un ospite che entra, in secondi.
const REACTION_SECONDS: float = 0.8
## Forma di partenza della reazione, come scala del corpo: chi sta bene si distende verso
## l'alto e chi non sta bene si affloscia.
const HAPPY_REACTION_SCALE: Vector2 = Vector2(0.8, 1.25)
const SAD_REACTION_SCALE: Vector2 = Vector2(1.15, 0.75)
## Ampiezza dello scuotimento quando un ospite non può entrare, in pixel.
const SHAKE_PIXELS: float = 24.0
## Raggio dell'icona con i turni rimasti, in pixel.
const TURNS_BADGE_RADIUS_PIXELS: float = 22.0
## Distanza del centro di quell'icona dall'angolo in alto a sinistra della camera, in pixel.
const TURNS_BADGE_INSET_PIXELS: float = 34.0
## Spazio tra quell'icona e il numero, in pixel.
const TURNS_TEXT_GAP_PIXELS: float = 4.0
## Dimensione del testo piccolo, per i turni rimasti, in pixel.
const SMALL_FONT_PIXELS: int = 28
## Dimensione del testo dei guadagni, in pixel.
const EARNING_FONT_PIXELS: int = 44
## Larghezza riservata a un numero disegnato, in pixel.
const NUMBER_WIDTH_PIXELS: float = 120.0
## Di quanto scendere per centrare un numero piccolo in altezza, in pixel.
const SMALL_TEXT_BASELINE_PIXELS: float = 10.0
## Durata della comparsa dei guadagni, in secondi.
const EARNING_SECONDS: float = 1.1
## Di quanti pixel sale il guadagno durante la comparsa.
const EARNING_RISE_PIXELS: float = 70.0

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
## La sagoma è semitrasparente: deve mostrare lo spazio occupato senza nascondere la camera.
const SILHOUETTE_COLOR: Color = Color(0.77, 0.42, 0.28, 0.55)
const HANDLE_COLOR: Color = Color(0.17, 0.36, 0.32)
const VALID_COLOR: Color = Color(0.09, 0.47, 0.36)
const INVALID_COLOR: Color = Color(0.72, 0.13, 0.13)
const STATUS_BACKGROUND_COLOR: Color = Color(1.0, 1.0, 1.0)

## Segno sulle celle libere in modalità costruzione: sfondo, margine dal bordo della cella in pixel
## e raggio del simbolo «+» in pixel.
const BUILD_CELL_COLOR: Color = Color(0.09, 0.47, 0.36, 0.14)
const BUILD_CELL_INSET_PIXELS: float = 8.0
const BUILD_MARKER_RADIUS_PIXELS: float = 22.0

## Velo disegnato sopra l'interno delle camere speciali e di quelle in lavori. Sta sotto l'ospite.
const DARK_ROOM_TINT: Color = Color(0.06, 0.07, 0.2, 0.62)
const BRIGHT_ROOM_TINT: Color = Color(1.0, 0.9, 0.35, 0.3)
const WORKS_ROOM_TINT: Color = Color(0.45, 0.43, 0.42, 0.55)
## Raggio dell'icona della luce nell'angolo in alto a destra di una camera, in pixel.
const LIGHTING_BADGE_RADIUS_PIXELS: float = 22.0

## Raggio dell'icona della piscina nell'angolo in basso a sinistra di una camera, in pixel.
const POOL_BADGE_RADIUS_PIXELS: float = 22.0
## Spessore della barra su quell'icona quando l'ospite non riceve il bonus, in pixel.
const POOL_BADGE_STRIKE_PIXELS: float = 5.0

## Spessore delle linee principali, in pixel.
const THICK_LINE_PIXELS: float = 5.0
## Spessore delle linee della griglia, in pixel.
const THIN_LINE_PIXELS: float = 1.5

## Tutte le camere, nell'ordine in cui sono state create.
var rooms: Array[Room] = []
## La camera attiva: quella selezionata, oppure l'ultima usata. Gli altri script la leggono
## soltanto: le modifiche passano da Grid.
var room: Room
## La partita in corso: fila degli ospiti, turni e monete.
var session: HotelSession

## La griglia con le regole.
var _grid: Grid
## true se la camera è selezionata e mostra le maniglie.
var _is_room_selected: bool = false
## Il gesto in corso, sia un lato sia l'intera camera, oppure null se non ce n'è nessuno.
var _drag: RoomGesture = null
## true se un dito ha toccato l'interno della camera e non si sa ancora se è un tocco o un trascinamento.
var _is_recognizing_gesture: bool = false
## La maniglia su cui si è appoggiato quel dito dentro la camera, oppure NONE se è nel centro.
var _pressed_handle: int = NONE
## Indice del dito che trascina o di cui si riconosce il gesto, oppure NONE. Ogni dito ha
## un indice diverso.
var _drag_finger_index: int = NONE
## Punto in cui quel dito ha toccato lo schermo, in pixel del nodo.
var _drag_start_position: Vector2 = Vector2.ZERO
## Ultima posizione di quel dito, in pixel del nodo.
var _finger_position: Vector2 = Vector2.ZERO
## Il rettangolo in cui si disegna ora ogni camera, in pixel dall'angolo dell'involucro. Un
## Dictionary associa a ogni chiave, qui una camera, un valore.
var _visual_rects: Dictionary[Room, Rect2] = {}
## Curvatura attuale del lato trascinato: direzione e ampiezza, in pixel.
var _bend: Vector2 = Vector2.ZERO
## Il lato che si incurva: resta valido anche durante l'assestamento dopo il rilascio.
var _bent_side: Room.MovableSide = Room.MovableSide.CEILING
## Scala delle maniglie, da 0 (invisibili) a 1 (dimensione piena).
var _handles_scale: float = 0.0
## L'animazione di assestamento in corso, per poterla fermare a un nuovo tocco.
var _settle_tween: Tween = null
## La camera il cui ospite sta reagendo, oppure null.
var _reacting_room: Room = null
## Scala attuale del corpo dell'ospite che reagisce: 1 è la misura normale.
var _reaction_scale: Vector2 = Vector2.ONE
## Spostamento orizzontale attuale dell'ospite che non può entrare, in pixel.
var _shake_offset_pixels: float = 0.0
## I guadagni dell'ultimo turno, da mostrare sopra le camere.
var _shown_earnings: Dictionary[Room, int] = {}
## Avanzamento della comparsa dei guadagni: da 0 (appena iniziata) a 1 (finita).
var _earning_progress: float = 1.0
## Chi disegna l'interno e il muro di ogni camera (prova di stile, D-018).
var _painters: Dictionary[Room, RoomPainter] = {}
## true se il prossimo tocco serve a scegliere dove costruire una camera.
var _is_building: bool = false
## Che cosa costruisce quel tocco: NONE per una camera, oppure un servizio comune.
var _build_facility: Room.Facility = Room.Facility.NONE


## Godot chiama _ready() una sola volta, quando il nodo entra nella scena: qui si crea
## lo stato iniziale.
func _ready() -> void:
	# Le immagini di RoomPainter sono piccole e devono ripetersi invece di fermarsi al bordo.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	start_new_game()


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
	if _is_building:
		_draw_build_cells(origin)

	# Ciò che è disegnato dopo sta sopra: la camera attiva copre la vicina.
	for other_room: Room in rooms:
		if other_room != room:
			_draw_room(origin, other_room)
	_draw_room(origin, room)

	_draw_handles()
	if _drag != null:
		_draw_target_outline(origin)
		_draw_status_icon()
	_draw_guest_icons(origin)
	_draw_earnings(origin)


## Restituisce true se un dito sta trascinando un lato o l'intera camera.
func is_dragging() -> bool:
	return _drag != null


## Restituisce true se una camera è selezionata: è sempre quella attiva, room.
func is_room_selected() -> bool:
	return _is_room_selected


## Restituisce la camera selezionata, oppure null se non ce n'è nessuna.
func get_selected_room() -> Room:
	return room if _is_room_selected else null


## Applica una modifica alla luce della camera selezionata. Durante un gesto non fa nulla, come gli
## altri pulsanti. HotelSession decide se è possibile e la fa pagare.
func apply_lighting_action(action: int) -> void:
	if _drag != null or _is_recognizing_gesture or not _is_room_selected:
		return

	if session.apply_lighting_action(room, action as HotelSession.LightingAction):
		session_changed.emit()
		queue_redraw()


## Restituisce true se il prossimo tocco serve a scegliere dove costruire una camera.
func is_building() -> bool:
	return _is_building


## Restituisce true se il prossimo tocco serve a scegliere dove costruire la piscina.
func is_building_pool() -> bool:
	return _is_building and _build_facility == Room.Facility.POOL


## Attiva o disattiva la costruzione di una camera.
func toggle_build_mode() -> void:
	_toggle_build(Room.Facility.NONE, session.can_build_room())


## Attiva o disattiva la costruzione della piscina.
func toggle_pool_build_mode() -> void:
	_toggle_build(Room.Facility.POOL, session.can_build_pool())


## Ricomincia da zero: solo le camere iniziali, nessuna moneta e una fila nuova. Interrompe il gesto
## in corso e dimentica ciò che resta sullo schermo della partita precedente. Non tocca il
## salvataggio: è compito di chi chiama.
func start_new_game() -> void:
	_clear_drag()
	_stop_settle_animation()
	_set_build_mode(false)
	_set_room_selected(false)
	_bend = Vector2.ZERO
	_shown_earnings = {}
	_reacting_room = null

	_grid = Grid.new(Envelope.new())
	rooms.clear()
	_painters.clear()
	_visual_rects.clear()
	_add_initial_room(INITIAL_ROOM_CELLS)
	_add_initial_room(SECOND_ROOM_CELLS)
	room = rooms[0]

	# randi() dà un numero casuale: ogni partita ha un ordine di arrivo diverso.
	start_session(GuestQueue.new(GuestQueue.PROTOTYPE_GUESTS, randi(), GuestQueue.LIGHT_GUESTS))
	queue_redraw()


## Inizia una partita con la fila indicata. Le camere restano come sono.
func start_session(queue: GuestQueue) -> void:
	session = HotelSession.new(_grid, queue)
	session_changed.emit()


## Sostituisce camere e partita con una partita ricaricata da un salvataggio. Va chiamata all'avvio,
## prima di qualsiasi gesto. Il salvataggio contiene almeno una camera: lo controlla HotelSession.
func restore_session(saved_session: HotelSession) -> void:
	_grid = saved_session.get_grid()
	rooms.clear()
	_painters.clear()
	_visual_rects.clear()

	for saved_room: Room in _grid.get_rooms():
		_show_room(saved_room)
	room = rooms[0]

	session = saved_session
	session_changed.emit()
	queue_redraw()


## Gestisce il tasto Indietro, che annulla l'azione in corso: prima la costruzione o il gesto, poi
## la selezione. Restituisce true se c'era qualcosa da annullare, false se il tasto resta da gestire
## a chi chiama.
func handle_back() -> bool:
	if _is_building:
		_set_build_mode(false)
		return true

	if _drag != null or _is_recognizing_gesture:
		_cancel_drag()
		return true

	if _is_room_selected:
		_set_room_selected(false)
		return true

	return false


## Rifiuta l'ospite di turno. Durante un trascinamento non fa nulla: un secondo
## dito sul pulsante non deve cambiare la partita mentre il primo sposta una parete.
func refuse_current_guest() -> void:
	if _drag != null:
		return

	_set_build_mode(false)
	_apply_turn_report(session.refuse_current_guest(), null)


## Restituisce l'angolo in alto a sinistra dell'involucro, in pixel del nodo: l'involucro
## resta al centro su schermi di forma diversa.
func get_envelope_origin() -> Vector2:
	return (size - _get_envelope_size()) / 2.0


## Restituisce il centro di una maniglia, in pixel del nodo. Con il lato incurvato il
## centro segue la curva, così la maniglia resta attaccata alla parete.
func get_handle_position(side: Room.MovableSide) -> Vector2:
	var active_rect: Rect2 = _visual_rects[room]
	var center: Vector2 = get_envelope_origin() + active_rect.get_center()
	var half_size: Vector2 = active_rect.size / 2.0
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


## Crea una camera iniziale. La posizione rispetta le regole per costruzione: se non fosse
## così sarebbe un errore di programmazione da far notare subito.
func _add_initial_room(cells: Rect2i) -> void:
	var new_room: Room = Room.new(cells)
	if not _grid.add_room(new_room):
		push_error("Una camera iniziale non rispetta le regole della griglia.")
		return

	_show_room(new_room)


## Aggiunge una camera già presente nella griglia a quelle disegnate. Le camere si alternano tra due
## aspetti in base alla loro posizione nell'elenco, così l'aspetto non cambia dopo un salvataggio. La
## piscina ha il suo.
func _show_room(new_room: Room) -> void:
	var is_even_position: bool = rooms.size() % 2 == 0
	if new_room.is_facility():
		_painters[new_room] = PoolPainter.new()
	elif is_even_position:
		_painters[new_room] = RoomPainter.new()
	else:
		_painters[new_room] = RoomPainter.new(RoomPainter.ROSE_WALLPAPER_LIGHT, RoomPainter.ROSE_WALLPAPER_DARK, RoomPainter.ROSE_WAINSCOT_COLOR)
	_visual_rects[new_room] = _cells_to_pixels(new_room.cells)
	rooms.append(new_room)


## Gestisce un dito che tocca o lascia lo schermo.
func _handle_touch(touch: InputEventScreenTouch) -> void:
	# Durante un gesto conta solo il dito che l'ha iniziato: un secondo dito, per esempio
	# quello che regge il telefono, non deve fare nulla.
	if _drag_finger_index != NONE and touch.index != _drag_finger_index:
		return

	if touch.pressed:
		_handle_press(touch)
	elif _drag == null:
		# Il dito si è alzato prima che il gesto fosse riconosciuto: era un semplice tocco. Se
		# era sulla camera selezionata, serve a far entrare l'ospite di turno.
		var was_tap_on_room: bool = _is_recognizing_gesture and not touch.canceled
		_clear_drag()
		if was_tap_on_room:
			_try_host_current_guest()
	elif touch.canceled:
		# Un tocco annullato dal sistema non è una scelta del giocatore: non si conferma.
		_cancel_drag()
	else:
		_finish_drag()


## Decide che cosa significa un dito appena appoggiato.
func _handle_press(touch: InputEventScreenTouch) -> void:
	if _is_building:
		_handle_build_press(touch.position)
		return

	var touched_room: Room = _find_room_at(touch.position)

	# Il primo tocco serve solo a selezionare. Il gesto non parte subito, così in futuro un
	# trascinamento su una camera non selezionata potrà far scorrere l'edificio.
	if not _is_room_selected:
		if touched_room != null:
			_select_room(touched_room)
		return

	# Dentro la camera non si sa ancora se è un tocco o un trascinamento: lo dirà il dito. Il punto
	# toccato dice già che cosa trascinerebbe: la parte interna di una maniglia oppure il centro.
	if touched_room == room:
		_is_recognizing_gesture = true
		_pressed_handle = _find_handle_at(touch.position)
		_drag_finger_index = touch.index
		_drag_start_position = touch.position
		return

	# Le maniglie della camera attiva sporgono sopra la vicina e hanno la precedenza su di essa.
	var handle: int = _find_handle_at(touch.position)
	if handle != NONE:
		_begin_drag(handle, touch.index, touch.position)
	elif touched_room != null:
		_select_room(touched_room)
	else:
		_set_room_selected(false)


## Gestisce un tocco in modalità costruzione, che finisce comunque qui. Su una cella libera compra
## la camera o la piscina; altrove annulla soltanto. HotelSession decide se si può costruire. point è
## in pixel.
func _handle_build_press(point: Vector2) -> void:
	var is_pool: bool = is_building_pool()
	_set_build_mode(false)

	# floor() arrotonda verso il basso: ogni punto di una cella dà il numero di quella cella, e un
	# punto a sinistra o sopra l'involucro dà un numero negativo, che le regole rifiutano.
	var cell: Vector2i = Vector2i(((point - get_envelope_origin()) / CELL_SIZE_PIXELS).floor())
	var new_room: Room = session.build_pool(cell) if is_pool else session.build_room(cell)
	if new_room == null:
		return

	_show_room(new_room)
	_select_room(new_room)
	session_changed.emit()

	# La camera nasce più piccola, attorno al centro della cella, e cresce con un rimbalzo.
	var final_rect: Rect2 = _visual_rects[new_room]
	_visual_rects[new_room] = final_rect.grow(-final_rect.size.x * (1.0 - NEW_ROOM_START_FRACTION) / 2.0)
	_animate_to_room_shape(SETTLE_SECONDS, Tween.TRANS_ELASTIC)


## Attiva o disattiva la costruzione di ciò che è indicato da facility. Si attiva solo se can_build è
## true, e ripremendo il pulsante della stessa costruzione si annulla. Durante un gesto non fa nulla: un
## secondo dito sul pulsante non deve interrompere il primo.
func _toggle_build(facility: Room.Facility, can_build: bool) -> void:
	if _drag != null or _is_recognizing_gesture:
		return

	if _is_building and _build_facility == facility:
		_set_build_mode(false)
	elif can_build:
		# Le maniglie coprirebbero le celle libere vicine alla camera.
		_set_room_selected(false)
		_set_build_mode(true, facility)


## Attiva o disattiva la modalità costruzione e lo fa sapere all'interfaccia. facility è ciò che si
## costruisce: conta solo se active è true.
func _set_build_mode(active: bool, facility: Room.Facility = Room.Facility.NONE) -> void:
	if active == _is_building and facility == _build_facility:
		return

	_is_building = active
	_build_facility = facility
	build_mode_changed.emit()
	queue_redraw()


## Prova a far entrare l'ospite di turno nella camera attiva. Se non può, lo scuote: il motivo si
## legge già dalla sua icona. HotelSession decide; questa funzione mostra soltanto il risultato.
func _try_host_current_guest() -> void:
	# Toccare un servizio comune non è un tentativo di ospitare: nessuno può entrarci.
	if room.is_facility():
		return

	var report: TurnReport = session.host_current_guest(room)

	if report == null:
		create_tween().tween_method(_set_shake_offset, SHAKE_PIXELS, 0.0, RETURN_SECONDS).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		_apply_turn_report(report, room)


## Mostra il risultato dell'arrivo di un ospite e, se la giornata è finita, i guadagni. hosting_room è la camera in cui un ospite è appena
## entrato, oppure null se l'ospite è stato rifiutato.
func _apply_turn_report(report: TurnReport, hosting_room: Room) -> void:
	session_changed.emit()

	# Un ospite che resta un solo turno è già partito: non c'è nessuno che possa reagire.
	if hosting_room != null and hosting_room.guest != null:
		_play_reaction(hosting_room)

	# Si paga solo a fine giornata. A giornata in corso il resoconto è vuoto: l'animazione dei guadagni
	# precedenti non va interrotta.
	if not report.earnings.is_empty():
		_shown_earnings = report.earnings
		create_tween().tween_method(_set_earning_progress, 0.0, 1.0, EARNING_SECONDS)
	queue_redraw()


## Imposta l'avanzamento dei guadagni. La chiama il Tween durante l'animazione.
func _set_earning_progress(value: float) -> void:
	_earning_progress = value
	queue_redraw()


## Anima la reazione dell'ospite appena entrato, diversa se sta bene oppure no (D-019).
func _play_reaction(target_room: Room) -> void:
	var is_happy: bool = target_room.guest.need.evaluate_in_room(target_room.cells.size, target_room.lighting) == Need.Fit.COMFORTABLE
	var start_scale: Vector2 = HAPPY_REACTION_SCALE if is_happy else SAD_REACTION_SCALE
	var transition: Tween.TransitionType = Tween.TRANS_ELASTIC if is_happy else Tween.TRANS_SINE

	_reacting_room = target_room
	create_tween().tween_method(_set_reaction_scale, start_scale, Vector2.ONE, REACTION_SECONDS).set_trans(transition).set_ease(Tween.EASE_OUT)


## Imposta la scala della reazione. La chiama il Tween durante l'animazione.
func _set_reaction_scale(value: Vector2) -> void:
	_reaction_scale = value
	queue_redraw()


## Imposta lo scuotimento. La chiama il Tween durante l'animazione.
func _set_shake_offset(value: float) -> void:
	_shake_offset_pixels = value
	queue_redraw()


## Restituisce l'ospite da mostrare in una camera: il suo, oppure quello di turno se la camera è
## selezionata e libera. Può essere null.
func _get_shown_guest(target_room: Room) -> Guest:
	if target_room.guest != null:
		return target_room.guest

	if target_room == room and _is_room_selected and not target_room.is_facility():
		return session.get_current_guest()

	return null


## Restituisce le celle su cui giudicare come starebbe l'ospite: durante un gesto valido, quelle
## previste, così il viso cambia mentre il dito si muove.
func _get_displayed_cells(target_room: Room) -> Rect2i:
	if _drag != null and _drag.preview.is_valid():
		if target_room == room:
			return _drag.preview.resulting_cells
		for change: RoomChange in _drag.preview.neighbor_changes:
			if change.room == target_room:
				return change.resulting_cells

	return target_room.cells


## Rende attiva una camera e ne fa comparire le maniglie.
func _select_room(target_room: Room) -> void:
	room = target_room
	_is_room_selected = false
	_handles_scale = 0.0
	_set_room_selected(true)


## Restituisce la camera disegnata sotto un punto, oppure null. La camera attiva viene
## controllata per prima perché è disegnata sopra le altre.
func _find_room_at(point: Vector2) -> Room:
	if _is_point_on_room(point, room):
		return room

	for other_room: Room in rooms:
		if _is_point_on_room(point, other_room):
			return other_room

	return null


## Restituisce true se il punto, in pixel del nodo, cade sul disegno della camera.
func _is_point_on_room(point: Vector2, target_room: Room) -> bool:
	var rect: Rect2 = _visual_rects[target_room]
	return Rect2(get_envelope_origin() + rect.position, rect.size).has_point(point)


## Mostra o nasconde le maniglie con una breve animazione.
func _set_room_selected(selected: bool) -> void:
	if selected == _is_room_selected:
		return

	_is_room_selected = selected
	selection_changed.emit()

	# create_tween() crea un'animazione legata a questo nodo; tween_method() chiama più
	# volte la funzione indicata con un valore che va da quello iniziale a quello finale.
	# TRANS_BACK supera un po' il valore finale e torna indietro, dando un piccolo rimbalzo.
	var target_scale: float = 1.0 if selected else 0.0
	create_tween().tween_method(_set_handles_scale, _handles_scale, target_scale, HANDLES_APPEAR_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Inizia il trascinamento di un lato. finger_index è il dito che lo esegue e start_position
## il punto, in pixel del nodo, da cui si misura lo spostamento.
func _begin_drag(side: Room.MovableSide, finger_index: int, start_position: Vector2) -> void:
	_bent_side = side
	_start_gesture(RoomDrag.new(_grid, room, side, CELL_SIZE_PIXELS), finger_index, start_position)


## Inizia un gesto. Se la camera si sta ancora assestando, si riparte dalla sua forma vera, con i
## lati dritti. finger_index è il dito che lo esegue e start_position il punto di partenza, in pixel.
func _start_gesture(gesture: RoomGesture, finger_index: int, start_position: Vector2) -> void:
	_stop_settle_animation()
	for each_room: Room in rooms:
		_visual_rects[each_room] = _cells_to_pixels(each_room.cells)
	_bend = Vector2.ZERO

	_drag = gesture
	_is_recognizing_gesture = false
	_drag_finger_index = finger_index
	_drag_start_position = start_position
	_finger_position = start_position
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
		# riconoscimento non vanno persi e il disegno non resta indietro rispetto al dito.
		if _pressed_handle != NONE:
			_begin_drag(_pressed_handle, finger_move.index, _drag_start_position)
		else:
			_start_gesture(RoomMove.new(_grid, room, CELL_SIZE_PIXELS), finger_move.index, _drag_start_position)

	_finger_position = finger_move.position
	_drag.update(_finger_position - _drag_start_position)
	_visual_rects[room] = _drag.get_visual_rect()
	for other_room: Room in rooms:
		if other_room != room:
			_visual_rects[other_room] = _drag.get_neighbor_visual_rect(other_room)
	# Solo il lato trascinato si incurva: una camera spostata intera resta dritta.
	if _drag is RoomDrag:
		var side_drag: RoomDrag = _drag as RoomDrag
		_bend = _compute_bend(side_drag.offset_pixels, side_drag.side)
	queue_redraw()


## Conclude il trascinamento dopo il rilascio del dito: conferma e anima il risultato.
func _finish_drag() -> void:
	var was_applied: bool = _drag.commit().is_valid()
	_clear_drag()

	# TRANS_ELASTIC oscilla come una molla prima di fermarsi; TRANS_BACK torna indietro con
	# un piccolo rimbalzo. La differenza fa sentire se la modifica è stata accettata.
	if was_applied:
		# Allargare una camera può occupare l'ultima cella libera: l'interfaccia deve saperlo.
		session_changed.emit()
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
	_pressed_handle = NONE
	_drag_finger_index = NONE


## Anima il disegno dalla forma attuale alla forma vera delle camere. Questa animazione è
## solo estetica: quando parte, la regola ha già deciso.
func _animate_to_room_shape(seconds: float, transition: Tween.TransitionType) -> void:
	_stop_settle_animation()

	_settle_tween = create_tween()
	# set_parallel() fa partire insieme le due animazioni, invece che una dopo l'altra.
	_settle_tween.set_parallel()
	for each_room: Room in rooms:
		# bind() aggiunge un parametro fisso alla chiamata: il Tween passa il rettangolo e bind
		# aggiunge la camera a cui appartiene.
		_settle_tween.tween_method(_set_visual_rect.bind(each_room), _visual_rects[each_room], _cells_to_pixels(each_room.cells), seconds).set_trans(transition).set_ease(Tween.EASE_OUT)
	_settle_tween.tween_method(_set_bend, _bend, Vector2.ZERO, seconds).set_trans(transition).set_ease(Tween.EASE_OUT)


## Ferma l'assestamento in corso, se c'è. La curvatura resta dov'è: chi chiama decide se
## azzerarla, come un nuovo trascinamento, o se animarla, come il rilascio del dito.
func _stop_settle_animation() -> void:
	if _settle_tween != null:
		_settle_tween.kill()
		_settle_tween = null


## Imposta il rettangolo disegnato di una camera. La chiama il Tween durante l'animazione.
func _set_visual_rect(rect: Rect2, target_room: Room) -> void:
	_visual_rects[target_room] = rect
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
		var offset: Vector2 = point - get_handle_position(side)
		var outward: Vector2 = _get_outward_direction(side)
		# dot() misura quanto un vettore va nella direzione di un altro: qui, quanto il punto è fuori
		# dalla camera, con un valore negativo se è dentro. Il resto è la distanza lungo il lato.
		var distance_outward: float = offset.dot(outward)
		var distance_along: float = absf(offset.dot(outward.orthogonal()))
		var is_inside: bool = distance_along <= HANDLE_TOUCH_HALF_LENGTH_PIXELS and distance_outward <= HANDLE_TOUCH_OUTSIDE_PIXELS and distance_outward >= -HANDLE_TOUCH_INSIDE_PIXELS

		if is_inside and offset.length() < best_distance:
			best_side = side
			best_distance = offset.length()

	return best_side


## Restituisce la direzione in cui un lato guarda fuori dalla camera. In Godot la Y cresce verso il
## basso, quindi il soffitto guarda verso Y negative.
func _get_outward_direction(side: Room.MovableSide) -> Vector2:
	match side:
		Room.MovableSide.LEFT_WALL:
			return Vector2.LEFT
		Room.MovableSide.RIGHT_WALL:
			return Vector2.RIGHT
		Room.MovableSide.CEILING:
			return Vector2.UP
		_:
			return Vector2.DOWN


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


## Segna le celle dove si può costruire: uno sfondo e il simbolo «+», così il segno non dipende solo
## dal colore. Quali celle sono libere lo decide Grid.
func _draw_build_cells(origin: Vector2) -> void:
	for cell: Vector2i in _grid.get_free_cells():
		var rect: Rect2 = Rect2(origin + Vector2(cell) * CELL_SIZE_PIXELS, Vector2.ONE * CELL_SIZE_PIXELS)
		draw_rect(rect.grow(-BUILD_CELL_INSET_PIXELS), BUILD_CELL_COLOR)
		if is_building_pool():
			GuestPainter.draw_pool_icon(self, rect.get_center(), BUILD_MARKER_RADIUS_PIXELS)
		else:
			GuestPainter.draw_plus_icon(self, rect.get_center(), BUILD_MARKER_RADIUS_PIXELS)


## Disegna una camera con l'eventuale lato incurvato. Interno e muro sono compito del suo
## RoomPainter. L'ospite sta tra i due, così i suoi piedi restano dietro il muro.
func _draw_room(origin: Vector2, target_room: Room) -> void:
	var visual_rect: Rect2 = _visual_rects[target_room]
	var rect: Rect2 = Rect2(origin + visual_rect.position, visual_rect.size)
	var outline: PackedVector2Array = _build_room_outline(rect, _get_bent_side_of(target_room))
	var painter: RoomPainter = _painters[target_room]

	painter.paint_interior(self, outline, rect, origin)
	_draw_room_tint(outline, target_room)
	_draw_room_guest(rect, target_room)
	painter.paint_frame(self, outline)
	_draw_lighting_badge(rect, target_room)
	_draw_pool_badge(rect, target_room)

	if target_room.guest != null:
		_draw_turns_badge(rect, target_room.turns_left)


## Disegna il velo che dà alla camera la sua luce. Una camera normale non ne ha.
func _draw_room_tint(outline: PackedVector2Array, target_room: Room) -> void:
	if target_room.is_under_works:
		draw_colored_polygon(outline, WORKS_ROOM_TINT)
	elif target_room.lighting == Need.Lighting.DARK:
		draw_colored_polygon(outline, DARK_ROOM_TINT)
	elif target_room.lighting == Need.Lighting.BRIGHT:
		draw_colored_polygon(outline, BRIGHT_ROOM_TINT)


## Disegna nell'angolo in alto a destra l'icona della luce o dei lavori: lo stato della camera si legge
## da una forma, non solo dal colore. Una camera normale non ne ha bisogno.
func _draw_lighting_badge(room_rect: Rect2, target_room: Room) -> void:
	var center: Vector2 = room_rect.position + Vector2(room_rect.size.x - TURNS_BADGE_INSET_PIXELS, TURNS_BADGE_INSET_PIXELS)

	if target_room.is_under_works:
		GuestPainter.draw_works_icon(self, center, LIGHTING_BADGE_RADIUS_PIXELS)
	elif target_room.lighting != Need.Lighting.NORMAL:
		GuestPainter.draw_lighting_icon(self, target_room.lighting, center, LIGHTING_BADGE_RADIUS_PIXELS)


## Disegna nell'angolo in basso a sinistra l'icona della piscina, se la camera è attaccata: con il bonus
## accanto se l'ospite sta bene, barrata se non lo riceve, da sola se la camera è vuota e non ci sarebbe
## nessuno a riceverlo. Usa le celle previste da un gesto in corso, così l'effetto si vede prima di
## lasciare il dito. Le regole stanno in HotelSession.
func _draw_pool_badge(room_rect: Rect2, target_room: Room) -> void:
	var pool: Room = _grid.get_pool()
	if pool == null or target_room == pool:
		return

	var room_cells: Rect2i = _get_displayed_cells(target_room)
	var pool_cells: Rect2i = _get_displayed_cells(pool)
	if not Room.cells_touch(room_cells, pool_cells):
		return

	var center: Vector2 = room_rect.position + Vector2(TURNS_BADGE_INSET_PIXELS, room_rect.size.y - TURNS_BADGE_INSET_PIXELS)
	GuestPainter.draw_pool_icon(self, center, POOL_BADGE_RADIUS_PIXELS)

	var guest: Guest = _get_shown_guest(target_room)
	if guest == null:
		return

	var fit: Need.Fit = guest.need.evaluate_in_room(room_cells.size, target_room.lighting)
	var bonus: int = HotelSession.get_pool_bonus(fit, room_cells, pool_cells)
	if bonus > 0:
		var text_position: Vector2 = center + Vector2(POOL_BADGE_RADIUS_PIXELS + TURNS_TEXT_GAP_PIXELS, SMALL_TEXT_BASELINE_PIXELS)
		draw_string(ThemeDB.fallback_font, text_position, "+%d" % bonus, HORIZONTAL_ALIGNMENT_LEFT, NUMBER_WIDTH_PIXELS, SMALL_FONT_PIXELS, GuestPainter.INK_COLOR)
	else:
		var strike: Vector2 = Vector2(1.0, -1.0) * POOL_BADGE_RADIUS_PIXELS * 0.7
		draw_line(center - strike, center + strike, GuestPainter.INK_COLOR, POOL_BADGE_STRIKE_PIXELS, true)


## Restituisce il lato di una camera che ora va incurvato, oppure NONE. La camera attiva curva
## il lato trascinato; una vicina curva il lato che coincide con quel muro, perché il muro è
## uno solo. Il controllo guarda il disegno, così vale anche durante l'assestamento.
func _get_bent_side_of(target_room: Room) -> int:
	if target_room == room:
		return _bent_side

	var facing_side: Room.MovableSide = Room.opposite_side(_bent_side)
	var distance_pixels: float = absf(_rect_side_pixels(_visual_rects[room], _bent_side) - _rect_side_pixels(_visual_rects[target_room], facing_side))
	if distance_pixels <= SAME_WALL_TOLERANCE_PIXELS and Room.side_span_covers(room.cells, _bent_side, target_room.cells):
		return facing_side

	return NONE


## Restituisce dove si trova un lato di un rettangolo, in pixel: X per le pareti, Y per gli altri.
func _rect_side_pixels(rect: Rect2, side: Room.MovableSide) -> float:
	match side:
		Room.MovableSide.LEFT_WALL:
			return rect.position.x
		Room.MovableSide.RIGHT_WALL:
			return rect.end.x
		Room.MovableSide.CEILING:
			return rect.position.y
		_:
			return rect.end.y


## Costruisce il contorno della camera in senso orario, a partire dall'angolo in alto a
## sinistra. Solo bent_side si incurva; NONE significa nessun lato.
func _build_room_outline(rect: Rect2, bent_side: int) -> PackedVector2Array:
	var top_left: Vector2 = rect.position
	var top_right: Vector2 = rect.position + Vector2(rect.size.x, 0.0)
	var bottom_right: Vector2 = rect.end
	var bottom_left: Vector2 = rect.position + Vector2(0.0, rect.size.y)

	var points: PackedVector2Array = PackedVector2Array()
	_append_side_points(points, top_left, top_right, Room.MovableSide.CEILING == bent_side)
	_append_side_points(points, top_right, bottom_right, Room.MovableSide.RIGHT_WALL == bent_side)
	_append_side_points(points, bottom_right, bottom_left, Room.MovableSide.FLOOR == bent_side)
	_append_side_points(points, bottom_left, top_left, Room.MovableSide.LEFT_WALL == bent_side)
	return points


## Aggiunge i punti di un lato, escluso l'ultimo: è il primo del lato successivo. La
## formula 4 × t × (1 - t) vale 0 agli estremi (t = 0 e t = 1) e 1 a metà: gli angoli
## restano fermi e il centro si sposta di tutta la curvatura.
func _append_side_points(points: PackedVector2Array, from: Vector2, to: Vector2, is_bent: bool) -> void:
	var bend: Vector2 = _bend if is_bent else Vector2.ZERO

	for segment: int in SEGMENTS_PER_SIDE:
		var t: float = float(segment) / SEGMENTS_PER_SIDE
		points.append(from.lerp(to, t) + bend * 4.0 * t * (1.0 - t))


## Disegna nell'angolo della camera quanti turni resta l'ospite.
func _draw_turns_badge(room_rect: Rect2, turns_left: int) -> void:
	var center: Vector2 = room_rect.position + Vector2.ONE * TURNS_BADGE_INSET_PIXELS
	GuestPainter.draw_stay_icon(self, center, TURNS_BADGE_RADIUS_PIXELS)
	var text_position: Vector2 = center + Vector2(TURNS_BADGE_RADIUS_PIXELS + TURNS_TEXT_GAP_PIXELS, SMALL_TEXT_BASELINE_PIXELS)
	draw_string(ThemeDB.fallback_font, text_position, str(turns_left), HORIZONTAL_ALIGNMENT_LEFT, NUMBER_WIDTH_PIXELS, SMALL_FONT_PIXELS, GuestPainter.INK_COLOR)


## Disegna i guadagni dell'ultimo turno: salgono sopra ogni camera e svaniscono.
func _draw_earnings(origin: Vector2) -> void:
	if _earning_progress >= 1.0:
		return

	var color: Color = GuestPainter.INK_COLOR
	color.a = 1.0 - _earning_progress

	for each_room: Room in _shown_earnings:
		var rect: Rect2 = _visual_rects[each_room]
		# Parte da metà camera: più in alto finirebbe sotto le icone dell'ospite.
		var position: Vector2 = origin + Vector2(rect.position.x, rect.get_center().y - EARNING_RISE_PIXELS * _earning_progress)
		var text: String = "+%d" % _shown_earnings[each_room]
		draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, EARNING_FONT_PIXELS, color)


## Disegna l'ospite di una camera, appoggiato al centro del pavimento. Non viene tagliato dalle
## pareti, così si vede subito se la camera è troppo piccola. room_rect è in pixel del nodo.
func _draw_room_guest(room_rect: Rect2, target_room: Room) -> void:
	var guest: Guest = _get_shown_guest(target_room)
	if guest == null:
		return

	var fit: Need.Fit = guest.need.evaluate_in_room(_get_displayed_cells(target_room).size, target_room.lighting)
	var is_preview: bool = target_room.guest == null
	var pose_scale: Vector2 = _reaction_scale if target_room == _reacting_room else Vector2.ONE
	var floor_center: Vector2 = Vector2(room_rect.get_center().x, room_rect.end.y)
	if is_preview:
		floor_center.x += _shake_offset_pixels

	GuestPainter.draw_guest(self, guest, floor_center, CELL_SIZE_PIXELS, fit, pose_scale, is_preview)


## Disegna le icone dell'ospite mostrato nella camera attiva: il bisogno e come starebbe. Durante
## il gesto stanno accanto all'icona del risultato, sopra il dito; altrimenti sopra la camera.
func _draw_guest_icons(origin: Vector2) -> void:
	var guest: Guest = _get_shown_guest(room)
	if guest == null or not _is_room_selected:
		return

	var center: Vector2
	if _drag != null:
		center = _get_status_icon_center() + Vector2(-GUEST_ICON_SPACING_PIXELS, 0.0)
		# Vicino al bordo sinistro le icone si spostano dall'altra parte, per restare visibili.
		if center.x - GUEST_ICON_SPACING_PIXELS < GUEST_ICON_RADIUS_PIXELS:
			center = _get_status_icon_center() + Vector2(2.0 * GUEST_ICON_SPACING_PIXELS, 0.0)
	else:
		var rect: Rect2 = _visual_rects[room]
		var guest_top: float = rect.end.y - guest.body_size_cells.y * CELL_SIZE_PIXELS
		center = origin + Vector2(rect.get_center().x + GUEST_ICON_SPACING_PIXELS / 2.0, minf(rect.position.y, guest_top) - GUEST_ICON_ABOVE_ROOM_PIXELS)

	var fit: Need.Fit = guest.need.evaluate_in_room(_get_displayed_cells(room).size, room.lighting)
	GuestPainter.draw_fit_icon(self, fit, center, GUEST_ICON_RADIUS_PIXELS)
	GuestPainter.draw_need_icons(self, guest.need, center + Vector2(-GUEST_ICON_SPACING_PIXELS, 0.0), GUEST_ICON_RADIUS_PIXELS)


## Disegna le maniglie: tutte se la camera è solo selezionata, solo quella in uso durante
## il trascinamento, perché in quel momento contano contorno, maniglia e risultato. Mentre la camera
## si sposta intera non ne serve nessuna.
func _draw_handles() -> void:
	if _drag != null:
		if _drag is RoomDrag:
			_draw_handle((_drag as RoomDrag).side, ACTIVE_HANDLE_SCALE)
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


## Disegna il contorno del risultato: dove finiranno le camere se la modifica è valida,
## oppure dove torneranno se è rifiutata, segnando anche la camera che la blocca. Il colore
## aiuta, ma l'icona dice lo stesso con una forma.
func _draw_target_outline(origin: Vector2) -> void:
	var preview: ResizePreview = _drag.preview

	if preview.is_valid():
		_draw_cells_outline(origin, preview.resulting_cells, VALID_COLOR)
		for change: RoomChange in preview.neighbor_changes:
			_draw_cells_outline(origin, change.resulting_cells, VALID_COLOR)
		return

	_draw_cells_outline(origin, room.cells, INVALID_COLOR)
	if preview.blocking_room != null:
		_draw_cells_outline(origin, preview.blocking_room.cells, INVALID_COLOR)


## Disegna il contorno di un rettangolo di celle.
func _draw_cells_outline(origin: Vector2, cells: Rect2i, color: Color) -> void:
	var rect: Rect2 = _cells_to_pixels(cells)
	rect.position += origin
	draw_rect(rect, color, false, THICK_LINE_PIXELS)


## Restituisce il centro dell'icona del risultato, in pixel del nodo. Vicino ai bordi l'icona
## deve restare dentro lo schermo: clampf() limita un valore tra un minimo e un massimo.
func _get_status_icon_center() -> Vector2:
	var center: Vector2 = _finger_position + Vector2(0.0, -STATUS_DISTANCE_ABOVE_FINGER_PIXELS)
	center.x = clampf(center.x, STATUS_RADIUS_PIXELS, size.x - STATUS_RADIUS_PIXELS)
	center.y = clampf(center.y, STATUS_RADIUS_PIXELS, size.y - STATUS_RADIUS_PIXELS)
	return center


## Disegna sopra il dito l'icona del risultato: un segno di spunta se la modifica è
## permessa, una X se è rifiutata. La forma dice l'esito anche a chi non distingue i colori.
func _draw_status_icon() -> void:
	var center: Vector2 = _get_status_icon_center()
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
