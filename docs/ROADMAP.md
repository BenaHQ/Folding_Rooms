# Scaletta di sviluppo

**Stato:** approvata da Riccardo il 2026-11-03 (`docs/DECISIONI.md`, D-007). Le «proposte» dei singoli passi restano da decidere quando si arriva a quel passo.

## Come si usa

- Si lavora una fase alla volta, nell'ordine. Ogni fase ha il suo branch e vale la definizione di «fatto» di `AGENTS.md`, sezione 8.
- **Cancello:** punto in cui Riccardo decide se proseguire. Non si salta.
- **Decisione:** punto aperto (`AGENTS.md`, sezione 3). «Proposta» è solo una raccomandazione: la scelta va chiesta a Riccardo e registrata in `docs/DECISIONI.md`.
- Qui si spuntano i passi completati; il dettaglio delle sessioni resta in `docs/STATO.md`.

## Fase 0 — Fondamenta

**Obiettivo:** un progetto Godot vuoto che si avvia e un test automatico che gira.

- [x] Decisione: renderer Compatibility (D-009).
- [x] Decisione: framework di test GUT 9.7.1 (D-008).
- [x] Creare `project.godot` (verticale, 720×1280, `canvas_items`, `expand`, emulazione del tocco con il mouse), le cartelle di `AGENTS.md`, sezione 6, e i file `.gdignore`.
- [x] Installare il framework e far girare un primo test da terminale.

**Fatto quando:** l'import non dà errori, il test passa e si apre una finestra verticale.

## Fase 1 — Regole di una camera

**Obiettivo:** il codice, senza grafica, sa dire se una modifica è permessa e perché.

- [x] Decisione: griglia di 6×8 celle, camere rettangolari, misura minima 1×1 (D-010).
- [x] Scrivere `Grid`, `Room` ed `Envelope` in `core/`.
- [x] Scrivere la funzione di anteprima: dati camera, lato e spostamento in celle, restituisce il risultato previsto e il motivo di un eventuale rifiuto, senza modificare nulla.
- [x] Test: spazio libero, limite dell'involucro, dimensione minima, sovrapposizioni.

## Fase 2 — Il gesto su una camera

**Obiettivo:** su PC, con grafica segnaposto, trascinare una parete è già piacevole. È la fase più importante del progetto (concept, sezione 2).

- [x] Disegnare involucro e camera con forme semplici.
- [x] Selezione della camera e maniglie con area sensibile di almeno 48 dp. Nelle camere da 1 cella le aree possono sovrapporsi: vince la maniglia con il centro più vicino al dito.
- [x] Trascinamento: la deformazione elastica segue il dito, le regole scattano a celle intere.
- [x] Anteprima valido/non valido con contorno, icona e sagoma di prova, senza che il dito copra l'informazione.
- [x] Rilascio: assestamento morbido se la modifica è valida, ritorno elastico se è rifiutata.
- [x] Casi limite: secondo dito e tocco interrotto.
- [x] Gesto dall'interno della camera: la metà toccata e l'asse del dito scelgono il lato (D-012).
- [x] Riccardo giudica se il gesto è piacevole direttamente sul telefono, al Cancello 1, senza una prova separata su PC (D-016).

## Fase 3 — Prova su un telefono vero

**Obiettivo:** il gesto funziona con un dito su uno schermo piccolo, non solo con il mouse.

- [x] Decisione: la prova si fa su iPhone, l'unico telefono disponibile (D-013).
- [x] Installare export templates 4.7.2. Xcode era già presente. JDK e Android SDK sono rinviati (D-013).
- [x] Preparare l'export iOS, escludendo `addons/gut/` e `tests/`, e compilare per iPhone senza firma.
- [ ] Decisione: identificativo definitivo dell'app. Per le prove si usa `com.benahq.foldingrooms.dev` (D-014). Va fissato prima della pubblicazione, perché cambiarlo dopo crea un'app diversa.
- [x] Riccardo accede con il suo Apple ID in Xcode e collega l'iPhone.
- [x] Installare sull'iPhone una prima build di debug firmata.
- [x] Riccardo autorizza lo sviluppatore sull'iPhone e l'app si avvia.
- [x] Regolare dimensione delle maniglie, elasticità, precisione e fluidità: nessuna regolazione necessaria su iPhone (D-017). I gesti di sistema ai bordi vanno ricontrollati su Android, dove i bordi laterali sono più sensibili.

**Cancello 1:** superato il 2026-11-04 (D-017). Riccardo prova il gesto sul telefono. Se non convince si torna alla fase 2 e non si aggiunge altro.

- [x] Prova di stile (esito in D-018): una sola camera disegnata con lo stile previsto (concept, sezione 9), deformata con il gesto vero sul telefono. Serve a capire come costruire la grafica perché si allunghi senza rovinarsi; il risultato si annota in `docs/DECISIONI.md`. Non è grafica definitiva.

## Fase 4 — Due camere vicine

**Obiettivo:** modificare una camera può coinvolgere quella accanto, in modo leggibile.

- [ ] Decisione: accessi e corridoi. Proposta: ignorati nel prototipo, da rivalutare dopo la prova con i giocatori.
- [ ] Regola della parete condivisa: spostarla cambia entrambe le camere; rifiuto se una diventa inutilizzabile; nessuna cancellazione automatica. Con test.
- [ ] Anteprima visiva delle due modifiche insieme.

## Fase 5 — Ospiti

**Obiettivo:** la forma della camera ha uno scopo.

- [ ] Decisione: terzo ospite. Giraffa e serpente sono nel concept, gli altri suoi ospiti hanno bisogni ambientali. Proposta: un ospite piccolo che vuole una camera raccolta, così «più grande» non è sempre meglio.
- [ ] `Guest` e `Need` come `Resource` in `data/`, regola con due soglie, «entra» e «sta bene» (D-019), con test.
- [ ] Icona del bisogno e sagoma dell'ospite durante il trascinamento.
- [ ] Assegnazione e reazione dell'ospite, con un'animazione semplice, diversa se l'ospite è stipato o sta bene (D-019).

## Fase 6 — Salvataggio

**Obiettivo:** la disposizione dell'hotel sopravvive alla chiusura dell'app.

- [ ] Formato con numero di versione in `user://`, scrittura su file temporaneo e poi rinomina, nessuna `Resource` caricata da file modificabili.
- [ ] Salvataggio alla pausa dell'app e gestione del tasto Indietro.
- [ ] Test: salva e ricarica, file danneggiato, versione diversa.

## Fase 7 — Prova con i giocatori

**Obiettivo:** capire se il nucleo regge con chi non conosce il gioco.

- [ ] Far provare la build a 3–5 persone, senza spiegazioni, osservandole con le domande del concept, sezione 11. In più: chi stipa gli ospiti lo fa per scelta, e come si sente quando li vede (D-019)?
- [ ] Annotare i risultati in `docs/PROVE_GIOCATORI.md` e correggere i problemi emersi.

**Cancello 2:** Riccardo decide se proseguire, cambiare le regole o tornare indietro.

- [ ] Solo se la prova è positiva: una singola interazione ambientale (concept, sezioni 5 e 11).

## Fase 8 — Primi minuti completi

**Obiettivo:** la sequenza del concept, sezione 3, è giocabile dall'inizio alla fine con grafica vera.

- [ ] Decisioni: lingue (proposta: italiano e inglese), versioni minime dei sistemi operativi, come accedere a un Mac con Xcode.
- [ ] Guida di stile in `docs/STILE.md`, approvata da Riccardo: palette, forme, regole per camere e ospiti (compreso come si allungano, in base alla prova di stile della fase 3), componenti dell'interfaccia e icone.
- [ ] Interfaccia (Hotel, Ospiti, Arredi, Progetti), aree sicure e testi con `tr()`.
- [ ] Reception, sequenza dei primi minuti e primo compenso, con un'economia minima.
- [ ] Grafica definitiva secondo la guida, prima su una camera e un ospite, poi su tutto il resto; audio; `docs/CREDITI.md`.
- [ ] Prima build iOS su un iPhone vero, così i problemi emergono presto.

**Cancello 3:** prova dei primi minuti con giocatori nuovi.

## Fase 9 — Gioco completo

**Obiettivo:** la progressione del concept, sezioni 5–8. Si procede un blocco alla volta, con una piccola prova alla fine di ognuno. Ogni nuovo componente grafico segue `docs/STILE.md`.

- [ ] Piani (`Storey`) e scorrimento dell'edificio. Rischio: lo scorrimento non deve confondersi con il trascinamento delle pareti.
- [ ] Arredi funzionali (`Furniture`) e decorazioni, tenuti separati.
- [ ] Luce e buio: pipistrello e ospite vegetale.
- [ ] Servizi comuni (`Facility`), draghetto, ospite acquatico e sinergie.
- [ ] Ricordi (`Keepsake`), ospiti che tornano e incarichi (`Task`).
- [ ] Decisioni: numero di specie e monetizzazione, prima di bilanciare l'economia perché la condizionano.
- [ ] Bilanciamento dell'economia: compensi legati soprattutto al benessere, nessun premio alla densità di ospiti (D-019).
- [ ] Decisioni e sviluppo: finale, contenuti successivi, salvataggi remoti.

## Fase 10 — Pubblicazione

**Obiettivo:** il gioco è sugli store. Prima si ricontrollano i requisiti aggiornati (`AGENTS.md`, sezione 10).

- [ ] Account sviluppatore Google e Apple, creati da Riccardo.
- [ ] Keystore di rilascio con backup fuori dal repository, AAB firmato e target API verificato.
- [ ] Export iOS con Xcode.
- [ ] Icone, schermata iniziale, pagine degli store, informativa sulla privacy e moduli.
- [ ] Prove su dispositivi reali, consumo della batteria e aggiornamento dei salvataggi da una versione precedente.
- [ ] Test chiuso sugli store (verificare i requisiti attuali per i nuovi account), poi pubblicazione con la conferma di Riccardo.
