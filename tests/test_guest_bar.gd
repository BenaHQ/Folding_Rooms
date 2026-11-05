extends GutTest
## Test della barra degli ospiti e del suo collegamento con la scena delle camere.
##
## COMPORTAMENTO PROTETTO: i comandi sono abbastanza grandi per un dito, non si sovrappongono, e
## la scena principale tiene aggiornata l'interfaccia a ogni turno.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per avviarli è scritto
## in docs/STATO.md.
## PERCHÉ È SEPARATO: controlla l'interfaccia, non le regole (test_hotel_session.gd).
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di GUT. Un nodo
## aggiunto con add_child_autofree() entra nella scena di prova e viene eliminato a fine test.

## La scena principale, che contiene barra e camere.
const MAIN_SCENE_PATH: String = "res://scenes/main/main.tscn"
## Percorso di un salvataggio che non esiste.
const NO_SAVE_PATH: String = "user://test_guest_bar_no_save.json"
## Area sensibile minima di un comando, in pixel: vale 48 dp su un telefono largo 360 dp.
const MIN_TOUCH_PIXELS: float = 96.0

## La scena principale, ricreata prima di ogni test.
var _main: Node
## La barra degli ospiti.
var _bar: GuestBar
## La scena delle camere.
var _editor: RoomEditor
## Le informazioni in alto.
var _hud: Hud


## GUT chiama questa funzione prima di ogni test.
func before_each() -> void:
	var scene: PackedScene = load(MAIN_SCENE_PATH)
	var main_scene: Node = scene.instantiate()
	# Un percorso senza file: questi test non devono leggere il salvataggio vero.
	main_scene.save_path = NO_SAVE_PATH
	_main = add_child_autofree(main_scene)
	_bar = _main.get_node("GuestBar")
	_editor = _main.get_node("RoomEditor")
	_hud = _main.get_node("Hud")


## Simula un dito che tocca la barra.
func _press_bar(point: Vector2) -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.position = point
	touch.pressed = true
	_bar._gui_input(touch)


## Il pulsante per rifiutare deve essere comodo da toccare.
func test_refuse_button_is_large_enough() -> void:
	var rect: Rect2 = _bar.get_refuse_rect()

	assert_gte(rect.size.x, MIN_TOUCH_PIXELS)
	assert_gte(rect.size.y, MIN_TOUCH_PIXELS)


## Scheda di turno, pulsante e schede in fila non si devono sovrapporre.
func test_bar_elements_do_not_overlap() -> void:
	assert_false(_bar.get_current_card_rect().intersects(_bar.get_refuse_rect()))
	assert_false(_bar.get_refuse_rect().intersects(_bar.get_upcoming_card_rect(0)))
	assert_false(_bar.get_upcoming_card_rect(0).intersects(_bar.get_upcoming_card_rect(1)))


## La barra deve stare nello schermo di riferimento: l'ultima scheda non può uscire a destra.
func test_upcoming_cards_fit_in_width() -> void:
	var last_index: int = HotelSession.VISIBLE_UPCOMING_GUESTS - 1

	assert_gt(_bar.get_upcoming_card_rect(last_index).size.x, 0.0)
	assert_lte(_bar.get_upcoming_card_rect(last_index).end.x, _bar.size.x)


## Il tocco sul pulsante deve arrivare fino alla partita, attraverso la scena principale.
func test_refuse_button_ends_turn() -> void:
	_press_bar(_bar.get_refuse_rect().get_center())

	assert_eq(_editor.session.turns_played, 1)


## Toccare una scheda non deve rifiutare nessuno per sbaglio.
func test_touching_cards_does_nothing() -> void:
	_press_bar(_bar.get_current_card_rect().get_center())
	_press_bar(_bar.get_upcoming_card_rect(0).get_center())

	assert_eq(_editor.session.turns_played, 0)


## All'avvio e dopo ogni turno l'interfaccia deve mostrare lo stato della partita.
func test_interface_follows_session() -> void:
	assert_eq(_bar._current_guest, _editor.session.get_current_guest())
	assert_eq(_bar._upcoming_guests, _editor.session.get_upcoming_guests())

	_press_bar(_bar.get_refuse_rect().get_center())

	assert_eq(_bar._current_guest, _editor.session.get_current_guest())
	assert_eq(_hud._turns, 1)


## Simula un dito che tocca il pulsante Costruisci.
func _press_build_button() -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	_hud._build_button._gui_input(touch)


## Il pulsante Costruisci deve essere comodo da toccare e non deve coprire i numeri.
func test_build_button_size_and_position() -> void:
	var button: BuildButton = _hud._build_button
	var rect: Rect2 = button.get_global_rect()

	assert_gte(rect.size.x, MIN_TOUCH_PIXELS)
	assert_gte(rect.size.y, MIN_TOUCH_PIXELS)
	assert_false(rect.intersects(_hud.get_turn_icon_rect()))
	assert_gte(rect.position.y, 0.0)
	# Sopra l'involucro: il pulsante fermerebbe i tocchi destinati alle camere.
	assert_lte(rect.end.y, _editor.get_envelope_origin().y)


## Il tocco sul pulsante arriva fino alla scena delle camere, e il pulsante mostra lo stato.
func test_build_button_toggles_build_mode() -> void:
	_editor.session.coins = HotelSession.FIRST_NEW_ROOM_PRICE
	_editor.session_changed.emit()
	assert_true(_hud._build_button._can_build)

	_press_build_button()

	assert_true(_editor.is_building())
	assert_true(_hud._build_button._is_active)

	_press_build_button()

	assert_false(_editor.is_building())
	assert_false(_hud._build_button._is_active)


## Dopo un acquisto l'interfaccia mostra le monete rimaste e il prezzo nuovo.
func test_interface_follows_building() -> void:
	assert_eq(_hud._build_button._price, HotelSession.FIRST_NEW_ROOM_PRICE)
	assert_false(_hud._build_button._can_build)

	_editor.session.coins = HotelSession.FIRST_NEW_ROOM_PRICE
	_editor.toggle_build_mode()
	var free_cell: Vector2 = _editor.get_envelope_origin() + Vector2(1.0, (Envelope.PROTOTYPE_HEIGHT_CELLS - 0.5) * RoomEditor.CELL_SIZE_PIXELS)
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = free_cell
	_editor._gui_input(touch)

	assert_eq(_hud._coins, 0)
	assert_eq(_hud._build_button._price, HotelSession.FIRST_NEW_ROOM_PRICE + HotelSession.NEW_ROOM_PRICE_STEP)
	assert_false(_hud._build_button._can_build)


## L'interfaccia mostra quanti ospiti devono ancora arrivare, anche a metà giornata.
func test_interface_shows_arrivals_left() -> void:
	assert_eq(_hud._arrivals_left, _editor.session.arrivals_left)

	_editor.session.arrivals_left = 3
	_press_bar(_bar.get_refuse_rect().get_center())

	assert_eq(_hud._arrivals_left, 2)
	assert_eq(_hud._turns, 0)


## Le icone degli arrivi devono stare nello schermo, con il loro numero.
func test_arrivals_icon_fits_in_width() -> void:
	var number_start: float = _hud.size.x - Hud.MARGIN_PIXELS - Hud.NUMBER_WIDTH_PIXELS + Hud.ARRIVALS_ICON_OFFSET_PIXELS + Hud.NUMBER_OFFSET_PIXELS
	var room_for_digit: float = float(Hud.FONT_SIZE_PIXELS)

	assert_lte(number_start + room_for_digit, _hud.size.x)


## Simula un dito che tocca il pulsante per ricominciare.
func _press_reset_button() -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	_hud._reset_button._gui_input(touch)


## Il pulsante per ricominciare è comodo da toccare, non copre nulla e non sta sulle camere.
func test_reset_button_size_and_position() -> void:
	var rect: Rect2 = _hud._reset_button.get_global_rect()

	assert_gte(rect.size.x, MIN_TOUCH_PIXELS)
	assert_gte(rect.size.y, MIN_TOUCH_PIXELS)
	assert_false(rect.intersects(_hud._build_button.get_global_rect()))
	assert_false(rect.intersects(_hud.get_turn_icon_rect()))
	assert_lte(rect.end.x, _hud.size.x)
	assert_lte(rect.end.y, _editor.get_envelope_origin().y)


## Un solo tocco non deve cancellare la partita: il pulsante chiede conferma.
func test_single_press_does_not_reset() -> void:
	_editor.session.coins = 50

	_press_reset_button()

	assert_true(_hud._reset_button.is_armed())
	assert_eq(_editor.session.coins, 50)


## Il secondo tocco ricomincia da zero, e l'interfaccia si aggiorna.
func test_second_press_resets_game() -> void:
	_editor.session.coins = 50
	_press_reset_button()

	_press_reset_button()

	assert_false(_hud._reset_button.is_armed())
	assert_eq(_editor.session.coins, 0)
	assert_eq(_hud._coins, 0)
	assert_eq(_hud._build_button._price, HotelSession.FIRST_NEW_ROOM_PRICE)


## Se la conferma non arriva, il pulsante torna normale e il tocco dopo non cancella nulla.
func test_reset_button_disarms_after_waiting() -> void:
	_editor.session.coins = 50
	_press_reset_button()

	await wait_seconds(ResetButton.ARMED_SECONDS + 0.1)

	assert_false(_hud._reset_button.is_armed())
	_press_reset_button()
	assert_eq(_editor.session.coins, 50)


## Seleziona la prima camera, passando dalla scena come farebbe un dito.
func _select_first_room() -> void:
	_editor._select_room(_editor.rooms[0])


## Simula un dito che tocca un pulsante del pannello della luce.
func _press_lighting_button(index: int) -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = _hud._lighting_panel.get_button_rect(index).get_center()
	_hud._lighting_panel._gui_input(touch)


## Il pannello compare solo con una camera selezionata, e sparisce togliendo la selezione.
func test_lighting_panel_follows_selection() -> void:
	assert_false(_hud._lighting_panel.visible)

	_select_first_room()
	assert_true(_hud._lighting_panel.visible)

	_editor.handle_back()
	assert_false(_hud._lighting_panel.visible)


## I pulsanti della luce sono comodi da toccare e non coprono gli altri comandi né le camere.
func test_lighting_panel_size_and_position() -> void:
	_select_first_room()
	var panel: LightingPanel = _hud._lighting_panel
	var rect: Rect2 = panel.get_global_rect()

	assert_gte(panel.get_button_rect(0).size.x, MIN_TOUCH_PIXELS)
	assert_gte(panel.get_button_rect(0).size.y, MIN_TOUCH_PIXELS)
	assert_false(rect.intersects(_hud._reset_button.get_global_rect()))
	assert_false(rect.intersects(_hud._build_button.get_global_rect()))
	assert_lte(rect.end.y, _editor.get_envelope_origin().y)


## Toccando il primo pulsante la camera diventa buia, si paga e l'interfaccia si aggiorna.
func test_lighting_button_changes_room() -> void:
	_editor.session.coins = HotelSession.SPECIAL_ROOM_PRICE
	_editor.session_changed.emit()
	_select_first_room()

	_press_lighting_button(0)

	assert_eq(_editor.rooms[0].lighting, Need.Lighting.DARK)
	assert_eq(_hud._coins, 0)
	assert_eq(_hud._lighting_panel._actions[0], HotelSession.LightingAction.RESTORE_PAID)


## Senza monete il pulsante c'è, per mostrare il prezzo, ma non fa nulla.
func test_lighting_button_without_coins_does_nothing() -> void:
	_select_first_room()
	assert_true(_hud._lighting_panel.visible)

	_press_lighting_button(0)

	assert_eq(_editor.rooms[0].lighting, Need.Lighting.NORMAL)


## L'attesa è gratis: si può scegliere anche senza monete, e lascia la camera in lavori.
func test_waiting_button_is_free() -> void:
	_editor.session.coins = HotelSession.SPECIAL_ROOM_PRICE
	_editor.session_changed.emit()
	_select_first_room()
	_press_lighting_button(0)

	_press_lighting_button(1)

	assert_true(_editor.rooms[0].is_under_works)
	assert_false(_hud._lighting_panel.visible)


## Il pulsante della piscina è comodo da toccare, non copre gli altri comandi e nessuno copre l'involucro.
func test_pool_button_size_and_position() -> void:
	var rect: Rect2 = _hud._pool_button.get_global_rect()

	assert_gte(rect.size.x, MIN_TOUCH_PIXELS)
	assert_gte(rect.size.y, MIN_TOUCH_PIXELS)
	assert_false(rect.intersects(_hud._build_button.get_global_rect()))
	assert_false(rect.intersects(_hud._reset_button.get_global_rect()))
	assert_false(rect.intersects(_hud._lighting_panel.get_global_rect()))
	assert_lte(rect.end.x, _hud.size.x)


## Il pulsante attiva la scelta della cella; costruita la piscina, sparisce.
func test_pool_button_toggles_and_disappears_when_built() -> void:
	assert_true(_hud._pool_button.visible)
	assert_eq(_hud._pool_button.icon, BuildButton.Icon.POOL)
	assert_eq(_hud._pool_button._price, HotelSession.POOL_PRICE)
	assert_false(_hud._pool_button._can_build)

	_editor.session.coins = HotelSession.POOL_PRICE
	_editor.session_changed.emit()
	assert_true(_hud._pool_button._can_build)

	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	_hud._pool_button._gui_input(touch)
	assert_true(_editor.is_building_pool())
	assert_true(_hud._pool_button._is_active)
	assert_false(_hud._build_button._is_active)

	# Una cella dell'ultima fila: i piani più in alto sono ancora chiusi.
	_editor._handle_build_press(_editor.get_envelope_origin() + Vector2(1.0, (Envelope.PROTOTYPE_HEIGHT_CELLS - 0.5) * RoomEditor.CELL_SIZE_PIXELS))
	assert_false(_hud._pool_button.visible)
	await wait_seconds(RoomEditor.SETTLE_SECONDS)
