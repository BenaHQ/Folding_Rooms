# Stato del progetto

Ogni agente aggiorna questo file a fine sessione: riscrive «Adesso» e «Prossimi passi» e aggiunge una riga in cima al registro.

**Ultimo aggiornamento:** 2026-11-05 — Claude Code

## Adesso

- **Fase:** preparazione; il progetto Godot non esiste ancora.
- **Versione di Godot:** `4.7.2-stable` (`AGENTS.md`, sezione 1).
- **Repository:** https://github.com/BenaHQ/Folding_Rooms, collegato come remote `origin`, branch `main`.
- **Lavori in corso:** nessuno.
- **Percorso dell'eseguibile Godot:** da indicare dopo l'installazione.
- **Ambiente rilevato sul PC Windows:** Git e VS Code presenti; Godot e JDK non trovati nel PATH.

## Prossimi passi

1. Installare Godot 4.7.2-stable con i relativi export templates.
2. Creare il progetto Godot e costruire il primo prototipo (concept, sezione 11).
3. Stabilire come ottenere le build iOS: l'export richiede un Mac con Xcode.
4. Funzioni richieste in attesa: `docs/FUNZIONI.md`.

## Registro delle sessioni

| Data | Agente | Fatto | Verificato |
|---|---|---|---|
| 2026-11-05 | Claude Code | Creato `docs/FUNZIONI.md` con la prima funzione richiesta (F-001, condivisione di una foto dell'hotel); registrata la decisione D-007 | Solo documenti; nessun codice. Il bisogno di un plugin per la condivisione è da verificare |
| 2026-11-03 | Claude Code (Opus 5.5) | Fissata la versione di Godot; inizializzato Git con remote, `.gitignore` e `.gitattributes`; primo commit e push su `main` | Regole di esclusione e fine riga provate |
| 2026-11-02 | Claude Code (Opus 5.5) | Creati `AGENTS.md`, `CLAUDE.md`, `docs/STATO.md` e `docs/DECISIONI.md` | Regole di caricamento e dati di store controllati sulle fonti; l'esempio GDScript non è stato eseguito perché Godot non è installato |
