# ADR-0001 — Engine-Wahl

**Status:** Akzeptiert
**Datum:** Phase 0
**Kontext-Phase:** Pre-Production
**Reviewer:** Game Director, Technical Director

## Kontext

Evolution ist ein 2D/UI-lastiges Idle-Spiel mit einer GPU-Shader-getriebenen 3D-Hauptfigur (BioNexus-Zelle). Es soll auf Windows, Linux, macOS und Steam Deck veröffentlicht werden, mit Mobile-Companion-Build in einer späteren Phase. Solo-Dev-Setup mit 15–40 Wochenstunden, kein Hire-Budget für Engine-Spezialisten.

Ein funktionaler HTML/Three.js-Prototyp existiert. Er validiert Core Loop, Stage-Progression und das visuelle Cell-Konzept.

## Optionen

### Option A — Godot 4.x (aktuelle stabile Version zum Projektstart)

**Pro:**
- MIT-Lizenz, keine Royalties, keine Install-Fees, kein Sub-Model
- 2D/UI-Stack ist Engine-Kernkompetenz; Control-Nodes + Theme-System ideal für Idle-UI
- GDShader ist GLSL-Dialekt → Three.js-Shader-Port mit <80 % Code-Identität möglich
- Engine-Footprint ~100 MB Editor, schnelle Iteration (<1 s Reload)
- Native Mobile-Export (Android, iOS via macOS-Buildhost)
- Linux-Build trivial → Steam-Deck-Kompatibilität ohne Sonderaufwand
- Mehrere kommerziell erfolgreiche Steam-Indies validieren die Plattform (Brotato, Halls of Torment, Dome Keeper, Buckshot Roulette)
- Open Source → kein Vendor-Lock-in, kein Lizenz-Risiko nach Release
- GDScript ist schnell zu schreiben für Solo-Dev; C#-Support für Hot-Paths verfügbar

**Contra:**
- Kleinerer Asset-Store als Unity
- Kleinerer Hire-Pool falls Skalierung ins Team
- 3D-Toolchain weniger ausgereift als Unity/Unreal (irrelevant für UI-lastiges Spiel)
- Steam-Integration via Community-Plugin (GodotSteam / GDExtension) — keine First-Party-Integration

### Option B — Unity (aktuelle LTS)

**Pro:**
- Größtes Indie-Ecosystem, größter Asset-Store, größter Hire-Pool
- Steamworks.NET / Facepunch.Steamworks als reife Integrationen
- C# ist eine mature Sprache mit besserer Refactoring-Tool-Unterstützung
- UI Toolkit (post-2022) ist sehr leistungsfähig
- Unity Cloud Build als Build-Service verfügbar

**Contra:**
- 2023-Install-Fee-Debakel hat Vertrauen erschüttert (zurückgenommen, aber Risiko-Aroma bleibt)
- Subscription-Modell (Pro-Tier) ab bestimmten Umsatz-Schwellen
- C#-Domain-Reload kostet 3–10 s pro Code-Change → über 12 Monate hunderte Stunden Entwicklungs-Reibung
- Engine-Footprint groß (~1.5 GB Editor)
- Build-Größe einer Idle-App typisch 100–200 MB (Godot 30–60 MB)
- UI Toolkit ist mächtig aber komplex; Overhead nicht amortisiert für UI-getriebenes Spiel

### Option C — Unreal Engine 5

**Pro:**
- Beste 3D-Render-Qualität der drei
- Reife Steam-Integration via Online Subsystem Steam (First-Party)
- Stark in AAA-Genres

**Contra:**
- 5 % Royalty nach 1 M$ Lifetime-Revenue (problematisch falls Indie-Hit)
- 2D-UI-Tooling (UMG) ist Schwachstelle, AAA-3D-fokussiert
- Engine-Größe ~50 GB Editor, langsame Iteration für 2D-Logik
- Mobile-Build typisch >300 MB
- HLSL + Material-Graph für Shader-Port aufwändiger als GDShader
- Falsche Werkzeugklasse für UI-lastiges Indie-Idle

## Entscheidung

**Godot 4.x in der aktuellen stabilen Version zum Projektstart (Phase 1).**

GDScript als Hauptsprache. GDShader für Visuals. C#-Modul nur falls Phase-3-Profiler einen Hot-Path identifiziert, der GDScript-Limits sprengt.

## Begründung

1. **Game-Profil:** 90 % UI, 10 % GPU-Shader-Spektakel. Godots Stärken decken sich exakt.
2. **Shader-Port:** GDShader-Syntax ist näher an unserem bestehenden GLSL als HLSL — niedrigster Migrationsaufwand.
3. **Lizenz-Sicherheit:** MIT schließt jede zukünftige Lizenz-Änderung aus. Wichtig bei Indie-Launch ohne Rechtsanwalt.
4. **Iterations-Geschwindigkeit:** <1 s Reload halbiert effektive Entwicklungszeit gegenüber Unitys 3–10 s. Über 12 Monate hunderte Stunden.
5. **Steam Deck:** Linux-Build trivial → Verified-Pfad ohne Sonderaufwand.
6. **Solo-Dev-Realismus:** Engine ist klein genug für komplette Repo-Kontrolle, Build-Größe spart Bandbreite + Speicher beim Spieler.
7. **Marktbeweis:** Brotato, Halls of Torment, Dome Keeper sind kommerziell erfolgreiche Steam-Indies auf Godot — die Plattform ist nicht spekulativ.

## Akzeptierte Trade-offs

- Kleinerer Asset-Store: Wir kaufen wenig zu, der Großteil ist Eigenentwicklung
- Kleinerer Hire-Pool: Bei Team-Erweiterung bevorzugen wir Godot-erfahrene Devs, andernfalls Onboarding-Aufwand einplanen
- Steamworks via Community-Plugin: GodotSteam ist stabil, wird in Phase 2 via Spike validiert (siehe ADR-0002, ADR-0004 und TDD)

## Konsequenzen

- Engine-Version: **Godot 4.x, bevorzugt aktuelle stabile Version zum Projektstart**. Konkrete Patch-Version wird in Phase 1 fixiert (`project.godot` + `.godot-version`-Datei).
- Build-Targets: Windows + Linux + macOS für Steam-Launch. Android in Phase 7 als Companion. iOS optional.
- Shader-Sprache: GDShader für alle Game-Visuals.
- Steam-Integration: GodotSteam via Spike validiert (siehe Phase-2-Backlog).
- Save-Format: JSON via Godots `FileAccess` + `JSON.stringify/parse_string` (siehe ADR-0003).
- Daten-Modell: externe JSON-Dateien für alle Game-Balance-Werte (siehe ADR-0004).

## Review-Trigger (wann diese Entscheidung neu evaluieren)

- Godot-Engine-Roadmap kündigt Breaking Change an, der unser Projekt zwingt zu portieren
- Steam-Integration via GodotSteam-Spike scheitert (Plan B: dann Unity-Migration mit ~3 Monate Verzug)
- Performance auf Steam Deck bricht ein und lässt sich nicht via Godot-Optimierung fixen
