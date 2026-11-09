# Folding Rooms: mercato, costi e stime

Analisi di business del gioco: giochi simili, numeri del mobile gratuito, costo per comprare
un'installazione, come si incassano pubblicità e acquisti in app, stime del primo anno. Sono
**proposte e ordini di grandezza**, non decisioni: le scelte restano di Riccardo. Il fisco è un
modello semplificato, non una consulenza.

Tutto ciò che riguarda Folding Rooms sta in questo repository (D-040). Il simulatore che calcola le
stime è uno strumento generico per tutti i giochi e sta in `Gaming-Business`; legge gli scenari da
`docs/business/scenari/`. Fonti con codice ([P1], [C5]…) in `FONTI.md`, accanto a questo file. Il
piano per farlo conoscere è in `PROMOZIONE.md`.

## 1. Giochi simili e numeri del mobile gratuito

| Gioco | Formula | Risultato | Lezione |
|---|---|---|---|
| **A Little to the Left** [C5] | Puzzle cozy di riordino | ~1 milione di copie su PC e Switch prima di arrivare su mobile; spinta enorme da TikTok | Il gesto soddisfacente si vende con video brevi. Il mobile è arrivato **dopo**, con prova gratuita + sblocco a 9,99 €, e ha subito **molti cloni**. |
| **Unpacking** [C6] | Puzzle cozy spaziale | 100.000 copie in 10 giorni su PC/console | Stesso percorso: prima PC e console, mobile anni dopo. |

**Il mobile a pagamento senza pubblicità è il canale più difficile.** Nessuna delle fonti trovate
mostra un gioco a pagamento per mobile di un singolo sviluppatore che abbia avuto successo partendo
da zero sul mobile. I successi cozy citati sono partiti da PC e console e sono arrivati su mobile già
famosi.

**Gratis con pubblicità e acquisti in app (free-to-play)** è il modello più diffuso sul mobile ed è
quello che hai scelto per Folding Rooms. I numeri che contano [P1–P7]:

| Misura | Gioco medio | Quartile migliore / puzzle | Cosa significa per Folding Rooms |
|---|---|---|---|
| Retention D1 | ~22% | 25–33% | La prima impressione: tutorial e primo ospite devono funzionare in 2 minuti |
| Retention D7 | <4% | 6–7% (puzzle ~12%) | Serve un motivo per tornare: l'hotel che cresce, nuovi ospiti |
| Retention D30 | ~0,75% | 1,6–1,8% (puzzle ~5%) | I giocatori fedeli: quasi tutti gli acquisti vengono da loro |
| eCPM video a premio, Europa | iOS ~8,9 $, Android ~5,1 $ | | I video a premio si adattano bene a un gioco cozy (un arredo, un ospite speciale) |
| eCPM interstiziali, Europa | iOS ~5,3 $, Android ~3,6 $ | | Pochi e in pause naturali, o fanno scappare i giocatori |
| Quota di paganti | 0,5–5%, nessun benchmark solido | | «Rimuovi pubblicità» e pacchetti di arredi |
| Costo per installazione, casual puzzle Europa | Android 0,8–2 $, iOS 1,5–3,5 $ | | Il prezzo da battere per comprare utenti |

Cosa ne ricavo:

1. **La retention decide tutto.** Con retention da gioco medio un'installazione incassa pochi
   centesimi in un anno (simulatore: ~0,16 €) e comprare utenti non conviene. Raddoppiare D30 vale
   più di qualsiasi ottimizzazione della pubblicità.
2. **Le installazioni organiche sono il vero rischio.** Senza budget, gli utenti arrivano da store,
   passaparola e video. Il gesto di Folding Rooms (trascinare una parete e vedere la giraffa che
   finalmente sta dritta) è proprio il tipo di momento che funziona in un video di 10 secondi: è la
   leva principale.
3. **È un lavoro diverso dal gioco a pagamento:** negozio nel gioco, gestione del consenso alla
   pubblicità (GDPR in Europa, ATT su iPhone), analisi dei dati dei giocatori, aggiornamenti continui.
   `AGENTS.md` (§9) esclude gli SDK di pubblicità finché la monetizzazione non è decisa: la scelta di
   Riccardo (pubblicità e acquisti in app) va ancora registrata in `docs/DECISIONI.md`.

## 2. Quanto costa comprare un'installazione

Dati raccolti il 2026-11-05. Le fonti pubbliche sono poche e non concordano: la stessa misura cambia
di 10 volte da un report all'altro, a seconda di generi, paesi e piattaforme dentro la media. Le
tabelle servono per l'ordine di grandezza; il numero vero lo dà solo una campagna di prova.

**Come si paga.** Su Meta (Facebook e Instagram) e TikTok si paga per visualizzazioni (CPM, costo per
mille) e la piattaforma cerca chi installa; su Apple Ads, nei risultati di ricerca, si paga per tocco
(CPT); con Apple Ads Basic e con le campagne per app di Google si fissa il costo per installazione
desiderato. In ogni caso il CPI (costo per installazione) è un risultato: dipende soprattutto dal
video e dalla pagina dello store, non solo dalla rete.

**Pubblicità sugli store.** Su Google Play non esiste una pubblicità separata: le campagne per app di
Google (Google Ads) mostrano il gioco insieme su Google Play, ricerca, YouTube e altri spazi. Su App
Store c'è Apple Ads: risultati di ricerca, scheda Cerca, scheda Oggi e pagine delle altre app.

### Tutti i giochi, per regione (Adjust, dati 2025) [P8]

Media di tutti i generi e di tutte le piattaforme, dominata dai paesi e dai giochi più economici:
sottostima il costo di un gioco casual su iPhone in Europa.

| Regione | CPI 2025 | Variazione su 2024 |
|---|---|---|
| Mondo | 0,56 $ | +30% |
| Nord America | 1,68 $ (USA 1,71 $) | +31% |
| Europa | 0,53 $ (Germania, Austria e Svizzera 1,70 $) | +47% |
| Asia e Pacifico | 0,27 $ (Singapore 2,49 $) | +29% |
| America Latina | 0,14 $ | +40% |
| Medio Oriente e Nord Africa | non indicato | +15% |

### Giochi casual, per piattaforma [P6]

| Fonte | iPhone | Android | Note |
|---|---|---|---|
| Liftoff, casual nel mondo (feb. 2024 – feb. 2025) | 1,41 $ | 0,14 $ | Comprende gli hypercasual, molto economici |
| Admiral Media 2026, casual puzzle nei paesi principali | 2,50–6,00 $ | 1,20–3,00 $ | Intervalli senza fonte né data dichiarate |
| Admiral Media 2025, casual puzzle in Europa | 1,50–3,50 $ | 0,80–2,00 $ | Come sopra |

### Apple Ads, per paese (AppTweak, dati 2025, risultati di ricerca) [P9]

| Paese | CPI, tutte le app | CPT, tutte le app |
|---|---|---|
| USA | 4,06 $ (giochi: 4,63 $) | 1,91 $ (giochi: 2,03 $) |
| Regno Unito | 2,60 $ | 1,35 $ |
| Giappone | 2,57 $ | 1,11 $ |
| Germania | 2,14 $ | 1,11 $ |
| Francia | 1,78 $ | 0,92 $ |
| Italia | 1,32 $ | non indicato |
| Mediana mondiale | 1,80 $ | 0,92 $ |

I giochi esistono solo per gli USA, dove costano circa il 14% più della media. Applicando lo stesso
rapporto, un gioco su Apple Ads in Italia costerebbe circa 1,5 $ a installazione: è una mia stima.
Le campagne «Discovery» (parole chiave larghe) costano molto meno, 1,34 $ negli USA, quelle sui nomi
dei concorrenti molto di più, 8,69 $.

### Per rete pubblicitaria [P10]

Non esiste uno studio pubblico affidabile che confronti le reti per i giochi casual: i numeri qui
sotto vengono da blog di agenzie, senza dati verificabili.

| Rete | CPI indicato, giochi casual | Adatta a |
|---|---|---|
| TikTok | 0,50–1,80 $; altre fonti 1,75–4,00 $ | Video brevi del gesto: il formato naturale di Folding Rooms |
| Meta (Instagram e Facebook) | 1,20–3,00 $ | Pubblico cozy adulto, la rete più facile per iniziare |
| Google (Play, YouTube, ricerca) | 1,50–4,50 $ | Android e volumi; poco controllo su dove appare |
| Apple Ads | vedi tabella sopra | Chi cerca giochi simili su App Store, l'utente più motivato |

### Il budget minimo conta più del CPI [P11]

Le reti imparano chi far installare solo dopo un certo numero di installazioni. Sotto quella soglia
il CPI resta alto e instabile.

| Rete | Regola | Con un CPI di 1,5 $ |
|---|---|---|
| Meta | Fase di apprendimento: circa 50 risultati a settimana per gruppo di inserzioni | ~75 $ a settimana, ~300 € al mese |
| TikTok | Minimo 20 $ al giorno per gruppo di inserzioni, 50 $ per campagna | ~600–1.500 $ al mese |
| Google | Budget giornaliero consigliato: almeno 50 volte il CPI desiderato | ~75 $ al giorno, ~2.250 $ al mese |
| Apple Ads | Nessuna soglia simile trovata; si parte anche con pochi euro | — |

Cosa ne ricavo:

1. **Il CPI del simulatore, 1,5 $ (0,6–3,5), regge per una campagna in Europa** divisa tra iPhone e
   Android. Puntare su USA o Regno Unito con l'iPhone porta il costo verso 3–6 $; puntare su America
   Latina o Asia costa pochi centesimi, ma anche la pubblicità nel gioco rende molto meno lì.
2. **300 € al mese bastano per una sola rete:** Meta o Apple Ads. Google e TikTok, con quel budget,
   non escono dalla fase di apprendimento.
3. **La campagna di misura della fase 4** (`PROMOZIONE.md`) con 100–200 € compra
   circa 70–150 installazioni: bastano per una prima stima di CPI e D1, non per ottimizzare.
4. Il confronto vero resta tra costo e valore di un'installazione: con la retention di un gioco medio
   un'installazione vale ~0,16 €, quindi nessuna rete conviene finché la retention non sale.

## 3. Soldi: pubblicità e acquisti in app

- **La pubblicità non passa dagli store.** La pagano le reti pubblicitarie (AdMob, AppLovin, Unity
  Ads…) al netto della loro quota: niente IVA da togliere e niente commissione di Apple o Google.
  Gli **acquisti in app** invece seguono la catena degli store: IVA, rimborsi, 15% Apple, 25% Google
  nello SEE.
- **La pubblicità è un'attività commerciale**, non lo sfruttamento di un'opera dell'ingegno: per
  quella parte la strada dei diritti d'autore non regge. Con incassi continui serve quasi certamente
  la partita IVA; per questo gli scenari mobile usano il forfettario. Nel simulatore, se scegli
  comunque «diritti d'autore», la pubblicità viene tassata senza deduzione.
- **Nel forfettario le spese non si deducono**, nemmeno la pubblicità a pagamento per acquisire
  utenti: con 3.600 € di campagne l'anno paghi le imposte sul 67% degli incassi come se non le
  avessi spese.
- Le reti pubblicitarie pagano solo sopra una soglia minima di incasso e chiedono i dati fiscali,
  come Steam.
- Regimi fiscali in generale (diritti d'autore, prestazione occasionale, forfettario), ritenuta USA e
  domande per il commercialista valgono per tutti i giochi di Riccardo: sono in `Gaming-Business`,
  `docs/03_soldi_e_fisco.md`.

## 4. Stime del primo anno

Calcolate il 2026-11-05 con il simulatore di `Gaming-Business` (`bizsim`), che legge gli scenari di
questa cartella (`scenari/`). 3.000 estrazioni Monte Carlo, 23 anni, nessun altro reddito, regime
forfettario per il mobile (la pubblicità è un'attività commerciale), diritti d'autore per il PC. Il
netto comprende la probabilità di abbandonare il progetto. P10 è il caso che va male, P90 quello
che va bene.

| Scenario | P10 | P50 | P90 | Atteso | € per ora (P50) | Perdita |
|---|---|---|---|---|---|---|
| Mobile gratis (`folding_rooms_mobile`) | −400 € | 5.400 € | 24.100 € | 8.700 € | 4,9 € | 36% |
| Mobile gratis + 300 €/mese di acquisizione utenti (`folding_rooms_mobile_ua`) | −400 € | 2.100 € | 20.900 € | 6.600 € | 1,7 € | 43% |
| Steam a 9,99 €, solo come confronto (`folding_rooms_pc`) | −450 € | 7.600 € | 27.800 € | 10.500 € | 4,5 € | 36% |

Ipotesi principali dello scenario mobile, tutte da sostituire con dati veri:

| Voce | Valore (intervallo) | Perché |
|---|---|---|
| Installazioni organiche nel primo anno | 25.000 (1.000–200.000) | Il numero più incerto: dipende da video e store |
| Retention D1 / D7 / D30 | 25% / 6% / 1,5% | Gioco medio-buono (§1) |
| Pubblicità per utente al giorno | 2 video a premio, 2 interstiziali | Pubblicità leggera, adatta a un gioco cozy |
| Spese | 800 € | Account Apple (99 $ l'anno) e Google (25 $), asset e musica; il Mac c'è già |
| Ore di Riccardo | 900 (500–2.000) | Gli agenti scrivono il codice; restano grafica, livelli, negozio, prove, promozione |
| Rischio di abbandono | 35% | Cancello 1 superato (D-017), prototipo giocabile |

Come leggerla:

- **La distribuzione è molto larga.** Nella mediana circa 5.400 € nel primo anno; se le installazioni
  esplodono, per esempio per un video virale, oltre 24.000 €. Lo scenario centrale, senza estrazioni
  a caso, dà circa 2.200 € con 25.000 installazioni: la mediana è più alta perché l'intervallo delle
  installazioni arriva a 200.000. Con il rischio di abbandono al 45%, la mediana scenderebbe a circa
  2.700 €.
- **Comprare utenti fa perdere soldi con queste ipotesi.** Con questa retention un'installazione
  incassa circa 0,16 € in un anno, mentre comprarla costa circa 1,30 € (1,5 $): ogni euro di
  pubblicità torna come 13 centesimi. Si comincia a spendere solo dopo aver misurato retention e
  incassi veri (`PROMOZIONE.md`, fase 4).
- **Le ore sono la stima più debole.** Vanno sostituite con quelle registrate davvero.

Come si aggiorna: si cambiano i numeri in `scenari/*.toml` (per esempio D1 e D7 misurati nel test
chiuso) e da `Gaming-Business` si rilancia `python -m bizsim simula folding_rooms_mobile` o
`python -m bizsim confronta`.
