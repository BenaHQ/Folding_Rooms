class_name SaveFile
extends RefCounted
## Il file di salvataggio sul disco del telefono.
##
## COSA FA: scrive e rilegge un Dictionary in formato JSON, insieme al numero di versione del
## formato. Non sa che cosa contiene: del contenuto si occupa HotelSession.
## CHI LA USA: la scena principale Main, all'avvio e quando l'app sta per chiudersi.
## PERCHÉ È SEPARATA: qui stanno soltanto i problemi del disco, cioè scritture interrotte e file
## danneggiati, così i test automatici possono provarli senza avviare il gioco.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena. «user://» è la
## cartella privata dell'app sul dispositivo. JSON è un formato di solo testo: a differenza di una
## Resource, un file JSON non può contenere codice da eseguire, quindi è sicuro leggerlo anche se
## qualcuno lo ha modificato (AGENTS.md, sezione 6). FileAccess legge e scrive i file, DirAccess li
## rinomina e li cancella.

## Com'è andata la lettura di un file.
enum Status {
	LOADED, ## Letto: i dati sono in data.
	MISSING, ## Il file non esiste: è il caso normale al primo avvio.
	DAMAGED, ## Il file esiste ma non è un salvataggio leggibile.
	OTHER_VERSION, ## Il file è stato scritto con un formato diverso da quello attuale.
}

## Versione attuale del formato. Va aumentata ogni volta che cambia la struttura dei dati salvati.
## La versione 2 ha aggiunto gli arrivi rimasti nella giornata (D-029).
## La versione 3 ha aggiunto la luce delle camere, i lavori (D-032) e i valori propri di ogni
## ospite (D-033).
## La versione 4 ha aggiunto i servizi comuni (D-036).
## La versione 5 ha aggiunto i piani aperti (D-037).
const FORMAT_VERSION: int = 5
## Nome del campo con la versione del formato.
const VERSION_KEY: String = "format_version"
## Nome del campo con i dati veri e propri.
const DATA_KEY: String = "data"
## Aggiunto al percorso del file temporaneo usato durante la scrittura.
const TEMPORARY_SUFFIX: String = ".tmp"
## Aggiunto al percorso del file messo da parte perché non si può leggere.
const UNREADABLE_SUFFIX: String = ".unreadable"
## Rientro del testo JSON: rende il file leggibile a chi lo apre per controllarlo.
const JSON_INDENT: String = "\t"

## Valore di «numero non valido» durante la lettura: i numeri salvati non sono mai negativi.
const INVALID_COUNT: int = -1
## Il numero più grande che si accetta da un file: 2^53, l'ultimo che un numero con la virgola
## rappresenta ancora senza perdere precisione.
const MAX_SAVED_COUNT: float = 9007199254740992.0

## Com'è andata la lettura.
var status: Status
## I dati letti, solo se status è LOADED; altrimenti è vuoto.
var data: Dictionary


## Crea il risultato di una lettura. _init() è la funzione che Godot chiama con .new().
func _init(read_status: Status, read_data: Dictionary = {}) -> void:
	status = read_status
	data = read_data


## Legge da un Dictionary un numero intero non negativo, oppure INVALID_COUNT se manca o non è
## valido. Il file può contenere qualsiasi cosa: JSON dà ogni numero come float, quindi si controlla
## che sia intero e abbastanza piccolo da restare preciso.
static func read_count(values: Dictionary, key: String) -> int:
	var value: Variant = values.get(key)
	if not value is float or value < 0.0 or value > MAX_SAVED_COUNT or value != floorf(value):
		return INVALID_COUNT

	return int(value)


## Legge un salvataggio dal percorso indicato e dice com'è andata. Non modifica nessun file.
## «static» significa che la funzione si chiama sulla classe: SaveFile.read(...).
static func read(path: String) -> SaveFile:
	if not FileAccess.file_exists(path):
		return SaveFile.new(Status.MISSING)

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return SaveFile.new(Status.DAMAGED)

	# Si usa un oggetto JSON e non JSON.parse_string(): così un testo rotto è un risultato da
	# gestire e non un errore stampato nel registro.
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return SaveFile.new(Status.DAMAGED)

	var content: Dictionary = json.data
	var version: Variant = content.get(VERSION_KEY)
	# JSON non distingue i numeri interi dagli altri: ogni numero arriva come float.
	if not version is float:
		return SaveFile.new(Status.DAMAGED)
	if version != FORMAT_VERSION:
		return SaveFile.new(Status.OTHER_VERSION)

	var saved_data: Variant = content.get(DATA_KEY)
	if not saved_data is Dictionary:
		return SaveFile.new(Status.DAMAGED)

	return SaveFile.new(Status.LOADED, saved_data)


## Scrive un salvataggio nel percorso indicato e restituisce true se è riuscito. Scrive prima su un
## file temporaneo e solo alla fine lo rinomina: se l'app viene chiusa a metà, il salvataggio
## precedente resta intatto. Se qualcosa fallisce il salvataggio precedente non viene toccato.
static func write(path: String, saved_data: Dictionary) -> bool:
	var temporary_path: String = path + TEMPORARY_SUFFIX
	var content: Dictionary = {VERSION_KEY: FORMAT_VERSION, DATA_KEY: saved_data}

	var file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_warning("Salvataggio non riuscito: impossibile creare %s (errore %d)." % [temporary_path, FileAccess.get_open_error()])
		return false

	var was_stored: bool = file.store_string(JSON.stringify(content, JSON_INDENT))
	# close() svuota sul disco ciò che è ancora in memoria: va fatto prima di rinominare.
	file.close()
	if not was_stored:
		push_warning("Salvataggio non riuscito: impossibile scrivere %s." % temporary_path)
		return false

	# Sui telefoni la rinomina sostituisce il vecchio file in un solo passaggio: non esiste un
	# momento in cui il salvataggio manca.
	var rename_error: Error = DirAccess.rename_absolute(temporary_path, path)
	if rename_error != OK:
		push_warning("Salvataggio non riuscito: impossibile rinominare %s (errore %d)." % [temporary_path, rename_error])
		return false

	return true


## Mette da parte un file che non si può leggere, così il prossimo salvataggio non lo cancella: una
## versione futura dell'app o una persona potrebbero ancora recuperarlo. Sostituisce un eventuale
## file già messo da parte. Restituisce true se è riuscito.
static func set_aside(path: String) -> bool:
	return DirAccess.rename_absolute(path, path + UNREADABLE_SUFFIX) == OK
