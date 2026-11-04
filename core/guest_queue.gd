class_name GuestQueue
extends RefCounted
## La fila degli ospiti in arrivo, uno alla volta, come i pezzi di Tetris.
##
## COSA FA: decide l'ordine di arrivo e permette di guardare chi è in fila senza farlo avanzare.
## Usa un «sacchetto»: mescola tutte le specie, le fa arrivare una per una e poi rimescola. Così
## una specie non può mancare a lungo né ripetersi troppe volte di seguito.
## CHI LA USA: HotelSession, che la fa avanzare a ogni turno.
## PERCHÉ È SEPARATA: l'ordine non dipende dalle regole dell'hotel, e con lo stesso «seme» è sempre
## uguale, quindi i test automatici possono provarlo.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena. preload()
## carica un file quando lo script viene letto. Un generatore di numeri casuali produce sempre la
## stessa sequenza a partire dallo stesso numero iniziale, chiamato «seme».

## Gli ospiti del prototipo. Sono dati: aggiungerne uno significa aggiungere un file e una riga.
const PROTOTYPE_GUESTS: Array[Guest] = [
	preload("res://data/guests/giraffe.tres"),
	preload("res://data/guests/snake.tres"),
	preload("res://data/guests/dormouse.tres"),
]

## Le specie che finiscono nel sacchetto.
var _species: Array[Guest]
## Gli ospiti già decisi, nell'ordine di arrivo: il primo è quello di turno.
var _line: Array[Guest] = []
## Il generatore di numeri casuali di questa fila.
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


## Crea la fila. species elenca le specie e rng_seed è il seme, che decide l'ordine.
func _init(species: Array[Guest], rng_seed: int) -> void:
	_species = species
	_random.seed = rng_seed


## Restituisce i primi count ospiti della fila, senza farla avanzare.
func peek(count: int) -> Array[Guest]:
	# Riempie finché ce ne sono abbastanza: un sacchetto può contenere meno di count ospiti.
	while _line.size() < count:
		_add_shuffled_bag()

	return _line.slice(0, count)


## Toglie dalla fila l'ospite di turno, facendo avanzare gli altri.
func advance() -> void:
	# Serve se nessuno ha ancora guardato la fila: il primo ospite deve esistere per uscirne.
	peek(1)
	_line.pop_front()


## Aggiunge in fondo alla fila un sacchetto mescolato. Usa il metodo di Fisher-Yates: dall'ultima
## posizione alla prima, scambia ogni elemento con uno scelto a caso tra i precedenti e sé stesso.
## Il metodo shuffle() di Godot non si può usare qui: non dipende dal seme di questa fila.
func _add_shuffled_bag() -> void:
	var bag: Array[Guest] = _species.duplicate()

	for index: int in range(bag.size() - 1, 0, -1):
		var other_index: int = _random.randi_range(0, index)
		var moved_guest: Guest = bag[index]
		bag[index] = bag[other_index]
		bag[other_index] = moved_guest

	_line.append_array(bag)
