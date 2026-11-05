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

## D-007 — 2026-11-05 — Condivisione di una foto dell'hotel

- **Decisione:** aggiungere alle funzioni del gioco un pulsante per condividere un'immagine del proprio hotel o di una camera. Dettagli e punti aperti in `docs/FUNZIONI.md`, voce F-001.
- **Motivo:** ogni hotel è diverso; le immagini condivise dai giocatori fanno conoscere il gioco senza costi di pubblicità.
- **Deciso da:** Riccardo, su proposta di Claude Code.

## D-008 — 2026-11-05 — Politica su IA e crediti

- **Decisione:** adottare `docs/IA_E_CREDITI.md` come regola comune su uso dell'IA, ruoli, registro degli asset e trasparenza verso i giocatori; creato `docs/CREDITI.md`. Deciso: codice e grafica provvisoria dagli agenti IA, grafica definitiva con forte aiuto dell'IA, musica di un amico musicista, dichiarare l'uso dell'IA fin dall'inizio. Restano proposte (🟡 nel documento): ospiti e icona da una persona, frase di dichiarazione, dove pubblicarla.
- **Motivo:** evitare che i giocatori scoprano l'uso dell'IA dopo essersi affezionati al progetto; proteggere gli asset (L. 132/2025) e chiarire i diritti sulla musica.
- **Deciso da:** Riccardo, su proposta di Claude Code.
