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

## D-020 — 2026-11-04 — Accessi e corridoi nel prototipo

- **Decisione:** accessi e corridoi sono ignorati nel prototipo: nessuna regola controlla come si raggiunge una camera. Si rivalutano dopo la prova con i giocatori (fase 7).
- **Motivo:** permette di provare da sola la regola della parete condivisa. Il rischio accettato è che alcune disposizioni approvate ora non siano più valide quando arriveranno i corridoi.
- **Deciso da:** Riccardo, su proposta della scaletta.

## D-021 — 2026-11-04 — Regola della parete condivisa

- **Decisione:** una parete che raggiunge una camera vicina la sposta; se la tocca già, la vicina la segue anche quando rientra. La modifica è rifiutata se la vicina scende sotto la misura minima o se resterebbe non rettangolare, cioè se la parete non copre tutto il suo lato. La spinta non passa a una terza camera e nessuna camera viene cancellata. Se la vicina è più lunga della parete, rientrando si lascia spazio libero.
- **Motivo:** applica la scaletta (fase 4) e il concept, sezione 2, mantenendo le camere rettangolari (D-010). Il comportamento in rientro non è ancora provato: due camere che si toccano con lo stesso lato non possono separarsi trascinando quella parete.
- **Deciso da:** Claude Code, seguendo la regola approvata nella scaletta; i dettagli sono da confermare con la prova di Riccardo.

## D-022 — 2026-11-04 — La camera vicina si muove solo se spinta

- **Decisione:** quando una parete rientra, la camera vicina resta ferma e si crea spazio libero, anche se le due camere si toccano. Spingere resta come in D-021.
- **Motivo:** provando sul telefono, Riccardo ha giudicato un difetto che la seconda camera seguisse la prima quando sono già attaccate.
- **Deciso da:** Riccardo, che ha confermato la regola dopo la correzione.
- **Sostituisce:** in D-021, la parte sulla camera vicina che segue la parete quando rientra.

## D-023 — 2026-11-04 — Prove nel simulatore iPhone con l'app nativa

- **Decisione:** le prove rapide si fanno nel simulatore iPhone con l'app nativa, tramite `tools/run_ios_simulator.sh`. Il telefono resta necessario per giudicare tocco vero e fluidità.
- **Motivo:** nei modelli ufficiali di Godot 4.7.2 la libreria per simulatore è solo `x86_64` e su questo Mac viene rifiutata. La libreria `arm64` è stata compilata dai sorgenti ufficiali di `4.7.2-stable` (checksum verificato) con SCons 4.11.1, in circa 6 minuti, ed è salvata fuori dal repository in `~/Library/Application Support/Godot/custom_templates/4.7.2-ios-simulator-arm64/`. Serve solo al simulatore: le build per iPhone usano i modelli ufficiali.
- **Deciso da:** Riccardo.

## D-024 — 2026-11-04 — Terzo ospite

- **Decisione:** il terzo ospite del prototipo è un ospite piccolo che vuole una camera raccolta. Serve a mostrare che più grande non è sempre meglio (D-019).
- **Deciso da:** Riccardo, su proposta della scaletta. La specie è provvisoria: nei dati è un ghiro (`data/guests/dormouse.tres`), scelto da Claude Code.

## D-025 — 2026-11-04 — Misure degli ospiti e assegnazione nel prototipo

- **Decisione:** misure iniziali, in celle (larghezza × altezza). Giraffa: entra da 1×3, sta bene da 2×3. Serpente: entra da 3×1, sta bene da 4×1 con altezza massima 2. Ghiro: entra da 1×1, sta bene fino a 2×2. Si sceglie un ospite dalla scheda e si tocca la camera selezionata per farlo entrare; toccando la scheda di un ospite in camera, esce. Una modifica che lascerebbe fuori un ospite già presente è rifiutata.
- **Motivo:** applica D-019 e la frase del concept, sezione 2, sulle trasformazioni che renderebbero una camera inutilizzabile. I numeri stanno nei file di `data/guests/` e sono facili da cambiare.
- **Deciso da:** Claude Code; misure e modo di assegnare sono da confermare con la prova di Riccardo.

## D-026 — 2026-11-04 — Ciclo di gioco: fila di ospiti, turni e compensi

- **Decisione:** gli ospiti arrivano uno alla volta da una fila, alla Tetris; si vedono quello di turno e i due successivi. Ognuno indica il bisogno, per quanti turni resta e quanto paga se è comodo o scomodo. Un turno finisce quando l'ospite di turno viene sistemato o rifiutato. A ogni turno chi è in camera paga secondo come sta in quel momento. Si può rifiutare senza penalità e, per ora, non si perde mai. Spostare le pareti è gratis. Una camera troppo grande paga come una in cui si è stipati.
- **Valori iniziali** (turni di permanenza, monete a turno da comodo, da scomodo): giraffa 3, 10, 4; serpente 2, 12, 5; ghiro 3, 6, 3. Sono proposte di Claude Code, in `data/guests/`, da bilanciare provando.
- **Motivo:** una fila crea la pressione che le schede libere non davano, e i compensi legati al comfort applicano D-019. Le regole non bloccano le prove con i giocatori: una condizione di sconfitta e i costi delle modifiche si valutano dopo.
- **Deciso da:** Riccardo per il ciclo e le quattro regole; Claude Code per valori e per il trattamento delle camere troppo grandi.
- **Sostituisce:** in D-019, la permanenza più breve per chi è stipato: la permanenza ora è fissa, cambia il compenso. In D-025, la scelta libera dell'ospite dalla scheda e l'uscita a comando. Anticipa l'economia minima prevista dalla scaletta in fase 8.

## D-027 — 2026-11-04 — Salvataggio locale della partita

- **Decisione:** la partita si salva in `user://hotel_save.json`, testo JSON con `format_version` 1: monete, turni, camere, ospiti con i turni rimasti, fila e stato del generatore casuale, così gli arrivi futuri non cambiano. Il salvataggio avviene quando l'app passa in secondo piano, alla chiusura della finestra e con Indietro, non a ogni mossa. Al caricamento tutto ripassa dalle regole di `Grid`. Un file danneggiato, di un'altra versione o con una partita impossibile non blocca il gioco: si inizia una partita nuova e il file resta da parte come `hotel_save.json.unreadable`. Su Android, Indietro annulla il gesto in corso, poi toglie la selezione, poi salva ed esce.
- **Motivo:** applica `AGENTS.md`, sezioni 6 e 7. JSON non può eseguire codice, a differenza di una `Resource`. Mettere da parte il file evita di perdere dati che una versione futura potrebbe ancora leggere.
- **Deciso da:** Riccardo per il salvataggio, con la scaletta (D-007); Claude Code per formato, momenti di salvataggio e comportamento di Indietro, da riconsiderare se la prova con i giocatori lo richiede.

## D-028 — 2026-11-04 — Prova con i giocatori rinviata e nuove camere a monete

- **Decisione:** la prova con i giocatori della fase 7 è rinviata finché il prototipo non ha più funzioni. La prima funzione aggiunta sono le nuove camere: si tocca il pulsante Costruisci, le celle libere si segnano con «+» e toccandone una si compra una camera da 1 cella, che si allarga gratis con il gesto delle pareti. La prima costa 30 monete e ogni camera in più costa 20 monete in più (30, 50, 70…). Costruire non consuma il turno. Toccare altrove, ripremere il pulsante o Indietro annulla senza spendere.
- **Idea da riprendere:** Riccardo vorrebbe valutare più avanti che costruire consumi il turno, diventando un'alternativa a ospitare. Annotata nella scaletta, fase 9, con il bilanciamento.
- **Motivo:** per Riccardo il prototipo è ancora troppo acerbo per farlo giudicare ad altri. Le monete non avevano uno scopo, e con più camere il ciclo di gioco e le funzioni successive diventano più interessanti. Resta il rischio di costruire molto su un nucleo che nessun altro ha provato: per questo la scaletta prevede una prima prova con una sola persona dopo due o tre funzioni.
- **Deciso da:** Riccardo per il rinvio, il pulsante, i prezzi e il turno. Claude Code per la misura iniziale da 1 cella e per gli annullamenti. I prezzi sono da bilanciare provando.
- **Sostituisce:** in D-007, l'ordine della scaletta: la fase 7 non è più il passo successivo alla fase 6.

## D-029 — 2026-11-04 — Giornate con più arrivi

- **Decisione:** un turno diventa una giornata. Arrivano più ospiti, uno alla volta, e ognuno va ospitato o rifiutato. Dopo l'ultimo la giornata finisce: chi è in camera paga, resta un turno in meno e chi ha finito parte. Gli arrivi al giorno sono la metà delle camere, per eccesso (2 camere 1 arrivo, 3 o 4 camere 2, 5 o 6 camere 3), e una camera costruita conta dal giorno dopo. In alto si vedono gli arrivi rimasti. Il formato del salvataggio passa alla versione 2, senza conversione: un salvataggio della versione 1 viene messo da parte e si riparte da una partita nuova, perché esistevano solo salvataggi di prova.
- **Motivo:** provando, Riccardo non ha mai avuto più di 3 camere occupate. Con un arrivo a turno e permanenze di massimo 3 turni era un limite matematico, e le camere comprate in più restavano inutili. Permanenze e compensi non cambiano.
- **Controllo:** simulazione con un giocatore automatico semplice, 20 partite da 40 giorni: dal giorno 20 circa 8 camere e 5 occupate, poi circa 10 camere e 6 occupate. Dal giorno 30 l'involucro è quasi pieno e le monete si accumulano, perché non c'è altro da comprare. Il giocatore automatico sceglie male le celle e non restringe le camere: i numeri indicano solo l'ordine di grandezza.
- **Deciso da:** Riccardo per le giornate con più arrivi; Claude Code per la formula degli arrivi e per il formato del salvataggio. La formula è da bilanciare provando.
- **Sostituisce:** in D-026, il turno che finisce a ogni ospite sistemato o rifiutato.

## D-030 — 2026-11-04 — Spostare la camera intera dal centro

- **Decisione:** a camera selezionata, trascinandola dal centro la si sposta intera, con il suo ospite; le maniglie cambiano la forma. Un tocco senza trascinare continua a far entrare l'ospite di turno. Lo spostamento è gratis e non consuma il turno. Conta solo dove la camera arriva: può passare sopra le altre mentre è sollevata dal dito, ma non può fermarsi su un'altra camera né uscire dall'involucro, e non spinge nessuno. Se il punto d'arrivo non è valido, al rilascio torna dov'era.
- **Maniglie:** l'area sensibile misura 112 pixel lungo il lato e 96 di traverso, 68 fuori dalla camera e 28 dentro. La parte interna è stretta per lasciare un centro anche nelle camere da 1 cella, dove il centro misura circa 54 pixel per lato.
- **Motivo:** Riccardo vuole riorganizzare l'hotel senza dover restringere e riallargare le camere.
- **Deciso da:** Riccardo per il gesto. Claude Code per gratuità, passaggio sopra le altre camere e misure dell'area sensibile, da confermare provando.
- **Sostituisce:** D-012: dall'interno della camera non si sceglie più un lato in base alla metà toccata. Rimpicciolire ora richiede le maniglie.

## D-031 — 2026-11-04 — Pulsante per ricominciare da zero

- **Decisione:** un pulsante in alto a destra, sotto la riga dei numeri, riporta la partita all'inizio. Il primo tocco lo arma: mostra una spunta e un bordo rosso per 3 secondi. Il secondo tocco conferma. La partita nuova sostituisce subito quella salvata, senza possibilità di tornare indietro.
- **Motivo:** Riccardo vuole poter ripartire da zero durante le prove; prima bisognava disinstallare l'app. La conferma evita di perdere la partita con un tocco per sbaglio.
- **Deciso da:** Riccardo per il pulsante; Claude Code per posizione e conferma. Posizione e aspetto sono da rivedere con l'interfaccia definitiva della fase 8.

## D-032 — 2026-11-04 — Luce e buio come camere speciali a pagamento

- **Decisione:** la luce non dipende da dove sta la camera: è una caratteristica che si compra. Ogni camera nasce normale. Per 10 monete diventa buia, togliendo l'illuminazione, oppure ottiene le lampade speciali. Per tornare normale si scelgono 20 monete, subito, oppure gratis: la camera resta in lavori fino a fine giornata e non può ospitare nessuno. Il pipistrello vuole il buio e l'ospite vegetale le lampade, gli altri ospiti la luce normale. Con la luce sbagliata si entra, ma si paga il compenso da scomodo. Pipistrello e ospite vegetale arrivano dalla quarta camera in poi, dai sacchetti successivi. Comprare non consuma il turno.
- **Scelte di Claude Code, da confermare provando:** la luce si può cambiare anche con un ospite dentro, per rimediare, ma i lavori richiedono una camera libera; da buia a lampade si passa da normale; tra i problemi di un ospite l'icona mostra prima la luce, poi la misura; un pannello con due pulsanti compare sotto la riga dei numeri quando una camera è selezionata. **Valori iniziali:** pipistrello entra da 1×1, sta bene da 1×2, 3 turni, 11 monete da comodo e 3 da scomodo; ospite vegetale entra da 1×1, sta bene da 2×1 con altezza massima 2, 3 turni, 11 e 3.
- **Motivo:** Riccardo ha proposto questa regola al posto di quella che legava la luce alle pareti esterne: una camera speciale diventa un investimento, e servendo solo al suo ospite rende vera la scelta se tornare normale. Le monete hanno un altro uso.
- **Deciso da:** Riccardo per la regola, i prezzi, le due vie di ritorno, gli ospiti comuni e la quarta camera.
- **Differenza dal concept:** nella sezione 5 il buio viene da una stanza schermata o interna e la luce da una parete esterna. Il concept resta da aggiornare, con l'approvazione di Riccardo.
- **Formato del salvataggio:** versione 3, senza conversione: i salvataggi precedenti vengono messi da parte.

## D-033 — 2026-11-04 — Paga e permanenza variabili per ogni ospite

- **Decisione:** ogni ospite in arrivo ha valori propri di permanenza e compenso, estratti entro un margine della sua specie, e la scheda mostra quelli. Margini iniziali, in più o in meno: permanenza 1 turno per tutti; compenso da comodo 2 monete, 1 per il ghiro; compenso da scomodo 1 moneta. Stare comodi rende sempre più che stare scomodi, anche nel caso peggiore (D-019). I valori restano nel salvataggio, e lo stesso seme dà gli stessi ospiti.
- **Motivo:** Riccardo vuole che gli ospiti di una specie non siano tutti uguali.
- **Deciso da:** Riccardo per gli intervalli; Claude Code per i margini, da bilanciare provando. I margini stanno in `data/guests/`.

## D-034 — 2026-11-04 — Progressione più semplice

- **Decisione:** gli arrivi al giorno sono un terzo delle camere, per eccesso (fino a 3 camere 1 arrivo, da 4 a 6 camere 2, da 7 a 9 camere 3). Le permanenze scendono a circa 2 turni, da 2 a 3 con il margine: un ospite estratto non resta mai un turno solo, perché sparirebbe appena entrato. Le misure degli ospiti non cambiano.
- **Motivo:** Riccardo riferisce di non riuscire a sistemare tutti gli ospiti fin dall'inizio. Con la metà delle camere in arrivo e permanenze di 3 turni, gli ospiti erano in media una volta e mezza le camere: era impossibile sistemarli tutti. Il giocatore automatico ne rifiutava il 18-34%.
- **Scartato:** Claude Code aveva abbassato anche le misure di ingresso di giraffa e serpente, così da entrare nelle camere iniziali senza modificarle. Riccardo l'ha rifiutato: stare stipati e stare comodi devono restare misure diverse e il gesto deve servire. Giraffa e serpente vanno quindi ancora adattati prima di entrare.
- **Controllo:** stessa simulazione, 40 partite da 40 giorni, comprando appena possibile: rifiutati 0% al giorno 1, 12% nei giorni 1-3, 8% nei giorni 4-10, 5% nei giorni 11-20, 7% dopo; nei giorni 21-40 circa 9 camere e 7 occupate. Il giocatore automatico sceglie male e non sposta le camere, quindi i numeri indicano solo l'ordine di grandezza. Una persona non è ancora stata misurata.
- **Deciso da:** Riccardo per l'obiettivo e per le misure; Claude Code per i valori, confermati da Riccardo senza ancora una prova misurata.
- **Sostituisce:** in D-029, la formula degli arrivi; in D-026, D-032 e D-033, le permanenze iniziali.

## D-035 — 2026-11-04 — Formato della proposta grafica principale

- **Decisione:** la proposta della schermata principale usa un rapporto **9:16 verticale**, come richiesto esplicitamente da Riccardo dopo l'esplorazione delle proporzioni iPhone. Il file finale è `immagini/folding_rooms_main_ui_style_v1.png`, 1152×2048 pixel.
- **Motivo:** definire il formato desiderato per la proposta. Il progetto usa già una base 720×1280 con espansione sugli schermi più lunghi: nessuna impostazione Godot è cambiata.
- **Deciso da:** Riccardo per il rapporto. Direzione artistica, guida in `docs/STILE.md` e integrazione nel gioco restano da valutare; questa decisione non approva automaticamente lo stile.
