# Attributions

Drittsoftware-, Asset- und Lizenz-Hinweise. Diese Datei wird laufend ergänzt
sobald in späteren Phasen weitere Abhängigkeiten dazukommen (Audio,
Icon-Sets, Fonts, Engine-Addons).

**Status:** Phase 0 — Pre-Production. Liste enthält aktuell genutzte
Abhängigkeiten und Platzhalter für geplante Integrationen.

---

## Aktuell aktive Abhängigkeiten

### Three.js
- **Verwendung:** HTML/Three.js-Prototyp (`index.html`) lädt Three.js zur Laufzeit per Import-Map vom jsDelivr CDN (`three@0.160.0`).
- **Funktion im Projekt:** Rendert die BioNexus-3D-Cell-Visualisierung (`MultiMeshInstance`, Custom GLSL-Shader).
- **Lizenz:** MIT License
- **Copyright:** © 2010 three.js authors
- **Quellen:**
  - Source: https://github.com/mrdoob/three.js
  - Lizenztext: https://github.com/mrdoob/three.js/blob/master/LICENSE
- **Hinweis:** Three.js wird **nicht** in den Godot-Build wandern. Nach der Phase-1-Migration werden die Shader nach GDShader portiert; Three.js bleibt ausschließlich Bestandteil des HTML-Prototypen (Validation Asset).

### System-UI-Font-Stack
- **Verwendung:** CSS-Property `font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif` im Prototyp.
- **Funktion:** Nutzt die jeweilige System-Standard-UI-Font (San Francisco auf Apple, Segoe UI auf Windows, Roboto auf Android, etc.).
- **Lizenz:** je System-Provider, keine eigene Distribution.
- **Hinweis:** In Phase 2/3 wird wahrscheinlich **Inter** (SIL Open Font License 1.1) als gebündelter Font ergänzt für plattform-konsistente Typografie. Wird hier ergänzt sobald in Repo aufgenommen.

---

## Geplante Abhängigkeiten (noch nicht im Repo)

### Godot Engine 4.x
- **Verwendung:** **Aktiv** seit Phase 1, P1-001 (Repo enthält `project.godot` + `.godot-version`).
- **Funktion:** Komplette Game-Engine (Editor, Renderer, GDScript, GDShader, Export-Pipelines).
- **Lizenz:** MIT License
- **Copyright:** © 2007–present Juan Linietsky, Ariel Manzur, Godot Engine contributors
- **Quellen:**
  - Source: https://github.com/godotengine/godot
  - Lizenztext: https://github.com/godotengine/godot/blob/master/LICENSE.txt
- **Status:** Initialer Pin in `.godot-version` ist `4.3-stable`. Bei Update auf neuere stabile Version: in ADR-0001 dokumentieren + `.godot-version` + `project.godot:config/features` synchron updaten.

### GodotSteam (Plugin / GDExtension)
- **Verwendung:** Geplant für Phase 2 (Vertical Slice) / Phase 5 (Release-Prep). Steamworks-SDK-Integration für Achievements, Cloud-Save, Steam Input, Rich Presence.
- **Funktion:** Bindings zur Steamworks-API.
- **Lizenz:** MIT License
- **Copyright:** © CoaguCo Industries / GodotSteam contributors
- **Quellen:**
  - Source: https://github.com/CoaguCo-Industries/GodotSteam
- **Distribution-Form:** **GDExtension** (kein eigener Engine-Build) — Spike-Ergebnis in `docs/decisions/ADR-0005-godotsteam-integration.md`.
- **Status:** Phase 1 Spike (P1-012) abgeschlossen: `scripts/autoload/steam_api.gd` hat alle Hooks feature-detected; ohne installierte GDExtension läuft das Spiel im no-op-Modus.
  Plugin-Files werden in Phase 2 ins Repo aufgenommen (`addons/godotsteam/`). Setup-Anleitung: `docs/steam/godotsteam-setup.md`.

### Steamworks SDK (Valve)
- **Verwendung:** Wird mit dem Spiel ausgeliefert (`steam_api64.dll` / `libsteam_api.so` / `libsteam_api.dylib`) — Pflicht für die GodotSteam-Integration.
- **Lizenz:** Steamworks SDK Agreement — Distribution-Recht ist im Agreement explizit für Steam-veröffentlichte Spiele erteilt.
- **Quellen:** https://partner.steamgames.com (Steamworks Partner Login erforderlich)
- **Status:** Wird in Phase 2 mit der GodotSteam-Integration eingespielt.

### GUT (Godot Unit Test)
- **Verwendung:** **Geplant** — Test-Framework für Phase-1-Unit-Tests (Save-System, Economy-Math, Data-Loader, Milestone-Logic).
- **Lizenz:** MIT License
- **Quellen:** https://github.com/bitwes/Gut
- **Status:** Noch nicht integriert.

---

## Platzhalter für spätere Phasen

Die folgenden Asset-Klassen sind heute **nicht** im Repo; sobald sie hinzukommen, wird der jeweilige Eintrag mit echter Lizenz aktualisiert. **Keine vorzeitigen Lizenz-Claims** — diese Platzhalter sind nur Strukturen, nicht Behauptungen.

### Audio-Assets (geplant Phase 2 / Phase 3)
- **Music:** Eigenproduktion ODER Komponist-Auftrag (Buy-Out-Klausel). Aktueller Stand: noch nicht beauftragt.
- **SFX:** Wahrscheinlich Hybrid aus SFX-Library-Pack (z. B. Soniss/BOOM Library, kommerziell) + Eigenproduktion (Synth, Foley).
- **Lizenz pro Asset wird hier dokumentiert sobald geliefert.**

### Icons / UI-Assets (in Arbeit)
- **Wave-1-Iconset** (Tabs + Abilities, im Prototyp aktiv): **Eigenproduktion**, MIT-Lizenz fürs Studio-Werk.
- **Wave-2-Iconset** (60 Upgrade-Icons): **geplant**, Eigenproduktion oder externer Illustrator.
- Externe Icon-Bibliotheken: bisher keine genutzt.

### Fonts (geplant)
- Wahrscheinlicher Kandidat: **Inter** (SIL Open Font License 1.1)
- CJK-Fallback wahrscheinlich: **Noto Sans CJK** (SIL Open Font License 1.1)
- Final-Entscheidung in Phase 2 (Art Bible Refinement).

### Übersetzungen (geplant Phase 3)
- Externe Übersetzer mit Buy-Out-Klausel pro Sprache.
- Übersetzungen werden als bearbeitetes Werk im `localization/strings.csv` versioniert; Studio behält Rechte für die Verwendung im Spiel.

### Sentry (Crash-Reporting, geplant Phase 3)
- **Verwendung:** geplant — Crash-Reporting + Performance-Monitoring.
- **Lizenz / Plan:** Sentry SDK ist BSL/Apache, Sentry-Cloud-Service ist kommerzieller Dienst (Free-Tier ausreichend für Indie-Start).
- **Quellen:** https://github.com/getsentry

---

## AI-Generated Content

**Stand Phase 0:** Es gibt im Spiel-Build **keine AI-generierten Assets**. Konzept-Skizzen / Brainstorming-Outputs in `docs/` sind als interne Mockups klar gekennzeichnet falls vorhanden und gehen **nicht** in den Steam-Build.

Falls in einer späteren Phase AI-generierte Assets verwendet werden (was aktuell nicht geplant ist), erfordert das:
1. Eigenen ADR-Eintrag (`docs/decisions/ADR-NNNN-ai-assets.md`) mit Begründung + Lizenz-Lage
2. Konforme Disclosure im Steam-Backend (Steam fordert Offenlegung)
3. Eigene Sektion in dieser Datei

---

## Quellen-Compliance

- Alle hier gelisteten Dependencies sind aktuell entweder MIT / SIL OFL / vergleichbar permissive — keine Copyleft-Kette (GPL) ist eingebunden.
- Sobald LGPL-Pakete erwogen werden (z. B. spezielle Audio-Codec-Library), separate Prüfung vor Aufnahme.

---

## Wartung dieser Datei

- Bei jeder neuen Drittsoftware-Integration: Eintrag mit Lizenz + Source + Verwendung
- Bei Asset-Bestellung (Audio, Übersetzung, Icons): Eintrag mit Lieferant + Lizenz-Klausel-Hinweis (Buy-Out / Royalty / Public Domain)
- Vor Steam-Release: Datei wird auf Open-Source-Attribution-Bildschirm im Spiel referenziert (Pflicht-Punkt in `docs/10-release-checklist.md`)

---

## Studio-Werk

Soweit nicht hier oder in `LICENSE` anders angegeben, sind:
- Game-Design / Story / Konzept-Texte / Doku in `docs/`, `production/`, `data/`: **alle Rechte vorbehalten** (Studio).
- HTML-Prototyp (`index.html`): wird in Phase 1 unter MIT freigegeben sobald Engine-Migration abgeschlossen ist; bis dahin: alle Rechte vorbehalten.
- Branding / Spieltitel / Logos: alle Rechte vorbehalten, Trademark-Status siehe `docs/decisions/` (ADR-0005 sobald angelegt).
