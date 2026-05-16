# Evolution

Ein meditativer Idle-Clicker, der aus einem einzelnen Proto-Molekül über 30 Evolutionsstufen zu einer kosmischen Transzendenz wächst. Bio-Neon-Ästhetik, lebendiges 3D-Cell-Visual, ruhige adaptive Musik, klassischer Incremental-Loop mit moderner UX.

> **Status: Pre-Production / HTML-Prototyp aktiv / Steam-ready Godot-Migration geplant.**
> Das Spiel ist **noch nicht** bei Steam eingereicht und **noch nicht** veröffentlicht. Der HTML/Three.js-Prototyp dient als Validation Asset für den Core Loop und die Atmosphäre; die finale Engine-Implementation entsteht in Godot 4.x ab Phase 1.

---

## Inhaltsverzeichnis

- [Projektstatus](#projektstatus)
- [HTML-Prototyp lokal öffnen](#html-prototyp-lokal-öffnen)
- [Godot-Projekt lokal öffnen](#godot-projekt-lokal-öffnen)
- [Ordnerstruktur](#ordnerstruktur)
- [Phase-0-Dokumente](#phase-0-dokumente)
- [Extrahierte Daten (`data/`)](#extrahierte-daten-data)
- [Engine-Wahl](#engine-wahl)
- [Phase-1-Vorbereitung](#phase-1-vorbereitung)
- [Mitwirken / Änderungen](#mitwirken--änderungen)
- [Lizenz & Attribution](#lizenz--attribution)

---

## Projektstatus

| Aspekt | Status |
|---|---|
| Phase | **1 — Engine-Prototyp (P1-004 abgeschlossen: Save-System + Tests)** |
| Spielbarer Prototyp | ✓ HTML/Three.js, ein-File (`index.html`), online via GitHub Pages |
| Engine-Entscheidung | ✓ Godot 4.x (siehe `docs/decisions/ADR-0001-engine-choice.md`) |
| Game-Design-Document | ✓ v0.1 in `docs/02-gdd.md` |
| Daten (Stages/Upgrades/etc.) | ✓ extrahiert in `data/*.json` (Phase-1-tauglich) |
| Godot-Projekt | ✓ Skelett + Autoloads + DataLoader + SaveSystem mit Tests (bis P1-004), Systeme folgen in P1-005..P1-013 |
| Steam-Partner-Account | ⬜ Phase 0 (in Bearbeitung) |
| Steam-Einreichung | ⬜ Phase 5 (geplant) |

**Aktiver Branch:** `main`
**Phasen-Tracking:** `production/phase-0-plan.md`, `production/phase-1-backlog.md`
**Roadmap-Bigpicture:** `production/definition-of-done.md`

---

## HTML-Prototyp lokal öffnen

Der Prototyp ist eine **single-file HTML-App** ohne Build-Step. Three.js wird via Import-Map vom CDN nachgeladen.

### Variante A: einfach doppelklicken

`index.html` im Browser öffnen. Funktioniert für alle nicht-shader-bezogenen Features. Für die volle 3D-Cell-Darstellung (`<script type="module">`) **muss** der Browser jedoch über HTTP/HTTPS laden — siehe Variante B.

### Variante B: lokaler HTTP-Server (empfohlen)

```bash
# Python 3 (überall vorinstalliert)
python3 -m http.server 8000

# Browser:
open http://localhost:8000
```

oder mit Node:

```bash
npx serve .
```

### Variante C: live über GitHub Pages

Der `main`-Branch wird via GitHub Pages automatisch deployed unter:
`https://beko2210.github.io/EVOLUTION/`

Deployment-Delay typisch 1–3 Minuten nach Push auf `main`.

### Wofür der Prototyp da ist

Der Prototyp ist ein **Validation Asset**, kein Endprodukt. Er beweist:

- Core Loop trägt (Klick → DNA → Upgrade → Stage)
- Die Bio-Nexus-Cell-Visualisierung funktioniert visuell + performant
- Die Wirtschaft (Cost-Growth 1.15, Milestone-Doppelung, Prestige) trägt mathematisch

Er wird **nicht** zum Steam-Release gepusht. Die finale Engine-Implementation ist Godot 4.x (siehe `docs/decisions/ADR-0001-engine-choice.md`).

---

## Godot-Projekt lokal öffnen

**Vorausgesetzt:** Godot 4.3-stable lokal installiert (siehe `.godot-version`).

1. Godot Editor starten
2. **Import** → `project.godot` aus diesem Repo auswählen
3. Godot generiert die Import-Cache (kann beim ersten Mal 10–30 s dauern)
4. **F5** drücken → `scenes/main.tscn` startet als Hauptszene
5. Ein Fenster mit dem Bootstrap-Label öffnet sich, Konsole zeigt `[Evolution] Phase 1 skeleton booted — engine ...`

**Wenn Godot eine andere Version hat:** Phase-1-Backlog P1-001 sagt „Patch-Version pinnen". Wenn deine lokale Godot-Version vom Pin abweicht und das Projekt nicht öffnet:
1. Korrekte Version via [Godot-Downloads](https://godotengine.org/download/archive/) installieren, ODER
2. Wenn du bewusst eine neuere Version testest: in einem separaten Branch `project.godot:config/features` und `.godot-version` updaten, vor PR mit dem Original-Pin auf Kompatibilität testen.

Aktueller Stand: **P1-003 abgeschlossen** — Autoload-Singletons + funktionaler DataLoader. F5 zeigt im Bootstrap-Label, wieviele Stages, Upgrades, Forschungen, Abilities und Achievements aus `data/*.json` geladen wurden. Real-Spielsysteme (Save, Tick, Click, Stage, Prestige, Achievement, Shader, UI, Steam) landen in P1-004 bis P1-013.

### Tests lokal laufen lassen

```bash
./tools/run_tests.sh
```

erfordert `godot` (4.x stable) auf `$PATH` oder `GODOT_BIN=/pfad/zu/godot ./tools/run_tests.sh`. Aktuell laufen zwei Test-Suites:

**`tests/test_data_loader.gd`** — Daten-Layer-Validierung:

- alle 7 JSON-Files laden
- erwartete Item-Counts (30/30/30/12/4/27)
- keine duplizierten IDs
- monotone Stage-Thresholds, stage_001 startet bei 0
- alle Enum-Werte aus dem Allowlist (research effects, ability kinds, achievement conditions/rewards)
- `unlock_after_id`-Verkettungen intakt
- Lookups treffen + Misses returnen sauber null

**`tests/test_save_system.gd`** — Save-System-Integrität (überschreibt **Slot 3** während der Tests, säubert nach sich auf):

- Round-Trip preserved alle GameState-Felder
- 100-Cycle Save/Load ohne Degradation
- Checksum-Korruption wird erkannt
- JSON-Korruption wird erkannt
- Fehlende Checksum wird erkannt
- Manipuliertes Feld wird via Checksum-Mismatch erkannt
- Missing-Slot-Load returnt sauber false
- Ungültige Slots (-1, 99) werden abgelehnt
- Export-to-File / Import-from-File Round-Trip
- Import refused bei korruptem External-File
- `list_slots()` reportet korrekte Metadaten
- `slot_exists()` + `delete_slot()` arbeiten korrekt

Exit-Code 0 = grün, 1 = Failure (Details im Output).

---

## Ordnerstruktur

```
EVOLUTION/
├── README.md                     ← du bist hier
├── index.html                    ← HTML/Three.js Prototyp (Validation Asset)
├── .gitignore                    ← Godot-/OS-/Editor-Ignorierregeln (für Phase 1)
├── .gitattributes                ← Text-Normalisierung + Binärasset-Markierung
├── ATTRIBUTIONS.md               ← Lizenzhinweise (Godot, Three.js, geplante Pakete)
├── data/                         ← extrahierte Game-Daten (Phase-1-ready)
│   ├── stages.json
│   ├── upgrades_auto.json
│   ├── upgrades_click.json
│   ├── research.json
│   ├── abilities.json
│   ├── achievements.json
│   ├── balance_constants.json
│   └── schema-notes.md
├── docs/                         ← Phase-0-Dokumente
│   ├── 00-vision-pitch.md
│   ├── 01-game-pillars.md
│   ├── 02-gdd.md
│   ├── 03-art-bible.md
│   ├── 04-audio-bible.md
│   ├── 05-technical-design-document.md
│   ├── 06-risk-register.md
│   ├── 07-competitive-analysis.md
│   ├── 08-steam-marketing-plan.md
│   ├── 09-balance-model.md
│   ├── 10-release-checklist.md
│   ├── decisions/                ← ADRs (Architecture Decision Records)
│   │   ├── ADR-0001-engine-choice.md
│   │   ├── ADR-0002-steam-platform-scope.md
│   │   ├── ADR-0003-save-system.md
│   │   └── ADR-0004-data-driven-upgrades.md
│   └── steam/                    ← Steam-spezifische Checklisten
│       ├── asset-checklist.md
│       ├── store-page-checklist.md
│       ├── release-timeline.md
│       └── steam-deck-checklist.md
└── production/                   ← operative Planung
    ├── phase-0-plan.md
    ├── phase-1-backlog.md
    ├── scope-control.md
    └── definition-of-done.md
```

Aktiv seit P1-001 (Phase 1):

```
EVOLUTION/
├── project.godot                 ← Godot-Projektkonfiguration
├── .godot-version                ← Engine-Pin (aktuell 4.3-stable)
├── icon.svg                      ← Placeholder-Icon (final in Phase 2)
├── LICENSE                       ← MIT für Code; Assets separat (siehe ATTRIBUTIONS.md)
├── scenes/                       ← UI/3D-Szenen (main.tscn + leere Unterordner)
├── scripts/                      ← GDScript (main.gd + leere Unterordner)
├── shaders/                      ← GDShader (leer, P1-010)
├── assets/                       ← Audio/Icons/Fonts/Steam (leer)
├── theme/                        ← Godot Theme (leer, P1-011)
├── localization/                 ← strings.csv (leer, P1-011)
├── tests/                        ← GUT-Tests (leer, P1-003+)
├── qa/                           ← QA-Checklisten (leer)
├── tools/                        ← CLI-Utilities (leer)
└── ci/                           ← Build-Scripts (leer)
```

Leere Ordner enthalten kommentierte `.gitkeep`-Dateien die erklären, was hin kommt und in welchem Ticket.

---

## Phase-0-Dokumente

Alle in `docs/`. Lies in dieser Reihenfolge wenn du neu im Projekt bist:

1. **`00-vision-pitch.md`** — was das Spiel ist, wer die Zielgruppe ist, was es NICHT ist
2. **`01-game-pillars.md`** — vier nicht-verhandelbare Säulen mit Veto-Regeln
3. **`02-gdd.md`** — vollständiges Game-Design-Document
4. **`decisions/ADR-0001-engine-choice.md`** — warum Godot 4.x
5. **`05-technical-design-document.md`** — Architektur, Ordner, Save-System
6. **`production/phase-0-plan.md`** — was als nächstes zu tun ist

Weitere Docs:
- Art Bible · Audio Bible · Risk Register · Competitive Analysis · Steam Marketing Plan · Balance Model · Release Checklist
- Steam-spezifisch: Asset Checklist · Store-Page Checklist · Release Timeline · Steam Deck Checklist
- ADRs zu Steam-Plattform-Scope, Save-System, Data-driven Upgrades

---

## Extrahierte Daten (`data/`)

Alle Spielwerte (Stages, Upgrades, Forschungen, Abilities, Achievements, globale Konstanten) sind aus dem HTML-Prototyp in **valides JSON** extrahiert. Sie sind **direkt von Godot importierbar** (siehe ADR-0004 für die Strategie).

| Datei | Inhalt |
|---|---|
| `stages.json` | 30 Evolutionsstufen (Threshold, Stage-Bonus, Visual-Hinweise) |
| `upgrades_auto.json` | 30 passive DPS-Upgrades |
| `upgrades_click.json` | 30 Click-Power-Upgrades |
| `research.json` | 12 einmalige Forschungen mit deklariertem Effect-Kind |
| `abilities.json` | 4 aktive Cooldown-Abilities |
| `achievements.json` | 27 Achievements mit deklarativen Conditions |
| `balance_constants.json` | Alle globalen Formeln + Konstanten (Cost-Growth, Milestones, Prestige, Crit, Combo, Offline, Tick-Rates, Spawn-Raten) |
| `schema-notes.md` | Schema-Dokumentation: Pflichtfelder, Enums, Validierung, Source-Mapping |

**Wichtig:** Diese Dateien sind aktuell **statische Daten**, kein Game-Code liest sie zur Laufzeit. Der HTML-Prototyp benutzt weiterhin die inline-JS-Konstanten (sind identisch). Der Loader in Godot wird in Phase 1 (Ticket P1-003) implementiert.

---

## Engine-Wahl

**Ziel-Engine:** Godot 4.x in der **aktuellen stabilen Version zum Projektstart** (Phase 1). Die konkrete Patch-Version wird in `.godot-version` und `project.godot` fixiert, sobald das Godot-Projekt angelegt wird.

**Warum Godot:**
- 2D/UI-Stack ideal für UI-lastiges Idle-Spiel
- GDShader = GLSL-Dialekt → Three.js-Shader-Port mit minimalem Aufwand
- MIT-Lizenz, keine Royalties, kein Vendor-Lock-in
- Native Mobile-Export (Phase 7)
- Schnelle Iteration (<1 s Reload)
- Steam Deck Verified-Pfad via Linux-Build

Vollständige Begründung mit Vergleich gegen Unity und Unreal: `docs/decisions/ADR-0001-engine-choice.md`.

---

## Phase-1-Vorbereitung

Phase 1 (Engine-Prototyp) ist in `production/phase-1-backlog.md` als 13 Tickets (P1-001 bis P1-013) ausformuliert. Jedes Ticket hat Ziel, Aufgaben, Akzeptanzkriterium, Risiko, Aufwand.

**Pre-Flight-Checks** (vor Phase-1-Start):
- [ ] Phase-0-Definition-of-Done erreicht (`production/definition-of-done.md`)
- [ ] Engine-Patch-Version festgelegt (in ADR-0001 ergänzt)
- [ ] GodotSteam-Verfügbarkeit für gewählte Patch-Version geprüft (Spike P1-012)
- [ ] Datenbank `data/*.json` ist final (diese Iteration)

---

## Mitwirken / Änderungen

### Änderungen am kreativen Kern

Botschaft, Vision, Pillars und Kern-Gameplay-Loop sind **nicht verhandelbar ohne ADR**. Wenn du eine fundamentale Änderung vorschlägst:

1. Neues ADR in `docs/decisions/ADR-NNNN-<topic>.md` anlegen
2. Kontext, Optionen, Entscheidung, Konsequenzen dokumentieren
3. Via Pull Request einreichen
4. Bei Akzeptanz: ADR wird Quelle, betroffene Docs werden aktualisiert

### Änderungen an Balance-Werten

Werte in `data/*.json` ändern und Pull Request stellen. **Nicht** in `index.html` ändern (das ist Prototyp, nicht Quelle). Die finale Quelle wird ab Phase 1 das Balance-Spreadsheet (`docs/09-balance-model.xlsx`) — bis dahin sind die JSON-Files in `data/` die Quelle.

### Pull-Request-Konvention

- Branch-Name: `<typ>/<kurzbeschreibung>`, z. B. `feature/skill-tree`, `docs/audio-brief`, `data/rebalance-r3`
- Draft-PR während WIP, Ready-for-Review bei Abschluss
- Mindestens ein Reviewer (kann Solo-Dev sein, dann mit Self-Review-Kommentar)

### Code-Style (ab Phase 1)

- GDScript: PEP-8-artig, klare Funktionsnamen, kein abkürzungs-overload
- GDShader: GLSL-Konvention
- Save-Format-Änderung erfordert IMMER Schema-Version-Bump + Migration

---

## Lizenz & Attribution

- **Game-Code (ab Phase 1)**: MIT — siehe `LICENSE` (kommt mit Godot-Projekt-Setup)
- **HTML-Prototyp** (`index.html`): MIT, siehe Notizen in Datei
- **Game-Design / Story / Konzept-Texte / Doku**: alle Rechte vorbehalten (Studio)
- **Audio / Icons / Fonts (kommt in Phase 2)**: separat dokumentiert in `ATTRIBUTIONS.md`

Verwendete Drittsoftware-Lizenzen siehe `ATTRIBUTIONS.md`.

---

## Steam-Hinweis

Dieses Spiel ist für eine spätere Veröffentlichung auf Steam geplant. Der Release ist **noch nicht** eingereicht. Steam-Submission ist Phase 5 (`production/definition-of-done.md`).

**Wishlist-Aufbau startet** wenn die Steam-Page in Phase 5 live geht. Folge dem Repo / dem Discord (kommt in Phase 4), um informiert zu werden.

---

## Quick-Links

- **GDD lesen** → [`docs/02-gdd.md`](docs/02-gdd.md)
- **Engine-Begründung** → [`docs/decisions/ADR-0001-engine-choice.md`](docs/decisions/ADR-0001-engine-choice.md)
- **Phase-1-Tickets** → [`production/phase-1-backlog.md`](production/phase-1-backlog.md)
- **Daten-Schema** → [`data/schema-notes.md`](data/schema-notes.md)
- **Release-Timeline** → [`docs/steam/release-timeline.md`](docs/steam/release-timeline.md)
