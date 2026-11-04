class_name GuestQueue
extends RefCounted
## La fila degli ospiti in arrivo, uno alla volta, come i pezzi di Tetris.
##
## COSA FA: decide l'ordine di arrivo e permette di guardare chi è in fila senza farlo avanzare.
## Usa un «sacchetto»: mescola tutte le specie, le fa arrivare una per una e poi rimescola. Così
## una specie non può mancare a lungo né ripetersi troppe volte di seguito. Ogni ospite nel sacchetto
## ha valori propri di paga e permanenza (D-033).
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
## Gli ospiti che arrivano solo quando l'hotel cresce (D-032).
const LIGHT_GUESTS: Array[Guest] = [
	preload("res://data/guests/bat.tres"),
	preload("res://data/guests/plant.tres"),
]
## Nomi dei campi nel salvataggio.
const LINE_KEY: String = "line"
const RANDOM_STATE_KEY: String = "random_state"
## Seme di passaggio per una fila ricaricata: il suo stato viene subito sostituito da quello salvato.
const UNUSED_SEED: int = 0

## Le specie che finiscono nel sacchetto.
var _species: Array[Guest]
## Le specie che entrano nel sacchetto solo dopo unlock_late_species().
var _late_species: Array[Guest]
## Gli ospiti già decisi, nell'ordine di arrivo: il primo è quello di turno.
var _line: Array[Guest] = []
## Il generatore di numeri casuali di questa fila.
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


## Crea la fila. species elenca le specie e rng_seed è il seme, che decide l'ordine. late_species
## elenca le specie che arrivano solo dopo unlock_late_species().
func _init(species: Array[Guest], rng_seed: int, late_species: Array[Guest] = []) -> void:
	_species = species.duplicate()
	_late_species = late_species
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


## Aggiunge le specie in attesa ai prossimi sacchetti: chi è già in fila non cambia. Chiamarla di
## nuovo non fa nulla.
func unlock_late_species() -> void:
	_species.append_array(_late_species)
	_late_species = []


## Restituisce lo stato della fila in valori semplici, adatti a un file di salvataggio. Non modifica
## nulla. Lo stato del generatore è scritto come testo: JSON salva i numeri con una precisione
## minore di quella che serve qui, e l'ordine futuro degli arrivi cambierebbe.
func to_data() -> Dictionary:
	var line_entries: Array[Dictionary] = []
	for guest: Guest in _line:
		line_entries.append(guest.to_data())

	return {LINE_KEY: line_entries, RANDOM_STATE_KEY: str(_random.state)}


## Ricrea una fila dai valori di to_data(). species e late_species sono come in _init(). Restituisce
## null se i valori non sono validi. Gli ospiti arrivano nello stesso ordine in cui sarebbero arrivati,
## a patto che le specie in attesa vengano sbloccate come nella partita salvata.
static func from_data(data: Dictionary, species: Array[Guest], late_species: Array[Guest] = []) -> GuestQueue:
	var line_entries: Variant = data.get(LINE_KEY)
	var random_state: Variant = data.get(RANDOM_STATE_KEY)
	if not line_entries is Array or not random_state is String or not (random_state as String).is_valid_int():
		return null

	var queue: GuestQueue = GuestQueue.new(species, UNUSED_SEED, late_species)
	var all_species: Array[Guest] = species + late_species
	queue._random.state = (random_state as String).to_int()

	for entry: Variant in line_entries:
		var guest: Guest = Guest.from_data(entry, all_species)
		if guest == null:
			return null
		queue._line.append(guest)

	return queue


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

	# Ogni ospite estrae qui i suoi valori, con lo stesso generatore: lo stesso seme dà gli stessi ospiti.
	for species: Guest in bag:
		_line.append(species.roll_visit(_random))
