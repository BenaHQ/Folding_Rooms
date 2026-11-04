extends GutTest
## Test del calcolo con cui la prova di stile dispone la grafica della camera.
##
## COMPORTAMENTO PROTETTO: allungando una camera nulla viene stirato. Gli arredi hanno misura
## fissa e restano agganciati al loro lato, compaiono solo se c'è spazio, e la carta da parati
## non scivola. L'aspetto del disegno non è giudicabile da un test: va guardato sul telefono.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per avviarli è
## scritto in docs/STATO.md.
## PERCHÉ È SEPARATO: controlla solo la disposizione, mentre il gesto è in test_room_drag.gd
## e test_room_editor.gd.
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di GUT.
## COORDINATE: pixel, con Y verso il basso.

## Camera di partenza: 2×2 celle da 110 pixel.
const SMALL_ROOM: Rect2 = Rect2(100.0, 400.0, 220.0, 220.0)
## La stessa camera con il soffitto alzato di 2 celle: il pavimento non si è mosso.
const TALL_ROOM: Rect2 = Rect2(100.0, 180.0, 220.0, 440.0)
## Misura ben oltre ogni minimo degli arredi, in pixel.
const HUGE_ROOM_SIZE: Vector2 = Vector2(660.0, 880.0)
## Misura sotto ogni minimo degli arredi, in pixel.
const TINY_ROOM_SIZE: Vector2 = Vector2(10.0, 10.0)
## Scarto accettato nei confronti tra numeri decimali.
const TOLERANCE: float = 0.001


## Allungando la camera nessun arredo cambia misura: è ciò che evita la grafica stirata.
func test_pieces_keep_their_size_when_room_grows() -> void:
	for piece: Dictionary in RoomPainter.PIECES:
		var small_rect: Rect2 = RoomPainter.get_piece_rect(piece, SMALL_ROOM)
		var tall_rect: Rect2 = RoomPainter.get_piece_rect(piece, TALL_ROOM)
		assert_eq(small_rect.size, tall_rect.size)


## Gli arredi appoggiati restano sul pavimento e quelli appesi seguono il soffitto.
func test_pieces_follow_their_anchored_side() -> void:
	var ceiling_movement: float = TALL_ROOM.position.y - SMALL_ROOM.position.y

	for piece: Dictionary in RoomPainter.PIECES:
		var small_rect: Rect2 = RoomPainter.get_piece_rect(piece, SMALL_ROOM)
		var tall_rect: Rect2 = RoomPainter.get_piece_rect(piece, TALL_ROOM)
		var anchor: Vector2 = piece["anchor"]
		var expected_movement: float = 0.0 if anchor.y > 0.5 else ceiling_movement
		assert_almost_eq(tall_rect.position.y - small_rect.position.y, expected_movement, TOLERANCE)


## Un arredo è nascosto sotto il suo minimo, poi cresce gradualmente fino alla misura piena.
func test_piece_appears_gradually_after_minimum_size() -> void:
	var piece: Dictionary = RoomPainter.PIECES[0]
	var minimum: Vector2 = piece["min_room"]
	var halfway: Vector2 = minimum + Vector2.ONE * RoomPainter.APPEAR_DISTANCE_PIXELS / 2.0

	assert_eq(RoomPainter.get_piece_scale(piece, minimum), 0.0)
	assert_almost_eq(RoomPainter.get_piece_scale(piece, halfway), 0.5, TOLERANCE)
	assert_eq(RoomPainter.get_piece_scale(piece, HUGE_ROOM_SIZE), 1.0)
	assert_eq(RoomPainter.get_piece_scale(piece, TINY_ROOM_SIZE), 0.0)


## Conta l'asse più stretto: una camera alta ma stretta non deve mostrare mobili che non ci stanno.
func test_piece_needs_room_on_both_axes() -> void:
	var piece: Dictionary = RoomPainter.PIECES[0]
	var minimum: Vector2 = piece["min_room"]

	assert_eq(RoomPainter.get_piece_scale(piece, Vector2(minimum.x, HUGE_ROOM_SIZE.y)), 0.0)
	assert_eq(RoomPainter.get_piece_scale(piece, Vector2(HUGE_ROOM_SIZE.x, minimum.y)), 0.0)


## Nelle misure del prototipo, ogni arredo visibile deve stare dentro la camera.
func test_visible_pieces_stay_inside_room_at_every_cell_size() -> void:
	var cell_pixels: float = RoomEditor.CELL_SIZE_PIXELS

	for width_cells: int in range(1, Envelope.PROTOTYPE_WIDTH_CELLS + 1):
		for height_cells: int in range(1, Envelope.PROTOTYPE_HEIGHT_CELLS + 1):
			var room_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(width_cells, height_cells) * cell_pixels)

			for piece: Dictionary in RoomPainter.PIECES:
				if RoomPainter.get_piece_scale(piece, room_rect.size) > 0.0:
					assert_true(room_rect.encloses(RoomPainter.get_piece_rect(piece, room_rect)), "arredo fuori dalla camera %s" % [room_rect])


## La camera più piccola ha comunque un arredo: non deve sembrare vuota.
func test_smallest_room_shows_a_piece() -> void:
	var smallest_size: Vector2 = Vector2.ONE * RoomEditor.CELL_SIZE_PIXELS
	var visible_count: int = 0

	for piece: Dictionary in RoomPainter.PIECES:
		if RoomPainter.get_piece_scale(piece, smallest_size) > 0.0:
			visible_count += 1

	assert_gt(visible_count, 0)


## Lo stesso punto dell'involucro deve avere sempre le stesse coordinate nell'immagine ripetuta:
## così, spostando una parete, la carta da parati non scivola.
func test_tile_uvs_are_fixed_to_the_envelope() -> void:
	var points: PackedVector2Array = PackedVector2Array([Vector2(130.0, 250.0)])
	var uvs: PackedVector2Array = RoomPainter.compute_tile_uvs(points, Vector2(30.0, 50.0), Vector2(50.0, 100.0))

	assert_almost_eq(uvs[0].x, 2.0, TOLERANCE)
	assert_almost_eq(uvs[0].y, 2.0, TOLERANCE)
