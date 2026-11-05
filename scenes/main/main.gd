extends Control
## Scena di avvio del gioco: è la prima cosa che Godot apre.
##
## COSA FA: contiene lo sfondo, la scena del gesto RoomEditor, la barra degli ospiti GuestBar e
## le informazioni Hud, e li collega tra loro. All'avvio ricarica la partita salvata e la salva
## quando l'app sta per chiudersi. I comportamenti di gioco stanno in quelle scene.
## CHI LA USA: Godot, che la apre da solo perché project.godot la indica come scena principale
## (run/main_scene).
## PERCHÉ È SEPARATA: quelle scene non si conoscono tra loro. Salgono con un segnale fin qui, e
## questa scena chiama direttamente il nodo interessato (AGENTS.md, sezione 6).
## NOTA GDSCRIPT: una «scena» è un albero di «nodi». «extends Control» aggiunge comportamento a
## un nodo d'interfaccia. @onready assegna la variabile appena i nodi sono pronti e $Nome trova
## il nodo figlio con quel nome. Un segnale è un avviso: connect() indica chi deve riceverlo.

## Dove si salva la partita. «user://» è la cartella privata dell'app sul dispositivo.
const DEFAULT_SAVE_PATH: String = "user://hotel_save.json"

## Il file di salvataggio in uso. I test ne indicano un altro prima di aggiungere la scena, per non
## toccare la partita vera.
var save_path: String = DEFAULT_SAVE_PATH

## La scena delle camere.
@onready var _room_editor: RoomEditor = $RoomEditor
## La barra con l'ospite di turno e la fila.
@onready var _guest_bar: GuestBar = $GuestBar
## Le informazioni in alto: monete e turni.
@onready var _hud: Hud = $Hud


## Godot chiama _ready() quando il nodo e i suoi figli sono pronti: qui si fanno i collegamenti.
func _ready() -> void:
	_guest_bar.refuse_pressed.connect(_room_editor.refuse_current_guest)
	_hud.build_pressed.connect(_room_editor.toggle_build_mode)
	_hud.pool_pressed.connect(_room_editor.toggle_pool_build_mode)
	_hud.reset_confirmed.connect(_start_new_game)
	_hud.lighting_action_chosen.connect(_room_editor.apply_lighting_action)
	_room_editor.selection_changed.connect(_refresh_interface)
	_room_editor.session_changed.connect(_refresh_interface)
	_room_editor.build_mode_changed.connect(_refresh_interface)
	_load_game()
	_refresh_interface()


## Godot chiama _notification() per gli avvisi di sistema. Salva quando l'app passa in secondo piano
## su un telefono, dove iOS concede circa 5 secondi e poi può chiuderla senza altri avvisi, e
## quando si chiude la finestra su un computer.
func _notification(what: int) -> void:
	# Prima di _ready() la partita salvata non è ancora stata letta: salvare ora la cancellerebbe.
	if not is_node_ready():
		return

	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_go_back()


## Ricarica la partita salvata, se c'è. Se non si può leggere, la mette da parte e resta la partita
## nuova preparata da RoomEditor: il giocatore può continuare a giocare e il vecchio file non viene
## cancellato. Oggi esiste un solo formato; dal secondo in poi, qui si aggiornano quelli vecchi.
func _load_game() -> void:
	var save: SaveFile = SaveFile.read(save_path)
	if save.status == SaveFile.Status.MISSING:
		return

	var saved_session: HotelSession = null
	if save.status == SaveFile.Status.LOADED:
		saved_session = HotelSession.from_data(save.data, GuestQueue.PROTOTYPE_GUESTS, GuestQueue.LIGHT_GUESTS)

	if saved_session != null:
		_room_editor.restore_session(saved_session)
		return

	push_warning("Salvataggio non leggibile: si inizia una partita nuova.")
	if not SaveFile.set_aside(save_path):
		push_warning("Impossibile mettere da parte il salvataggio non leggibile.")


## Ricomincia da zero e salva subito: se l'app si chiudesse adesso, la vecchia partita non deve
## tornare. La nuova sostituisce la vecchia nel file: da qui non si può più tornare indietro.
func _start_new_game() -> void:
	_room_editor.start_new_game()
	_save_game()


## Salva la partita. Se non riesce avvisa nel registro e il salvataggio precedente resta valido.
## Un trascinamento in corso non è compreso: le camere cambiano solo al rilascio del dito.
func _save_game() -> void:
	SaveFile.write(save_path, _room_editor.session.to_data())


## Gestisce il tasto Indietro di Android: annulla ciò che è in corso e, se non c'è nulla da
## annullare, salva ed esce. Godot esce da solo solo se config/quit_on_go_back è attivo, e in questo
## progetto non lo è: il tasto servirebbe altrimenti soltanto a chiudere il gioco.
func _handle_go_back() -> void:
	if _room_editor.handle_back():
		return

	_save_game()
	_quit_game()


## Chiude l'app. È una funzione a parte perché i test possano sostituirla senza fermarsi.
func _quit_game() -> void:
	get_tree().quit()


## Mostra nell'interfaccia lo stato attuale della partita.
func _refresh_interface() -> void:
	var session: HotelSession = _room_editor.session
	_guest_bar.update_queue(session.get_current_guest(), session.get_upcoming_guests())
	_hud.update_values(session.coins, session.turns_played, session.arrivals_left)
	_hud.update_build_button(session.get_new_room_price(), session.can_build_room(), _room_editor.is_building() and not _room_editor.is_building_pool())
	_hud.update_pool_button(HotelSession.POOL_PRICE, session.can_build_pool(), _room_editor.is_building_pool(), session.get_grid().get_pool() == null)
	_hud.update_lighting_panel(_room_editor.get_selected_room(), session)
