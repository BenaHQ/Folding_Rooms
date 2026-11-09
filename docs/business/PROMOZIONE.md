# Piano di promozione di Folding Rooms (mobile)

Folding Rooms è un gioco **solo mobile** (Android e iOS, decisione D-001), gratis
con pubblicità e acquisti in app, pensato per sessioni brevi e per il pensiero «ancora un'altra
camera». Questo piano dice come farlo conoscere senza budget pubblicitario. Le fasi si aprono con un
traguardo del gioco, non con una data. Al 2026-11-05 il prototipo è giocabile su iPhone (fase 6b
della sua scaletta: gesto, ospiti, giornate, monete, piscina, piani), con grafica provvisoria
disegnata dal codice e senza musica. Il gesto ha già convinto Riccardo sul telefono (Cancello 1,
D-017); nessun altro l'ha ancora provato.

È una proposta: le soglie per passare da una fase all'altra le confermi tu, prima di misurare, così
non si spostano dopo aver visto i risultati. Regole sulla trasparenza verso i giocatori:
`docs/IA_E_CREDITI.md`. Numeri e fonti citati ([P1]…) in `MERCATO.md` e `FONTI.md`, accanto a
questo file.

## Il principio

Sul mobile non esistono le wishlist di Steam e non si vince con il primo giorno di uscita. Contano
tre cose, in quest'ordine:

1. **retention**: quanti tornano a giocare (D1, D7, D30, `MERCATO.md` §1);
2. **installazioni organiche**: quante persone arrivano senza pagare, soprattutto da video brevi e
   dagli store;
3. **incasso per giocatore**: pubblicità e acquisti in app.

Se la retention è bassa, nessuna promozione salva il gioco: chi arriva se ne va. Per questo il piano
misura la retention **prima** di esporsi al pubblico.

## Fase 1 — Adesso: gioco con placeholder

**Traguardo d'uscita:** il gioco convince chi non lo conosce: capisce il gesto da solo e vuole
sistemare un altro ospite.

Pubblico: nessuno, solo persone che conosci.

- [ ] Controllare che il nome «Folding Rooms» sia libero su App Store, Google Play e sui social;
      altrimenti scegliere ora il nome definitivo. Il nome è ancora provvisorio. **Controllo rapido
      del 2026-11-09:** nessun gioco o app con questo nome trovato con una ricerca web (store,
      Steam, itch.io), e nessun marchio «folding rooms» su TMview, la banca dati dei marchi
      dell'Unione europea e di molti uffici nazionali. Nomi vicini, non uguali: «Rooms: The Main
      Building» (puzzle di stanze, 2008), l'app «Rooms» di Things, Inc. e «Fold It Away». Restano da
      controllare i nomi utente sui social e, quando il nome sarà definitivo, una verifica più
      accurata dei marchi.
- [ ] Registrare gli account del gioco: TikTok, Instagram, YouTube, un indirizzo email. Non serve
      pubblicare nulla.
- [ ] Registrare clip di 10–20 secondi a ogni traguardo, anche con i placeholder, in una cartella
      «archivio video». Servono dopo per i video «com'era e com'è». Per clip senza scatti si può
      usare la modalità Movie Maker di Godot (opzione `--write-movie` da terminale), che registra
      a fotogrammi fissi anche su un computer lento; il formato 9:16 del gioco è già quello dei
      video brevi. La clip è anche una prova a basso costo del gesto: se 10 secondi di camera che
      cambia forma non incuriosiscono, è un segnale sul gioco, non solo sulla promozione.
- [ ] Far provare il prototipo a 3–5 persone di persona, senza spiegare nulla, con le domande del
      concept (sezione 11): capiscono dove trascinare? Provano un'altra sistemazione da sole? È la
      fase 7 della scaletta del gioco, rinviata da D-028: è anche il modo più economico per
      scegliere tra partita senza fine e livelli (F-002).
- [ ] Annotare i risultati in `docs/PROVE_GIOCATORI.md`, come prevede la sua scaletta.

## Fase 2 — Il gioco convince: stile definitivo e fetta verticale

**Traguardo d'uscita:** esiste una «fetta verticale», cioè un pezzo piccolo del gioco alla qualità
finale: una camera, la giraffa, la grafica definitiva, un brano dell'amico musicista. E il test
chiuso ha dato le prime misure di retention.

Pubblico: test chiuso, 20–50 persone.

- [ ] Guida di stile e fetta verticale (`docs/IA_E_CREDITI.md` §2); accordo scritto per la musica (§4).
- [ ] Test chiuso con TestFlight (iPhone) e test chiuso di Google Play, con uno strumento gratuito
      di analisi (GameAnalytics o Firebase) per misurare D1 e D7. Lo strumento di analisi
      raccoglie dati dei giocatori: serve prima una decisione esplicita (`AGENTS.md`, sezione 9).
- [ ] **Requisito di Google Play, non solo promozione:** un account sviluppatore *personale* creato
      di recente può pubblicare solo dopo un test chiuso con almeno 12 tester per 14 giorni di
      fila. Numeri da ricontrollare sulla guida ufficiale prima di aprire l'account, perché sono già
      cambiati in passato. Il test chiuso di questa fase può servire anche a questo, se parte su
      Google Play e non solo su TestFlight. Serve un telefono Android per le prove (D-013).
- [ ] Domande ai tester dopo una settimana: cosa ti ha fatto tornare? Cosa ti ha fatto smettere?
- [ ] Inserire D1 e D7 misurati in `docs/business/scenari/folding_rooms_mobile.toml` e rifare i
      conti con `python -m bizsim simula folding_rooms_mobile` da `Gaming-Business`.

**Soglia proposta per passare alla fase 3**, da confermare prima del test: **D1 ≥ 25%** e
**D7 ≥ 6%**, cioè almeno il livello del quartile migliore dei giochi mobile [P1]. Sotto queste
soglie si lavora sul gioco (primi minuti, motivi per tornare) e si ripete il test, senza promozione.

Il test chiuso è piccolo: con 30 persone una differenza di qualche punto percentuale non è
significativa. Serve a scoprire problemi grandi, non a misurare con precisione.

## Fase 3 — Si comincia in pubblico

**Traguardo d'uscita:** il gioco ha il ciclo completo (accogliere ospiti, sistemare camere,
crescere) ed è giocabile per qualche settimana di fila.

Pubblico: chi ama i giochi cozy e i puzzle, sui social.

- [ ] Frase di dichiarazione nella bio di ogni profilo fin dal primo post (`docs/IA_E_CREDITI.md` §5).
- [ ] **Video brevi, 1–2 a settimana**, sempre con il gesto nei primi 2 secondi. Formati che di
      solito funzionano per un gioco così:
  - «Questo ospite non entra» → trascinamento → reazione felice dell'ospite;
  - l'hotel che cresce in accelerato;
  - camere strane fatte dai tester;
  - prima e dopo, con le clip dell'archivio della fase 1.
- [ ] Una pagina con un link solo (il profilo o una pagina semplice) dove raccogliere chi vuole
      essere avvisato all'uscita.
- [ ] Appena c'è una build presentabile: **pre-registrazione su Google Play** e **preordine su App
      Store**, con il link sotto ogni video. Sono l'equivalente mobile delle wishlist. Prima serve
      l'identificativo definitivo dell'app (D-014): una volta aperta la scheda sugli store non si
      cambia più. Il preordine su App Store si crea dal MacBook Air M1 già usato per le build iOS.
- [ ] Comunità: Reddit (giochi cozy, giochi per iPhone e Android, e r/godot e r/IndieDev per chi
      sviluppa), l'hashtag settimanale #screenshotsaturday su Bluesky e X, un Discord per i tester.
      Si partecipa e si risponde, non si pubblica solo il link.
- [ ] Una pagina stampa semplice (press kit): descrizione breve, GIF del gesto, schermate, logo,
      contatto. Serve per scrivere alle testate sui giochi mobile, per esempio Pocket Gamer, che
      ha un modulo per proporre i giochi, e ai creator.
- [ ] Facoltativo: una demo su itch.io, come esportazione web o file APK Android. L'esportazione
      web va provata nel browser del telefono (tocco, fluidità, audio) prima di pubblicarla.
- [ ] Creator di giochi cozy piccoli e medi: messaggio personale con un video e l'invito al test.
- [ ] Ascoltare le reazioni, anche sull'uso dell'IA: se il pubblico reagisce male, cambiare strada
      ora costa poco.

**Cosa misurare ogni settimana:** follower, visualizzazioni medie per video, video migliore della
settimana e perché, pre-registrazioni. Si annotano in un foglio: dicono quali video funzionano e
quale ospite piace di più.

### Un piccolo boost a pagamento (facoltativo)

Con 150–200 € non si accende il passaparola: ogni persona che arriva ne porta di solito meno di
un'altra, e qualche centinaio di pre-registrazioni non muove le classifiche degli store. Il boost
serve a **scoprire se il gioco si diffonde da solo** quando lo vedono persone sconosciute, e a quale
costo. È un test, non un motore.

**Quando:** solo se valgono tutte e tre le condizioni:
- la pre-registrazione su Google Play o il preordine su App Store sono attivi, o almeno il Discord
  dei tester. Prima i soldi vanno persi, perché chi vede il video non ha niente da fare;
- ci sono almeno 6–8 video pubblicati gratis;
- almeno uno di quei video è andato chiaramente meglio degli altri senza spendere.

**Come, nel primo mese:**
- [ ] **~50 € di prova dei video:** 3–4 video diversi, pochi euro al giorno ciascuno, su una sola
      rete (TikTok con Spark Ads o «Promuovi», oppure Instagram con «Metti in evidenza»). Si spingono
      post già pubblicati, così i commenti e i follower restano sul profilo.
- [ ] **Il resto (100–150 €) sul video vincitore**, verso la pagina di pre-registrazione.
- [ ] Paesi: l'Italia più 1–2 paesi europei in inglese o vicini ai mercati principali; costi per
      paese in `MERCATO.md` §2.
- [ ] Ogni video invita a fare qualcosa: pre-registrarsi, entrare nel Discord, mostrare l'hotel. Il
      passaparola va reso un meccanismo, non sperato.

**Cosa misurare:**
- **costo per pre-registrazione:** dice in anticipo quanto costerà un giocatore al lancio;
- **video migliore e perché:** l'ospite, il primo secondo, il formato;
- **effetto sul gratuito:** se dopo il boost crescono anche visualizzazioni e follower dei video
  non pagati, il gioco si diffonde. Se no, il gioco si presenta male nei primi secondi, e un budget
  più alto non lo risolve.

**Regola:** il boost porta pre-registrazioni e follower, non installazioni da pagare in continuo.
Si ferma dopo il primo mese e si decide con i numeri raccolti. Comprare installazioni resta
legato alla retention misurata (fase 4).

## Fase 4 — Lancio di prova in pochi paesi (soft launch)

**Traguardo d'uscita:** retention e incassi del lancio di prova sopra le soglie fissate prima.

- [ ] Pubblicazione in 1–3 paesi soltanto. Di solito si scelgono paesi in inglese con giocatori
      simili ai mercati principali; la scelta si fa al momento, guardando costi e regole degli store.
- [ ] Pubblicità e acquisti in app attivi, consenso GDPR e ATT funzionanti.
- [ ] **Campagna di misura da 100–200 €** su una sola rete, Meta o Apple Ads: dà il costo reale di
      un'installazione e la retention di giocatori sconosciuti, più affidabile di quella dei tester.
      Sono circa 70–150 installazioni: bastano per una prima stima, non per far imparare la rete,
      che su Meta chiede circa 50 installazioni a settimana. Costi per regione e per rete in
      `MERCATO.md` §2 [P6, P8–P11].
- [ ] Aggiornare lo scenario con D1, D7, D30, eCPM, quota di paganti e spesa per pagante veri: il
      simulatore diventa una previsione invece di un'ipotesi.
- [ ] Correggere e ripetere finché i numeri sono sopra le soglie.

**Soglie proposte per il lancio mondiale**, da confermare prima del lancio di prova: D1 ≥ 30%,
D7 ≥ 8%, D30 ≥ 2%. Sono valori sopra il quartile migliore dei giochi mobile [P1]: senza, il lancio
mondiale consuma l'unica occasione di novità del gioco.

## Fase 5 — Lancio mondiale

- [ ] Richiesta di vetrina alla redazione di App Store (in App Store Connect, sezione dedicata alle
      candidature) e verifica dei programmi di Google Play per i giochi indie attivi in quel
      momento. La candidatura Apple è gratuita, non garantisce nulla e va inviata almeno 2
      settimane prima del lancio; Apple consiglia fino a 3 mesi prima. Quindi va preparata durante
      la fase 4, non al lancio. Si fa dal MacBook Air M1 già usato per le build iOS.
- [ ] Scheda store curata: icona, prime due schermate, video di anteprima, parole chiave nel titolo
      e nel sottotitolo, traduzioni della scheda nelle lingue principali.
- [ ] Avviso a chi si è pre-registrato, post su tutti i profili, messaggio ai creator.
- [ ] **Condivisione dell'hotel dal gioco** (F-001 in `docs/FUNZIONI.md`) attiva dal
      primo giorno.
- [ ] Acquisizione utenti a pagamento **solo se** il valore di un'installazione supera il suo costo
      (riquadro «Quanto vale un giocatore» del simulatore).

## Dopo il lancio

Sul mobile il lancio è un inizio. Aggiornamenti regolari con nuovi ospiti ed eventi stagionali danno
motivi per tornare e materiale per nuovi video, e lo store guarda anche alla frequenza degli
aggiornamenti.

## Cosa non fare

- Mostrare al pubblico i placeholder come se fossero il gioco.
- Comprare installazioni prima di aver misurato la retention (il boost della fase 3 compra solo
  pre-registrazioni e informazioni, ed è limitato a un mese).
- Promettere date di uscita prima della fase 4.
- Nascondere l'uso dell'IA.
