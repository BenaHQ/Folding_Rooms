class_name Need
extends Resource
## Bisogno di un ospite: quali misure di camera gli servono, quali gli piacciono e che luce vuole.
##
## COSA FA: dalla misura e dalla luce di una camera ricava come ci starebbe l'ospite. Applica il principio
## «su misura, non al minimo» (decisione D-019): entrare e stare bene sono due cose diverse.
## CHI LA USA: Guest la contiene, Grid la consulta per le regole e RoomEditor per le reazioni.
## PERCHÉ È SEPARATA: i numeri stanno nei file di dati in data/, non in catene di «if», e le
## regole si possono provare senza grafica.
## NOTA GDSCRIPT: «extends Resource» crea un oggetto di dati che Godot sa salvare in un file
## .tres. @export rende una variabile visibile nell'editor e salvabile in quel file. Un «enum»
## è un elenco di valori con un nome.
## COORDINATE: tutte le misure sono in celle.

## Come starebbe un ospite in una camera.
enum Fit {
	DOES_NOT_FIT, ## Non può entrare.
	CRAMPED, ## Entra, ma è stipato: la camera è troppo stretta per stare bene.
	COMFORTABLE, ## Sta bene.
	TOO_BIG, ## Entra, ma la camera è troppo grande per lui e lo mette a disagio.
	WRONG_LIGHT, ## Entra, ma la luce della camera non è quella che vuole (D-032).
}

## Il tipo di forma che l'ospite cerca: decide l'icona mostrata al giocatore.
enum Shape {
	TALL, ## Vuole una camera alta.
	LONG, ## Vuole una camera bassa e lunga.
	COZY, ## Vuole una camera raccolta.
}

## La luce di una camera, e quella che un ospite vuole (D-032).
enum Lighting {
	NORMAL, ## Luce normale: è quella di ogni camera nuova e la vogliono gli ospiti comuni.
	DARK, ## Illuminazione tolta: è quella che vuole il pipistrello.
	BRIGHT, ## Lampade speciali: è quella che vuole l'ospite vegetale.
}

## Valore che significa «nessun limite massimo» nelle misure massime.
const NO_LIMIT: int = 0

## Il tipo di forma cercata.
@export var shape: Shape = Shape.TALL
## Misura minima per entrare, in celle: X è la larghezza e Y l'altezza.
@export var enter_size: Vector2i = Vector2i.ONE
## Misura minima per stare bene, in celle. Deve essere almeno pari a enter_size.
@export var comfortable_min_size: Vector2i = Vector2i.ONE
## Misura massima per stare bene, in celle. NO_LIMIT su un asse significa nessun limite.
@export var comfortable_max_size: Vector2i = Vector2i(NO_LIMIT, NO_LIMIT)
## La luce che l'ospite vuole per stare bene.
@export var lighting: Lighting = Lighting.NORMAL


## Restituisce come starebbe l'ospite in una camera di room_size celle. Non modifica nulla.
func evaluate(room_size: Vector2i) -> Fit:
	if room_size.x < enter_size.x or room_size.y < enter_size.y:
		return Fit.DOES_NOT_FIT

	if room_size.x < comfortable_min_size.x or room_size.y < comfortable_min_size.y:
		return Fit.CRAMPED

	if _exceeds_limit(room_size.x, comfortable_max_size.x) or _exceeds_limit(room_size.y, comfortable_max_size.y):
		return Fit.TOO_BIG

	return Fit.COMFORTABLE


## Restituisce come starebbe l'ospite in una camera di room_size celle con la luce indicata. La luce
## sbagliata non impedisce mai di entrare: la misura sì. Non modifica nulla.
func evaluate_in_room(room_size: Vector2i, room_lighting: Lighting) -> Fit:
	var size_fit: Fit = evaluate(room_size)

	if size_fit != Fit.DOES_NOT_FIT and room_lighting != lighting:
		return Fit.WRONG_LIGHT

	return size_fit


## Restituisce true se size supera il limite, a meno che il limite sia NO_LIMIT.
func _exceeds_limit(size: int, limit: int) -> bool:
	return limit != NO_LIMIT and size > limit
