extends GutTest
## Test del file di salvataggio sul disco.
##
## COMPORTAMENTO PROTETTO: ciò che si scrive si rilegge uguale; una scrittura interrotta non rovina
## il salvataggio precedente; un file danneggiato o di un altro formato viene riconosciuto e non
## scambiato per una partita valida.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per avviarli è scritto
## in docs/STATO.md.
## PERCHÉ È SEPARATO: prova solo i problemi del disco. Il contenuto è in test_hotel_save.gd.
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di GUT. «user://» è
## la cartella privata dell'app: qui si usa un nome di file riservato ai test.

## File usato dai test, diverso da quello della partita vera.
const TEST_PATH: String = "user://test_save_file.json"
## Un percorso in una cartella inesistente, dove non si può scrivere.
const IMPOSSIBLE_PATH: String = "user://cartella_inesistente/salvataggio.json"
## Una versione del formato che non esiste ancora.
const FUTURE_VERSION: int = SaveFile.FORMAT_VERSION + 1
## Dati di esempio.
const SAMPLE_DATA: Dictionary = {"coins": 17.0, "name": "prova"}


## GUT chiama questa funzione dopo ogni test: non deve restare nessun file di prova.
func after_each() -> void:
	# remove_absolute() cancella anche una cartella vuota, come quella creata da un test.
	for path: String in [TEST_PATH, TEST_PATH + SaveFile.TEMPORARY_SUFFIX, TEST_PATH + SaveFile.UNREADABLE_SUFFIX]:
		if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
			DirAccess.remove_absolute(path)


## Scrive un testo qualsiasi in un file, per simulare un file rovinato.
func _write_text(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Ciò che si salva si rilegge uguale.
func test_write_then_read_gives_same_data() -> void:
	assert_true(SaveFile.write(TEST_PATH, SAMPLE_DATA))

	var save: SaveFile = SaveFile.read(TEST_PATH)

	assert_eq(save.status, SaveFile.Status.LOADED)
	assert_eq(save.data, SAMPLE_DATA)


## Una nuova scrittura sostituisce quella precedente, senza lasciare il file temporaneo.
func test_second_write_replaces_first_and_leaves_no_temporary_file() -> void:
	SaveFile.write(TEST_PATH, {"coins": 1.0})
	assert_true(SaveFile.write(TEST_PATH, SAMPLE_DATA))

	assert_eq(SaveFile.read(TEST_PATH).data, SAMPLE_DATA)
	assert_false(FileAccess.file_exists(TEST_PATH + SaveFile.TEMPORARY_SUFFIX))


## Simula un'app chiusa a metà scrittura: resta un file temporaneo incompleto. Il salvataggio
## precedente deve restare valido, e il salvataggio dopo deve funzionare.
func test_interrupted_write_keeps_previous_save() -> void:
	SaveFile.write(TEST_PATH, SAMPLE_DATA)
	_write_text(TEST_PATH + SaveFile.TEMPORARY_SUFFIX, "{\"format_version\": 1, \"da")

	assert_eq(SaveFile.read(TEST_PATH).data, SAMPLE_DATA)
	assert_true(SaveFile.write(TEST_PATH, {"coins": 2.0}))
	assert_eq(SaveFile.read(TEST_PATH).data, {"coins": 2.0})


## La scrittura deve passare dal file temporaneo, mai direttamente sul salvataggio. Una cartella con
## lo stesso nome del file temporaneo impedisce di crearlo: scrivere deve fallire senza toccare il
## salvataggio. Se la scrittura andasse direttamente sul salvataggio, riuscirebbe e il test fallirebbe.
func test_write_never_touches_save_before_temporary_file_is_complete() -> void:
	SaveFile.write(TEST_PATH, SAMPLE_DATA)
	DirAccess.make_dir_absolute(TEST_PATH + SaveFile.TEMPORARY_SUFFIX)

	assert_false(SaveFile.write(TEST_PATH, {"coins": 2.0}))
	assert_eq(SaveFile.read(TEST_PATH).data, SAMPLE_DATA)


## Una scrittura impossibile lo dice, invece di far credere che la partita sia salva.
func test_write_failure_is_reported() -> void:
	assert_false(SaveFile.write(IMPOSSIBLE_PATH, SAMPLE_DATA))


## Al primo avvio il file non c'è: non è un errore.
func test_missing_file_is_reported_as_missing() -> void:
	assert_eq(SaveFile.read(TEST_PATH).status, SaveFile.Status.MISSING)


## Un file illeggibile non deve mai diventare una partita: troncato, vuoto o di altro tipo.
func test_damaged_files_are_recognized() -> void:
	var valid_header: String = "\"%s\": %d" % [SaveFile.VERSION_KEY, SaveFile.FORMAT_VERSION]
	var damaged_texts: Array[String] = [
		"",
		"non è JSON",
		"{" + valid_header + ", \"data\": {\"coins\": 1",
		"[1, 2, 3]",
		"42",
		"{\"data\": {}}",
		"{\"%s\": \"uno\", \"data\": {}}" % SaveFile.VERSION_KEY,
		"{" + valid_header + "}",
		"{" + valid_header + ", \"data\": [1]}",
	]

	for text: String in damaged_texts:
		_write_text(TEST_PATH, text)
		var save: SaveFile = SaveFile.read(TEST_PATH)
		assert_eq(save.status, SaveFile.Status.DAMAGED, "Testo: «%s»" % text)
		assert_true(save.data.is_empty())


## Un file scritto con un altro formato si riconosce: i suoi dati non vanno interpretati.
func test_other_versions_are_recognized() -> void:
	for version: int in [FUTURE_VERSION, 0]:
		_write_text(TEST_PATH, JSON.stringify({SaveFile.VERSION_KEY: version, SaveFile.DATA_KEY: SAMPLE_DATA}))
		var save: SaveFile = SaveFile.read(TEST_PATH)
		assert_eq(save.status, SaveFile.Status.OTHER_VERSION)
		assert_true(save.data.is_empty())


## Mettere da parte conserva il contenuto e libera il posto per il prossimo salvataggio.
func test_set_aside_keeps_content_and_frees_path() -> void:
	_write_text(TEST_PATH, "contenuto rovinato")

	assert_true(SaveFile.set_aside(TEST_PATH))

	assert_false(FileAccess.file_exists(TEST_PATH))
	assert_eq(FileAccess.get_file_as_string(TEST_PATH + SaveFile.UNREADABLE_SUFFIX), "contenuto rovinato")
