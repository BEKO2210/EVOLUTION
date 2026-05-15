# ADR-0002 — Steam-Plattform-Scope für v1.0

**Status:** Akzeptiert
**Datum:** Phase 0

## Kontext

Welche Plattformen unterstützt v1.0 zum Steam-Launch? Welche kommen post-launch? Welche bleiben ausgeschlossen?

## Optionen

| Option | Plattformen v1.0 | Aufwand | Reichweite |
|---|---|---|---|
| A | Windows only | niedrig | ~75 % Steam-Nutzer |
| B | Windows + Linux | niedrig + Steam-Deck-Bonus | ~78 % + Deck-Verified-Sichtbarkeit |
| C | Windows + Linux + macOS | mittel | ~95 % Steam-Nutzer + Deck-Verified |
| D | Wie C + Android Companion | hoch | + Mobile-Käuferschaft, aber separates Produkt |

## Entscheidung

**Option C — Windows + Linux + macOS für v1.0 Steam-Launch.**

Android-Companion-Build kommt in Phase 7 als separater Release (Google Play und/oder F-Droid), nicht im Steam-v1.0-Scope. iOS optional in Phase 7+, abhängig von Apple-Developer-Account-Aufwand.

## Begründung

- **Godot exportiert alle drei Desktop-Targets trivial** — der Build-Pipeline-Overhead ist minimal.
- **Steam Deck Verified ist ein signifikanter Sichtbarkeits-Boost** für Idle/Casual-Genre; Linux-Build dafür Pflicht.
- **macOS-Build kostet wenig zusätzlich** (Cross-Compile vom Linux-Build-Host möglich), erschließt aber kreatives Indie-Publikum auf Mac.
- **Mobile in v1.0 wäre Doppel-Belastung** (separates UI-Layout, separater Store-Approval-Prozess) → in Phase 7 als eigenes Produkt.

## Konsequenzen

- CI-Build-Pipeline muss 3 Desktop-Targets produzieren (siehe TDD).
- QA-Matrix in Phase 4 testet alle 3 Plattformen + Steam Deck (LCD + OLED, plugged + battery).
- Steam-Page listet 3 Plattformen.
- Empfohlene System-Requirements werden pro Plattform in Phase 4 verifiziert.
- Cloud-Save funktioniert cross-platform.

## Steam-spezifische Implikationen

- **Steam Deck Verified anstreben** (nicht garantieren) — siehe `docs/steam/steam-deck-checklist.md` für konkrete Prüfpunkte.
- **macOS Notarization** ist via Steam nicht zwingend (Steam-Launcher handelt Run-Permission), aber sauber notarisierter Build vereinfacht Out-of-Steam-Distribution falls später Itch.io geplant.
- **Linux-Build als 64-Bit** (Steam Runtime 3 / Soldier oder Steam Linux Runtime aktuell empfohlen).

## Review-Trigger

- Steam Deck Markt-Anteil sinkt drastisch → Linux-Build-Priorität neu evaluieren
- Apple Silicon erfordert separate ARM-Build-Pipeline → Aufwand neu bewerten
