# Funzioni da aggiungere

Elenco delle funzioni che Riccardo ha chiesto di aggiungere al gioco, oltre a quanto descritto in
`Folding_Rooms_Concept.md`. Una voce qui significa «da fare», non «da fare subito»: la priorità resta
quella del concept (prima il gesto di trasformare una camera, poi il resto). Ogni voce rimanda alla
decisione in `docs/DECISIONI.md`.

Stato: 🟡 da progettare · 🔵 in lavorazione · ✅ fatta.

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
- **Quando:** dopo il primo prototipo, quando l'hotel ha un aspetto che vale la pena mostrare.
- **Decisione:** D-007.
