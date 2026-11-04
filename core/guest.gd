class_name Guest
extends Resource
## Un ospite dell'hotel: il suo bisogno e l'aspetto segnaposto.
##
## COSA FA: conserva i dati di un ospite, letti da un file .tres in data/guests/: il bisogno, per
## quanti turni resta e quanto paga a ogni turno, secondo come sta (D-026). Ogni ospite che arriva
## ha valori propri, entro un piccolo margine rispetto a quelli della specie (D-033).
## CHI LA USA: Room ricorda quale ospite ospita; RoomEditor e GuestBar lo disegnano.
## PERCHÉ È SEPARATA: aggiungere un ospite significa aggiungere un file di dati, senza toccare
## il codice (AGENTS.md, sezione 6).
## NOTA GDSCRIPT: «extends Resource» crea un oggetto di dati salvabile in un file .tres.
## @export rende una variabile visibile nell'editor e salvabile in quel file. duplicate() crea una
## copia indipendente dell'oggetto: la specie resta com'è e la copia descrive un singolo ospite.

## Nomi dei campi nel salvataggio.
const ID_KEY: String = "id"
const STAY_TURNS_KEY: String = "stay_turns"
const COMFORTABLE_PAY_KEY: String = "comfortable_pay"
const UNCOMFORTABLE_PAY_KEY: String = "uncomfortable_pay"

## Nome stabile della specie: è ciò che finisce nel salvataggio. Non va cambiato, altrimenti i
## salvataggi esistenti non ritrovano più l'ospite.
@export var id: String = ""
## Il bisogno di forma dell'ospite.
@export var need: Need
## Per quanti turni resta, compreso quello in cui arriva.
@export var stay_turns: int = 1
## Monete pagate a ogni turno se sta bene.
@export var comfortable_pay: int = 0
## Monete pagate a ogni turno se è stipato, se la camera è troppo grande per lui o se la luce è sbagliata.
@export var uncomfortable_pay: int = 0
## Di quanto può variare la permanenza di ogni ospite della specie, in più o in meno, in turni.
@export var stay_turns_spread: int = 0
## Di quanto può variare il compenso da comodo, in più o in meno, in monete.
@export var comfortable_pay_spread: int = 0
## Di quanto può variare il compenso da scomodo, in più o in meno, in monete.
@export var uncomfortable_pay_spread: int = 0
## Misura del corpo disegnato, in celle: larghezza e altezza. Non è una regola: decide solo il
## disegno. Le regole usano need.
@export var body_size_cells: Vector2 = Vector2.ONE
## Colore segnaposto del corpo.
@export var body_color: Color = Color.WHITE


## Crea un singolo ospite di questa specie, con valori estratti entro i margini. Resta almeno un turno
## e non paga mai meno di zero. Se la specie non ha margini restituisce sé stessa, perché non c'è
## nulla da variare. random è il generatore da usare: quello della fila, che dipende dal seme.
func roll_visit(random: RandomNumberGenerator) -> Guest:
	if stay_turns_spread == 0 and comfortable_pay_spread == 0 and uncomfortable_pay_spread == 0:
		return self

	var visit: Guest = duplicate() as Guest
	visit.stay_turns = maxi(stay_turns + random.randi_range(-stay_turns_spread, stay_turns_spread), 1)
	visit.comfortable_pay = maxi(comfortable_pay + random.randi_range(-comfortable_pay_spread, comfortable_pay_spread), 0)
	visit.uncomfortable_pay = maxi(uncomfortable_pay + random.randi_range(-uncomfortable_pay_spread, uncomfortable_pay_spread), 0)
	return visit


## Restituisce questo ospite in valori semplici, adatti a un file di salvataggio: la specie e i suoi
## valori estratti. Il resto si ritrova dalla specie.
func to_data() -> Dictionary:
	return {
		ID_KEY: id,
		STAY_TURNS_KEY: stay_turns,
		COMFORTABLE_PAY_KEY: comfortable_pay,
		UNCOMFORTABLE_PAY_KEY: uncomfortable_pay,
	}


## Ricrea un ospite dai valori di to_data(). species elenca le specie possibili. Restituisce null se i
## valori non sono validi: data arriva da un file, quindi il suo tipo non è garantito. Non controlla
## che i valori stiano nei margini: un ribilanciamento non deve invalidare chi è già in hotel.
static func from_data(data: Variant, species: Array[Guest]) -> Guest:
	if not data is Dictionary:
		return null

	var entry: Dictionary = data
	var saved_stay: int = SaveFile.read_count(entry, STAY_TURNS_KEY)
	var saved_comfortable: int = SaveFile.read_count(entry, COMFORTABLE_PAY_KEY)
	var saved_uncomfortable: int = SaveFile.read_count(entry, UNCOMFORTABLE_PAY_KEY)
	var guest_species: Guest = _find_species(species, entry.get(ID_KEY))
	if guest_species == null or saved_stay < 1 or saved_comfortable == SaveFile.INVALID_COUNT or saved_uncomfortable == SaveFile.INVALID_COUNT:
		return null

	var visit: Guest = guest_species.duplicate() as Guest
	visit.stay_turns = saved_stay
	visit.comfortable_pay = saved_comfortable
	visit.uncomfortable_pay = saved_uncomfortable
	return visit


## Restituisce le monete pagate in un turno, dato come sta l'ospite. Non modifica nulla.
func get_pay(fit: Need.Fit) -> int:
	match fit:
		Need.Fit.COMFORTABLE:
			return comfortable_pay
		Need.Fit.DOES_NOT_FIT:
			# Una camera occupata non può diventare troppo piccola: resta solo per completezza.
			return 0
		_:
			return uncomfortable_pay


## Restituisce la specie con il nome indicato, oppure null se non esiste o se guest_id non è un testo.
## Non usa GuestQueue, che carica i file degli ospiti: si caricherebbero a vicenda e Godot non ci riesce.
static func _find_species(species: Array[Guest], guest_id: Variant) -> Guest:
	if guest_id is String:
		for candidate: Guest in species:
			if candidate.id == guest_id:
				return candidate

	return null
