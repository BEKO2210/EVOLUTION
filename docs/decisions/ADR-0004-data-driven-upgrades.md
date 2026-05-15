# ADR-0004 — Daten-getriebene Upgrades & Balance

**Status:** Akzeptiert
**Datum:** Phase 0

## Kontext

Game-Balance ist Iteration. Wir müssen ohne Code-Änderung Werte tunen können — sowohl in Dev als auch idealerweise von Modder-Community in Post-Launch.

## Optionen

| Option | Format | Vor | Nach |
|---|---|---|---|
| A | Hartcodiert in GDScript | einfach | keine Iteration ohne Recompile, keine Mod-Möglichkeit |
| B | Godot Resources (`.tres`) | engine-native, Inspector-editierbar | binär, nicht-trivial diffbar, schwer external-tool-friendly |
| C | JSON | text-editierbar, Spreadsheet-exportierbar, mod-freundlich | leichte Parse-Overhead, kein Inspector |
| D | CSV | Spreadsheet-direkt | komplexe Schemas schwer abbildbar |

## Entscheidung

**Option C — JSON-Dateien in `data/`-Ordner, geladen via `data_loader.gd` Autoload.**

## Dateien

```
data/
├── balance_constants.json       # COST_GROWTH, MILESTONES, PRESTIGE_THRESHOLD, etc.
├── stages.json                  # 30 Stages
├── upgrades_auto.json           # 30 Auto-Upgrades
├── upgrades_click.json          # 30 Click-Upgrades
├── research.json                # 12 Forschungen
├── abilities.json               # 4 Abilities
├── achievements.json            # 50 Achievements
├── codex.json                   # Lore-Texte pro Stage + Upgrade
└── skill_tree.json              # Skill-Tree-Knoten + Verbindungen
```

## Beispiel-Schemas

### `data/balance_constants.json`
```json
{
  "version": 1,
  "cost_growth": 1.15,
  "milestones": [10, 25, 50, 100],
  "milestone_multiplier": 2.0,
  "prestige_threshold_lifetime_dna": 1000000,
  "evolution_point_formula": "floor(sqrt(lifetime_dna / 1000000))",
  "prestige_multiplier_base": 1.10,
  "auto_synergy_per_count": 0.005,
  "click_synergy_per_count": 0.003,
  "offline_efficiency_default": 0.5,
  "offline_efficiency_research_r12": 1.0,
  "offline_cap_seconds_default": 14400,
  "offline_cap_seconds_skill_endloser_idle": 43200,
  "crit_chance_base": 0.05,
  "crit_multiplier_base": 5.0
}
```

### `data/upgrades_auto.json`
```json
{
  "version": 1,
  "items": [
    {
      "id": "a1",
      "name_key": "upg.a1.name",
      "desc_key": "upg.a1.desc",
      "icon": "mitochondria",
      "dps": 0.4,
      "cost_base": 60,
      "unlock_after": null,
      "codex_key": "codex.a1"
    },
    {
      "id": "a2",
      "name_key": "upg.a2.name",
      "desc_key": "upg.a2.desc",
      "icon": "ribosomes",
      "dps": 1.8,
      "cost_base": 850,
      "unlock_after": "a1",
      "codex_key": "codex.a2"
    }
  ]
}
```

### `data/stages.json`
```json
{
  "version": 1,
  "items": [
    {
      "id": 1,
      "name_key": "stage.1.name",
      "threshold_dna": 0,
      "bonus_multiplier": 1.0,
      "visual_radius": 30,
      "visual_wobble": 0.015,
      "color_hex": "#00ffa3",
      "bionexus_phase": "solo",
      "codex_key": "codex.stage.1"
    }
  ]
}
```

## Loader-Verantwortung

`scripts/autoload/data_loader.gd`:
- Liest alle `data/*.json` beim Spielstart
- Validiert Schema (Pflicht-Felder, Typen, Wertebereiche)
- Cached in Memory-Maps für O(1)-Zugriff via `DataLoader.get_upgrade_auto("a1")`
- Bei Schema-Verstoß: `push_error` + Crash mit klarer Meldung (Dev-Fehler, kein User-Problem)

## Mod-Support (Post-Launch v1.1+)

JSON-Dateien sind in der Spiel-Installation lesbar. User können Override-Files in `user://mods/<modname>/data/` ablegen. Loader prüft erst `user://mods/`, fällt auf shipped-Dateien zurück.

## Tests

- `tests/test_data_loader.gd`: lädt jede `data/*.json`, validiert Schema, prüft auf duplizierte IDs
- `tests/test_economy_math.gd`: simuliert Kosten-Wachstum gegen erwartete Werte aus Balance-Sheet

## Akzeptierte Trade-offs

- Cheaten möglich (Save manipulieren oder JSON-Files ändern) — akzeptiert für Singleplayer-Premium
- Keine Inspector-Edit-Erfahrung — kompensiert durch klare JSON-Struktur
- Schema-Änderungen erfordern Loader-Update + Daten-Migration

## Konsequenzen

- Game-Logik referenziert **nie** Werte hartcodiert
- Designer (du oder Externer) kann Balance ohne Code-Change tunen
- Balance-Sheet (`docs/09-balance-model.md`) ist Source of Truth, JSON-Files sind dessen Export
- Mod-Support ist mit minimalem Zusatzaufwand möglich (Phase 7)

## Review-Trigger

- Daten-Schema wird zu komplex für JSON (Conditional Logic, Formeln) → Erwäge GDScript-Resource-Files oder Lua-Embedded
- Mod-Community fordert Hot-Reload → File-Watcher in Editor-Build hinzufügen
