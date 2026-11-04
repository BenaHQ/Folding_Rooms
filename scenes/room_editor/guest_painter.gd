class_name GuestPainter
extends RefCounted
## Disegna ospiti e icone con forme segnaposto.
##
## COSA FA: disegna il corpo e il viso di un ospite, l'icona del suo bisogno e quella di come
## starebbe in una camera. Viso e icone cambiano forma, non solo colore (AGENTS.md, sezione 7).
## CHI LA USA: la scena RoomEditor e la barra GuestBar, dentro le loro funzioni _draw().
## PERCHÉ È SEPARATA: le due scene devono disegnare gli ospiti nello stesso modo. Non decide
## nessuna regola: riceve già il risultato di Need.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena. Tutte le
## funzioni sono «static»: si chiamano sulla classe, senza crearne un oggetto. Le funzioni
## draw_...() di Godot funzionano solo mentre il nodo disegna, cioè dentro _draw().
## COORDINATE: pixel del nodo che disegna, X verso destra e Y verso il basso. Negli angoli degli
## archi, 0 è verso destra e l'angolo cresce in senso orario: da 0 a PI si passa per il basso.

## Trasparenza di un ospite non ancora entrato: 1 è opaco, 0 è invisibile.
const PREVIEW_ALPHA: float = 0.55
## Raggio di un occhio, in pixel.
const EYE_RADIUS_PIXELS: float = 5.0
## Distanza di ogni occhio dal centro del viso, in pixel.
const EYE_SPACING_PIXELS: float = 9.0
## Raggio della bocca, in pixel.
const MOUTH_RADIUS_PIXELS: float = 7.0
## Distanza del centro della bocca sotto gli occhi, in pixel.
const MOUTH_OFFSET_PIXELS: float = 7.0
## Lato più corto di un corpo su cui il viso ha la misura piena, in pixel: i corpi più piccoli,
## come quelli sulle schede, hanno un viso proporzionalmente più piccolo.
const FACE_REFERENCE_PIXELS: float = 50.0
## Punti usati per disegnare un arco: abbastanza da sembrare curvo.
const ARC_POINTS: int = 12
## Spessore delle linee di viso e icone, in pixel.
const LINE_PIXELS: float = 4.0
## Misura della punta di una freccia, in frazioni del raggio dell'icona.
const ARROW_HEAD_FRACTION: float = 0.32

## Colore delle icone delle monete.
const COIN_COLOR: Color = Color(0.95, 0.75, 0.3)
## Colore di occhi, bocca e simboli.
const INK_COLOR: Color = Color(0.2, 0.14, 0.11)
## Colore di sfondo delle icone.
const BADGE_COLOR: Color = Color(1.0, 1.0, 1.0)


## Disegna un ospite appoggiato al punto floor_center. cell_pixels è il lato di una cella in
## pixel. fit decide l'espressione. pose_scale deforma il corpo per le reazioni: 1 è la misura
## normale. is_preview lo rende trasparente, perché non è ancora entrato.
static func draw_guest(canvas: CanvasItem, guest: Guest, floor_center: Vector2, cell_pixels: float, fit: Need.Fit, pose_scale: Vector2 = Vector2.ONE, is_preview: bool = false) -> void:
	var body_size: Vector2 = guest.body_size_cells * cell_pixels * pose_scale
	var body_rect: Rect2 = Rect2(floor_center - Vector2(body_size.x / 2.0, body_size.y), body_size)

	# StyleBoxFlat disegna un rettangolo arrotondato; con raggio pari a metà del lato più corto
	# diventa una capsula.
	var body: StyleBoxFlat = StyleBoxFlat.new()
	body.bg_color = guest.body_color
	if is_preview:
		body.bg_color.a = PREVIEW_ALPHA
	body.anti_aliasing = true
	body.set_corner_radius_all(int(minf(body_size.x, body_size.y) / 2.0))
	canvas.draw_style_box(body, body_rect)

	var face_scale: float = minf(minf(body_size.x, body_size.y) / FACE_REFERENCE_PIXELS, 1.0)
	_draw_face(canvas, _get_face_center(body_rect), fit, face_scale)


## Disegna l'icona del bisogno: frecce verticali per l'altezza, orizzontali per la lunghezza, un
## punto dentro un anello per una camera raccolta.
static func draw_need_icon(canvas: CanvasItem, shape: Need.Shape, center: Vector2, radius: float) -> void:
	_draw_badge(canvas, center, radius)
	var reach: float = radius * 0.6

	match shape:
		Need.Shape.TALL:
			_draw_arrow(canvas, center, center + Vector2(0.0, -reach), radius)
			_draw_arrow(canvas, center, center + Vector2(0.0, reach), radius)
		Need.Shape.LONG:
			_draw_arrow(canvas, center, center + Vector2(-reach, 0.0), radius)
			_draw_arrow(canvas, center, center + Vector2(reach, 0.0), radius)
		Need.Shape.COZY:
			canvas.draw_arc(center, reach, 0.0, TAU, ARC_POINTS * 2, INK_COLOR, LINE_PIXELS, true)
			canvas.draw_circle(center, radius * 0.18, INK_COLOR)


## Disegna l'icona di come starebbe l'ospite: spunta se sta bene, X se non entra, frecce verso
## il centro se è stipato, frecce verso l'esterno se la camera è troppo grande.
static func draw_fit_icon(canvas: CanvasItem, fit: Need.Fit, center: Vector2, radius: float) -> void:
	_draw_badge(canvas, center, radius)
	var reach: float = radius * 0.65

	match fit:
		Need.Fit.COMFORTABLE:
			var check: PackedVector2Array = PackedVector2Array([
				center + Vector2(-0.45, 0.0) * radius,
				center + Vector2(-0.1, 0.35) * radius,
				center + Vector2(0.5, -0.35) * radius,
			])
			canvas.draw_polyline(check, INK_COLOR, LINE_PIXELS, true)
		Need.Fit.DOES_NOT_FIT:
			canvas.draw_line(center + Vector2(-0.4, -0.4) * radius, center + Vector2(0.4, 0.4) * radius, INK_COLOR, LINE_PIXELS, true)
			canvas.draw_line(center + Vector2(0.4, -0.4) * radius, center + Vector2(-0.4, 0.4) * radius, INK_COLOR, LINE_PIXELS, true)
		Need.Fit.CRAMPED:
			_draw_arrow(canvas, center + Vector2(-reach, 0.0), center + Vector2(-radius * 0.08, 0.0), radius)
			_draw_arrow(canvas, center + Vector2(reach, 0.0), center + Vector2(radius * 0.08, 0.0), radius)
		Need.Fit.TOO_BIG:
			_draw_arrow(canvas, center + Vector2(-radius * 0.1, 0.0), center + Vector2(-reach, 0.0), radius)
			_draw_arrow(canvas, center + Vector2(radius * 0.1, 0.0), center + Vector2(reach, 0.0), radius)


## Disegna l'icona di una moneta.
static func draw_coin_icon(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	canvas.draw_circle(center, radius, COIN_COLOR)
	canvas.draw_arc(center, radius, 0.0, TAU, ARC_POINTS * 2, INK_COLOR, LINE_PIXELS, true)
	canvas.draw_arc(center, radius * 0.55, 0.0, TAU, ARC_POINTS * 2, INK_COLOR, LINE_PIXELS / 2.0, true)


## Disegna l'icona del tempo: un orologio con due lancette.
static func draw_stay_icon(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	_draw_badge(canvas, center, radius)
	canvas.draw_line(center, center + Vector2(0.0, -radius * 0.6), INK_COLOR, LINE_PIXELS, true)
	canvas.draw_line(center, center + Vector2(radius * 0.45, 0.0), INK_COLOR, LINE_PIXELS, true)


## Disegna l'icona degli ospiti in arrivo: la porta dell'hotel, con la maniglia.
static func draw_arrivals_icon(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	_draw_badge(canvas, center, radius)
	var door_size: Vector2 = Vector2(0.75, 1.15) * radius
	canvas.draw_rect(Rect2(center - door_size / 2.0, door_size), INK_COLOR, false, LINE_PIXELS)
	canvas.draw_circle(center + Vector2(radius * 0.18, 0.0), LINE_PIXELS / 2.0, INK_COLOR)


## Disegna l'icona per ricominciare: una freccia che gira in cerchio. Gli angoli sono in radianti: lo
## zero è a destra e si cresce in senso orario, perché in Godot la Y va verso il basso.
static func draw_reset_icon(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	_draw_badge(canvas, center, radius)
	var arc_radius: float = radius * 0.5
	var end_angle: float = TAU * 0.8
	canvas.draw_arc(center, arc_radius, 0.0, end_angle, ARC_POINTS * 2, INK_COLOR, LINE_PIXELS, true)

	# La punta è formata da due tratti che partono dalla fine dell'arco, lungo il verso di rotazione.
	var tip: Vector2 = center + Vector2.from_angle(end_angle) * arc_radius
	var forward: Vector2 = Vector2.from_angle(end_angle + PI / 2.0)
	var head_length: float = radius * ARROW_HEAD_FRACTION
	canvas.draw_line(tip, tip - forward.rotated(PI / 4.0) * head_length, INK_COLOR, LINE_PIXELS, true)
	canvas.draw_line(tip, tip - forward.rotated(-PI / 4.0) * head_length, INK_COLOR, LINE_PIXELS, true)


## Disegna l'icona della costruzione: un segno «+».
static func draw_plus_icon(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	_draw_badge(canvas, center, radius)
	var reach: float = radius * 0.55
	canvas.draw_line(center + Vector2(-reach, 0.0), center + Vector2(reach, 0.0), INK_COLOR, LINE_PIXELS, true)
	canvas.draw_line(center + Vector2(0.0, -reach), center + Vector2(0.0, reach), INK_COLOR, LINE_PIXELS, true)


## Disegna un viso in un'icona: sorridente se is_happy è true, triste altrimenti.
static func draw_mood_icon(canvas: CanvasItem, center: Vector2, radius: float, is_happy: bool) -> void:
	_draw_badge(canvas, center, radius)
	var fit: Need.Fit = Need.Fit.COMFORTABLE if is_happy else Need.Fit.CRAMPED
	_draw_face(canvas, center + Vector2(0.0, -radius * 0.25), fit, radius / FACE_REFERENCE_PIXELS * 2.0)


## Restituisce dove sta il viso: in cima a un corpo alto, a destra in uno lungo.
static func _get_face_center(body_rect: Rect2) -> Vector2:
	var center: Vector2 = body_rect.get_center()

	if body_rect.size.x > body_rect.size.y:
		return Vector2(body_rect.end.x - body_rect.size.y / 2.0, center.y)

	return Vector2(center.x, body_rect.position.y + body_rect.size.x / 2.0)


## Disegna occhi e bocca: sorriso se l'ospite sta bene, bocca all'ingiù negli altri casi.
## face_scale riduce tutte le misure del viso: 1 è la misura piena.
static func _draw_face(canvas: CanvasItem, center: Vector2, fit: Need.Fit, face_scale: float) -> void:
	var eye_offset: Vector2 = Vector2(EYE_SPACING_PIXELS * face_scale, 0.0)
	var eye_radius: float = EYE_RADIUS_PIXELS * face_scale
	var mouth_radius: float = MOUTH_RADIUS_PIXELS * face_scale
	var mouth_offset: float = MOUTH_OFFSET_PIXELS * face_scale
	var line_width: float = LINE_PIXELS * face_scale

	canvas.draw_circle(center - eye_offset, eye_radius, INK_COLOR)
	canvas.draw_circle(center + eye_offset, eye_radius, INK_COLOR)

	if fit == Need.Fit.COMFORTABLE:
		# Da 0 a PI l'arco passa per il basso: è un sorriso.
		canvas.draw_arc(center + Vector2(0.0, mouth_offset), mouth_radius, 0.0, PI, ARC_POINTS, INK_COLOR, line_width, true)
	else:
		# Da PI a TAU l'arco passa per l'alto: è una bocca triste. Va più in basso perché la sua
		# parte visibile sta sopra il centro dell'arco.
		canvas.draw_arc(center + Vector2(0.0, mouth_offset + mouth_radius), mouth_radius, PI, TAU, ARC_POINTS, INK_COLOR, line_width, true)


## Disegna lo sfondo rotondo di un'icona.
static func _draw_badge(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	canvas.draw_circle(center, radius, BADGE_COLOR)
	canvas.draw_arc(center, radius, 0.0, TAU, ARC_POINTS * 2, INK_COLOR, LINE_PIXELS, true)


## Disegna una freccia da from a to, con la punta su to. icon_radius è il raggio dell'icona, da
## cui dipende la misura della punta.
static func _draw_arrow(canvas: CanvasItem, from: Vector2, to: Vector2, icon_radius: float) -> void:
	canvas.draw_line(from, to, INK_COLOR, LINE_PIXELS, true)

	# La punta è formata da due tratti che partono da to e tornano indietro, inclinati di 45
	# gradi (PI / 4) rispetto alla freccia.
	var back: Vector2 = (from - to).normalized() * icon_radius * ARROW_HEAD_FRACTION
	canvas.draw_line(to, to + back.rotated(PI / 4.0), INK_COLOR, LINE_PIXELS, true)
	canvas.draw_line(to, to + back.rotated(-PI / 4.0), INK_COLOR, LINE_PIXELS, true)
