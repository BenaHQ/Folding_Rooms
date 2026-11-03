# AGENTS.md — Istruzioni comuni di Folding Rooms

Questo file è l'unica fonte delle regole di lavoro per Claude Code, Codex, Antigravity/Gemini, modelli locali e ogni altro agente. Leggilo per intero prima di iniziare. Se una regola è in conflitto con una richiesta esplicita dell'utente, segnalalo e segui l'utente. Scrivi all'utente in italiano e spiega i termini tecnici quando li introduci.

## 1. Versione di Godot — controllo obbligatorio

| Voce | Valore |
|---|---|
| **Versione attiva** | **`4.7.2-stable`** |
| Motore e linguaggio | Godot 4, GDScript |
| Repository | https://github.com/BenaHQ/Folding_Rooms |

Prima di scrivere o modificare GDScript, scene, shader o impostazioni di export:

1. Leggi la versione attiva qui sopra e, se il progetto esiste, `config/features` in `project.godot`, che riporta solo `major.minor` (esempio: `"4.7"`): confronta quella parte.
2. Fermati e chiedi all'utente quale versione usare se il valore è `DA DEFINIRE`, se i due file non coincidono o se l'utente ne cita un'altra. Non dedurla dalla tua memoria e non scegliere da solo «l'ultima».
3. Una volta definita, aggiorna la tabella prima di scrivere codice. Il valore vale per tutti gli agenti finché l'utente non lo cambia.
4. Usa la documentazione di quel ramo: `https://docs.godotengine.org/en/<major.minor>/` (esempio: `/en/4.7/`). Evita `/en/stable/`, che cambia nel tempo. La tua memoria può riferirsi a versioni diverse: se un'API non è verificata, controllala; se non puoi, dichiaralo.
5. Editor, export templates e strumenti di test devono corrispondere esattamente alla stessa versione.
6. Si cambia versione solo su richiesta esplicita, su un branch dedicato, dopo aver letto la guida di aggiornamento ufficiale e rieseguito le verifiche; annota il cambio in `docs/DECISIONI.md`.
7. Indica la versione usata nel resoconto di ogni sessione che tocca il progetto Godot.

## 2. Lavoro condiviso tra agenti

Gli agenti non condividono memoria: ciò che serve agli altri deve stare nel repository, non nella memoria privata di uno strumento.

**A inizio sessione**
1. Leggi questo file, `docs/STATO.md` e `docs/DECISIONI.md`.
2. Se esiste il repository Git, controlla `git status` e gli ultimi commit: non sovrascrivere lavoro altrui e non dare per scontato che le modifiche non tue siano errori.
3. Se `docs/STATO.md` segnala un lavoro in corso sugli stessi file, chiedi all'utente come procedere.
4. Leggi le sezioni di `Folding_Rooms_Concept.md` pertinenti al compito.

**A fine sessione**
1. Aggiorna `docs/STATO.md`: cosa è stato fatto, cosa è stato verificato davvero, cosa manca, prossimo passo, agente e modello usati.
2. Aggiungi a `docs/DECISIONI.md` ogni decisione presa con l'utente.
3. Se lasci un lavoro a metà, scrivi cosa funziona, cosa no e da dove riprendere.

Se hai poco contesto o un modello meno capace: prendi un compito piccolo, non fare refactor estesi e fermati a chiedere quando non sei sicuro.

| Strumento | Come riceve queste istruzioni |
|---|---|
| Codex, Antigravity | Leggono `AGENTS.md` da soli |
| Claude Code | `CLAUDE.md` importa questo file |
| Modelli locali e altri | Se non lo caricano da soli, passa questo file e `docs/STATO.md` come primo contesto |

## 3. Il progetto

Folding Rooms è un gioco per Android e iOS, in verticale: un gestionale creativo di hotel con puzzle spaziali. Il giocatore trascina pareti e solai per adattare le camere a ospiti con esigenze riconoscibili. Il risultato deve essere un gioco completo e pubblicabile, non una demo.

**Ordine delle fonti:** richiesta esplicita dell'utente → questo file → `docs/DECISIONI.md` → `Folding_Rooms_Concept.md` → `immagini/Folding_Rooms_UI_Concept.png`. L'immagine è solo un riferimento artistico: numeri, testi e layout non sono specifiche. Nel concept, le voci indicate come «proposta» non sono requisiti.

**Priorità:** prima deve essere piacevole e leggibile il gesto di trasformare una camera (concept, sezioni 2 e 11), poi si costruisce il resto attorno a quel gesto. Negozi, valute e progressione non vengono prima.

**Decisioni aperte — proponi opzioni e una raccomandazione, ma non scegliere da solo:** architettura definitiva, dimensioni della griglia, libertà delle forme, accessi e corridoi, numero di specie, economia, monetizzazione, salvataggi remoti, finale, renderer, lingue, versioni minime dei sistemi operativi, identificativo dell'app.

Non aggiungere funzioni non richieste e non toccare file estranei al compito.

## 4. Codice comprensibile e commenti — regola prioritaria

**Lettore di riferimento:** una persona alle prime armi con la programmazione, che non conosce GDScript né Godot. Deve poter capire cosa fa ogni file e perché, leggendo soltanto il codice e i commenti. Il codice senza questi commenti non è completo.

- **Lingua:** commenti e documentazione in italiano semplice; nomi di file, classi, funzioni e variabili in inglese, coerenti con il glossario (sezione 11).
- **Intestazione di ogni script:** cosa fa, chi lo usa, a quale scena o sistema appartiene e perché esiste separato dagli altri.
- **Funzioni, segnali, costanti e variabili esportate:** commento di documentazione `##` con scopo, parametri, valore restituito ed effetti su altri oggetti.
- **Dentro le funzioni:** commenta ogni passaggio logico con `#`, spiegando l'obiettivo e il motivo, non solo l'istruzione. Rendi espliciti casi limite e condizioni non ovvie.
- **Concetti di GDScript e Godot:** alla prima comparsa in ogni file spiega in parole semplici elementi come `extends`, nodo, scena, segnale, `@export`, `@onready`, `$`, `await`, `_ready()`, `_process()`, `_input()`, `Tween`.
- **Numeri:** niente valori «magici». Usa costanti con nome e indica sempre l'unità: celle, pixel, secondi.
- **Matematica e coordinate:** spiega la formula e il sistema di riferimento; in Godot 2D la Y cresce verso il basso.
- **Termini tecnici:** quando sono inevitabili, spiegali la prima volta che compaiono nel file.
- **Coerenza:** aggiorna i commenti insieme al codice. Un commento sbagliato è un difetto, e il codice commentato e dimenticato va rimosso.
- **Il commento non sostituisce la chiarezza:** nomi descrittivi, funzioni brevi con un solo compito, nessun trucco «furbo» se esiste una forma più leggibile.
- **Scene, shader e test:** il comportamento di una scena si documenta nello script collegato; anche gli shader vanno commentati; ogni test dichiara quale comportamento protegge.

Esempio di densità e tono (lo stile è vincolante, la regola di gioco è inventata):

```gdscript
class_name RoomRules
extends RefCounted
## Regole che decidono se una camera può cambiare altezza.
##
## COSA FA: risponde a una sola domanda: «questa modifica è permessa?».
## CHI LA USA: lo script della camera, mentre il giocatore trascina una maniglia.
## PERCHÉ È SEPARATA: non disegna nulla, quindi i test automatici possono
## provarla senza avviare il gioco.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella
## scena e che Godot elimina da solo quando nessuno lo usa più.

## Altezza minima di una camera, in celle della griglia. Sotto questo valore
## nessun ospite potrebbe entrare e la camera sarebbe inutilizzabile.
const MIN_HEIGHT_CELLS: int = 2


## Restituisce true se la camera può passare da current_height a new_height.
## Tutte le misure sono in celle; free_cells_above indica quante celle libere
## ci sono sopra la camera. La funzione non modifica nulla: controlla soltanto.
static func can_change_height(current_height: int, new_height: int, free_cells_above: int) -> bool:
	# Rifiuta la modifica se renderebbe la camera troppo bassa per essere usata.
	if new_height < MIN_HEIGHT_CELLS:
		return false

	# Calcola di quanto cresce la camera. Se si abbassa, il risultato è negativo
	# e il confronto è sempre vero: abbassarsi non richiede spazio libero.
	var extra_cells: int = new_height - current_height
	return extra_cells <= free_cells_above
```

## 5. Regole GDScript

- Segui la guida di stile ufficiale del ramo attivo: `https://docs.godotengine.org/en/<major.minor>/tutorials/scripting/gdscript/gdscript_styleguide.html`.
- **Indentazione con TAB:** gli spazi mescolati causano errori di parsing. File in UTF-8 con fine riga LF.
- **Nomi:** file e funzioni `snake_case`; classi e nodi `PascalCase`; costanti `CONSTANT_CASE`; segnali al passato (`room_resized`); membri privati con `_` iniziale.
- **Tipi sempre espliciti** su variabili, parametri e valori restituiti.
- **Ordine nel file:** `class_name`, `extends`, documentazione, segnali, enum, costanti, `@export`, variabili, `@onready`, metodi virtuali (`_init`, `_ready`, `_process`…), metodi pubblici, metodi privati.
- **Errori:** controlla ciò che può fallire (file, dati caricati, nodi cercati) e gestisci il caso in modo esplicito; non ignorarlo in silenzio. Non aggiungere però controlli per situazioni impossibili.

**Sintassi di Godot 3 da non usare:** `yield` → `await`; `export var`/`onready var` → `@export var`/`@onready var`; `connect("x", obj, "f")` → `x.connect(f)`; `.instance()` → `.instantiate()`; nodo `Tween` → `create_tween()`; `File`/`Directory` → `FileAccess`/`DirAccess`; `rand_range` → `randf_range`.

**File di Godot**
- Non modificare `.godot/`: è una cache rigenerabile.
- Nel versionamento includi `project.godot`, `.tscn`, `.tres`, `.import` e `.uid`. Se sposti uno script, sposta con lui il suo `.uid`.
- Se modifichi a mano `.tscn` o `.tres`, non inventare `uid://` o riferimenti e valida subito il progetto (sezione 8).

## 6. Linee guida di architettura

Valgono come punto di partenza per il prototipo; si cambiano registrando la decisione in `docs/DECISIONI.md`.

- **Regole separate dalla grafica:** griglia, dimensioni delle camere e validazione stanno in classi senza nodi né disegno, provabili con test automatici. Le scene mostrano lo stato e inviano i comandi; animazioni e deformazioni elastiche non decidono mai le regole.
- **Dati separati dal codice:** ospiti, arredi e bisogni stanno in file di dati (`Resource`), non in lunghe catene di `if`.
- **Comunicazione:** chiamate dirette verso il basso, segnali verso l'alto. Evita percorsi fragili come `get_parent().get_parent()`. Usa gli autoload solo per servizi davvero globali, come i salvataggi.
- **Funzione separata dalla decorazione:** un elemento estetico non deve influire sui bisogni degli ospiti.
- **Salvataggi:** in `user://`, con numero di versione del formato fin dal primo salvataggio; scrivi su un file temporaneo e poi rinominalo, così un'interruzione non danneggia i dati. Non caricare `Resource` da file modificabili dall'esterno.

Struttura proposta, con `project.godot` nella radice e un file `.gdignore` in `docs/` e `immagini/`:

```text
core/          regole di gioco, senza nodi né grafica
data/          dati di ospiti, arredi e bisogni
scenes/        scene .tscn con il proprio script accanto
ui/            interfaccia
assets/        grafica, audio e font del gioco
translations/  testi del gioco
tests/         test automatici
docs/          stato, decisioni e documentazione
```

## 7. Mobile

- **Schermo:** orientamento `portrait`, base 720×1280 (1080×1920 se la grafica lo richiede), stretch mode `canvas_items`, stretch aspect `expand`.
- **Aree sicure:** niente comandi sotto notch o barre di sistema; usa `DisplayServer.get_display_safe_area()`.
- **Tocco:** comandi di almeno 48 dp su Android e 44 pt su iOS, con area sensibile più grande del disegno. Il dito non deve coprire l'informazione che serve durante il trascinamento. Gestisci secondo dito e tocco interrotto. Per le prove su PC usa l'emulazione del tocco con il mouse.
- **Trascinamento:** durante il gesto contano contorno, maniglia, bisogno dell'ospite e risultato previsto; le decorazioni non coprono le parti selezionabili.
- **Ciclo di vita:** salva su `NOTIFICATION_APPLICATION_PAUSED` (su iOS ci sono circa 5 secondi) e gestisci il tasto Indietro con `NOTIFICATION_WM_GO_BACK_REQUEST`. Se il sistema chiude l'app durante una modifica, i dati devono restare integri.
- **Prestazioni e batteria:** niente `_process` se basta un segnale; prova fluidità e consumo su un dispositivo reale, non solo sul PC.
- **Testi:** nessun testo visibile scritto direttamente nel codice; usa `tr()` e i file di traduzione fin dall'inizio.
- **Accessibilità:** valido/non valido non deve dipendere solo dal colore; aggiungi sempre icona o forma. Testi leggibili su schermo piccolo.

## 8. Verifica e definizione di «fatto»

Comandi di base (se `godot` non è nel PATH, usa il percorso indicato in `docs/STATO.md`):

```bash
godot --headless --path . --import
godot --headless --path . --check-only --script res://percorso/script.gd
```

Un compito è fatto quando:
1. il progetto si importa e gli script modificati non hanno errori né nuovi avvisi nella versione attiva;
2. le regole di gioco nuove o modificate hanno test automatici, e tutti i test passano. Il framework (GUT o gdUnit4) è da scegliere dopo averne verificato la compatibilità con la versione attiva;
3. i commenti rispettano la sezione 4;
4. per ciò che un test non può giudicare (sensazione del gesto, leggibilità, fluidità) hai dato all'utente passi precisi per provarlo su dispositivo;
5. `docs/STATO.md` è aggiornato.

**Onestà del risultato:** non dire «funziona» per qualcosa che non hai eseguito. Distingui sempre tra eseguito, verificato e non verificato, e riporta gli errori così come sono. Non disattivare o eliminare test per farli passare. Per un bug, prima riproducilo e trova la causa, poi correggi.

## 9. Git e sicurezza

- Lavora con commit piccoli e descrittivi, in italiano. Fai commit solo quando l'utente lo chiede o lo ha autorizzato per quel compito. Usa un branch per ogni funzione; `main` deve restare funzionante.
- Il file `.gitattributes` deve forzare i fine riga LF: su questo PC Git converte in CRLF per impostazione predefinita.
- In `.gitignore`: `.godot/`, `*.translation`, `android/`, build esportate, `*.keystore`, `*.jks`, `*.p12`, `*.mobileprovision`.
- **Mai nel repository:** chiavi di firma, password, certificati, token. Controlla `export_presets.cfg` prima del commit. La keystore di rilascio va conservata con un backup fuori dal repository.
- **Chiedi conferma prima di:** cancellazioni difficili da annullare, `git push --force`, reset distruttivi, pubblicazioni sugli store, pagamenti, creazione di account, accettazione di condizioni.
- **Dipendenze:** nessun addon, plugin o SDK senza approvazione; verifica licenza, compatibilità con la versione attiva e supporto Android/iOS. SDK di pubblicità, analisi o acquisti restano esclusi finché la monetizzazione non è decisa.
- **Asset e dati personali:** registra in `docs/CREDITI.md` fonte e licenza di ogni asset di terzi o generato con IA. Non raccogliere dati personali senza una decisione esplicita.

## 10. Pubblicazione su Android e iOS

Dati controllati il 2026-11-02: gli store e Godot cambiano, quindi ricontrolla le fonti ufficiali prima di ogni rilascio.

**Android**
- Export in AAB tramite build Gradle, con keystore di rilascio e «Export With Debug» disattivato.
- JDK 17 o superiore; versioni di SDK e NDK secondo la guida di export del ramo attivo.
- Google Play richiede target API 36 o superiore per nuove app e aggiornamenti (dal 31 agosto 2026), mentre la guida di Godot 4.7 cita Platform 35: controlla il target effettivo dell'AAB e impostalo se necessario.

**iOS**
- L'export richiede macOS con Xcode: da Windows non si può completare. Servono anche Team ID Apple e identificativo univoco dell'app.
- App Store Connect richiede Xcode 26 o superiore e SDK iOS 26 (dal 28 aprile 2026).

**Entrambi:** numero di versione incrementato, icone e schermata iniziale, informativa sulla privacy, moduli degli store, prove su dispositivi reali, verifica del salvataggio dopo l'aggiornamento da una versione precedente.

## 11. Glossario

Usa sempre questi nomi nel codice.

| Italiano | Codice | Italiano | Codice |
|---|---|---|---|
| Camera | `Room` | Griglia / cella | `Grid` / `Cell` |
| Ospite | `Guest` | Involucro disponibile | `Envelope` |
| Bisogno | `Need` | Anteprima | `Preview` |
| Parete | `Wall` | Arredo | `Furniture` |
| Soffitto / pavimento | `Ceiling` / `Floor` | Servizio comune | `Facility` |
| Piano dell'edificio | `Storey` | Ricordo dell'ospite | `Keepsake` |
| Maniglia | `Handle` | Incarico | `Task` |

## 12. Manutenzione di questo file

- Modificalo solo con l'approvazione dell'utente, salvo l'aggiornamento della versione attiva dopo la sua scelta.
- Resta sotto i 20 KB e circa 200 righe: Antigravity tronca i file oltre 24.000 byte, Codex carica di default 32 KiB in totale e Claude Code consiglia meno di 200 righe. Il dettaglio va in `docs/`.
- Non duplicare queste regole in altri file. `CLAUDE.md` contiene solo l'import e non serve un `GEMINI.md`: Antigravity sommerebbe le regole dei due file.
- Non copiare qui il contenuto del concept: rimanda alle sue sezioni.
