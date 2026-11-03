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
