class_name ResetButton
extends Control
## Il pulsante per ricominciare la partita da zero, con una conferma.
##
## COSA FA: il primo tocco lo «arma»: cambia aspetto e per qualche secondo aspetta un secondo tocco,
## che conferma. Se il secondo tocco non arriva, torna da solo come prima. Non contiene regole.
## CHI LA USA: Hud, che lo contiene come nodo figlio e ne inoltra il segnale.
## PERCHÉ È SEPARATA: ricominciare cancella la partita in corso e non si può annullare, quindi un
## tocco per sbaglio non deve bastare. Questa attesa riguarda solo il pulsante.
## NOTA GDSCRIPT: «extends Control» indica un nodo d'interfaccia, che riceve i tocchi in _gui_input().
## Un «segnale» è un avviso che un nodo lancia a chi si è collegato. Un Tween può anche chiamare una
## funzione dopo un certo tempo. I simboli non si traducono, quindi non serve tr().
## COORDINATE: pixel del nodo; (0, 0) è il suo angolo in alto a sinistra.

## Lanciato quando il giocatore conferma con il secondo tocco.
signal confirmed

## Lato del pulsante, in pixel: i 96 pixel valgono 48 dp su un telefono stretto.
const SIDE_PIXELS: float = 96.0
## Raggio del simbolo, in pixel.
const ICON_RADIUS_PIXELS: float = 28.0
## Spessore del bordo, in pixel: normale e in attesa di conferma.
const BORDER_PIXELS: int = 3
const ARMED_BORDER_PIXELS: int = 6
## Per quanti secondi il pulsante aspetta la conferma.
const ARMED_SECONDS: float = 3.0
## Colore del bordo in attesa di conferma: avvisa che il prossimo tocco cancella la partita.
const ARMED_BORDER_COLOR: Color = Color(0.72, 0.13, 0.13)

## true se il pulsante sta aspettando la conferma.
var _is_armed: bool = false
## L'attesa in corso, per poterla fermare quando arriva la conferma.
var _armed_tween: Tween = null


## Godot chiama _gui_input() per ogni evento di tocco che arriva a questo nodo.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		accept_event()
		if (event as InputEventScreenTouch).pressed:
			_handle_press()


## Godot chiama _draw() per disegnare il nodo. Lo stato si legge dal simbolo, non solo dal colore:
## la freccia circolare propone di ricominciare, la spunta chiede di confermare.
func _draw() -> void:
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = GuestBar.CARD_COLOR
	background.border_color = ARMED_BORDER_COLOR if _is_armed else GuestBar.BORDER_COLOR
	background.set_border_width_all(ARMED_BORDER_PIXELS if _is_armed else BORDER_PIXELS)
	background.set_corner_radius_all(GuestBar.CARD_RADIUS_PIXELS)
	draw_style_box(background, Rect2(Vector2.ZERO, size))

	if _is_armed:
		GuestPainter.draw_fit_icon(self, Need.Fit.COMFORTABLE, size / 2.0, ICON_RADIUS_PIXELS)
	else:
		GuestPainter.draw_reset_icon(self, size / 2.0, ICON_RADIUS_PIXELS)


## Restituisce true se il pulsante sta aspettando la conferma.
func is_armed() -> bool:
	return _is_armed


## Il primo tocco arma il pulsante, il secondo conferma.
func _handle_press() -> void:
	if _is_armed:
		_set_armed(false)
		confirmed.emit()
		return

	_set_armed(true)
	# tween_interval() aspetta senza cambiare nulla; tween_callback() chiama poi una funzione. bind()
	# le aggiunge un parametro fisso, qui il valore false.
	_armed_tween = create_tween()
	_armed_tween.tween_interval(ARMED_SECONDS)
	_armed_tween.tween_callback(_set_armed.bind(false))


## Cambia lo stato di attesa e ferma l'eventuale attesa precedente.
func _set_armed(armed: bool) -> void:
	if _armed_tween != null:
		_armed_tween.kill()
		_armed_tween = null

	_is_armed = armed
	queue_redraw()
