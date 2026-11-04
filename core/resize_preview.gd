class_name ResizePreview
extends RefCounted
## Anteprima di una modifica: come diventerebbe la camera e se è permesso.
##
## COSA FA: conserva il risultato di un controllo di Grid. È solo un contenitore di
## dati, senza regole.
## CHI LA USA: la crea Grid e la legge la scena durante il trascinamento, per mostrare
## il risultato previsto, le camere vicine coinvolte e il motivo di un eventuale rifiuto.
## PERCHÉ È SEPARATA: un solo valore vero/falso non basterebbe, perché il giocatore
## deve capire perché una modifica è bloccata (concept, sezione 11).
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena
## e che Godot elimina da solo quando nessuno lo usa più. Un «enum» è un elenco di
## valori con un nome.

## Motivi per cui una modifica può essere rifiutata.
enum Rejection {
	NONE, ## Nessun rifiuto: la modifica è permessa.
	TOO_SMALL, ## La camera scenderebbe sotto le misure minime.
	OUTSIDE_ENVELOPE, ## La camera uscirebbe dall'involucro.
	OVERLAPS_ROOM, ## La camera finirebbe sopra un'altra, che non resterebbe rettangolare.
	NEIGHBOR_TOO_SMALL, ## Una camera vicina scenderebbe sotto le misure minime.
	GUEST_WOULD_NOT_FIT, ## L'ospite di questa camera o di una vicina non ci entrerebbe più.
}

## Le celle che la camera occuperebbe dopo la modifica, anche se è rifiutata, così
## da poter mostrare che cosa si è tentato. Con il rifiuto TOO_SMALL le misure
## possono essere zero o negative.
var resulting_cells: Rect2i
## Il motivo del rifiuto, oppure Rejection.NONE se la modifica è permessa.
var rejection: Rejection
## Le camere vicine che cambierebbero insieme a questa. È vuoto se la modifica è rifiutata.
var neighbor_changes: Array[RoomChange]
## La camera vicina che causa il rifiuto, oppure null se il motivo è un altro.
var blocking_room: Room


## Crea l'anteprima con le celle risultanti e il motivo di rifiuto. _init() è la funzione che
## Godot chiama automaticamente con ResizePreview.new(). Gli ultimi due parametri servono solo
## quando entra in gioco una camera vicina.
func _init(preview_cells: Rect2i, preview_rejection: Rejection, changes: Array[RoomChange] = [], blocker: Room = null) -> void:
	resulting_cells = preview_cells
	rejection = preview_rejection
	neighbor_changes = changes
	blocking_room = blocker


## Restituisce true se la modifica è permessa.
func is_valid() -> bool:
	return rejection == Rejection.NONE
