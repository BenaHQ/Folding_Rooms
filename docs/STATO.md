# Stato del progetto

Ogni agente aggiorna questo file a fine sessione: riscrive «Adesso» e «Prossimi passi» e aggiunge una riga in cima al registro.

**Ultimo aggiornamento:** 2026-11-03 — Claude Code (Opus 5.5)

## Adesso

- **Fase:** fase 0 della scaletta (`docs/ROADMAP.md`) completata sul branch `setup/fase-0-progetto`, non ancora unito a `main` né inviato al remote.
- **Versione di Godot:** `4.7.2-stable` (`AGENTS.md`, sezione 1).
- **Repository:** https://github.com/BenaHQ/Folding_Rooms, collegato come remote `origin`, branch `main`.
- **Lavori in corso:** nessuno.
- **Eseguire i test:** dalla radice del progetto, con l'eseguibile `_console` indicato qui sotto, `--headless --path . -d -s addons/gut/gut_cmdln.gd`. Restituisce 0 se tutti i test passano e 1 se qualcuno fallisce.
- **Finestra su PC:** 450×800 pixel per stare nello schermo (`window_width_override` e `window_height_override` in `project.godot`). L'area di gioco di riferimento resta 720×1280.
- **Problema noto, non bloccante:** aprendo l'editor, il controllo aggiornamenti di GUT verso `api.github.com` ha stampato `TLS handshake error: -9984` e `[GUT] Could not get version info`. Causa non indagata; non riguarda i test da terminale né il gioco.
- **Eseguibile Godot sul PC Windows:** `C:\Users\ricca\AppData\Roaming\craft-anything\engines\godot\Godot_v4.7.2-stable_win64.exe`. Per i comandi da terminale usa `Godot_v4.7.2-stable_win64_console.exe` nella stessa cartella, che mostra l'output. Non è nel PATH.
- **Ambiente rilevato sul PC Windows:** Git e VS Code presenti; export templates, JDK e Android SDK assenti.

## Prossimi passi

1. Far confermare a Riccardo GUT e Compatibility (D-008, D-009) e la prova dell'editor con interfaccia grafica, non ancora eseguita.
2. Iniziare la fase 1 della scaletta, partendo dalla decisione su griglia e forme.

## Registro delle sessioni

| Data | Agente | Fatto | Verificato |
|---|---|---|---|
| 2026-11-03 | Claude Code (Opus 5.5), Godot 4.7.2 | Fase 0: creati `project.godot`, cartelle, `.gdignore`, scena di avvio, GUT 9.7.1 e primo test; aggiunto `*.fnt` in `.gitattributes` | Import e `--check-only` senza errori; 5 test su 5 passano; alterando una copia del progetto 2 test falliscono con codice 1; la finestra reale si apre a 450×800 con base 720×1280 e renderer Compatibility; plugin GUT caricato nell'editor senza interfaccia grafica, con l'errore TLS indicato sopra. Non provati: editor con interfaccia grafica e telefono |
| 2026-11-03 | Claude Code (Opus 5.5) | Scritta la bozza della scaletta in `docs/ROADMAP.md`, con la prova di stile in fase 3 e la guida di stile in fase 8 chieste da Riccardo | Solo documentazione: nessun codice scritto o eseguito; le compatibilità citate nella scaletta sono ancora da verificare |
| 2026-11-03 | Claude Code (Opus 5.5) | Registrato il percorso di Godot | L'eseguibile riporta `4.7.2.stable.official.ed1daf0bf`; l'esempio GDScript di `AGENTS.md` supera `--check-only` e dà i risultati attesi in 4 casi, in un progetto di prova temporaneo |
| 2026-11-03 | Claude Code (Opus 5.5) | Fissata la versione di Godot; inizializzato Git con remote, `.gitignore` e `.gitattributes`; primo commit e push su `main` | Regole di esclusione e fine riga provate |
| 2026-11-02 | Claude Code (Opus 5.5) | Creati `AGENTS.md`, `CLAUDE.md`, `docs/STATO.md` e `docs/DECISIONI.md` | Regole di caricamento e dati di store controllati sulle fonti; l'esempio GDScript non è stato eseguito perché Godot non è installato |
