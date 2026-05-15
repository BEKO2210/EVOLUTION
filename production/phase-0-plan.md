# Phase 0 — Pre-Production Plan

**Status:** Aktiv
**Dauer:** 4–6 Wochen (15–20 h/Woche)
**Ziel:** Alle Design-, Tech- und Business-Entscheidungen dokumentiert. Spielfähiger Prototyp existiert (HTML/Three.js) als Validierung des Cores.

---

## Tag 1 (Heute, 2–3 h)

- [ ] Branch `claude/phase-0-foundation` gepullt
- [ ] `docs/`-Struktur in Repo akzeptiert + lokal gelesen
- [ ] **ADR-0001 (Engine-Choice) lesen** → Godot 4.x bestätigt
- [ ] **GDD-Skelett** überfliegen, eigene Anmerkungen in Markdown-TODO-Kommentaren ergänzen
- [ ] Trademark-Check Spieltitel:
  - https://tmsearch.uspto.gov (USA)
  - https://euipo.europa.eu/eSearch (EU)
  - https://www.dpma.de (Deutschland)
  - Backup-Namen vorbereiten falls Konflikt

## Tag 2–3

- [ ] Steam-Partner-Account anlegen (https://partner.steamgames.com)
- [ ] Tax + Bank-Info hochladen (kann 1–2 Wochen dauern, parallel laufen lassen)
- [ ] Konkrete Godot-Patch-Version aussuchen (aktuelle stabile zum Projektstart) und in `.godot-version`-Notiz festhalten (technische Datei kommt Phase 1)
- [ ] `docs/decisions/`-Ordner lesen, ADRs verstehen
- [ ] `docs/steam/release-timeline.md` lesen → eigene Release-Wunsch-Datum-Hypothese aufschreiben

## Woche 1

- [ ] **GDD vervollständigen** (`docs/02-gdd.md`):
  - Codex-Stil mit 2–3 Beispiel-Einträgen verfeinern
  - Skill-Tree-Knoten finalisieren (8 Knoten beschreiben)
  - Endgame-Win-Condition exakt formulieren
- [ ] **Art Bible vervollständigen** (`docs/03-art-bible.md`):
  - Color-Palette mit Hex aus Prototyp übernehmen
  - 5 Stage-Mood-Boards skizzieren (kann handgezeichnet sein, einscannen)
- [ ] **Audio Bible** (`docs/04-audio-bible.md`):
  - SFX-Wishlist konkretisieren (~25 IDs)
  - Komponist-Brief schreiben (1 Seite, basierend auf Bible-Inhalt)
- [ ] **Risk Register** (`docs/06-risk-register.md`):
  - Persönliche Risiken ergänzen (Familie, Krankheit, Job-Wechsel)

## Woche 2

- [ ] **Competitive Analysis** (`docs/07-competitive-analysis.md`):
  - 10 Spiele mit aktuellen Steam-Daten verifizieren
  - SteamSpy / Gamalytic für Sales-Schätzungen konsultieren
  - USP-Statement final
- [ ] **Steam Marketing Plan** (`docs/08-steam-marketing-plan.md`):
  - Outreach-Liste mit konkreten Namen erweitern (mind. 30 Einträge)
  - Discord-Server-Skelett aufsetzen (privat)
  - Domain reservieren (z. B. `evolution-game.com` falls verfügbar)
- [ ] **Balance Sheet** (`docs/09-balance-model.xlsx`):
  - Spreadsheet anlegen, alle 9 Tabs strukturieren
  - Existing-Prototyp-Werte importieren
  - Time-to-Stage-Simulation aufbauen
  - Sensitivitäts-Analyse durchführen

## Woche 3

- [ ] Audio-Komponist anfragen (mind. 3 Anbieter, Brief versenden)
- [ ] Übersetzer-Anfragen für DE→EN, DE→FR, DE→ES, DE→IT (mind. 2 Anbieter pro Sprache, z. B. LocalizeDirect, übersetzer.in)
- [ ] DSGVO: Privacy-Policy-Vorlage finden (oder generieren via iubenda / termsfeed)
- [ ] **Phase-0-Review-Termin** mit externer Person (Indie-Dev-Freund, Discord-Mentor) festlegen

## Woche 4

- [ ] **TDD-Vollständigkeits-Pass** (`docs/05-technical-design-document.md`):
  - Save-Format-Schema in JSON-Beispiel ausformulieren
  - Build-Pipeline-Script-Skelette in `ci/`-Ordner anlegen (leer ist OK, Strukturen klar)
- [ ] Engine-Version final festlegen (Godot 4.x stable von Phase-1-Start-Datum)
- [ ] Spieltitel final festlegen (Trademark-clear)
- [ ] Steam-Partner-Account verifiziert (sollte bis jetzt durch sein)

## Woche 5

- [ ] Audio-Komponist-Vertrag abgeschlossen (oder Eigenproduktion bestätigt)
- [ ] Übersetzer mind. 2 Sprachen unter Vertrag (Phase-3-Lieferung)
- [ ] **Externe Person hat GDD gelesen und Feedback gegeben**
- [ ] GDD final V1.0 (Tag „phase-0-gdd-v1")

## Woche 6

- [ ] **Phase-0-Review** mit allen Phase-0-Akzeptanzkriterien:
  - Siehe `production/definition-of-done.md` → DoD Phase 0
- [ ] Alle ADRs final
- [ ] Phase-1-Backlog finalisiert (`production/phase-1-backlog.md`)
- [ ] Git-Tag `phase-0-complete` setzen
- [ ] Phase-1 starten

---

## Phase-0-Deliverables (vollständige Liste)

| Datei | Status zum Phase-0-Ende |
|---|---|
| `docs/00-vision-pitch.md` | ✓ final |
| `docs/01-game-pillars.md` | ✓ final |
| `docs/02-gdd.md` | ✓ final V1.0 |
| `docs/03-art-bible.md` | ✓ final |
| `docs/04-audio-bible.md` | ✓ final |
| `docs/05-technical-design-document.md` | ✓ final |
| `docs/06-risk-register.md` | ✓ initial befüllt |
| `docs/07-competitive-analysis.md` | ✓ verifiziert mit aktuellen Steam-Daten |
| `docs/08-steam-marketing-plan.md` | ✓ final, Outreach-Liste >30 |
| `docs/09-balance-model.md` + `09-balance-model.xlsx` | ✓ final |
| `docs/10-release-checklist.md` | ✓ final |
| `docs/decisions/ADR-0001-engine-choice.md` | ✓ final |
| `docs/decisions/ADR-0002-steam-platform-scope.md` | ✓ final |
| `docs/decisions/ADR-0003-save-system.md` | ✓ final |
| `docs/decisions/ADR-0004-data-driven-upgrades.md` | ✓ final |
| `docs/steam/asset-checklist.md` | ✓ final |
| `docs/steam/store-page-checklist.md` | ✓ final |
| `docs/steam/release-timeline.md` | ✓ final |
| `docs/steam/steam-deck-checklist.md` | ✓ final |
| `production/phase-0-plan.md` | ✓ abgehakt |
| `production/phase-1-backlog.md` | ✓ Tickets formuliert |
| `production/scope-control.md` | ✓ final |
| `production/definition-of-done.md` | ✓ final |

## Zusätzlich (extern)

- [ ] Steam-Partner-Account verifiziert
- [ ] Spieltitel trademark-frei verifiziert
- [ ] Domain reserviert
- [ ] Audio-Komponist beauftragt (oder Eigenproduktion-Plan bestätigt)
- [ ] Übersetzer für mind. 2 Sprachen unter Vertrag
- [ ] Discord-Server-Skelett (privat)
- [ ] Externe Review-Person hat GDD durchgesehen

---

## Definition of Done — Phase 0

→ Siehe `production/definition-of-done.md` Sektion „Phase 0"

---

## Wenn du blockiert bist

- **Trademark-Konflikt:** Backup-Name nutzen, ADR-0005 (Spieltitel-Wahl) anlegen, weiter
- **Audio-Budget nicht da:** Eigenproduktion-Plan in Audio-Bible dokumentieren, Tools-Setup (Reaper + Free-Synth-Plugins) als Phase-2-Aufgabe
- **Übersetzer zu teuer:** Auf 5 Top-Sprachen reduzieren (EN, DE, FR, ES, zh-Hans), rest Community-Translation post-launch
- **GDD-Schreibblockade:** Kurz-Form zuerst (1 Bullet pro Sektion), expandieren in V0.2 / V0.3
- **Engine-Zweifel:** ADR-0001 nochmal lesen, falls Zweifel: Engine-Spike (1 Tag in Godot, 1 Tag in Unity, vergleichen)
