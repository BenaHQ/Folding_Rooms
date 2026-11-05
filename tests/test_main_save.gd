extends GutTest
## Test di quando il gioco salva e ricarica, con la scena principale vera.
##
## COMPORTAMENTO PROTETTO: passando in secondo piano o chiudendo si salva, e all'avvio successivo
## la partita riprende; un trascinamento in corso non finisce nel salvataggio; un file non leggibile
## non blocca il gioco e non viene cancellato; il tasto Indietro annulla prima di uscire.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per avviarli è scritto
## in docs/STATO.md.
## PERCHÉ È SEPARATO: prova il collegamento con le scene; disco e contenuto hanno i propri test.
## La vera chiusura dell'app su iOS e il tasto Indietro su Android qui sono solo simulati.
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di GUT.
## propagate_notification() invia un avviso di sistema a un nodo e ai suoi figli, come fa Godot.
## Una classe interna, scritta con «class» dentro un file, qui serve a sostituire una sola funzione.

## La scena principale, senza la chiusura vera dell'app, che fermerebbe i test.
class MainWithoutQuit:
	extends "res://scenes/main/main.gd"

	## Quante volte il gioco ha chiesto di chiudersi.
	var quit_count: int = 0

	## Sostituisce la chiusura vera.
	func _quit_game() -> void:
		quit_count += 1


## La scena principale.
const MAIN_SCENE_PATH: String = "res://scenes/main/main.tscn"
## File usato dai test, diverso da quello della partita vera.
const TEST_PATH: String = "user://test_main_save.json"
## L'ospite usato nei test: entra da 1×3 e sta bene da 2×3.
const GIRAFFE: Guest = preload("res://tests/data/fixed_giraffe.tres")
## Seme fisso: con una sola specie l'ordine è comunque sempre lo stesso.
const TEST_SEED: int = 1
## Forma della prima camera dopo aver alzato il soffitto di una cella.
const RAISED_ROOM_CELLS: Rect2i = Rect2i(2, 3, 2, 3)
## Spostamento di una cella verso l'alto, in celle.
const ONE_CELL_UP: int = -1
## Un dito qualsiasi, per i gesti simulati.
const FINGER: int = 0


## GUT chiama questa funzione dopo ogni test: non deve restare nessun file di prova.
func after_each() -> void:
	for path: String in [TEST_PATH, TEST_PATH + SaveFile.TEMPORARY_SUFFIX, TEST_PATH + SaveFile.UNREADABLE_SUFFIX]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


## Avvia la scena principale come fa il gioco, leggendo il file di prova.
func _launch() -> MainWithoutQuit:
	var scene: PackedScene = load(MAIN_SCENE_PATH)
	var main: Node = scene.instantiate()
	main.set_script(MainWithoutQuit)
	main.save_path = TEST_PATH
	return add_child_autofree(main)


## Restituisce la scena delle camere.
func _editor_of(main: Node) -> RoomEditor:
	return main.get_node("RoomEditor")


## Gioca un turno: alza il soffitto della prima camera e ci fa entrare una giraffa.
func _play_one_turn(main: Node) -> void:
	var editor: RoomEditor = _editor_of(main)
	editor.start_session(GuestQueue.new([GIRAFFE], TEST_SEED))
	editor.session.get_grid().resize_room(editor.rooms[0], Room.MovableSide.CEILING, ONE_CELL_UP)
	editor.session.host_current_guest(editor.rooms[0])


## Scrive un testo qualsiasi nel file di prova, per simulare un file rovinato.
func _write_text(text: String) -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Controlla che la partita sia quella nuova, con le camere iniziali.
func _assert_is_new_game(main: Node) -> void:
	var editor: RoomEditor = _editor_of(main)
	assert_eq(editor.session.coins, 0)
	assert_eq(editor.session.turns_played, 0)
	assert_eq(editor.rooms[0].cells, RoomEditor.INITIAL_ROOM_CELLS)
	assert_eq(editor.rooms[1].cells, RoomEditor.SECOND_ROOM_CELLS)


## Al primo avvio c'è una partita nuova, e nessun file finché non serve salvare.
func test_first_launch_starts_new_game() -> void:
	var main: MainWithoutQuit = _launch()

	_assert_is_new_game(main)
	assert_false(FileAccess.file_exists(TEST_PATH))
	assert_false(FileAccess.file_exists(TEST_PATH + SaveFile.UNREADABLE_SUFFIX))


## Il caso principale: si gioca, l'app va in secondo piano, e all'avvio dopo tutto è come prima.
func test_game_resumes_after_going_to_background() -> void:
	var first: MainWithoutQuit = _launch()
	_play_one_turn(first)
	var played: HotelSession = _editor_of(first).session
	first.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)

	var second: MainWithoutQuit = _launch()

	var editor: RoomEditor = _editor_of(second)
	assert_eq(editor.session.coins, played.coins)
	assert_eq(editor.session.turns_played, 1)
	assert_eq(editor.rooms.size(), 2)
	assert_eq(editor.rooms[0].cells, RAISED_ROOM_CELLS)
	assert_eq(editor.rooms[0].guest.id, GIRAFFE.id)
	assert_eq(editor.rooms[0].turns_left, played.get_grid().get_rooms()[0].turns_left)
	# La griglia usata dalla scena deve essere quella ricaricata: i gesti lavorano su di essa.
	assert_eq(editor.session.get_grid().get_rooms()[0], editor.rooms[0])
	# Il disegno parte dalla forma ricaricata, e nessuna camera è selezionata.
	assert_eq(editor._visual_rects[editor.rooms[0]], editor._cells_to_pixels(RAISED_ROOM_CELLS))
	assert_false(editor.is_room_selected())


## L'interfaccia mostra subito i valori della partita ricaricata.
func test_interface_shows_loaded_game() -> void:
	var first: MainWithoutQuit = _launch()
	_play_one_turn(first)
	first.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	var coins: int = _editor_of(first).session.coins

	var second: MainWithoutQuit = _launch()

	var hud: Hud = second.get_node("Hud")
	assert_eq(hud._coins, coins)
	assert_eq(hud._turns, 1)


## Su un computer si salva alla chiusura della finestra.
func test_closing_window_saves() -> void:
	var main: MainWithoutQuit = _launch()
	_play_one_turn(main)

	main.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

	assert_eq(SaveFile.read(TEST_PATH).status, SaveFile.Status.LOADED)


## Un trascinamento interrotto dalla pausa non è una scelta del giocatore: non va salvato.
func test_drag_in_progress_is_not_saved() -> void:
	var first: MainWithoutQuit = _launch()
	var editor: RoomEditor = _editor_of(first)
	editor._select_room(editor.rooms[0])
	var start: Vector2 = editor.get_handle_position(Room.MovableSide.CEILING)
	editor._begin_drag(Room.MovableSide.CEILING, FINGER, start)
	editor._drag.update(Vector2(0.0, -RoomEditor.CELL_SIZE_PIXELS))
	assert_true(editor._drag.preview.is_valid())

	first.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)

	assert_false(editor.is_dragging())
	var second: MainWithoutQuit = _launch()
	assert_eq(_editor_of(second).rooms[0].cells, RoomEditor.INITIAL_ROOM_CELLS)


## Un file rovinato non blocca il gioco, e il suo contenuto non va perso.
func test_damaged_save_starts_new_game_and_is_kept_aside() -> void:
	_write_text("{\"format_version\": 1, \"da")

	var main: MainWithoutQuit = _launch()

	_assert_is_new_game(main)
	assert_false(FileAccess.file_exists(TEST_PATH))
	assert_eq(FileAccess.get_file_as_string(TEST_PATH + SaveFile.UNREADABLE_SUFFIX), "{\"format_version\": 1, \"da")


## Un file di una versione diversa, per esempio dopo aver reinstallato un'app più vecchia, non si
## interpreta e non si cancella.
func test_other_version_starts_new_game_and_is_kept_aside() -> void:
	var future_save: String = JSON.stringify({SaveFile.VERSION_KEY: SaveFile.FORMAT_VERSION + 1, SaveFile.DATA_KEY: {}})
	_write_text(future_save)

	var main: MainWithoutQuit = _launch()

	_assert_is_new_game(main)
	assert_eq(FileAccess.get_file_as_string(TEST_PATH + SaveFile.UNREADABLE_SUFFIX), future_save)


## Un file ben scritto ma con una partita impossibile vale come rovinato.
func test_invalid_game_data_starts_new_game_and_is_kept_aside() -> void:
	SaveFile.write(TEST_PATH, {"coins": 5.0})

	var main: MainWithoutQuit = _launch()

	_assert_is_new_game(main)
	assert_true(FileAccess.file_exists(TEST_PATH + SaveFile.UNREADABLE_SUFFIX))


## Dopo un file rovinato si può giocare e salvare normalmente.
func test_can_save_after_damaged_file() -> void:
	_write_text("rovinato")
	var first: MainWithoutQuit = _launch()
	_play_one_turn(first)
	first.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)

	var second: MainWithoutQuit = _launch()

	assert_eq(_editor_of(second).session.turns_played, 1)


## Indietro con una camera selezionata toglie solo la selezione: il gioco non si chiude.
func test_back_with_selected_room_only_deselects() -> void:
	var main: MainWithoutQuit = _launch()
	var editor: RoomEditor = _editor_of(main)
	editor._select_room(editor.rooms[0])

	main.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)

	assert_false(editor.is_room_selected())
	assert_eq(main.quit_count, 0)


## Indietro durante un trascinamento annulla il gesto, senza cambiare la camera.
func test_back_during_drag_cancels_gesture() -> void:
	var main: MainWithoutQuit = _launch()
	var editor: RoomEditor = _editor_of(main)
	editor._select_room(editor.rooms[0])
	editor._begin_drag(Room.MovableSide.CEILING, FINGER, editor.get_handle_position(Room.MovableSide.CEILING))
	editor._drag.update(Vector2(0.0, -RoomEditor.CELL_SIZE_PIXELS))

	main.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)

	assert_false(editor.is_dragging())
	assert_true(editor.is_room_selected())
	assert_eq(editor.rooms[0].cells, RoomEditor.INITIAL_ROOM_CELLS)
	assert_eq(main.quit_count, 0)


## Indietro senza nulla da annullare salva ed esce.
func test_back_with_nothing_to_cancel_saves_and_quits() -> void:
	var main: MainWithoutQuit = _launch()
	_play_one_turn(main)

	main.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)

	assert_eq(main.quit_count, 1)
	assert_eq(SaveFile.read(TEST_PATH).status, SaveFile.Status.LOADED)


## Dopo il caricamento anche la camera costruita è disegnabile e toccabile come le altre.
func test_built_room_is_restored_in_scene() -> void:
	var first: MainWithoutQuit = _launch()
	var first_editor: RoomEditor = _editor_of(first)
	first_editor.session.coins = HotelSession.FIRST_NEW_ROOM_PRICE
	first_editor.session.build_room(Vector2i(0, 7))
	first.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)

	var editor: RoomEditor = _editor_of(_launch())

	assert_eq(editor.rooms.size(), 3)
	assert_true(editor._painters.has(editor.rooms[2]))
	assert_eq(editor._visual_rects[editor.rooms[2]], editor._cells_to_pixels(Rect2i(0, 7, 1, 1)))
	await wait_process_frames(2)
	assert_eq(editor.session.coins, 0)


## Ricominciando la vecchia partita non torna, nemmeno se l'app si chiude subito senza altri avvisi.
func test_reset_replaces_save_immediately() -> void:
	var first: MainWithoutQuit = _launch()
	_play_one_turn(first)
	first.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_editor_of(_launch()).session.turns_played, 1)

	first.get_node("Hud").reset_confirmed.emit()

	_assert_is_new_game(_launch())


## Una partita ricaricata si può azzerare, anche se aveva più camere di quelle iniziali.
func test_loaded_game_can_be_reset() -> void:
	var first: MainWithoutQuit = _launch()
	var first_editor: RoomEditor = _editor_of(first)
	first_editor.session.coins = HotelSession.FIRST_NEW_ROOM_PRICE
	first_editor.session.build_room(Vector2i(0, 7))
	first.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	var second: MainWithoutQuit = _launch()

	second.get_node("Hud").reset_confirmed.emit()

	_assert_is_new_game(second)
	assert_eq(_editor_of(second).rooms.size(), HotelSession.STARTING_ROOMS)


## Una partita con le specie nuove e le camere speciali riprende dalla scena vera.
func test_light_game_resumes_in_scene() -> void:
	var first: MainWithoutQuit = _launch()
	var first_editor: RoomEditor = _editor_of(first)
	first_editor.session.coins = 1000
	first_editor.session.apply_lighting_action(first_editor.rooms[0], HotelSession.LightingAction.MAKE_DARK)
	first_editor.session.get_grid().assign_guest(GuestQueue.LIGHT_GUESTS[0], first_editor.rooms[0])
	first.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)

	var editor: RoomEditor = _editor_of(_launch())

	assert_eq(editor.rooms[0].lighting, Need.Lighting.DARK)
	assert_eq(editor.rooms[0].guest.id, GuestQueue.LIGHT_GUESTS[0].id)


## Dopo il caricamento la piscina è disegnata con il suo aspetto e il pulsante per comprarla non c'è più.
func test_pool_is_restored_in_scene() -> void:
	var first: MainWithoutQuit = _launch()
	var first_editor: RoomEditor = _editor_of(first)
	first_editor.session.coins = HotelSession.POOL_PRICE
	first_editor.session.build_pool(Vector2i(0, 7))
	first.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)

	var second: MainWithoutQuit = _launch()
	var editor: RoomEditor = _editor_of(second)
	var pool: Room = editor.session.get_grid().get_pool()

	assert_not_null(pool)
	if pool == null:
		return

	assert_true(editor._painters[pool] is PoolPainter)
	assert_eq(editor._visual_rects[pool], editor._cells_to_pixels(Rect2i(0, 7, 1, 1)))
	assert_false((second.get_node("Hud") as Hud)._pool_button.visible)


## Dopo il caricamento i piani comprati restano aperti e il prezzo del prossimo non riparte da capo.
func test_bought_storey_is_restored() -> void:
	var first: MainWithoutQuit = _launch()
	var first_editor: RoomEditor = _editor_of(first)
	first_editor.session.coins = HotelSession.FIRST_NEW_STOREY_PRICE
	assert_true(first_editor.session.build_storey())
	first.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)

	var editor: RoomEditor = _editor_of(_launch())

	assert_eq(editor.session.get_grid().get_open_storeys(), HotelSession.STARTING_STOREYS + 1)
	assert_eq(editor.session.get_new_storey_price(), HotelSession.FIRST_NEW_STOREY_PRICE + HotelSession.NEW_STOREY_PRICE_STEP)
	assert_true(editor._storey_button.visible)
