class_name Hud
extends Control
## Le informazioni in alto sullo schermo: monete guadagnate e turni giocati.
##
## COSA FA: mostra due numeri, ognuno con la sua icona, sotto la zona occupata dal sistema.
## CHI LA USA: la scena principale main.tscn, che le passa i valori.
## PERCHÉ È SEPARATA: è interfaccia, senza regole. Lascia passare i tocchi, così non disturba le
## camere (nella scena ha mouse_filter impostato su «Ignore»).
## NOTA GDSCRIPT: «extends Control» indica un nodo d'interfaccia. _draw() disegna il nodo; Godot la
## richiama dopo queue_redraw(). I numeri non si traducono, quindi non serve tr().
## COORDINATE: pixel del nodo; (0, 0) è il suo angolo in alto a sinistra.

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

## Le monete da mostrare.
var _coins: int = 0
## I turni da mostrare.
var _turns: int = 0


## Aggiorna i numeri mostrati.
func update_values(coins: int, turns: int) -> void:
	_coins = coins
	_turns = turns
	queue_redraw()


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


## Disegna un numero accanto all'icona che ha il centro indicato.
func _draw_number(font: Font, icon_center: Vector2, value: int) -> void:
	var position: Vector2 = icon_center + Vector2(NUMBER_OFFSET_PIXELS, TEXT_BASELINE_OFFSET_PIXELS)
	draw_string(font, position, str(value), HORIZONTAL_ALIGNMENT_LEFT, NUMBER_WIDTH_PIXELS, FONT_SIZE_PIXELS, GuestPainter.INK_COLOR)


## Restituisce quanti pixel di gioco occupano notch e barre di sistema in alto. La zona sicura è in
## pixel dello schermo, quindi va convertita nella scala dell'area di gioco.
func _get_top_safe_margin() -> float:
	var window_height: float = float(DisplayServer.window_get_size().y)
	var safe_top: float = float(DisplayServer.get_display_safe_area().position.y)
	return maxf(safe_top, 0.0) * get_viewport_rect().size.y / window_height
