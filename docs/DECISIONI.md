# Registro delle decisioni

Una voce per ogni decisione presa con l'utente, la più recente in fondo. Non cancellare le voci superate: aggiungine una nuova che le sostituisce.

Formato: numero, data, decisione, motivo, chi ha deciso, eventuale voce o documento sostituito.

## D-001 — 2026-11-02 — Piattaforme

- **Decisione:** Android e iOS, con un gioco completo e pubblicabile.
- **Deciso da:** Riccardo.

## D-002 — 2026-11-02 — Motore e linguaggio

- **Decisione:** Godot 4 con GDScript. La versione precisa si definisce in `AGENTS.md`, sezione 1, per evitare codice non compatibile.
- **Deciso da:** Riccardo.
- **Sostituisce:** la voce «Engine» tra le decisioni aperte del concept, sezione 12.

## D-003 — 2026-11-02 — Strumenti e istruzioni comuni

- **Decisione:** sviluppo in VS Code con più agenti (Claude Code, Codex, Antigravity, eventuali modelli locali). Le regole stanno solo in `AGENTS.md`; `CLAUDE.md` si limita a importarlo.
- **Motivo:** Codex e Antigravity leggono `AGENTS.md` da soli, Claude Code tramite import: un solo file evita regole divergenti.
- **Deciso da:** Riccardo per il file unico; proposta di Claude Code per la struttura.

## D-004 — 2026-11-02 — Commenti nel codice

- **Decisione:** commenti esaustivi, comprensibili per chi è alle prime armi con la programmazione (`AGENTS.md`, sezione 4).
- **Deciso da:** Riccardo.

## D-005 — 2026-11-03 — Versione di Godot

- **Decisione:** versione attiva `4.7.2-stable`.
- **Motivo:** è l'ultima stabile presente nell'archivio ufficiale al momento della scelta.
- **Deciso da:** Riccardo.

## D-006 — 2026-11-03 — Repository

- **Decisione:** il repository del progetto è https://github.com/BenaHQ/Folding_Rooms, con `project.godot` destinato alla radice.
- **Deciso da:** Riccardo per il repository; la posizione di `project.godot` resta la proposta di `AGENTS.md`, sezione 6.

## D-007 — 2026-11-03 — Scaletta di sviluppo

- **Decisione:** si segue la scaletta di `docs/ROADMAP.md`, comprese la prova di stile in fase 3 e la guida di stile in fase 8. Le proposte dei singoli passi restano decisioni aperte.
- **Deciso da:** Riccardo.

## D-008 — 2026-11-03 — Framework di test

- **Decisione:** GUT 9.7.1 (licenza MIT, https://github.com/bitwes/Gut), copiato in `addons/gut/` dal tag ufficiale `v9.7.1` e da escludere dagli export.
- **Motivo:** le note di rilascio di GUT 9.7 trattano Godot 4.7. Provati entrambi su 4.7.2 con un test riuscito e uno fallito: funzionano sia GUT sia gdUnit4 6.2.3. GUT è preferito per i test scritti in forma più semplice, adatta a chi inizia, e perché da terminale restituisce solo 0 o 1, senza generare file di report.
- **Deciso da:** Claude Code. Riccardo ha approvato l'installazione del framework con la scaletta e ha chiesto di completare la fase 0 senza fermarsi; la scelta tra i due è da confermare e si può cambiare con poco lavoro finché esistono pochi test.

## D-009 — 2026-11-03 — Renderer

- **Decisione:** Compatibility (`gl_compatibility`) su tutte le piattaforme, telefoni compresi.
- **Motivo:** la documentazione di Godot 4.7 lo indica come sufficiente di solito per il 2D, con il supporto hardware più ampio e consigliato per i telefoni meno recenti. Gli effetti avanzati degli altri renderer non servono a questo gioco.
- **Deciso da:** Claude Code, seguendo la proposta della scaletta e la richiesta di Riccardo di completare la fase 0 senza fermarsi; da confermare. Si cambia in `project.godot`.

## D-010 — 2026-11-03 — Griglia e forme del prototipo

- **Decisione:** involucro di 6×8 celle, camere solo rettangolari, misura minima di una camera 1×1 cella.
- **Motivo:** con 6 colonne ogni cella misura circa 110 px di base, più dei 96 px che corrispondono a 48 dp su un telefono largo circa 360 dp. Le camere rettangolari sono la regola proposta dal concept, sezione 2. La misura minima 1×1 dà la massima libertà: resta da risolvere nella fase 2 come non far sovrapporre le maniglie.
- **Deciso da:** Riccardo. Claude Code aveva raccomandato una misura minima di 2×2. Le misure sono costanti in `core/envelope.gd` e `core/room.gd`, da rivedere dopo la prova sul telefono.

## D-011 — 2026-11-03 — Conferma di framework di test e renderer

- **Decisione:** D-008 (GUT) e D-009 (renderer Compatibility) sono confermate.
- **Deciso da:** Riccardo.

## D-012 — 2026-11-03 — Gesto dall'interno della camera

- **Decisione:** a camera selezionata si può trascinare da qualsiasi punto al suo interno. La direzione del dito dà l'asse e il punto toccato dà il lato: dalla metà alta si muove il soffitto, dalla bassa il pavimento, dalla sinistra la parete sinistra, dalla destra la parete destra. Nello stesso gesto, un verso fa crescere la camera e l'altro la rimpicciolisce.
- **Motivo:** tutta la camera diventa un bersaglio e il dito non copre la parete che si sposta. Claude Code aveva raccomandato la variante in cui conta solo la direzione, che però da sola fa solo crescere la camera, perché qui toccando vicino al centro il risultato può invertirsi. Da verificare provando il gesto.
- **Deciso da:** Riccardo. Per il momento ha scelto di tenere anche le maniglie, visibili e afferrabili dalla parte fuori dalla camera.

## D-013 — 2026-11-04 — Telefono per la fase 3

- **Decisione:** la prova della fase 3 si fa su iPhone. La prova Android è rinviata: Riccardo non ha un telefono Android e vorrebbe provare senza, se possibile.
- **Motivo:** è l'unico telefono disponibile, e il progetto ora si sviluppa su un Mac con Xcode, quindi l'export iOS è possibile da subito. La scaletta prevedeva la prima build iOS in fase 8 e Android in fase 3.
- **Deciso da:** Riccardo. Resta da decidere se installare un emulatore Android, che però non sostituisce la prova con un dito su un telefono vero.

## D-014 — 2026-11-04 — Identificativo provvisorio dell'app

- **Decisione:** per le prove si usa `com.benahq.foldingrooms.dev`. L'identificativo definitivo resta una decisione aperta, da prendere prima della pubblicazione.
- **Deciso da:** Riccardo.

## D-015 — 2026-11-04 — Posizione di Godot sul Mac

- **Decisione:** l'editor sta in `/Applications/Godot.app`, fuori dalla cartella del progetto.
- **Motivo:** dentro il progetto occupava 337 MB non ignorati da Git e Godot ne scansionava il contenuto a ogni import.
- **Deciso da:** Riccardo.

## D-016 — 2026-11-04 — Giudizio sul gesto

- **Decisione:** Riccardo giudica il gesto direttamente sul telefono, al Cancello 1, senza una prova separata su PC.
- **Deciso da:** Riccardo.

## D-017 — 2026-11-04 — Cancello 1: gesto sul telefono

- **Decisione:** il gesto è approvato, si prosegue con la scaletta. Nessuna regolazione di maniglie o elasticità per ora.
- **Motivo:** provato su iPhone 15, Riccardo riferisce che funziona tutto e che il trascinamento è molto comodo.
- **Deciso da:** Riccardo.

## D-018 — 2026-11-04 — Esito della prova di stile

- **Decisione:** la grafica delle camere si costruisce a strati, senza stirare nulla: motivi che si ripetono agganciati all'involucro, fasce di altezza fissa, arredi di misura fissa agganciati a un lato, che compaiono quando c'è spazio. Vale come base per la guida di stile della fase 8; il disegno della prova non è definitivo.
- **Motivo:** provata sull'iPhone 15 con il gesto vero, Riccardo riferisce che regge; uno screenshot del telefono conferma una camera 1×3 disegnata correttamente. Fluidità non misurata.
- **Deciso da:** Riccardo, su proposta di Claude Code.

## D-019 — 2026-11-04 — Ospiti: su misura, non al minimo

- **Decisione:** il gioco non premia il minimo spazio in cui un ospite entra. Ogni ospite ha una misura per entrare e una per stare bene; stipare un ospite è permesso, ma ha conseguenze visibili (reazione triste, permanenza più breve, nessun ricordo); una camera troppo grande non è sempre migliore. I compensi dipendono soprattutto dal benessere e nessun punteggio premia la densità di ospiti per cella.
- **Motivo:** Riccardo ha osservato che ottimizzare lo spazio porta a ospiti stipati, come una giraffa in una camera 3×1, in contrasto con il concept, che promette ospiti felici e non ordini da smaltire. Il puzzle resta perché l'involucro è limitato.
- **Deciso da:** Riccardo, su proposta di Claude Code. Misure ed economia precise restano da definire; l'efficacia è un'ipotesi da verificare nella fase 7.
