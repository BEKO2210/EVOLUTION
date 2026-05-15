# Definition of Done

**Status:** Phase 0 v0.1

Pro Phase: harte, prüfbare Kriterien. Phase gilt erst als abgeschlossen wenn **alle** Kriterien erfüllt sind. Keine Ausnahmen.

---

## Phase 0 — Pre-Production

### Dokumente
- [ ] `docs/00-vision-pitch.md` final
- [ ] `docs/01-game-pillars.md` final
- [ ] `docs/02-gdd.md` final V1.0 (von externer Person gelesen, „verständlich" bestätigt)
- [ ] `docs/03-art-bible.md` final, inkl. 5 Stage-Mood-Boards
- [ ] `docs/04-audio-bible.md` final, inkl. Komponist-Brief
- [ ] `docs/05-technical-design-document.md` final
- [ ] `docs/06-risk-register.md` mit ≥15 Risiken + Mitigationen
- [ ] `docs/07-competitive-analysis.md` mit ≥10 Spielen verifiziert (aktuelle Steam-Daten)
- [ ] `docs/08-steam-marketing-plan.md` mit ≥30 Outreach-Targets
- [ ] `docs/09-balance-model.md` + `09-balance-model.xlsx` final (Time-to-Stage-Simulation ±20 % gegen Prototyp)
- [ ] `docs/10-release-checklist.md` final
- [ ] `docs/decisions/ADR-0001` bis `ADR-0004` final
- [ ] `docs/steam/asset-checklist.md`, `store-page-checklist.md`, `release-timeline.md`, `steam-deck-checklist.md` final
- [ ] `production/phase-0-plan.md`, `phase-1-backlog.md`, `scope-control.md`, `definition-of-done.md` final

### Geschäftlich
- [ ] Spieltitel ist trademark-frei verifiziert (USPTO + EUIPO + DPMA)
- [ ] Steam-Partner-Account angelegt + verifiziert (Tax + Bank)
- [ ] Steam Direct Fee bezahlt (kann auch in Phase 1 passieren, dann startet 30-Tage-Wartezeit)
- [ ] Domain reserviert
- [ ] Audio-Komponist beauftragt **oder** Eigenproduktion-Plan dokumentiert
- [ ] Mindestens 2 Übersetzer für Top-Sprachen unter Vertrag (Phase-3-Lieferung)

### Technisch
- [ ] Engine-Version final festgelegt (`docs/decisions/ADR-0001` enthält gewählte Godot-4.x-Patch-Version)
- [ ] Existing HTML/Three.js-Prototyp ist als Validierungs-Asset gekennzeichnet (README-Hinweis)

### Repo-Status
- [ ] Git-Tag `phase-0-complete`
- [ ] Branch `main` enthält alle Phase-0-Dokumente

---

## Phase 1 — Engine-Prototyp

### Code
- [ ] Godot-Projekt nach TDD-Struktur angelegt
- [ ] `.godot-version` Datei mit exakter Patch-Version
- [ ] Alle 6 Autoloads registriert + funktional
- [ ] Save-System mit Schema-Version 1 + Migration-Framework
- [ ] Data-Loader lädt + validiert alle `data/*.json`
- [ ] Tick-System: Logic 4 Hz + Visual 60 Hz, getrennt
- [ ] Click-System + Upgrade-System + Stage-System + Prestige-System + Achievement-System
- [ ] Milestone-Doppelung implementiert (10/25/50/100)
- [ ] BioNexus-Shader portiert nach GDShader, läuft mit 4000 Instanzen
- [ ] Greybox-UI für alle 5 Tabs

### Steam-Integration
- [ ] GodotSteam-Spike abgeschlossen
- [ ] Entscheidung dokumentiert: GDExtension oder eigener Engine-Build (in ADR oder Spike-Report)
- [ ] Spacewar-AppID-480-Test bestanden (Achievement + Cloud-Save)

### Performance
- [ ] 60 fps median auf Steam Deck (Test-Build, kein Final-Polish)
- [ ] Save/Load funktioniert über App-Restart
- [ ] 100-Cycle Save-Test bestanden (`tests/test_save_migration.gd`)

### Validierung
- [ ] 3 Test-Sessions mit ungeschulten Personen durchgeführt
- [ ] Mindestens 1 Tester erreicht Stage 4 ohne Hilfe in 15 min
- [ ] Test-Notizen in `docs/playtest-notes-phase-1.md`
- [ ] 3 wichtigste Insights als Aktion-Items für Phase 2

### Repo-Status
- [ ] Git-Tag `phase-1-complete`
- [ ] CI baut Godot-Projekt grün auf Win + Linux + macOS

---

## Phase 2 — Vertical Slice

**Zielzustand:** Stages 1–5 in **Shipping-Qualität**. Alles andere darf Greybox bleiben.

### Inhaltlich
- [ ] Stages 1–5 visuell ausgearbeitet (Cell-Variation, Hintergrund-Tönung, Phase-Übergänge)
- [ ] Auto-Upgrades a1–a10 mit finalen SVG-Icons
- [ ] Click-Upgrades c1–c10 mit finalen SVG-Icons
- [ ] Forschungen r1–r3 mit Final-Optik
- [ ] Abilities Photo + Adrena mit Final-Animation + Audio
- [ ] Onboarding-Sequenz (3-Schritt-FTUE)
- [ ] Tooltip-System (Hover + Long-Press)
- [ ] Settings-Menü V1 (Volume, Quality, Reduce-Motion, Sprache, Save-Export)

### Audio
- [ ] Drone + Pad-Layer für Stages 1–5
- [ ] Komplette SFX-Familie für Slice (Click, Buy, Stage-Up, Crit, Milestone, Achievement)
- [ ] Stage-Up Fanfare (final, gemastert)

### Marketing-Assets
- [ ] 8 Marketing-Screenshots in 1920×1080
- [ ] 60–90 s Trailer als MP4 H.264 (privater YouTube-Upload OK)
- [ ] Performance-Report auf 4 Geräten (Win-Mid, Win-Low, Steam Deck, Phone)

### Steam-Integration (Test-Modus)
- [ ] Steamworks-SDK eingebunden (Test-AppID Spacewar 480)
- [ ] 5 Achievements live + ingame triggert
- [ ] Cloud-Save aktiv
- [ ] Controller-Support (Steam Input API): Xbox + DualSense + Steam Deck getestet
- [ ] Touch-Layout für Mobile (Portrait + Landscape)

### Build-Pipeline
- [ ] GitHub Actions baut Win + Linux + macOS + Android
- [ ] `unstable`-Branch wird automatisch beladen
- [ ] Lokaler Build-Script funktioniert

### Akzeptanz
- [ ] Eine Testperson spielt den Slice 20+ min am Stück freiwillig durch
- [ ] Niemand fragt „ist das Pre-Alpha?"
- [ ] Steam Deck: 60 fps, Battery-Drain im Normal-Range

### Repo-Status
- [ ] Git-Tag `phase-2-vertical-slice`
- [ ] Steam-Coming-Soon-Seite vorbereitet (Capsules + Trailer + Beschreibungen)

---

## Phase 3 — Alpha / Feature Complete

### Content
- [ ] Alle 30 Stages implementiert + visuell unterscheidbar
- [ ] Alle 60 Upgrades (30 Auto + 30 Click) mit finalen Icons
- [ ] Alle 12 Forschungen
- [ ] Alle 4 Abilities
- [ ] Prestige-Skill-Tree mit 6–10 Knoten
- [ ] 50 Achievements im Steam-Backend registriert + Icons
- [ ] Codex mit ≥75 Einträgen
- [ ] Stats-Panel mit Sparkline-Charts
- [ ] Daily-Login-Bonus mit Streak-Mechanik
- [ ] Goldene Zellen + DNA-Drops + Mutationen funktional

### Technisch
- [ ] Multiple Save-Slots (3 lokal + 1 Cloud)
- [ ] Cloud-Save-Conflict-UI funktional
- [ ] Color-Blind-Modes (Deuteranopie, Protanopie, Tritanopie)
- [ ] Save-Export / Save-Import als Datei
- [ ] Telemetrie-Pipeline (Sentry + opt-in Game-Events)
- [ ] Crash-Rate <0.5 % in eigener 50-Stunden-Spielsession
- [ ] Localization-Pipeline live, `localization/strings.csv` mit allen Strings extrahiert

### Übersetzungen
- [ ] Übersetzungen für mind. 4 Top-Sprachen beauftragt (EN, DE, JA, zh-Hans)
- [ ] Übrige Sprachen in Pipeline

### Repo-Status
- [ ] Git-Tag `phase-3-alpha`
- [ ] Kein „TODO"-Marker im Spiel-Code (nur in Tests / Polish)

---

## Phase 4 — Beta / Content Complete

### Übersetzungen
- [ ] Übersetzungen für alle Launch-Sprachen integriert
- [ ] Native-Speaker-Review für EN, DE, JA, zh-Hans bestanden

### Beta-Programm
- [ ] Closed Beta mit 50–200 Spielern durchgeführt
- [ ] Beta-Feedback-Formular nach 1 h / 5 h / 20 h Spielzeit
- [ ] Beta-Player-NPS >40
- [ ] 7-Day-Retention >25 % bei Beta-Cohort
- [ ] Mindestens 30 Beta-Spieler haben Stage 20+ erreicht

### Balance
- [ ] Balancing-Pass auf Basis Telemetrie
- [ ] Time-to-First-Prestige im Wunsch-Range (8–12 h Median)
- [ ] Drop-off-Stages identifiziert + adressiert

### QA
- [ ] QA-Matrix auf allen Ziel-Geräten bestanden (Win/Linux/macOS in 3 Spec-Klassen + Steam Deck LCD/OLED)
- [ ] Zero P0, Zero P1, <10 dokumentierte P2
- [ ] Save-Migration über alle bisherigen Build-Versionen getestet
- [ ] 1000-Cycle Save-Stress-Test bestanden
- [ ] Accessibility-Audit bestanden (Touch-Targets ≥44 dp, Color-Blind, kein Flickering >3 Hz)
- [ ] Performance-Budget eingehalten (60 fps min-spec, <300 MB RAM, <16 ms Frametime 99-Perz.)

### Audio
- [ ] Audio-Mix-Pass abgeschlossen (-16 LUFS, -1 dBTP)

### Steam-Deck
- [ ] Steam-Deck-Checkliste komplett abgehakt
- [ ] Self-Submit für Steam Deck Review im Partner-Backend
- [ ] Erwartung: Verified, akzeptabel: Playable

### Repo-Status
- [ ] Git-Tag `phase-4-beta`
- [ ] Release-Candidate-Build identifiziert

---

## Phase 5–6 — Steam Release Candidate

### Steam-Integration final
- [ ] AppID final konfiguriert
- [ ] Achievements + Cloud-Save + Steam-Input voll funktional
- [ ] Build auf `default`-Branch gelocked
- [ ] Steam Direct 30-Tage-Wartezeit verstrichen
- [ ] Store-Page-Review bestanden
- [ ] Build-Review bestanden

### Marketing-Status
- [ ] ≥1000 Wishlists (Mindest), ≥3000 (Stretch)
- [ ] Steam-Page seit ≥3 Monaten live
- [ ] Demo verfügbar (Next Fest oder permanent)
- [ ] Discord-Server live, ≥200 Members
- [ ] Press-Kit online
- [ ] Mindestens 50 Reviewer-Keys ausgegeben

### Stabilität
- [ ] Hotfix-Branch < 2 h einsatzbereit
- [ ] Sentry-Dashboard erreichbar
- [ ] Source + Assets in 2 unabhängigen Backups

### Release-Tag-Bereitschaft
- [ ] Launch-Trailer auf YouTube als Premiere geplant
- [ ] Discord/Reddit/Twitter-Posts vorbereitet
- [ ] Solo-Dev hat Launch-Tag freigeschaufelt
- [ ] Day-0-Patch-Plan dokumentiert

### Repo-Status
- [ ] Git-Tag `v1.0.0` (semver für Release)
- [ ] CHANGELOG.md vollständig
