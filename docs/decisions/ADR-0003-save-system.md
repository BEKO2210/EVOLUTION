# ADR-0003 — Save-System

**Status:** Akzeptiert
**Datum:** Phase 0

## Kontext

Wie persistieren wir Spielstand? Welches Format? Wie verhindern wir Datenverlust? Wie funktioniert Migration zwischen Schema-Versionen? Wie integriert Steam Cloud?

## Optionen

| Option | Format | Vor | Nach |
|---|---|---|---|
| A | Binary (Godot Resource `.tres`) | Engine-Native, schnell | Schwer debug-/diffbar, weniger portabel |
| B | JSON | Lesbar, portabel, debug-freundlich, future-proof | Größer, langsameres Parsen (irrelevant für unsere Datenmenge) |
| C | SQLite | Mächtig, transaktional | Overkill, Setup-Overhead |
| D | Cloud-First (Steam Cloud direkt) | Cross-Device automatisch | Single-Point-of-Failure, kein Offline-Spielen ohne Steam |

## Entscheidung

**Option B — JSON-Datei in `user://`, mit Steam Cloud als Sync-Layer.**

## Schema

```json
{
  "schema_version": 1,
  "saved_at_unix": 1736889600,
  "game_version": "0.1.0",
  "slot_name": "main",
  "game": {
    "dna": 1234.5,
    "lifetime_dna": 9876.5,
    "stage": 7,
    "prestige_points": 2,
    "evolutionspunkte": 4,
    "skill_tree": { "schnellstart": 1, "auto_buyer": 0 },
    "divisions": 1,
    "total_clicks": 15234,
    "total_crits": 412,
    "total_goldens": 7,
    "start_time_unix": 1736000000,
    "last_real_tick_unix": 1736889600
  },
  "upgrades_auto": { "a1": 12, "a2": 5 },
  "upgrades_click": { "c1": 8 },
  "research": { "r1": true },
  "achievements": { "click10": 1736000000 },
  "abilities": { "photo": { "last_used": 1736000000, "active_until": 0 } },
  "settings": {
    "volume_master": 0.8,
    "volume_music": 0.6,
    "volume_sfx": 0.8,
    "quality_preset": "high",
    "reduce_motion": false,
    "color_blind_mode": "off",
    "language": "de",
    "haptic": true,
    "telemetry_opt_in": false
  },
  "checksum_sha256": "abc123..."
}
```

## Migration-Strategie

`scripts/autoload/save_system.gd` enthält eine Map:
```gdscript
const MIGRATIONS := {
    1: "_migrate_v1_to_v2",  # wird erst implementiert wenn v2 existiert
}
```

Beim Laden:
1. Schema-Version lesen
2. Falls niedriger als `CURRENT_SCHEMA_VERSION`: schrittweise migrieren (1→2→3→…)
3. Vor jeder Migration: Backup nach `user://save_slot_<n>.backup_v<old>.json`
4. Nach Migration: Checksum neu berechnen, neu speichern
5. Tests in `tests/test_save_migration.gd` für jede definierte Migration

## Disaster-Recovery

- **Auto-Backup vor Migration:** behalten bis zur 5. Generation
- **Manuelles Save-Export:** Settings-Menü → Datei-Picker → `.evolution-save`-Datei
- **Manuelles Save-Import:** Settings-Menü → Datei-Picker → Validation (Checksum, Schema-Version) → Restore
- **Multiple Slots:** 3 lokale Slots + 1 Steam-Cloud-Slot (`main`)
- **Checksum-Verifikation:** beim Laden, bei Mismatch → Backup anbieten

## Steam Cloud Integration

- Steam Cloud Quota: typisch 100 MB pro Spiel — unsere Save ist <10 KB
- Sync-Strategie: bei Spielstart von Cloud holen → falls Konflikt (zwei Geräte) → Konflikt-UI mit Diff
- Cloud-Pfad-Mapping in Steam Partner-Backend: `user://save_slot_main.json`
- Offline-Spielen: Save lokal funktioniert ohne Steam, Sync beim nächsten Online

## Konflikt-Resolution

Wenn `cloud.saved_at_unix != local.saved_at_unix` und beide nicht ältere Generation:

```
[Konflikt erkannt]
   Cloud:  Stage 7, 1.2M DNA, vor 2h gespeichert
   Lokal:  Stage 6, 800k DNA, vor 12h gespeichert

   [Cloud verwenden]  [Lokal verwenden]  [Beide behalten als 2 Slots]
```

## Akzeptierte Trade-offs

- JSON ist textbasiert → manipulierbar (Cheat möglich). Akzeptiert für ein Singleplayer-Premium-Spiel. Kein Anti-Cheat-Aufwand.
- Save-Größe wächst leicht im Late-Game. Bleibt aber <50 KB.
- Kein Compression (gzip). Bei Steam Cloud nicht nötig.

## Konsequenzen

- `scripts/autoload/save_system.gd` als Singleton, einzige Quelle für IO
- `tests/test_save_migration.gd` Pflicht-Test in CI
- 1000-Cycle Stress-Test in Phase 4 (1000× Save/Load/Modify-Loop)
- Restore-Tool als CLI-Script in `tools/restore.gd` für Notfall

## Review-Trigger

- Save-Größe überschreitet 1 MB → Format-Optimierung (binary chunks für historische Daten)
- Cloud-Quota wird knapp → Save-Garbage-Collection
