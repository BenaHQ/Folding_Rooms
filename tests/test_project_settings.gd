extends GutTest
## Test delle impostazioni del progetto Godot.
##
## COMPORTAMENTO PROTETTO: il gioco resta verticale, si adatta agli schermi dei
## telefoni, usa il renderer scelto e ha una scena di avvio che si carica. Sono
## scelte facili da cambiare per sbaglio nell'editor, e l'errore si noterebbe solo
## provando sul telefono.
## CHI LO USA: GUT, lo strumento che esegue i test automatici. Il comando per
## avviarli è scritto in docs/STATO.md.
## PERCHÉ È SEPARATO: controlla la configurazione, non le regole di gioco, che
## avranno i propri test.
## NOTA GDSCRIPT: «extends GutTest» dà a questo script le funzioni di controllo di
## GUT, come assert_eq(). GUT esegue da solo ogni funzione il cui nome inizia con
## «test_». assert_eq(a, b) segna il test come fallito se a e b sono diversi.

## Larghezza dell'area di gioco di riferimento, in pixel (AGENTS.md, sezione 7).
const BASE_WIDTH_PIXELS: int = 720
## Altezza dell'area di gioco di riferimento, in pixel (AGENTS.md, sezione 7).
const BASE_HEIGHT_PIXELS: int = 1280
## Nome interno del renderer Compatibility, il sistema che disegna la grafica,
## scelto nella decisione D-009 di docs/DECISIONI.md.
const RENDERER_NAME: String = "gl_compatibility"
## Percorso della scena che Godot apre all'avvio. «res://» indica la cartella
## principale del progetto.
const MAIN_SCENE_PATH: String = "res://scenes/main/main.tscn"
## Percorso del file con le configurazioni di export, cioè di creazione dell'app.
const EXPORT_PRESETS_PATH: String = "res://export_presets.cfg"
## Cartelle che servono solo allo sviluppo: non devono finire nell'app sul telefono.
const DEVELOPMENT_ONLY_FILTERS: Array[String] = ["addons/gut/*", "tests/*"]


## Controlla che la base sia in verticale e che il telefono non ruoti il gioco.
func test_game_is_portrait() -> void:
	# Le dimensioni di riferimento: ogni misura della grafica parte da queste.
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), BASE_WIDTH_PIXELS)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), BASE_HEIGHT_PIXELS)

	# L'orientamento che il sistema operativo del telefono deve mantenere.
	assert_eq(ProjectSettings.get_setting("display/window/handheld/orientation"), DisplayServer.SCREEN_PORTRAIT)


## Controlla che la grafica si adatti a telefoni con proporzioni diverse.
func test_game_adapts_to_screen_shape() -> void:
	# «canvas_items» ridisegna la grafica alla risoluzione dello schermo, così
	# resta nitida; «expand» allarga l'area di gioco invece di lasciare bande nere.
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")


## Controlla il renderer sia in generale sia sui telefoni.
func test_renderer_is_compatibility_on_every_platform() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), RENDERER_NAME)

	# Caso non ovvio: il suffisso «.mobile» è un'impostazione a parte. Senza di
	# essa i telefoni userebbero il renderer predefinito per il mobile, e non
	# quello provato sul PC.
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile"), RENDERER_NAME)


## Controlla che sul PC il mouse possa fare le veci del dito.
func test_mouse_emulates_touch() -> void:
	assert_true(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"))


## Controlla che la scena di avvio esista e si possa creare senza errori.
func test_main_scene_loads() -> void:
	# Il progetto deve indicare proprio questa scena come scena di avvio.
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), MAIN_SCENE_PATH)

	# load() legge il file della scena; se manca o è rotto restituisce null.
	var main_scene: PackedScene = load(MAIN_SCENE_PATH)
	assert_not_null(main_scene)

	# Evita di proseguire con un valore vuoto: il test è già segnato come fallito.
	if main_scene == null:
		return

	# instantiate() crea davvero i nodi della scena. autofree() è una funzione di
	# GUT che li elimina a fine test, così non restano in memoria.
	var main_node: Node = autofree(main_scene.instantiate())
	assert_true(main_node is Control)


## Controlla che le immagini vengano preparate anche nel formato usato dai telefoni.
func test_textures_are_imported_for_phones() -> void:
	# ETC2 e ASTC sono formati compressi di immagine letti direttamente dai telefoni. Senza
	# questa impostazione Godot rifiuta di creare l'app per telefono.
	assert_true(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc"))


## Controlla che GUT e i test restino fuori dall'app, in ogni configurazione di export.
func test_export_presets_exclude_development_files() -> void:
	# ConfigFile legge i file di testo divisi in sezioni, come export_presets.cfg.
	var presets: ConfigFile = ConfigFile.new()
	assert_eq(presets.load(EXPORT_PRESETS_PATH), OK, "il file dei preset deve esistere")

	# Ogni preset è una sezione «preset.N»; le sue opzioni stanno in «preset.N.options».
	var preset_count: int = 0
	for section: String in presets.get_sections():
		if section.ends_with(".options"):
			continue

		preset_count += 1
		var exclude_filter: String = presets.get_value(section, "exclude_filter", "")
		for filter: String in DEVELOPMENT_ONLY_FILTERS:
			assert_string_contains(exclude_filter, filter)

	assert_gt(preset_count, 0, "deve esistere almeno un preset")


## Controlla che il progetto abbia un'icona: senza, l'export per iOS si interrompe con un errore.
func test_project_has_icon() -> void:
	var icon_path: String = ProjectSettings.get_setting("application/config/icon")
	assert_true(ResourceLoader.exists(icon_path), "l'icona indicata nel progetto deve esistere")
