class_name Envelope
extends RefCounted
## Involucro: lo spazio totale dell'edificio dentro cui possono stare le camere.
##
## COSA FA: conosce le misure dello spazio disponibile e risponde a una domanda:
## «questo rettangolo di celle sta tutto dentro?».
## CHI LA USA: Grid, per rifiutare le camere che uscirebbero dall'edificio.
## PERCHÉ È SEPARATA: l'involucro cresce quando l'hotel si espande, senza dover
## cambiare le regole delle camere.
## PIANI (decisione D-037): i piani aperti sono quelli in basso, e ogni nuovo piano si
## aggiunge in cima. Le camere possono stare solo nei piani aperti.
## NOTA GDSCRIPT: «class_name» dà un nome alla classe, così gli altri file possono
## scrivere Envelope.new(). «extends RefCounted» crea un oggetto che non compare
## nella scena e che Godot elimina da solo quando nessuno lo usa più.
## COORDINATE: si contano le celle a partire da (0, 0), l'angolo in alto a
## sinistra. Come in tutto Godot 2D, la Y cresce verso il basso.

## Larghezza dell'involucro del prototipo, in celle (decisione D-010).
const PROTOTYPE_WIDTH_CELLS: int = 6
## Altezza dell'involucro del prototipo, in celle (decisione D-010).
const PROTOTYPE_HEIGHT_CELLS: int = 8
## Valore di open_storeys che apre tutti i piani.
const ALL_STOREYS: int = -1

## Tutte le celle che l'involucro può avere con ogni piano aperto. Rect2i è un rettangolo a numeri
## interi, descritto dall'angolo in alto a sinistra (position) e dalle misure (size).
var _full_cells: Rect2i
## Quanti piani sono aperti, contando dal basso. Un piano è alto una cella.
var _open_storeys: int


## Crea un involucro delle misure indicate, in celle. _init() è la funzione che
## Godot chiama automaticamente quando si scrive Envelope.new(). Senza parametri
## si ottiene l'involucro del prototipo, tutto aperto. open_storeys indica quanti piani
## sono aperti: ALL_STOREYS li apre tutti.
func _init(width_cells: int = PROTOTYPE_WIDTH_CELLS, height_cells: int = PROTOTYPE_HEIGHT_CELLS, open_storeys: int = ALL_STOREYS) -> void:
	_full_cells = Rect2i(0, 0, width_cells, height_cells)
	_open_storeys = height_cells if open_storeys == ALL_STOREYS else open_storeys


## Restituisce le celle dei piani aperti, come rettangolo in celle. La Y cresce verso il basso, quindi
## il rettangolo finisce sul fondo dell'edificio e comincia tanto più in alto quanti più piani sono aperti.
func get_cells() -> Rect2i:
	var closed_storeys: int = get_closed_storeys()
	return Rect2i(_full_cells.position.x, _full_cells.position.y + closed_storeys, _full_cells.size.x, _open_storeys)


## Restituisce quanti piani sono aperti.
func get_open_storeys() -> int:
	return _open_storeys


## Restituisce quanti piani restano da aprire.
func get_closed_storeys() -> int:
	return _full_cells.size.y - _open_storeys


## Apre un piano in cima. Restituisce true se l'ha aperto, false se erano già aperti tutti.
func add_storey() -> bool:
	if get_closed_storeys() <= 0:
		return false

	_open_storeys += 1
	return true


## Restituisce true se tutte le celle del rettangolo stanno nei piani aperti.
## Il parametro cells è in celle. La funzione non modifica nulla.
func contains(cells: Rect2i) -> bool:
	# encloses() è vero solo se il rettangolo è interamente contenuto: una camera
	# che tocca il bordo va bene, una che lo supera anche di una cella no.
	return get_cells().encloses(cells)
