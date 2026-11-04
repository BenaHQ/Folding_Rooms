class_name GuestBar
extends Control
## Barra in fondo allo schermo: l'ospite di turno con le sue condizioni e chi è in fila dietro.
##
## COSA FA: mostra l'ospite di turno (bisogno, turni di permanenza, compenso da comodo e da
## scomodo), il pulsante per rifiutarlo e i prossimi ospiti. Non contiene regole.
## CHI LA USA: la scena principale main.tscn, che la collega a RoomEditor.
## PERCHÉ È SEPARATA: è interfaccia, non gesto. Comunica verso l'alto con un segnale, così non ha
## bisogno di sapere che RoomEditor esiste.
## NOTA GDSCRIPT: «extends Control» indica un nodo d'interfaccia, che riceve i tocchi in
## _gui_input(). Un «segnale» è un avviso che un nodo lancia a chi si è collegato. _draw() disegna
## il nodo. I numeri non si traducono, quindi non serve tr().
## COORDINATE: pixel del nodo; (0, 0) è il suo angolo in alto a sinistra.

## Lanciato quando il giocatore tocca il pulsante per rifiutare l'ospite di turno.
signal refuse_pressed

## Altezza delle schede, in pixel: più dei 96 pixel che valgono 48 dp su un telefono stretto.
const CARD_HEIGHT_PIXELS: float = 150.0
## Spazio tra le schede e attorno a esse, in pixel.
const CARD_GAP_PIXELS: float = 14.0
## Larghezza della scheda dell'ospite di turno, in pixel.
const CURRENT_CARD_WIDTH_PIXELS: float = 320.0
## Larghezza del pulsante per rifiutare, in pixel: è il minimo comodo per un dito.
const REFUSE_WIDTH_PIXELS: float = 96.0
## Raggio degli angoli di una scheda, in pixel.
const CARD_RADIUS_PIXELS: int = 16
## Raggio dell'icona del bisogno sulla scheda dell'ospite di turno, in pixel.
const NEED_ICON_RADIUS_PIXELS: float = 22.0
## Raggio delle icone accanto ai numeri, in pixel.
const VALUE_ICON_RADIUS_PIXELS: float = 17.0
## Margine interno usato per far stare l'ospite nella scheda, in pixel.
const CARD_PADDING_PIXELS: float = 16.0
## Lato di una cella usato per disegnare gli ospiti nelle schede, in pixel, se ci stanno.
const CARD_CELL_PIXELS: float = 60.0
## Frazione della scheda di turno riservata all'ospite, a sinistra; il resto va ai numeri.
const FIGURE_AREA_FRACTION: float = 0.45
## Distanza verticale tra le righe di numeri, in pixel.
const VALUE_ROW_PIXELS: float = 44.0
## Distanza tra il centro di un'icona e l'inizio del suo numero, in pixel.
const VALUE_TEXT_OFFSET_PIXELS: float = 26.0
## Dimensione del testo dei numeri, in pixel.
const FONT_SIZE_PIXELS: int = 32
## Di quanto scendere per allineare un numero al centro dell'icona, in pixel.
const TEXT_BASELINE_OFFSET_PIXELS: float = 11.0
## Larghezza riservata a un numero, in pixel.
const VALUE_TEXT_WIDTH_PIXELS: float = 80.0
## Raggio dell'icona X sul pulsante per rifiutare, in pixel.
const REFUSE_ICON_RADIUS_PIXELS: float = 30.0
## Spessore del bordo di una scheda, in pixel: normale e per l'ospite di turno.
const BORDER_PIXELS: int = 3
const CURRENT_BORDER_PIXELS: int = 6

## Colori segnaposto delle schede.
const CARD_COLOR: Color = Color(1.0, 0.98, 0.93)
const UPCOMING_CARD_COLOR: Color = Color(0.93, 0.88, 0.8)
const BORDER_COLOR: Color = Color(0.62, 0.55, 0.47)
const CURRENT_BORDER_COLOR: Color = Color(0.09, 0.47, 0.36)

## L'ospite di turno, oppure null finché la scena principale non lo comunica.
var _current_guest: Guest = null
## Gli ospiti visibili in fila.
var _upcoming_guests: Array[Guest] = []


## Godot chiama _ready() quando il nodo entra nella scena: qui si riserva l'altezza della barra,
## lasciando libera la zona delle barre di sistema in basso.
func _ready() -> void:
	offset_top = -(CARD_HEIGHT_PIXELS + CARD_GAP_PIXELS + _get_bottom_safe_margin())


## Godot chiama _gui_input() per ogni evento di tocco che arriva a questo nodo.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		accept_event()

		if touch.pressed and get_refuse_rect().has_point(touch.position):
			refuse_pressed.emit()


## Godot chiama _draw() per disegnare il nodo.
func _draw() -> void:
	if _current_guest != null:
		_draw_current_card(_current_guest, get_current_card_rect())

	_draw_refuse_button(get_refuse_rect())

	for index: int in _upcoming_guests.size():
		_draw_upcoming_card(_upcoming_guests[index], get_upcoming_card_rect(index))


## Aggiorna gli ospiti mostrati.
func update_queue(current_guest: Guest, upcoming_guests: Array[Guest]) -> void:
	_current_guest = current_guest
	_upcoming_guests = upcoming_guests
	queue_redraw()


## Restituisce il rettangolo della scheda dell'ospite di turno, in pixel del nodo.
func get_current_card_rect() -> Rect2:
	return Rect2(CARD_GAP_PIXELS, 0.0, CURRENT_CARD_WIDTH_PIXELS, CARD_HEIGHT_PIXELS)


## Restituisce il rettangolo del pulsante per rifiutare, in pixel del nodo.
func get_refuse_rect() -> Rect2:
	return Rect2(get_current_card_rect().end.x + CARD_GAP_PIXELS, 0.0, REFUSE_WIDTH_PIXELS, CARD_HEIGHT_PIXELS)


## Restituisce il rettangolo di una scheda in fila, in pixel del nodo. Le schede dividono in parti
## uguali lo spazio rimasto a destra.
func get_upcoming_card_rect(index: int) -> Rect2:
	var count: float = float(HotelSession.VISIBLE_UPCOMING_GUESTS)
	var start_x: float = get_refuse_rect().end.x + CARD_GAP_PIXELS
	var card_width: float = (size.x - start_x - count * CARD_GAP_PIXELS) / count
	return Rect2(start_x + index * (card_width + CARD_GAP_PIXELS), 0.0, card_width, CARD_HEIGHT_PIXELS)


## Restituisce quanti pixel di gioco occupano le barre di sistema in basso. La zona sicura è in
## pixel dello schermo, quindi va convertita nella scala dell'area di gioco.
func _get_bottom_safe_margin() -> float:
	var window_height: float = float(DisplayServer.window_get_size().y)
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var bottom_pixels: float = maxf(window_height - safe_area.end.y, 0.0)
	return bottom_pixels * get_viewport_rect().size.y / window_height


## Disegna la scheda dell'ospite di turno: a sinistra lui e il bisogno, a destra i numeri.
func _draw_current_card(guest: Guest, rect: Rect2) -> void:
	_draw_card_background(rect, CARD_COLOR, CURRENT_BORDER_COLOR, CURRENT_BORDER_PIXELS)

	var figure_area: Rect2 = Rect2(rect.position, Vector2(rect.size.x * FIGURE_AREA_FRACTION, rect.size.y))
	_draw_guest_in(guest, figure_area)

	var icon_center: Vector2 = rect.position + Vector2.ONE * (NEED_ICON_RADIUS_PIXELS + BORDER_PIXELS)
	GuestPainter.draw_need_icon(self, guest.need.shape, icon_center, NEED_ICON_RADIUS_PIXELS)

	# Tre righe centrate in altezza: turni di permanenza, compenso da comodo e da scomodo.
	var column_x: float = figure_area.end.x + CARD_PADDING_PIXELS
	var first_row_y: float = rect.get_center().y - VALUE_ROW_PIXELS
	var row_centers: Array[Vector2] = [
		Vector2(column_x, first_row_y),
		Vector2(column_x, first_row_y + VALUE_ROW_PIXELS),
		Vector2(column_x, first_row_y + 2.0 * VALUE_ROW_PIXELS),
	]

	GuestPainter.draw_stay_icon(self, row_centers[0], VALUE_ICON_RADIUS_PIXELS)
	_draw_value(row_centers[0], str(guest.stay_turns))
	GuestPainter.draw_mood_icon(self, row_centers[1], VALUE_ICON_RADIUS_PIXELS, true)
	_draw_value(row_centers[1], str(guest.comfortable_pay))
	GuestPainter.draw_mood_icon(self, row_centers[2], VALUE_ICON_RADIUS_PIXELS, false)
	_draw_value(row_centers[2], str(guest.uncomfortable_pay))


## Disegna il numero accanto all'icona che ha il centro indicato.
func _draw_value(icon_center: Vector2, text: String) -> void:
	var position: Vector2 = icon_center + Vector2(VALUE_TEXT_OFFSET_PIXELS, TEXT_BASELINE_OFFSET_PIXELS)
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, VALUE_TEXT_WIDTH_PIXELS, FONT_SIZE_PIXELS, GuestPainter.INK_COLOR)


## Disegna una scheda in fila: solo l'ospite e il suo bisogno, per lasciare il posto a quella di turno.
func _draw_upcoming_card(guest: Guest, rect: Rect2) -> void:
	_draw_card_background(rect, UPCOMING_CARD_COLOR, BORDER_COLOR, BORDER_PIXELS)
	_draw_guest_in(guest, rect)

	var icon_center: Vector2 = rect.position + Vector2.ONE * (VALUE_ICON_RADIUS_PIXELS + BORDER_PIXELS)
	GuestPainter.draw_need_icon(self, guest.need.shape, icon_center, VALUE_ICON_RADIUS_PIXELS)


## Disegna il pulsante per rifiutare: la X dice il significato con una forma, senza testo.
func _draw_refuse_button(rect: Rect2) -> void:
	_draw_card_background(rect, CARD_COLOR, BORDER_COLOR, BORDER_PIXELS)
	GuestPainter.draw_fit_icon(self, Need.Fit.DOES_NOT_FIT, rect.get_center(), REFUSE_ICON_RADIUS_PIXELS)


## Disegna lo sfondo arrotondato di una scheda.
func _draw_card_background(rect: Rect2, color: Color, border_color: Color, border_pixels: int) -> void:
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = color
	card.border_color = border_color
	card.set_border_width_all(border_pixels)
	card.set_corner_radius_all(CARD_RADIUS_PIXELS)
	draw_style_box(card, rect)


## Disegna un ospite sorridente appoggiato in fondo a un'area. Il lato della cella si riduce se
## l'ospite non ci starebbe alla misura normale.
func _draw_guest_in(guest: Guest, area: Rect2) -> void:
	var available: Vector2 = area.size - Vector2.ONE * 2.0 * CARD_PADDING_PIXELS
	var fit_ratio: Vector2 = available / guest.body_size_cells
	var cell_pixels: float = minf(CARD_CELL_PIXELS, minf(fit_ratio.x, fit_ratio.y))
	var floor_center: Vector2 = Vector2(area.get_center().x, area.end.y - CARD_PADDING_PIXELS)
	GuestPainter.draw_guest(self, guest, floor_center, cell_pixels, Need.Fit.COMFORTABLE)
