# Funzioni da aggiungere

Elenco delle funzioni che Riccardo ha chiesto di aggiungere al gioco, oltre a quanto descritto in
`Folding_Rooms_Concept.md`. Una voce qui significa «da fare», non «da fare subito»: la priorità resta
quella del concept (prima il gesto di trasformare una camera, poi il resto). Ogni voce rimanda alla
decisione in `docs/DECISIONI.md`.

Stato: 💡 idea da valutare, non ancora decisa · 🟡 da progettare · 🔵 in lavorazione · ✅ fatta.

## F-001 — Condividere una foto del proprio hotel 🟡

- **Cosa:** un pulsante che crea un'immagine dell'hotel, o di una singola camera, e la condivide con
  le app del telefono (messaggi, social, galleria).
- **Perché:** ogni hotel è diverso, quindi ogni immagine condivisa mostra il gioco a chi non lo
  conosce. È promozione gratuita portata dai giocatori stessi, utile soprattutto finché non c'è un
  budget per la pubblicità.
- **Idee da valutare durante il design:**
  - inquadrare tutto l'edificio oppure solo la camera selezionata;
  - una cornice leggera con il nome del gioco, senza coprire l'hotel;
  - proporre la condivisione nei momenti di soddisfazione, per esempio quando un ospite difficile è
    sistemato o si apre un nuovo piano, senza insistere.
- **Punti aperti:**
  - Godot non ha un pulsante di condivisione nativo per Android e iOS: con ogni probabilità serve un
    plugin, che va approvato prima (`AGENTS.md`, sezione 9). Da verificare sulla documentazione di
    Godot 4.7.
  - L'immagine contiene solo l'hotel: nessun dato personale (`AGENTS.md`, sezione 9).
  - Testi del pulsante e della cornice tramite `tr()` (`AGENTS.md`, sezione 7).
- **Quando:** quando l'hotel ha la grafica definitiva e vale la pena mostrarlo (fase 8 della scaletta o dopo).
- **Decisione:** D-038.

## F-002 — Capitoli: più hotel, ognuno diviso in livelli 💡

- **Cosa:** il gioco si divide in capitoli. Ogni capitolo è un hotel diverso, con un suo stile, i suoi
  ospiti e una sua regola in più. Esempio di Riccardo: un hotel subacqueo, con ospiti acquatici. Ogni
  capitolo si gioca a livelli brevi.
- **Da chi:** più hotel con stili e ospiti diversi è un'idea di Riccardo (2026-11-05). La divisione in
  livelli è una proposta di Claude Code, nata dal confronto con Tetris e Cooking Fever che fa
  Riccardo. Oggi la partita è senza fine e non si perde mai (D-026).
- **Livello, proposta:** un «weekend» di 4–6 giornate. Ha una fila di ospiti preparata, cioè un seme o
  una sequenza fissa, e un obiettivo, per esempio guadagnare X monete, ospitare 3 giraffe comode o
  rifiutare al massimo 2 ospiti. Dà da 1 a 3 stelle. Se l'obiettivo manca si riprova: niente
  sconfitta punitiva. Durata da misurare; l'obiettivo è qualche minuto.
- **Hotel persistente:** camere, piani, piscina e luce comprati con le monete dei livelli restano.
  L'hotel non si azzera a ogni livello (concept, sezioni 1 e 10).
- **Gioco libero:** la partita senza fine di oggi resta come modo libero, da sbloccare dopo un
  capitolo (concept, sezione 7, «Dopo la campagna»).
- **Perché:**
  - un livello finito è un traguardo e invoglia a cominciare il prossimo;
  - si insegna un ospite alla volta (concept, sezione 3);
  - pubblicità e acquisti trovano momenti naturali tra un livello e l'altro;
  - si vede in quale livello i giocatori smettono;
  - dal giorno 30 circa le monete non si accumulano più senza scopo (D-029);
  - i nuovi hotel sono aggiornamenti naturali dopo il lancio.
- **Hotel diversi, proposta:** ogni hotel porta 4–6 ospiti propri, uno stile e una sola regola o un
  servizio comune nuovo. Gli ospiti di un hotel possono tornare come visitatori negli altri (concept,
  sezione 8). Per il subacqueo la regola nuova è tutta da progettare.
- **Costi e rischi:**
  - ogni hotel richiede una guida di stile, la grafica e qualche decina di livelli;
  - i livelli devono essere file di dati (`AGENTS.md`, sezione 6), così si producono in fretta, ma i
    primi vanno sistemati a mano provandoli;
  - con l'hotel che cresce, i livelli vanno resi più difficili man mano.
  - Proposta: 2–3 hotel al lancio e gli altri come aggiornamenti.
- **Punti aperti:**
  - se gli hotel sostituiscono le facciate previste da D-037;
  - se un livello parte dall'hotel com'è o da una disposizione preparata;
  - quali monete restano tra i livelli.
- **Prima prova proposta:** un solo capitolo di 5 livelli nel prototipo attuale, provato insieme alla
  partita senza fine da 2–3 persone (fase 7 della scaletta).

## F-003 — Rendita degli hotel completati 💡

- **Cosa:** finito il capitolo di un hotel, quell'hotel continua a rendere qualche moneta mentre si
  gioca il successivo. Il racconto: «ho imparato a gestirlo, ora posso dedicarmi ad altro», oppure la
  gestione passa a un dipendente.
- **Da chi:** idea di Riccardo (2026-11-05).
- **Giudizio di Claude Code:** può starci senza complicare il gioco, perché non aggiunge regole al
  puzzle. È un numero per hotel e un pulsante per raccogliere. Ha senso solo con F-002: serve almeno un
  secondo hotel. Forma proposta:
  - la rendita cresce con le stelle prese nei livelli di quell'hotel, così rigiocare i livelli vecchi
    ha uno scopo;
  - si accumula col tempo reale fino a un tetto, la «cassa piena», per esempio in 8–12 ore. Arrivati
    al tetto smette di crescere e non si perde nulla: è un motivo gentile per tornare ogni giorno;
  - il direttore è un ospite di quell'hotel, per esempio la giraffa che diventa direttrice. Usa
    personaggi che esistono già e dà un ricordo affettivo (concept, sezione 6);
  - una pubblicità facoltativa raddoppia la raccolta (`Gaming-Business`, modello mobile);
  - l'hotel completato resta giocabile in modo libero.
- **Rischi:**
  - se la rendita è troppo alta, rende facili gli hotel nuovi: il tetto deve valere al massimo
    quanto un livello;
  - va deciso su cosa si spende;
  - gli avvisi «cassa piena» vanno tenuti facoltativi, al massimo uno al giorno;
  - cambiando l'orologio del telefono si può barare: con il tetto il danno è piccolo;
  - il salvataggio deve registrare l'ora dell'ultima raccolta.
- **Quando:** dopo che F-002 è decisa e provata.
