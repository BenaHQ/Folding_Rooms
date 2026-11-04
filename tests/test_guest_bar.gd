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
	var free_cell: Vector2 = _editor.get_envelope_origin() + Vector2.ONE
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = free_cell
	_editor._gui_input(touch)

	assert_eq(_hud._coins, 0)
	assert_eq(_hud._build_button._price, HotelSession.FIRST_NEW_ROOM_PRICE + HotelSession.NEW_ROOM_PRICE_STEP)
	assert_false(_hud._build_button._can_build)
