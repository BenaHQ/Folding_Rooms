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
	_main = add_child_autofree(scene.instantiate())
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
