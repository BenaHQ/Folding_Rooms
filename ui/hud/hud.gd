class_name Hud
extends Control
## Le informazioni in alto sullo schermo: monete, turni giocati, arrivi rimasti e pulsante Costruisci.
##
## COSA FA: mostra tre numeri, ognuno con la sua icona, sotto la zona occupata dal sistema, e tiene
## il pulsante per costruire nella stessa riga.
## CHI LA USA: la scena principale main.tscn, che le passa i valori.
## PERCHÉ È SEPARATA: è interfaccia, senza regole. Lascia passare i tocchi, così non disturba le
## camere (nella scena ha mouse_filter impostato su «Ignore»).
## NOTA GDSCRIPT: «extends Control» indica un nodo d'interfaccia. _draw() disegna il nodo; Godot la
## richiama dopo queue_redraw(). I numeri non si traducono, quindi non serve tr(). @onready assegna
## la variabile appena i nodi sono pronti e $Nome trova il nodo figlio con quel nome. Il pulsante è un
## nodo figlio e riceve i suoi tocchi anche se questo nodo li lascia passare.
## COORDINATE: pixel del nodo; (0, 0) è il suo angolo in alto a sinistra.

## Lanciato quando il giocatore tocca il pulsante Costruisci.
signal build_pressed
## Lanciato quando il giocatore conferma di voler ricominciare da zero.
signal reset_confirmed
## Lanciato quando il giocatore sceglie una modifica alla luce. action è una HotelSession.LightingAction.
signal lighting_action_chosen(action: int)

## Distanza dai bordi dell'area sicura, in pixel.
const MARGIN_PIXELS: float = 28.0
## Raggio delle icone, in pixel.
const ICON_RADIUS_PIXELS: float = 24.0
## Distanza tra il centro dell'icona e l'inizio del numero, in pixel.
const NUMBER_OFFSET_PIXELS: float = 36.0
## Dimensione del testo dei numeri, in pixel.
const FONT_SIZE_PIXELS: int = 40
## Di quanto scendere per allineare un numero al centro dell'icona, in pixel.
const TEXT_BASELINE_OFFSET_PIXELS: float = 14.0
## Larghezza riservata a un numero, in pixel.
const NUMBER_WIDTH_PIXELS: float = 180.0
## Spazio tra la riga dei numeri e il pulsante per ricominciare, in pixel.
const RESET_BUTTON_GAP_PIXELS: float = 4.0
## Distanza tra il centro dell'icona dei turni e quello dell'icona degli arrivi, in pixel: lascia
## spazio a un numero di turni di due cifre.
const ARRIVALS_ICON_OFFSET_PIXELS: float = 112.0

## Le monete da mostrare.
var _coins: int = 0
## I turni da mostrare.
var _turns: int = 0
## Gli ospiti ancora in arrivo nella giornata, da mostrare.
var _arrivals_left: int = 0

## Il pulsante per costruire una camera.
@onready var _build_button: BuildButton = $BuildButton
## Il pulsante per ricominciare la partita.
@onready var _reset_button: ResetButton = $ResetButton
## I pulsanti per cambiare la luce della camera selezionata.
@onready var _lighting_panel: LightingPanel = $LightingPanel


## Godot chiama _ready() quando il nodo e i suoi figli sono pronti. Il pulsante sta al centro dello
## schermo (la scena lo ancora alla metà della larghezza) e alla stessa altezza dei numeri, sotto la
## zona del sistema. Gli «offset» sono le distanze dei bordi del nodo da quel punto, in pixel.
func _ready() -> void:
	_build_button.pressed.connect(build_pressed.emit)
	var row_y: float = _get_top_safe_margin() + MARGIN_PIXELS + ICON_RADIUS_PIXELS
	_build_button.offset_left = -BuildButton.WIDTH_PIXELS / 2.0
	_build_button.offset_right = BuildButton.WIDTH_PIXELS / 2.0
	_build_button.offset_top = row_y - BuildButton.HEIGHT_PIXELS / 2.0
	_build_button.offset_bottom = row_y + BuildButton.HEIGHT_PIXELS / 2.0

	# Il pulsante per ricominciare sta nell'angolo a destra, sotto la riga dei numeri e lontano dal
	# pulsante Costruisci, perché toccarlo per sbaglio costerebbe la partita. Sopra l'involucro anche
	# sullo schermo più basso previsto, alto 1280 pixel, dove lo spazio finisce a 200 pixel.
	_reset_button.confirmed.connect(reset_confirmed.emit)
	_reset_button.offset_left = -MARGIN_PIXELS - ResetButton.SIDE_PIXELS
	_reset_button.offset_right = -MARGIN_PIXELS
	_reset_button.offset_top = row_y + BuildButton.HEIGHT_PIXELS / 2.0 + RESET_BUTTON_GAP_PIXELS
	_reset_button.offset_bottom = _reset_button.offset_top + ResetButton.SIDE_PIXELS

	# Il pannello della luce sta sulla stessa fascia, a sinistra.
	_lighting_panel.action_chosen.connect(lighting_action_chosen.emit)
	_lighting_panel.offset_left = MARGIN_PIXELS
	_lighting_panel.offset_right = MARGIN_PIXELS + LightingPanel.TOTAL_WIDTH_PIXELS
	_lighting_panel.offset_top = _reset_button.offset_top
	_lighting_panel.offset_bottom = _reset_button.offset_bottom


## Aggiorna i numeri mostrati.
func update_values(coins: int, turns: int, arrivals_left: int) -> void:
	_coins = coins
	_turns = turns
	_arrivals_left = arrivals_left
	queue_redraw()


## Aggiorna il pulsante Costruisci. price è il prezzo in monete, can_build dice se ora si può
## costruire e is_active se la modalità costruzione è attiva.
func update_build_button(price: int, can_build: bool, is_active: bool) -> void:
	_build_button.update_state(price, can_build, is_active)


## Aggiorna il pannello della luce per la camera selezionata, oppure lo nasconde se room è null.
func update_lighting_panel(room: Room, session: HotelSession) -> void:
	_lighting_panel.update_for_room(room, session)


## Godot chiama _draw() per disegnare il nodo.
func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var row_y: float = _get_top_safe_margin() + MARGIN_PIXELS + ICON_RADIUS_PIXELS

	var coin_center: Vector2 = Vector2(MARGIN_PIXELS + ICON_RADIUS_PIXELS, row_y)
	GuestPainter.draw_coin_icon(self, coin_center, ICON_RADIUS_PIXELS)
	_draw_number(font, coin_center, _coins)

	var turn_center: Vector2 = Vector2(size.x - MARGIN_PIXELS - NUMBER_WIDTH_PIXELS, row_y)
	GuestPainter.draw_stay_icon(self, turn_center, ICON_RADIUS_PIXELS)
	_draw_number(font, turn_center, _turns)

	var arrivals_center: Vector2 = turn_center + Vector2(ARRIVALS_ICON_OFFSET_PIXELS, 0.0)
	GuestPainter.draw_arrivals_icon(self, arrivals_center, ICON_RADIUS_PIXELS)
	_draw_number(font, arrivals_center, _arrivals_left)


## Disegna un numero accanto all'icona che ha il centro indicato.
func _draw_number(font: Font, icon_center: Vector2, value: int) -> void:
	var position: Vector2 = icon_center + Vector2(NUMBER_OFFSET_PIXELS, TEXT_BASELINE_OFFSET_PIXELS)
	draw_string(font, position, str(value), HORIZONTAL_ALIGNMENT_LEFT, NUMBER_WIDTH_PIXELS, FONT_SIZE_PIXELS, GuestPainter.INK_COLOR)


## Restituisce il rettangolo dell'icona dei turni, in pixel del nodo: i numeri alla sua destra hanno
## il loro spazio, e a sinistra non deve arrivare il pulsante.
func get_turn_icon_rect() -> Rect2:
	var left: float = size.x - MARGIN_PIXELS - NUMBER_WIDTH_PIXELS - ICON_RADIUS_PIXELS
	return Rect2(left, _get_top_safe_margin() + MARGIN_PIXELS, 2.0 * ICON_RADIUS_PIXELS, 2.0 * ICON_RADIUS_PIXELS)


## Restituisce quanti pixel di gioco occupano notch e barre di sistema in alto. La zona sicura è in
## pixel dello schermo, quindi va convertita nella scala dell'area di gioco.
func _get_top_safe_margin() -> float:
	var window_height: float = float(DisplayServer.window_get_size().y)
	# Senza finestra, come nei test automatici, l'altezza è zero e la divisione sotto darebbe NaN,
	# cioè «non è un numero»: il pulsante finirebbe senza una posizione.
	if window_height <= 0.0:
		return 0.0

	var safe_top: float = float(DisplayServer.get_display_safe_area().position.y)
	return maxf(safe_top, 0.0) * get_viewport_rect().size.y / window_height
