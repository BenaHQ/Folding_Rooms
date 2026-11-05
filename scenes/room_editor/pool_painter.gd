class_name PoolPainter
extends RoomPainter
## Disegna la piscina: acqua con file di onde, dentro lo stesso muro delle camere.
##
## COSA FA: sostituisce l'interno di una camera con l'acqua. Le onde hanno misura fissa e sono agganciate
## all'involucro: allungando la piscina non si stirano, ne compaiono altre (D-018, D-036).
## CHI LA USA: la scena RoomEditor, nella sua funzione _draw(), come il disegno di ogni altra camera.
## PERCHÉ È SEPARATA: la piscina è solo un aspetto diverso. Non decide nessuna regola: il bonus sta in
## HotelSession. La grafica è un segnaposto.
## NOTA GDSCRIPT: «extends RoomPainter» eredita tutto da RoomPainter, compreso il muro, e la funzione
## scritta qui sotto prende il posto di quella con lo stesso nome.
## COORDINATE: pixel del nodo che disegna, X verso destra e Y verso il basso.

## Colore dell'acqua.
const WATER_COLOR: Color = Color(0.47, 0.76, 0.82)
## Colore delle onde.
const WAVE_COLOR: Color = Color(0.88, 0.96, 0.97)
## Distanza tra due file di onde, in pixel.
const WAVE_ROW_SPACING_PIXELS: float = 44.0
## Margine delle onde dal bordo della piscina, in pixel: maggiore della curvatura di un lato trascinato.
const WAVE_MARGIN_PIXELS: float = 20.0
## Distanza tra due punti di un'onda, in pixel.
const WAVE_STEP_PIXELS: float = 8.0
## Lunghezza di un'onda intera, in pixel.
const WAVE_LENGTH_PIXELS: float = 48.0
## Quanto un'onda sale e scende, in pixel.
const WAVE_HEIGHT_PIXELS: float = 5.0
## Spessore delle onde, in pixel.
const WAVE_WIDTH_PIXELS: float = 4.0
## Punti minimi di una linea: con meno non c'è nulla da disegnare.
const MIN_LINE_POINTS: int = 2


## Calcola le file di onde di una piscina, in pixel. È statica: si chiama sulla classe, senza creare un
## oggetto. Le file e la forma delle onde dipendono dalla posizione rispetto all'involucro, non dalla
## misura della piscina: spostando una parete, le onde restano ferme.
static func get_wave_lines(room_rect: Rect2, envelope_origin: Vector2) -> Array[PackedVector2Array]:
	var lines: Array[PackedVector2Array] = []
	var area: Rect2 = room_rect.grow(-WAVE_MARGIN_PIXELS)

	# ceilf() arrotonda per eccesso: dà la prima fila che cade dentro l'area.
	var row: float = ceilf((area.position.y - envelope_origin.y) / WAVE_ROW_SPACING_PIXELS)
	while envelope_origin.y + row * WAVE_ROW_SPACING_PIXELS <= area.end.y:
		var line: PackedVector2Array = _build_wave(area, envelope_origin, envelope_origin.y + row * WAVE_ROW_SPACING_PIXELS)
		if line.size() >= MIN_LINE_POINTS:
			lines.append(line)
		row += 1.0

	return lines


## Costruisce una fila di onde all'altezza y, dentro area. sin() sale e scende una volta quando il suo
## valore va da 0 a TAU, cioè un giro intero. Tutto è in pixel.
static func _build_wave(area: Rect2, envelope_origin: Vector2, y: float) -> PackedVector2Array:
	var line: PackedVector2Array = PackedVector2Array()
	var step: float = ceilf((area.position.x - envelope_origin.x) / WAVE_STEP_PIXELS)

	while envelope_origin.x + step * WAVE_STEP_PIXELS <= area.end.x:
		var x_from_origin: float = step * WAVE_STEP_PIXELS
		var wave_y: float = y + WAVE_HEIGHT_PIXELS * sin(x_from_origin / WAVE_LENGTH_PIXELS * TAU)
		line.append(Vector2(envelope_origin.x + x_from_origin, wave_y))
		step += 1.0

	return line


## Disegna l'acqua e le onde. I parametri sono quelli di RoomPainter.paint_interior().
func paint_interior(canvas: CanvasItem, outline: PackedVector2Array, room_rect: Rect2, envelope_origin: Vector2) -> void:
	canvas.draw_colored_polygon(outline, WATER_COLOR)

	for line: PackedVector2Array in get_wave_lines(room_rect, envelope_origin):
		canvas.draw_polyline(line, WAVE_COLOR, WAVE_WIDTH_PIXELS, true)
