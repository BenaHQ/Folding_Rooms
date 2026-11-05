class_name BuildButton
extends Control
## Un pulsante per costruire: mostra il prezzo di ciò che si compra e attiva la costruzione.
##
## COSA FA: disegna il pulsante nei suoi tre stati e avvisa quando viene toccato. Serve sia per le
## camere, per la piscina e per i piani. Non contiene regole: se si possa davvero costruire lo decide
## HotelSession (D-028, D-036, D-037).
## CHI LA USA: Hud e RoomEditor, che lo contengono come nodo figlio e gli passano i valori.
## PERCHÉ È SEPARATA: chi lo contiene gestisce altri tocchi, mentre il pulsante deve ricevere i suoi.
## Essendo un nodo a parte, ferma solo i tocchi caduti dentro il suo rettangolo.
## NOTA GDSCRIPT: «extends Control» indica un nodo d'interfaccia, che riceve i tocchi in _gui_input().
## Un «enum» è un elenco di valori con un nome. Un «segnale» è un avviso che un nodo lancia a chi si è collegato. @export rende una variabile
## impostabile dal file della scena. _draw() disegna il nodo. I
## simboli e i numeri non si traducono, quindi non serve tr().
## COORDINATE: pixel del nodo; (0, 0) è il suo angolo in alto a sinistra.

## Lanciato quando il giocatore tocca il pulsante.
signal pressed

## Il simbolo di ciò che il pulsante compra. Il valore sta nel file della scena: i numeri non vanno riordinati.
enum Icon {
	ROOM, ## Il segno «+», per una camera.
	POOL, ## Le onde, per la piscina.
	STOREY, ## La casetta, per un piano.
}

## Larghezza del pulsante, in pixel: abbastanza per il simbolo e un prezzo di tre cifre.
const WIDTH_PIXELS: float = 190.0
## Altezza del pulsante, in pixel: i 96 pixel valgono 48 dp su un telefono stretto.
const HEIGHT_PIXELS: float = 96.0
## Raggio del simbolo «+» o «X», in pixel.
const ACTION_ICON_RADIUS_PIXELS: float = 28.0
## Raggio dell'icona della moneta, in pixel.
const COIN_RADIUS_PIXELS: float = 16.0
## Distanza dal bordo sinistro del centro del simbolo e dell'icona della moneta, in pixel.
const ACTION_ICON_X_PIXELS: float = 44.0
const COIN_X_PIXELS: float = 96.0
## Distanza tra il centro della moneta e l'inizio del prezzo, in pixel.
const PRICE_OFFSET_PIXELS: float = 22.0
## Dimensione del testo del prezzo, in pixel.
const FONT_SIZE_PIXELS: int = 30
## Di quanto scendere per allineare il prezzo al centro dell'icona, in pixel.
const TEXT_BASELINE_OFFSET_PIXELS: float = 10.0
## Spessore del bordo, in pixel: normale e con la costruzione attiva.
const BORDER_PIXELS: int = 3
const ACTIVE_BORDER_PIXELS: int = 6
## Spessore della barra sul simbolo quando non si può costruire, in pixel.
const STRIKE_PIXELS: float = 6.0

## Che simbolo mostra il pulsante.
@export var icon: Icon = Icon.ROOM

## Il prezzo da mostrare, in monete.
var _price: int = 0
## true se ora si può costruire.
var _can_build: bool = false
## true se la modalità costruzione è attiva.
var _is_active: bool = false


## Godot chiama _gui_input() per ogni evento di tocco che arriva a questo nodo.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		accept_event()
		if (event as InputEventScreenTouch).pressed:
			pressed.emit()


## Godot chiama _draw() per disegnare il nodo. Lo stato si legge dal simbolo, non solo dal colore:
## il simbolo si può costruire, lo stesso barrato non si può, «X» annulla la costruzione in corso.
func _draw() -> void:
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = GuestBar.CARD_COLOR if _can_build or _is_active else GuestBar.UPCOMING_CARD_COLOR
	background.border_color = GuestBar.CURRENT_BORDER_COLOR if _is_active else GuestBar.BORDER_COLOR
	background.set_border_width_all(ACTIVE_BORDER_PIXELS if _is_active else BORDER_PIXELS)
	background.set_corner_radius_all(GuestBar.CARD_RADIUS_PIXELS)
	draw_style_box(background, Rect2(Vector2.ZERO, size))

	var middle_y: float = size.y / 2.0
	var icon_center: Vector2 = Vector2(ACTION_ICON_X_PIXELS, middle_y)
	if _is_active:
		GuestPainter.draw_fit_icon(self, Need.Fit.DOES_NOT_FIT, icon_center, ACTION_ICON_RADIUS_PIXELS)
	else:
		_draw_action_icon(icon_center)
		if not _can_build:
			var strike: Vector2 = Vector2(1.0, -1.0) * ACTION_ICON_RADIUS_PIXELS * 0.7
			draw_line(icon_center - strike, icon_center + strike, GuestPainter.INK_COLOR, STRIKE_PIXELS, true)

	var coin_center: Vector2 = Vector2(COIN_X_PIXELS, middle_y)
	GuestPainter.draw_coin_icon(self, coin_center, COIN_RADIUS_PIXELS)
	var price_position: Vector2 = coin_center + Vector2(PRICE_OFFSET_PIXELS, TEXT_BASELINE_OFFSET_PIXELS)
	var price_width: float = size.x - price_position.x
	draw_string(ThemeDB.fallback_font, price_position, str(_price), HORIZONTAL_ALIGNMENT_LEFT, price_width, FONT_SIZE_PIXELS, GuestPainter.INK_COLOR)


## Aggiorna ciò che il pulsante mostra. price è in monete, can_build dice se ora si può costruire e
## is_active se la modalità costruzione è attiva.
func update_state(price: int, can_build: bool, is_active: bool) -> void:
	_price = price
	_can_build = can_build
	_is_active = is_active
	queue_redraw()


## Disegna il simbolo di ciò che il pulsante compra.
func _draw_action_icon(center: Vector2) -> void:
	match icon:
		Icon.POOL:
			GuestPainter.draw_pool_icon(self, center, ACTION_ICON_RADIUS_PIXELS)
		Icon.STOREY:
			GuestPainter.draw_storey_icon(self, center, ACTION_ICON_RADIUS_PIXELS)
		_:
			GuestPainter.draw_plus_icon(self, center, ACTION_ICON_RADIUS_PIXELS)
