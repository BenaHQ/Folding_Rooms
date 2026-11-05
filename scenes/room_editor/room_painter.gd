class_name RoomPainter
extends RefCounted
## Prova di stile: disegna una camera a strati, così si allunga senza rovinarsi.
##
## COSA FA: disegna carta da parati, pavimento, cornice e arredi dentro il contorno della
## camera. Nulla viene stirato: la carta da parati si ripete, le fasce hanno altezza fissa
## e ogni arredo ha misura fissa ed è agganciato a un lato della camera. Quando la camera
## cresce abbastanza compaiono nuovi arredi; quando si restringe spariscono.
## CHI LA USA: la scena RoomEditor, nella sua funzione _draw().
## PERCHÉ È SEPARATA: la prova serve a capire come costruire la grafica (scaletta, fase 3),
## quindi deve poter cambiare senza toccare il gesto. Non decide nessuna regola di gioco:
## gli arredi qui sono solo decorazione.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena e che
## Godot elimina da solo quando nessuno lo usa più. Una «texture» è un'immagine pronta per
## essere disegnata; uno «StyleBoxFlat» disegna un rettangolo con gli angoli arrotondati.
## COORDINATE: pixel del nodo RoomEditor, X verso destra e Y verso il basso. Nelle tabelle
## degli arredi ogni parte è in frazioni della misura dell'arredo: (0, 0) è il suo angolo
## in alto a sinistra e (1, 1) quello in basso a destra.

## Altezza della fascia del pavimento, in pixel.
const FLOOR_HEIGHT_PIXELS: float = 16.0
## Altezza della fascia in basso sulla parete (la boiserie), in pixel.
const WAINSCOT_HEIGHT_PIXELS: float = 34.0
## Altezza della cornice sotto il soffitto, in pixel.
const CORNICE_HEIGHT_PIXELS: float = 12.0
## Di quanto le fasce superano la camera prima del ritaglio, in pixel: deve essere più della
## curvatura massima del lato, così anche la parte incurvata resta coperta.
const BAND_OVERFLOW_PIXELS: float = 30.0

## Larghezza di una striscia della carta da parati, in pixel.
const WALLPAPER_STRIPE_PIXELS: int = 22
## Altezza del quadrato ripetuto della carta da parati, in pixel.
const WALLPAPER_TILE_HEIGHT_PIXELS: int = 44
## Lunghezza di un'asse del pavimento, in pixel.
const FLOOR_PLANK_PIXELS: int = 64
## Spessore della fessura tra due assi del pavimento, in pixel.
const FLOOR_SEAM_PIXELS: int = 3

## Spessore totale del muro attorno alla camera, in pixel.
const FRAME_OUTER_WIDTH_PIXELS: float = 13.0
## Spessore della parte chiara del muro, in pixel: il resto forma il bordo scuro.
const FRAME_INNER_WIDTH_PIXELS: float = 8.0

## Distanza del tappeto dalle pareti, in pixel. Il tappeto è l'unico elemento che si allunga,
## e solo in larghezza: è una fascia a tinta unita e non si deforma in modo visibile.
const RUG_SIDE_MARGIN_PIXELS: float = 24.0
## Altezza del tappeto, in pixel.
const RUG_HEIGHT_PIXELS: float = 9.0
## Di quanti pixel deve crescere la camera, oltre il minimo, perché un arredo arrivi alla
## misura piena: così compare gradualmente mentre il dito si muove.
const APPEAR_DISTANCE_PIXELS: float = 30.0

## Raggio degli angoli dei mobili, in pixel: forme morbide, come chiede il concept, sezione 9.
const RADIUS_SOFT: int = 7
## Raggio così grande da trasformare il rettangolo in un ovale, in pixel.
const RADIUS_OVAL: int = 60

## Colori della prova, dalla palette del concept: crema, terracotta e menta.
const WALLPAPER_LIGHT: Color = Color(0.98, 0.9, 0.74)
const WALLPAPER_DARK: Color = Color(0.95, 0.85, 0.67)
const WAINSCOT_COLOR: Color = Color(0.56, 0.75, 0.66)
## Seconda tavolozza: le camere devono avere colori distinti (concept, sezione 9).
const ROSE_WALLPAPER_LIGHT: Color = Color(0.97, 0.84, 0.76)
const ROSE_WALLPAPER_DARK: Color = Color(0.94, 0.78, 0.69)
const ROSE_WAINSCOT_COLOR: Color = Color(0.82, 0.55, 0.42)
const CORNICE_COLOR: Color = Color(1.0, 0.96, 0.87)
const FLOOR_COLOR: Color = Color(0.68, 0.45, 0.28)
const FLOOR_SEAM_COLOR: Color = Color(0.5, 0.31, 0.19)
const FRAME_LIGHT: Color = Color(1.0, 0.96, 0.87)
const FRAME_DARK: Color = Color(0.3, 0.21, 0.16)
const TERRACOTTA: Color = Color(0.77, 0.42, 0.28)
const TERRACOTTA_LIGHT: Color = Color(0.91, 0.66, 0.45)
const GREEN: Color = Color(0.2, 0.42, 0.36)
const GREEN_LIGHT: Color = Color(0.3, 0.55, 0.46)
const WOOD: Color = Color(0.55, 0.34, 0.2)
const WOOD_DARK: Color = Color(0.36, 0.22, 0.14)
const CREAM: Color = Color(1.0, 0.96, 0.87)
const SKY: Color = Color(0.73, 0.88, 0.92)
const LAMP_LIGHT: Color = Color(1.0, 0.93, 0.62)

## Le parti di ogni arredo: rettangolo in frazioni dell'arredo, colore e raggio degli angoli.
## Sono dati e non codice, così cambiare un arredo non richiede di toccare le funzioni.
const ARMCHAIR_PARTS: Array = [
	[Rect2(0.1, 0.86, 0.12, 0.14), WOOD_DARK, 2],
	[Rect2(0.78, 0.86, 0.12, 0.14), WOOD_DARK, 2],
	[Rect2(0.08, 0.0, 0.84, 0.72), GREEN, RADIUS_SOFT],
	[Rect2(0.05, 0.52, 0.9, 0.36), GREEN_LIGHT, RADIUS_SOFT],
	[Rect2(0.0, 0.38, 0.2, 0.5), GREEN, RADIUS_SOFT],
	[Rect2(0.8, 0.38, 0.2, 0.5), GREEN, RADIUS_SOFT],
	[Rect2(0.3, 0.2, 0.4, 0.34), TERRACOTTA, RADIUS_SOFT],
]
const PLANT_PARTS: Array = [
	[Rect2(0.46, 0.25, 0.08, 0.5), GREEN, 2],
	[Rect2(0.02, 0.44, 0.46, 0.17), GREEN_LIGHT, RADIUS_OVAL],
	[Rect2(0.52, 0.38, 0.46, 0.17), GREEN, RADIUS_OVAL],
	[Rect2(0.04, 0.18, 0.5, 0.2), GREEN, RADIUS_OVAL],
	[Rect2(0.46, 0.1, 0.5, 0.2), GREEN_LIGHT, RADIUS_OVAL],
	[Rect2(0.22, 0.0, 0.56, 0.23), GREEN, RADIUS_OVAL],
	[Rect2(0.18, 0.72, 0.64, 0.28), TERRACOTTA, RADIUS_SOFT],
]
const LAMP_PARTS: Array = [
	[Rect2(0.47, 0.0, 0.06, 0.55), WOOD_DARK, 0],
	[Rect2(0.34, 0.8, 0.32, 0.2), LAMP_LIGHT, RADIUS_OVAL],
	[Rect2(0.0, 0.5, 1.0, 0.38), TERRACOTTA_LIGHT, RADIUS_SOFT],
]
const PICTURE_PARTS: Array = [
	[Rect2(0.0, 0.0, 1.0, 1.0), WOOD, 3],
	[Rect2(0.1, 0.12, 0.8, 0.76), CREAM, 0],
	[Rect2(0.34, 0.2, 0.32, 0.6), GREEN_LIGHT, RADIUS_OVAL],
]
const WINDOW_PARTS: Array = [
	[Rect2(0.08, 0.0, 0.84, 1.0), CREAM, 3],
	[Rect2(0.15, 0.05, 0.7, 0.9), SKY, 0],
	[Rect2(0.47, 0.05, 0.06, 0.9), CREAM, 0],
	[Rect2(0.0, 0.0, 0.26, 1.0), GREEN_LIGHT, RADIUS_SOFT],
	[Rect2(0.74, 0.0, 0.26, 1.0), GREEN_LIGHT, RADIUS_SOFT],
]
const BOOKCASE_PARTS: Array = [
	[Rect2(0.0, 0.0, 1.0, 1.0), WOOD, 4],
	[Rect2(0.08, 0.05, 0.84, 0.27), WOOD_DARK, 0],
	[Rect2(0.08, 0.37, 0.84, 0.27), WOOD_DARK, 0],
	[Rect2(0.08, 0.69, 0.84, 0.27), WOOD_DARK, 0],
	[Rect2(0.13, 0.12, 0.12, 0.2), TERRACOTTA, 0],
	[Rect2(0.27, 0.09, 0.12, 0.23), CREAM, 0],
	[Rect2(0.41, 0.12, 0.12, 0.2), GREEN_LIGHT, 0],
	[Rect2(0.5, 0.42, 0.14, 0.22), TERRACOTTA_LIGHT, 0],
	[Rect2(0.66, 0.45, 0.14, 0.19), GREEN_LIGHT, 0],
	[Rect2(0.15, 0.74, 0.14, 0.22), CREAM, 0],
	[Rect2(0.31, 0.72, 0.14, 0.24), TERRACOTTA, 0],
]

## Gli arredi della camera, dal più lontano al più vicino.
## «size» è la misura in pixel e non cambia mai. «anchor» è il punto della camera a cui
## l'arredo è agganciato, in frazioni della camera: Y 0 è il soffitto e Y 1 il pavimento.
## «offset» è lo spostamento dell'angolo in alto a sinistra dell'arredo da quel punto, in
## pixel. «min_room» è la misura della camera, in pixel, oltre la quale l'arredo compare.
const PIECES: Array = [
	{
		"parts": WINDOW_PARTS,
		"size": Vector2(64.0, 108.0),
		"anchor": Vector2(0.0, 0.0),
		"offset": Vector2(20.0, 116.0),
		"min_room": Vector2(165.0, 295.0),
	},
	{
		"parts": PICTURE_PARTS,
		"size": Vector2(56.0, 48.0),
		"anchor": Vector2(0.28, 0.0),
		"offset": Vector2(-28.0, 42.0),
		"min_room": Vector2(165.0, 185.0),
	},
	{
		"parts": BOOKCASE_PARTS,
		"size": Vector2(84.0, 116.0),
		"anchor": Vector2(0.32, 1.0),
		"offset": Vector2(-42.0, -132.0),
		"min_room": Vector2(400.0, 150.0),
	},
	{
		"parts": LAMP_PARTS,
		"size": Vector2(46.0, 62.0),
		"anchor": Vector2(0.72, 0.0),
		"offset": Vector2(-23.0, 12.0),
		"min_room": Vector2(165.0, 185.0),
	},
	{
		"parts": ARMCHAIR_PARTS,
		"size": Vector2(72.0, 62.0),
		"anchor": Vector2(0.0, 1.0),
		"offset": Vector2(20.0, -78.0),
		"min_room": Vector2(60.0, 60.0),
	},
	{
		"parts": PLANT_PARTS,
		"size": Vector2(44.0, 92.0),
		"anchor": Vector2(1.0, 1.0),
		"offset": Vector2(-58.0, -108.0),
		"min_room": Vector2(165.0, 120.0),
	},
]

## La carta da parati: un'immagine piccola che si ripete.
var _wallpaper_texture: ImageTexture
## Le assi del pavimento: un'immagine piccola che si ripete.
var _floor_texture: ImageTexture
## Il colore della fascia in basso sulla parete.
var _wainscot_color: Color
## Il rettangolo arrotondato riusato per ogni parte degli arredi: colore e raggio cambiano
## ogni volta, e Godot registra il disegno con i valori di quel momento.
var _part_box: StyleBoxFlat = StyleBoxFlat.new()


## Prepara le immagini ripetute con i colori indicati, così ogni camera può avere i suoi.
## _init() è la funzione che Godot chiama con RoomPainter.new().
func _init(wallpaper_light: Color = WALLPAPER_LIGHT, wallpaper_dark: Color = WALLPAPER_DARK, wainscot: Color = WAINSCOT_COLOR) -> void:
	_wainscot_color = wainscot
	_wallpaper_texture = _make_wallpaper_texture(wallpaper_light, wallpaper_dark)
	_floor_texture = _make_floor_texture()
	_part_box.anti_aliasing = true


## Calcola dove va disegnato un arredo, in pixel: la misura resta sempre piena e cambia solo
## la posizione, che segue il punto della camera a cui è agganciato. room_rect è in pixel.
## È statica: si chiama sulla classe, senza creare un oggetto.
static func get_piece_rect(piece: Dictionary, room_rect: Rect2) -> Rect2:
	var anchor: Vector2 = piece["anchor"]
	var offset: Vector2 = piece["offset"]
	var anchor_point: Vector2 = room_rect.position + room_rect.size * anchor
	return Rect2(anchor_point + offset, piece["size"])


## Restituisce a quale frazione della misura piena disegnare un arredo: 0 nascosto, 1 pieno.
## Sale gradualmente nei pixel dopo il minimo, sia in larghezza sia in altezza: conta l'asse
## più stretto. room_size è in pixel.
static func get_piece_scale(piece: Dictionary, room_size: Vector2) -> float:
	var extra_pixels: Vector2 = room_size - (piece["min_room"] as Vector2)
	return clampf(minf(extra_pixels.x, extra_pixels.y) / APPEAR_DISTANCE_PIXELS, 0.0, 1.0)


## Calcola le coordinate dentro un'immagine ripetuta (UV) per i punti di un poligono.
## Dividendo per la misura dell'immagine, 1 unità equivale a una ripetizione. L'origine è
## fissa nell'involucro, quindi spostando una parete il disegno non scivola: la parete scopre
## altra carta da parati. Punti, origine e misura sono in pixel.
static func compute_tile_uvs(points: PackedVector2Array, tile_origin: Vector2, tile_size: Vector2) -> PackedVector2Array:
	var uvs: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		uvs.append((point - tile_origin) / tile_size)
	return uvs


## Disegna tutto ciò che sta dentro la camera, dietro la sagoma dell'ospite. canvas è il nodo
## che disegna, outline il contorno con l'eventuale lato incurvato, room_rect il rettangolo
## della camera ed envelope_origin l'angolo dell'involucro, tutti in pixel. Va chiamata solo
## dentro _draw() di canvas, l'unico momento in cui Godot accetta comandi di disegno.
func paint_interior(canvas: CanvasItem, outline: PackedVector2Array, room_rect: Rect2, envelope_origin: Vector2) -> void:
	# La carta da parati è agganciata all'involucro, così non scivola quando si muove un lato.
	var wallpaper_tile: Vector2 = Vector2(_wallpaper_texture.get_size())
	canvas.draw_colored_polygon(outline, Color.WHITE, compute_tile_uvs(outline, envelope_origin, wallpaper_tile), _wallpaper_texture)

	_paint_bands(canvas, outline, room_rect, envelope_origin)

	# Il tappeto segue la larghezza della camera e poggia sul pavimento.
	var floor_top: float = room_rect.end.y - FLOOR_HEIGHT_PIXELS
	var rug_rect: Rect2 = Rect2(room_rect.position.x + RUG_SIDE_MARGIN_PIXELS, floor_top - RUG_HEIGHT_PIXELS / 2.0, room_rect.size.x - 2.0 * RUG_SIDE_MARGIN_PIXELS, RUG_HEIGHT_PIXELS)
	if rug_rect.size.x > 0.0:
		_draw_part(canvas, rug_rect, TERRACOTTA, RADIUS_SOFT)

	for piece: Dictionary in PIECES:
		_paint_piece(canvas, piece, room_rect)

	# Riporta il sistema di riferimento alla normalità per chi disegna dopo.
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Disegna il muro attorno alla camera, sopra la sagoma dell'ospite: una linea scura e, al
## suo centro, una più sottile e chiara, così il muro risulta chiaro con due bordi scuri.
func paint_frame(canvas: CanvasItem, outline: PackedVector2Array) -> void:
	# draw_polyline() non chiude la forma da sola: si ripete il primo punto alla fine.
	var closed_outline: PackedVector2Array = outline.duplicate()
	closed_outline.append(outline[0])

	canvas.draw_polyline(closed_outline, FRAME_DARK, FRAME_OUTER_WIDTH_PIXELS, true)
	canvas.draw_polyline(closed_outline, FRAME_LIGHT, FRAME_INNER_WIDTH_PIXELS, true)


## Disegna boiserie, pavimento e cornice: fasce di altezza fissa, ritagliate sul contorno.
func _paint_bands(canvas: CanvasItem, outline: PackedVector2Array, room_rect: Rect2, envelope_origin: Vector2) -> void:
	var floor_top: float = room_rect.end.y - FLOOR_HEIGHT_PIXELS
	var wainscot_top: float = floor_top - WAINSCOT_HEIGHT_PIXELS

	# Le fasce escono dalla camera di BAND_OVERFLOW_PIXELS: il ritaglio le riporta sul contorno.
	var left: float = room_rect.position.x - BAND_OVERFLOW_PIXELS
	var width: float = room_rect.size.x + 2.0 * BAND_OVERFLOW_PIXELS

	var wainscot_band: Rect2 = Rect2(left, wainscot_top, width, floor_top - wainscot_top)
	for piece: PackedVector2Array in _clip_to_outline(wainscot_band, outline):
		canvas.draw_colored_polygon(piece, _wainscot_color)

	var cornice_band: Rect2 = Rect2(left, room_rect.position.y - BAND_OVERFLOW_PIXELS, width, CORNICE_HEIGHT_PIXELS + BAND_OVERFLOW_PIXELS)
	for piece: PackedVector2Array in _clip_to_outline(cornice_band, outline):
		canvas.draw_colored_polygon(piece, CORNICE_COLOR)

	# Le assi seguono il pavimento in altezza e l'involucro in larghezza: spostando il
	# pavimento salgono con lui, spostando una parete non scivolano.
	var floor_band: Rect2 = Rect2(left, floor_top, width, FLOOR_HEIGHT_PIXELS + BAND_OVERFLOW_PIXELS)
	var floor_tile: Vector2 = Vector2(_floor_texture.get_size())
	var floor_tile_origin: Vector2 = Vector2(envelope_origin.x, floor_top)
	for piece: PackedVector2Array in _clip_to_outline(floor_band, outline):
		canvas.draw_colored_polygon(piece, Color.WHITE, compute_tile_uvs(piece, floor_tile_origin, floor_tile), _floor_texture)


## Restituisce la parte di un rettangolo che cade dentro il contorno. Il risultato è un
## elenco perché in teoria il ritaglio può produrre più pezzi separati.
func _clip_to_outline(band: Rect2, outline: PackedVector2Array) -> Array[PackedVector2Array]:
	var band_points: PackedVector2Array = PackedVector2Array([
		band.position,
		band.position + Vector2(band.size.x, 0.0),
		band.end,
		band.position + Vector2(0.0, band.size.y),
	])
	return Geometry2D.intersect_polygons(outline, band_points)


## Disegna un arredo, se la camera è abbastanza grande. Compare ingrandendosi a partire dal
## lato a cui è agganciato: dal pavimento gli arredi appoggiati, dal soffitto quelli appesi.
func _paint_piece(canvas: CanvasItem, piece: Dictionary, room_rect: Rect2) -> void:
	var piece_scale: float = get_piece_scale(piece, room_rect.size)
	if piece_scale <= 0.0:
		return

	var piece_rect: Rect2 = get_piece_rect(piece, room_rect)
	var anchor: Vector2 = piece["anchor"]
	var pivot: Vector2 = Vector2(piece_rect.get_center().x, room_rect.end.y if anchor.y > 0.5 else room_rect.position.y)

	# draw_set_transform() fa valere per i disegni successivi la formula
	# punto finale = posizione + scala × punto. Con posizione = pivot × (1 - scala) il pivot
	# resta fermo mentre tutto il resto si ingrandisce attorno a lui.
	canvas.draw_set_transform(pivot * (1.0 - piece_scale), 0.0, Vector2.ONE * piece_scale)

	for part: Array in (piece["parts"] as Array):
		var fraction: Rect2 = part[0]
		var part_rect: Rect2 = Rect2(piece_rect.position + fraction.position * piece_rect.size, fraction.size * piece_rect.size)
		_draw_part(canvas, part_rect, part[1], part[2])


## Disegna un rettangolo con angoli arrotondati. Il raggio è in pixel.
func _draw_part(canvas: CanvasItem, rect: Rect2, color: Color, radius_pixels: int) -> void:
	_part_box.bg_color = color
	_part_box.set_corner_radius_all(radius_pixels)
	canvas.draw_style_box(_part_box, rect)


## Crea l'immagine della carta da parati: due strisce verticali di colore diverso. Il nodo
## che disegna deve avere texture_repeat attivo, altrimenti l'immagine non si ripete.
func _make_wallpaper_texture(light: Color, dark: Color) -> ImageTexture:
	var image: Image = Image.create_empty(2 * WALLPAPER_STRIPE_PIXELS, WALLPAPER_TILE_HEIGHT_PIXELS, false, Image.FORMAT_RGBA8)
	image.fill(light)
	image.fill_rect(Rect2i(WALLPAPER_STRIPE_PIXELS, 0, WALLPAPER_STRIPE_PIXELS, WALLPAPER_TILE_HEIGHT_PIXELS), dark)
	return ImageTexture.create_from_image(image)


## Crea l'immagine del pavimento: un'asse con la fessura sul lato destro.
func _make_floor_texture() -> ImageTexture:
	var image: Image = Image.create_empty(FLOOR_PLANK_PIXELS, int(FLOOR_HEIGHT_PIXELS), false, Image.FORMAT_RGBA8)
	image.fill(FLOOR_COLOR)
	image.fill_rect(Rect2i(FLOOR_PLANK_PIXELS - FLOOR_SEAM_PIXELS, 0, FLOOR_SEAM_PIXELS, int(FLOOR_HEIGHT_PIXELS)), FLOOR_SEAM_COLOR)
	return ImageTexture.create_from_image(image)
