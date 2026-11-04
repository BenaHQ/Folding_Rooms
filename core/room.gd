class_name Room
extends RefCounted
## Camera dell'hotel: un rettangolo di celle dentro l'edificio.
##
## COSA FA: ricorda quali celle occupa e calcola che forma avrebbe spostando uno
## dei suoi lati. Non decide se la modifica è permessa: conosce solo sé stessa,
## mentre per decidere serve sapere dove sono l'involucro e le altre camere.
## CHI LA USA: Grid, che tiene l'elenco delle camere e applica le regole.
## PERCHÉ È SEPARATA: non disegna nulla, quindi i test automatici possono provarla
## senza avviare il gioco.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena
## e che Godot elimina da solo quando nessuno lo usa più. Un «enum» è un elenco di
## valori con un nome, più leggibile e sicuro di un numero qualsiasi.
## COORDINATE: tutto è in celle; (0, 0) è in alto a sinistra e la Y cresce verso il
## basso, quindi salire significa diminuire la Y.

## I quattro lati di una camera che il giocatore può trascinare. Attenzione: il nome
## «Side» da solo non si può usare, perché Godot ha già un elenco globale con quel
## nome e il tipo di un parametro verrebbe confuso con il suo.
enum MovableSide {
	LEFT_WALL, ## Parete sinistra.
	RIGHT_WALL, ## Parete destra.
	CEILING, ## Soffitto, cioè il lato in alto.
	FLOOR, ## Pavimento, cioè il lato in basso.
}

## I servizi comuni che possono occupare un rettangolo della griglia al posto di una camera per ospiti.
enum Facility {
	NONE, ## Nessun servizio: è una camera normale, che ospita.
	POOL, ## La piscina: dà un bonus alle camere attaccate (D-036).
}

## Larghezza minima di una camera, in celle (decisione D-010).
const MIN_WIDTH_CELLS: int = 1
## Altezza minima di una camera, in celle (decisione D-010).
const MIN_HEIGHT_CELLS: int = 1

## Le celle occupate dalla camera. Le regole di Grid controllano ogni modifica:
## non cambiare questo valore senza passare da Grid.
var cells: Rect2i
## L'ospite della camera, oppure null se è libera. Le modifiche passano da Grid.
var guest: Guest = null
## Quanti turni resta l'ospite, compreso quello in corso. Vale 0 se la camera è libera.
var turns_left: int = 0
## La luce della camera (D-032). Le modifiche passano da HotelSession, che le fa pagare.
var lighting: Need.Lighting = Need.Lighting.NORMAL
## true se la camera sta tornando normale gratis: fino a fine giornata non può ospitare nessuno.
var is_under_works: bool = false
## Il servizio comune che occupa questo rettangolo. Un servizio si sposta e si deforma come una camera,
## con le stesse regole di Grid, ma non ospita nessuno e non conta tra le camere dell'hotel.
var facility: Facility = Facility.NONE


## Crea una camera che occupa il rettangolo indicato, in celle. room_facility indica il servizio comune
## che contiene, se ne contiene uno.
func _init(room_cells: Rect2i, room_facility: Facility = Facility.NONE) -> void:
	cells = room_cells
	facility = room_facility


## Restituisce true se due rettangoli di celle si toccano lungo una parete: hanno un lato alla stessa
## altezza o alla stessa distanza da sinistra, e quel lato è in comune per almeno una cella. Due
## rettangoli che si toccano solo in un angolo non hanno una parete in comune e non contano.
static func cells_touch(first: Rect2i, second: Rect2i) -> bool:
	var share_column_line: bool = first.end.x == second.position.x or second.end.x == first.position.x
	var share_row_line: bool = first.end.y == second.position.y or second.end.y == first.position.y
	# Due intervalli hanno un tratto in comune se ognuno comincia prima che l'altro finisca.
	var rows_overlap: bool = first.position.y < second.end.y and second.position.y < first.end.y
	var columns_overlap: bool = first.position.x < second.end.x and second.position.x < first.end.x
	return (share_column_line and rows_overlap) or (share_row_line and columns_overlap)


## Restituisce true se questo rettangolo è un servizio comune e non una camera per ospiti.
func is_facility() -> bool:
	return facility != Facility.NONE


## Restituisce true se un rettangolo ha le misure minime di una camera. Il parametro
## è in celle. «static» significa che la funzione si chiama sulla classe, con
## Room.has_allowed_size(...), senza dover creare una camera.
static func has_allowed_size(room_cells: Rect2i) -> bool:
	return room_cells.size.x >= MIN_WIDTH_CELLS and room_cells.size.y >= MIN_HEIGHT_CELLS


## Restituisce il lato di fronte a quello indicato: una parete condivisa è la parete destra
## di una camera e la parete sinistra di quella accanto.
static func opposite_side(side: MovableSide) -> MovableSide:
	match side:
		MovableSide.LEFT_WALL:
			return MovableSide.RIGHT_WALL
		MovableSide.RIGHT_WALL:
			return MovableSide.LEFT_WALL
		MovableSide.CEILING:
			return MovableSide.FLOOR
		_:
			return MovableSide.CEILING


## Restituisce dove si trova un lato di un rettangolo, in celle: la X per le pareti e la Y per
## soffitto e pavimento. end indica il primo punto oltre il rettangolo, cioè il suo bordo.
static func side_coordinate(room_cells: Rect2i, side: MovableSide) -> int:
	match side:
		MovableSide.LEFT_WALL:
			return room_cells.position.x
		MovableSide.RIGHT_WALL:
			return room_cells.end.x
		MovableSide.CEILING:
			return room_cells.position.y
		_:
			return room_cells.end.y


## Restituisce true se il lato di room_cells è lungo almeno quanto il lato di other_cells che
## ha di fronte, e lo copre tutto. Solo così la parete può spostare l'altra camera lasciandola
## rettangolare. Non controlla se le due camere si toccano. Tutto è in celle.
static func side_span_covers(room_cells: Rect2i, side: MovableSide, other_cells: Rect2i) -> bool:
	if side == MovableSide.LEFT_WALL or side == MovableSide.RIGHT_WALL:
		return other_cells.position.y >= room_cells.position.y and other_cells.end.y <= room_cells.end.y

	return other_cells.position.x >= room_cells.position.x and other_cells.end.x <= room_cells.end.x


## Restituisce le celle che la camera occuperebbe spostando un lato, senza
## modificare la camera. offset_cells segue gli assi dello schermo, come il dito:
## positivo verso destra o verso il basso, negativo verso sinistra o verso l'alto.
## Se il lato oltrepassa quello opposto, le misure del risultato sono zero o
## negative: il controllo spetta a chi chiama, con has_allowed_size().
func cells_after_moving(side: MovableSide, offset_cells: int) -> Rect2i:
	var result: Rect2i = cells

	# Il rettangolo è descritto dall'angolo in alto a sinistra e dalle misure.
	# Destra e pavimento cambiano solo la misura. Sinistra e soffitto spostano
	# anche l'angolo, e la misura cambia al contrario: salendo di una cella (-1) il
	# soffitto rende la camera più alta di una cella (+1), a pavimento fermo.
	match side:
		MovableSide.LEFT_WALL:
			result.position.x += offset_cells
			result.size.x -= offset_cells
		MovableSide.RIGHT_WALL:
			result.size.x += offset_cells
		MovableSide.CEILING:
			result.position.y += offset_cells
			result.size.y -= offset_cells
		MovableSide.FLOOR:
			result.size.y += offset_cells

	return result
