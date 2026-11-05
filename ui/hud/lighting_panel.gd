class_name LightingPanel
extends Control
## I pulsanti che cambiano la luce della camera selezionata.
##
## COSA FA: mostra le modifiche alla luce possibili per la camera selezionata, ognuna con il suo
## prezzo, e avvisa quale viene toccata. Se non ce ne sono, resta nascosto (D-032).
## CHI LA USA: Hud, che lo contiene come nodo figlio e gli indica la camera.
## PERCHÉ È SEPARATA: è interfaccia, senza regole: quali modifiche esistono e quanto costano lo dice
## HotelSession. Un nodo nascosto non riceve tocchi, quindi non disturba quando non serve.
## NOTA GDSCRIPT: «extends Control» indica un nodo d'interfaccia, che riceve i tocchi in _gui_input().
## Un «segnale» è un avviso che un nodo lancia a chi si è collegato. I simboli e i numeri non si
## traducono, quindi non serve tr().
## COORDINATE: pixel del nodo; (0, 0) è il suo angolo in alto a sinistra.

## Lanciato quando il giocatore tocca una modifica che può permettersi. action è una
## HotelSession.LightingAction.
signal action_chosen(action: int)

## Quanti pulsanti può mostrare al massimo.
const MAX_BUTTONS: int = 2
## Larghezza di un pulsante, in pixel: abbastanza per il simbolo e un prezzo.
const BUTTON_WIDTH_PIXELS: float = 170.0
## Spazio tra i pulsanti, in pixel.
const BUTTON_GAP_PIXELS: float = 14.0
## Larghezza dell'intero pannello, in pixel.
const TOTAL_WIDTH_PIXELS: float = MAX_BUTTONS * BUTTON_WIDTH_PIXELS + (MAX_BUTTONS - 1) * BUTTON_GAP_PIXELS
## Raggio del simbolo della luce, in pixel.
const ACTION_ICON_RADIUS_PIXELS: float = 28.0
## Distanza dal bordo sinistro del pulsante del centro del simbolo e dell'icona a fianco, in pixel.
const ACTION_ICON_X_PIXELS: float = 42.0
const COST_ICON_X_PIXELS: float = 92.0
## Raggio dell'icona della moneta o dell'attesa, in pixel.
const COST_ICON_RADIUS_PIXELS: float = 16.0
## Distanza tra il centro dell'icona della moneta e l'inizio del prezzo, in pixel.
const PRICE_OFFSET_PIXELS: float = 22.0
## Dimensione del testo del prezzo, in pixel.
const FONT_SIZE_PIXELS: int = 30
## Di quanto scendere per allineare il prezzo al centro dell'icona, in pixel.
const TEXT_BASELINE_OFFSET_PIXELS: float = 10.0
## Spessore del bordo, in pixel.
const BORDER_PIXELS: int = 3
## Spessore della barra sul simbolo quando le monete non bastano, in pixel.
const STRIKE_PIXELS: float = 6.0

## Le modifiche mostrate, nell'ordine dei pulsanti.
var _actions: Array[HotelSession.LightingAction] = []
## Il prezzo di ogni modifica mostrata, in monete.
var _prices: Array[int] = []
## Per ogni modifica mostrata, true se le monete bastano.
var _affordable: Array[bool] = []


## Godot chiama _gui_input() per ogni evento di tocco che arriva a questo nodo.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		accept_event()
		var touch: InputEventScreenTouch = event as InputEventScreenTouch

		for index: int in _actions.size():
			if touch.pressed and _affordable[index] and get_button_rect(index).has_point(touch.position):
				action_chosen.emit(_actions[index])


## Godot chiama _draw() per disegnare il nodo.
func _draw() -> void:
	for index: int in _actions.size():
		_draw_button(index)


## Mostra le modifiche possibili per una camera, oppure nasconde il pannello se room è null o se non
## ce ne sono. Le regole stanno in session.
func update_for_room(room: Room, session: HotelSession) -> void:
	_actions = []
	_prices = []
	_affordable = []

	if room != null:
		_actions = session.get_lighting_actions(room)
		for action: HotelSession.LightingAction in _actions:
			var price: int = session.get_lighting_action_price(action)
			_prices.append(price)
			_affordable.append(session.coins >= price)

	visible = not _actions.is_empty()
	queue_redraw()


## Restituisce il rettangolo di un pulsante, in pixel del nodo.
func get_button_rect(index: int) -> Rect2:
	return Rect2(index * (BUTTON_WIDTH_PIXELS + BUTTON_GAP_PIXELS), 0.0, BUTTON_WIDTH_PIXELS, size.y)


## Disegna un pulsante: il simbolo del risultato e, accanto, il prezzo o l'orologio dell'attesa. Se le
## monete non bastano il simbolo è barrato, così lo stato non dipende solo dal colore.
func _draw_button(index: int) -> void:
	var rect: Rect2 = get_button_rect(index)
	var action: HotelSession.LightingAction = _actions[index]
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = GuestBar.CARD_COLOR if _affordable[index] else GuestBar.UPCOMING_CARD_COLOR
	background.border_color = GuestBar.BORDER_COLOR
	background.set_border_width_all(BORDER_PIXELS)
	background.set_corner_radius_all(GuestBar.CARD_RADIUS_PIXELS)
	draw_style_box(background, rect)

	var middle_y: float = rect.get_center().y
	var icon_center: Vector2 = Vector2(rect.position.x + ACTION_ICON_X_PIXELS, middle_y)
	GuestPainter.draw_lighting_icon(self, _get_resulting_lighting(action), icon_center, ACTION_ICON_RADIUS_PIXELS)
	if not _affordable[index]:
		var strike: Vector2 = Vector2(1.0, -1.0) * ACTION_ICON_RADIUS_PIXELS * 0.7
		draw_line(icon_center - strike, icon_center + strike, GuestPainter.INK_COLOR, STRIKE_PIXELS, true)

	var cost_center: Vector2 = Vector2(rect.position.x + COST_ICON_X_PIXELS, middle_y)
	if action == HotelSession.LightingAction.RESTORE_WAIT:
		GuestPainter.draw_stay_icon(self, cost_center, COST_ICON_RADIUS_PIXELS)
		return

	GuestPainter.draw_coin_icon(self, cost_center, COST_ICON_RADIUS_PIXELS)
	var price_position: Vector2 = cost_center + Vector2(PRICE_OFFSET_PIXELS, TEXT_BASELINE_OFFSET_PIXELS)
	var price_width: float = rect.end.x - price_position.x
	draw_string(ThemeDB.fallback_font, price_position, str(_prices[index]), HORIZONTAL_ALIGNMENT_LEFT, price_width, FONT_SIZE_PIXELS, GuestPainter.INK_COLOR)


## Restituisce la luce che la camera avrà dopo una modifica: è ciò che il simbolo mostra.
func _get_resulting_lighting(action: HotelSession.LightingAction) -> Need.Lighting:
	match action:
		HotelSession.LightingAction.MAKE_DARK:
			return Need.Lighting.DARK
		HotelSession.LightingAction.MAKE_BRIGHT:
			return Need.Lighting.BRIGHT
		_:
			return Need.Lighting.NORMAL
