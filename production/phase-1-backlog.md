# Phase 1 — Engine-Prototyp Backlog

**Phase-Ziel:** Core Loop läuft in Godot 4.x. Greybox-UI, keine Polish.
**Dauer:** 4–6 Wochen (15–20 h/Woche)

Jedes Ticket: Ziel · Aufgaben · Akzeptanz · Risiko · Aufwand.

---

## P1-001 — Godot-Projekt-Setup

**Ziel:** Sauber strukturiertes Godot-Projekt nach TDD-Ordnerstruktur.
**Aufgaben:**
- Aktuelle stabile Godot 4.x Version downloaden, Patch-Version pinnen
- Projekt anlegen mit Forward+ Renderer (Mobile fallback in `project.godot` konfigurieren)
- Ordnerstruktur aus `docs/05-technical-design-document.md` Sektion 2 anlegen
- `.gitignore`, `.gitattributes` (für text-mode `.tscn`/`.tres`)
- `project.godot` → text-mode aktivieren
- `.godot-version` Datei mit exakter Patch-Version
- README.md mit Setup-Anleitung
- LICENSE (MIT für Code, separat dokumentiert für Assets in ATTRIBUTIONS.md)
- ATTRIBUTIONS.md initial mit Godot + GodotSteam-Placeholder

**Akzeptanz:** Klones-Run-Test: andere Person klont Repo, öffnet in Godot, drückt F5, sieht leeres Fenster ohne Errors.
**Risiko:** Godot-Version-Mismatch zwischen Devs (gemildert durch `.godot-version`).
**Aufwand:** 4 h

---

## P1-002 — Autoload-Singletons

**Ziel:** Alle 6 Autoloads angelegt, registriert, mit minimalem No-Op-Stub.
**Aufgaben:**
- `scripts/autoload/game_state.gd` (Singleton mit allen GameState-Feldern aus Prototyp)
- `scripts/autoload/save_system.gd` (`save()`, `load(slot)`, `migrate()` Stubs)
- `scripts/autoload/data_loader.gd` (lädt `data/*.json`, validiert Schema)
- `scripts/autoload/audio_manager.gd` (Bus-Routing, `play_sfx(id)`)
- `scripts/autoload/steam_api.gd` (no-op falls Steam fehlt)
- `scripts/autoload/telemetry.gd` (no-op + Opt-in-Flag)
- In `project.godot` registrieren

**Akzeptanz:** Autoloads sind im Editor sichtbar. `GameState.dna += 1` läuft ohne Error.
**Risiko:** Singleton-Reihenfolge bei Boot. Lösung: explizite Init-Reihenfolge in `Main.tscn` `_ready()`.
**Aufwand:** 6 h

---

## P1-003 — Data-Loader für Balance-Tables

**Ziel:** Alle JSON-Tables aus Prototyp werden geladen + validiert.
**Aufgaben:**
- Existing-Prototyp-Daten exportieren aus `index.html`-JS-Arrays in JSON-Files:
  - `data/balance_constants.json`
  - `data/stages.json`
  - `data/upgrades_auto.json`
  - `data/upgrades_click.json`
  - `data/research.json`
  - `data/achievements.json`
  - `data/abilities.json`
- `data_loader.gd` implementiert: `get_stage(n)`, `get_upgrade_auto(id)`, etc.
- Schema-Validierung (Pflicht-Felder vorhanden, korrekte Typen)
- `tests/test_data_loader.gd` mit GUT-Test

**Akzeptanz:** Test schlägt grün, alle Daten geladen, keine duplizierten IDs.
**Risiko:** JSON-Schema-Inkonsistenzen → früher Test fängt das.
**Aufwand:** 8 h

---

## P1-004 — Save-System

**Ziel:** JSON-Save/Load mit Schema-Version und Migration-Framework.
**Aufgaben:**
- `save_system.gd` mit `CURRENT_SCHEMA_VERSION = 1`
- `save(slot: int)` → schreibt nach `user://save_slot_<n>.json`
- `load(slot: int)` → liest, prüft Schema-Version, migriert falls nötig
- SHA256-Checksum-Berechnung + -Verifikation
- Auto-Backup vor jeder Migration (`user://save_slot_<n>.backup_v<old>.json`)
- Migration-Map (leer in v1, Framework für Erweiterung)
- `tests/test_save_migration.gd` mit GUT-Test (Round-Trip Save→Load→Save vergleichen)

**Akzeptanz:** 100× Save/Load-Cycle ohne Datenverlust. Checksum-Mismatch erkannt + Backup vorgeschlagen.
**Risiko:** JSON-Encoding-Probleme bei großen Zahlen (BigInt!). Lösung: Godot-Float ist 64-Bit, ausreichend für unsere Skala bis ~10^15. Für noch größere Zahlen ggf. BigNumber-Library.
**Aufwand:** 12 h

---

## P1-005 — Tick-System

**Ziel:** Saubere Trennung Logic-Tick (4 Hz) und Visual-Tick (60 Hz).
**Aufgaben:**
- `scripts/systems/tick_system.gd` (Singleton oder als Node)
- Logic-Tick via `_physics_process` (4 Hz, also alle 0.25 s)
- Logic-Tick: DPS-Akkumulation, Mutationen, Achievement-Check
- Visual-Tick via `_process` (60 Hz)
- Visual-Tick: Cell-Animation, UI-Updates, FX-Layer
- Pause-Support: beide Ticks haltbar

**Akzeptanz:** Beide Ticks laufen separat, Tab-im-Hintergrund stoppt Visual-Tick nicht Logic-Tick (Godot pausiert `_process` im Hintergrund, `_physics_process` läuft weiter wenn `process_mode` korrekt).
**Risiko:** Browser/Desktop-Verhalten unterschiedlich bei Background. Lösung: Logic-Tick zusätzlich Timer-Node mit `process_mode = ALWAYS`.
**Aufwand:** 6 h

---

## P1-006 — Click-System & DPS

**Ziel:** Klick auf Zelle erhöht DNA. Auto-Upgrades produzieren DNA/s.
**Aufgaben:**
- `scripts/systems/click_system.gd` (Click-Logik, Combo, Crit)
- `scripts/systems/upgrade_system.gd` (Buy-Logic, Cost-Formel `cost × 1.15^count`)
- Milestone-Multiplier-Logik (`MILESTONES = [10, 25, 50, 100]`)
- DPS-Berechnung via `recalc_stats()` in GameState
- Float-Text-Spawn (Greybox: simple Label-Animation)

**Akzeptanz:** Klick → DNA steigt + Float-Text. Auto-Upgrade kaufen → DPS steigt sichtbar im HUD.
**Risiko:** Performance bei vielen Float-Texts. Lösung: Object-Pool für Float-Texts.
**Aufwand:** 10 h

---

## P1-007 — Stage-System

**Ziel:** Stage-Progression mit Threshold + visueller Wechsel.
**Aufgaben:**
- `scripts/systems/stage_system.gd`
- Stage-Threshold-Check bei DNA-Änderung
- Stage-Up-Signal emit (für UI + BioNexus + Audio)
- Stage-Down-Schutz (nach Prestige, Stage zurück auf 1)

**Akzeptanz:** DNA-Threshold erreicht → Stage erhöht sich, HUD aktualisiert, Stage-Up-Signal feuert.
**Risiko:** Off-by-One bei Threshold-Vergleichen (gemildert durch Tests).
**Aufwand:** 4 h

---

## P1-008 — Prestige-System (Soft-Reset)

**Ziel:** Spieler kann ab 1M Lifetime-DNA prestigen, Evolutionspunkte permanent gewinnen.
**Aufgaben:**
- `scripts/systems/prestige_system.gd`
- `get_evolution_points_available()` aus Lifetime-DNA
- `do_prestige()` mit Confirm-Dialog
- Reset von DNA, Upgrades, Stage; Beibehalt von Evolutionspunkten
- Multiplier-Update `1.10^prestige_points`

**Akzeptanz:** Prestige funktioniert ohne Datenverlust (Evolutionspunkte bleiben), DPS-Multiplier nach Prestige korrekt.
**Risiko:** Save-Schema-Forward-Compat falls später Skill-Tree dazukommt (gemildert via Migration-Framework).
**Aufwand:** 8 h

---

## P1-009 — Achievement-System

**Ziel:** Achievements triggern, werden persistiert, sind testbar.
**Aufgaben:**
- `scripts/systems/achievement_system.gd`
- Pro Achievement: Trigger-Function (Lambda oder Method-Ref)
- Persistenz in GameState.achievements (Map: id → timestamp)
- Toast-Notification beim Trigger

**Akzeptanz:** Test: Klick 10× → `click10`-Achievement triggered, Toast erscheint, persistiert nach Save/Load.
**Risiko:** Doppel-Trigger (gemildert durch „bereits erreicht"-Check).
**Aufwand:** 6 h

---

## P1-010 — BioNexus-Shader-Port

**Ziel:** Three.js BioNexus-Shader läuft in Godot via GDShader.
**Aufgaben:**
- `shaders/bionexus_cell.gdshader` schreiben (GLSL→GDShader-Port, siehe TDD Sektion 8)
- `scenes/cell/bionexus.tscn` mit SubViewport + MultiMeshInstance3D
- Per-Instance-Daten via `INSTANCE_CUSTOM` oder `MultiMesh.custom_data`
- Material-Resource konfigurieren
- 4000-Instanzen-Cap, Camera-Dolly aus HTML-Version übernehmen

**Akzeptanz:** 60 fps bei 4000 Cells auf Steam Deck. Visuell vergleichbar mit HTML-Prototyp.
**Risiko:** Shader-Port-Inkompatibilität (Three.js benutzt klassisches GLSL, Godot hat eigene Syntax). Gemildert durch Spike vor Phase-1-Start.
**Aufwand:** 16 h

---

## P1-011 — Greybox-UI (HUD, Tabs, Panels)

**Ziel:** Funktionales UI, ohne finale Optik.
**Aufgaben:**
- `theme/main_theme.tres` mit Default-Werten
- `scenes/ui/hud.tscn` (Header mit DNA, DPS, Stage)
- `scenes/ui/tabs.tscn` (5 Tabs)
- `scenes/ui/panels/panel_auto.tscn` (Liste der Auto-Upgrades)
- `scenes/ui/panels/panel_click.tscn`
- `scenes/ui/panels/panel_research.tscn`
- `scenes/ui/panels/panel_meta.tscn`
- Upgrade-Card-Komponente (`scripts/ui/upgrade_card.gd`)
- Tab-Controller (`scripts/ui/tab_controller.gd`)

**Akzeptanz:** Alle Tabs zeigen Inhalt. Klick auf Upgrade kauft es. UI aktualisiert sich.
**Risiko:** UI-Performance bei 30 Upgrades pro Panel. Lösung: VBoxContainer ist OK bei dieser Anzahl, kein Virtual-Scrolling nötig.
**Aufwand:** 16 h

---

## P1-012 — GodotSteam Spike (vor P1-013)

**Ziel:** Steamworks-Integration validiert. **Erst nach Spike entscheiden, ob Standard-Godot-Build genügt oder eigener Build nötig ist.**

**Aufgaben:**
- GodotSteam GitHub-Repo anschauen, aktuelle stabile Version für Godot 4.x identifizieren
- Prüfen ob GodotSteam als **GDExtension** verfügbar ist (bevorzugt, kein eigener Engine-Build)
- Falls GDExtension: in Test-Branch einbinden, Hello-World-Test
- Falls nur Modul: Engine-Build-Aufwand evaluieren (1 Tag, dokumentieren)
- AppID 480 (Spacewar) testen
- `Steam.init()` aufrufen, Username loggen
- Test-Achievement triggern (Spacewar hat eingebaute)
- Cloud-Save-Test (Datei schreiben, von anderem Gerät lesen)

**Akzeptanz:**
- Spacewar-Test läuft auf Win + Linux
- Achievement triggered, ist im Steam-Profil sichtbar
- Cloud-Save-Datei erscheint auf zweitem Gerät innerhalb 60 s
- Entscheidung dokumentiert: GDExtension oder eigener Build

**Risiko:** GDExtension-Variante existiert nicht für aktuelle Godot-Version → Fallback eigener Build (1 Tag Extra-Aufwand). Worst-Case: GodotSteam unsupported für aktuelle Godot-Version → Engine-Wechsel-Entscheidung notwendig (ADR-0001 Review-Trigger).
**Aufwand:** 6–10 h (Spike-Zeitbox, hartes Ende)

---

## P1-013 — Test-Sessions mit ungeschulten Personen

**Ziel:** Validieren, dass das Greybox-Spiel grundlegend Spaß macht.
**Aufgaben:**
- 3 Personen rekrutieren (Freunde, Family, ggf. Reddit-Discord)
- 30-Min-Session-Plan (kein Tutorial, nur Spiel starten)
- Screen-Record + Verbal-Walkthrough
- Beobachten: Was klicken sie zuerst? Wo verlieren sie Interesse? Wo sind sie verwirrt?
- Notizen in `docs/playtest-notes-phase-1.md` zusammenführen
- 3 wichtigste Insights als Aktion-Items für Phase 2 ableiten

**Akzeptanz:** 3 Sessions durchgeführt, Notizen dokumentiert, Aktion-Items identifiziert.
**Risiko:** Wenn niemand freiwillig 15 min spielt → Cor-Loop ist nicht ausreichend stark. Adressieren in Phase 2.
**Aufwand:** 6 h (Recruiting + 3× 1h-Sessions inkl. Vorbereitung)

---

## Phase-1-Aufwand-Summe

| Ticket | Aufwand (h) |
|---|---|
| P1-001 | 4 |
| P1-002 | 6 |
| P1-003 | 8 |
| P1-004 | 12 |
| P1-005 | 6 |
| P1-006 | 10 |
| P1-007 | 4 |
| P1-008 | 8 |
| P1-009 | 6 |
| P1-010 | 16 |
| P1-011 | 16 |
| P1-012 | 6–10 |
| P1-013 | 6 |
| **Summe** | **108–112 h** |

Bei 15–20 h/Woche: **~6 Wochen**.
Bei 30–40 h/Woche: **~3 Wochen**.

## Phase-1-Risiken-Liste (Konsolidiert)

| Risiko | Aus | Mitigation |
|---|---|---|
| GodotSteam-Inkompatibilität | P1-012 | Spike-Ergebnis bestimmt Eskalation (Eigen-Build oder Engine-Wechsel) |
| Shader-Port scheitert | P1-010 | Spike vor Phase-1-Commitment, ggf. Alternative `CPUParticles3D` |
| Save-Schema-Bug | P1-004 | 100-Cycle Test in CI |
| UI-Performance bei 30 Upgrades | P1-011 | Profiler-Check, ggf. VirtualBoxContainer in Phase 3 |
| Tester finden niemanden zum Test | P1-013 | Backup: bezahlte Tester via PlaytestCloud, ~50 € |

## Definition of Done — Phase 1

→ Siehe `production/definition-of-done.md` Sektion „Phase 1"
