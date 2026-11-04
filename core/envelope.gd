class_name Envelope
extends RefCounted
## Involucro: lo spazio totale dell'edificio dentro cui possono stare le camere.
##
## COSA FA: conosce le misure dello spazio disponibile e risponde a una domanda:
## «questo rettangolo di celle sta tutto dentro?».
## CHI LA USA: Grid, per rifiutare le camere che uscirebbero dall'edificio.
## PERCHÉ È SEPARATA: in futuro l'involucro potrà crescere quando l'hotel si
## espande, senza dover cambiare le regole delle camere.
## NOTA GDSCRIPT: «class_name» dà un nome alla classe, così gli altri file possono
## scrivere Envelope.new(). «extends RefCounted» crea un oggetto che non compare
## nella scena e che Godot elimina da solo quando nessuno lo usa più.
## COORDINATE: si contano le celle a partire da (0, 0), l'angolo in alto a
## sinistra. Come in tutto Godot 2D, la Y cresce verso il basso.

## Larghezza dell'involucro del prototipo, in celle (decisione D-010).
const PROTOTYPE_WIDTH_CELLS: int = 6
## Altezza dell'involucro del prototipo, in celle (decisione D-010).
const PROTOTYPE_HEIGHT_CELLS: int = 8

## Tutte le celle dell'involucro. Rect2i è un rettangolo a numeri interi, descritto
## dall'angolo in alto a sinistra (position) e dalle misure (size).
var _cells: Rect2i


## Crea un involucro delle misure indicate, in celle. _init() è la funzione che
## Godot chiama automaticamente quando si scrive Envelope.new(). Senza parametri
## si ottiene l'involucro del prototipo.
func _init(width_cells: int = PROTOTYPE_WIDTH_CELLS, height_cells: int = PROTOTYPE_HEIGHT_CELLS) -> void:
	_cells = Rect2i(0, 0, width_cells, height_cells)


## Restituisce tutte le celle dell'involucro, come rettangolo in celle.
func get_cells() -> Rect2i:
	return _cells


## Restituisce true se tutte le celle del rettangolo stanno dentro l'involucro.
## Il parametro cells è in celle. La funzione non modifica nulla.
func contains(cells: Rect2i) -> bool:
	# encloses() è vero solo se il rettangolo è interamente contenuto: una camera
	# che tocca il bordo va bene, una che lo supera anche di una cella no.
	return _cells.encloses(cells)
