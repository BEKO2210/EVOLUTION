# Changelog

Alle bemerkenswerten Änderungen an diesem Projekt werden hier dokumentiert.

Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
das Projekt folgt [SemVer](https://semver.org/lang/de/spec/v2.0.0.html).

## [Unreleased]

### Phase 2 (Vertical Slice) — geplant
- Final Theme, Audio, Onboarding
- Steam-Integration scharf (Plugin-Binaries)
- 5 ausgearbeitete Stages auf Shipping-Qualität

## [0.1.0-phase1] — 2026-05-16

**Phase 1 Code-Complete.** Engine-Prototyp mit allen Game-Systemen, daten-getrieben, signal-reaktiv, voll getestet. UI ist Greybox-Qualität — Polish kommt in Phase 2.

### Added — Architektur
- Godot 4.3-stable Projekt-Skelett (`project.godot`, `.godot-version`)
- 12 Autoload-Singletons in deterministischer Init-Reihenfolge:
  GameState · SaveSystem · DataLoader · AudioManager · SteamAPI · Telemetry · TickSystem · ClickSystem · PrestigeSystem · UpgradeSystem · StageSystem · AchievementSystem
- Signal-getriebene Cross-System-Kommunikation (kein Polling)
- TickSystem mit Logic-4-Hz + Visual-per-Frame + Auto-Save-Timer

### Added — Game-Systeme
- **ClickSystem** — Klick + Combo (cap 60, ramp 3→30) + Crit (5% base, 5× mult)
- **UpgradeSystem** — Cost-Formel `cost × 1.15^count`, Milestone-Verdopplung bei 10/25/50/100, Bulk-Buy + Buy-Max
- **StageSystem** — Threshold-Detection gegen `total_dna`, 30 Tiers von "Proto-Molekül" zu "Transzendenz"
- **PrestigeSystem** — Soft-Reset ab 1M Lifetime-DNA, EP-Formel `floor(sqrt(lifetime/1M))`, ×1.10 kompoundierender Multiplier
- **AchievementSystem** — 27 Achievements mit 9 deklarativen Condition-Kinds, Reward-Multiplier-Stack in `recalc_stats`
- **SaveSystem** — JSON-Format mit SHA-256-Checksum, Schema-Versionierung, Auto-Backup vor Migration, Steam-Cloud-vorbereitet
- **DataLoader** — alle 7 `data/*.json` Tables mit Schema-Validierung + Enum-Allowlist + Cross-Table-Referenzcheck

### Added — Visualisierung
- BioNexus 3D-Cell-Shader nach GDShader portiert (1:1 vom HTML/Three.js-Prototyp)
- MultiMeshInstance3D mit 4000-Instance-Cap, Fibonacci-Sphere-Layout
- Per-Stage-Animation: Count / Morph / Swim / Camera-Dolly aus 30-Tier-Lookup
- Click-Shockwave-Effekt mit Crit-Color-Tint
- Greybox-UI: HUD (DNA/DPS/Click/Stage) + 5 Tabs (Auto/Click/Forschung/Erfolge/Meta) + reaktive Upgrade-Cards + Prestige-Button

### Added — Steam-Integration (vorbereitet)
- `steam_api.gd` Wrapper mit echten GodotSteam-Calls
- Feature-Detection via `Engine.has_singleton("Steam")` → läuft no-op-safe ohne Plugin
- Manuelle Smoke-Test-Scene `scenes/dev/steam_smoke_test.tscn`
- Setup-Doku für Phase-2-Aktivierung
- **Entscheidung dokumentiert (ADR-0005):** GDExtension (nicht Engine-Modul)

### Added — Tests
- 11 Headless-Test-Suites, ~120 Assertions, alle grün
- `tools/run_tests.sh` shell-wrapper für CI
- Round-Trip-Save-Test (100 Cycles), Korruptions-Detection (Checksum/JSON/missing fields)
- Pro System: pure-function-Coverage + Signal-Contract-Verification + Idempotenz-Tests

### Added — Dokumentation
- 30+ Markdown-Files in `docs/`:
  - GDD, Art Bible, Audio Bible, Technical Design Document
  - Risk Register, Competitive Analysis, Steam Marketing Plan
  - 5 ADRs (Engine, Steam-Plattform, Save-System, Data-Driven, GodotSteam)
  - Steam-Spezifika (Asset-Checklist, Store-Page-Checklist, Release-Timeline, Deck-Verified-Checklist)
  - Production-Plans (Phase-0-Plan, Phase-1-Backlog, Definition-of-Done, Scope-Control)
- Playtest-Template + Skeleton-Notes für P1-013

### Changed
- `index.html` (Three.js-Prototyp) bleibt erhalten als Validation-Asset, wird nicht mehr aktiv weiterentwickelt im Godot-Repo

### Open
- **P1-013 Playtest** — wartet auf echte Tester (3 Personen, je 30 min). Templates + Notes-Skeleton sind bereit.

## [0.0.1-phase0] — 2026-05-15

**Phase 0 Foundation.** Dokumentations- und Planungs-Setup vor Engine-Migration.

### Added
- Phase-0-Foundation: GDD, Art/Audio Bibles, TDD, Risk-Register, Competitive-Analysis, Steam-Marketing-Plan, Release-Checklist
- 4 ADRs (Engine, Plattform-Scope, Save-System, Data-Driven-Upgrades)
- Steam-Spezifika: Asset-Checklist, Store-Page-Checklist, Release-Timeline, Deck-Verified
- Datenextraktion aus HTML/Three.js-Prototyp in `data/*.json` (7 Tables, 110+ Items)
- Repository-Hygiene: README, .gitignore (Godot-optimiert), .gitattributes, ATTRIBUTIONS, LICENSE

### Engine-Decision
- **Godot 4.x** über Unity / Unreal (ADR-0001) — begründet auf 2D-UI-Eignung, GDShader↔GLSL-Nähe, MIT-Lizenz-Sicherheit, schnelle Iteration

---

[Unreleased]: https://github.com/BEKO2210/EVOLUTION/compare/main...HEAD
[0.1.0-phase1]: https://github.com/BEKO2210/EVOLUTION/releases/tag/v0.1.0-phase1
[0.0.1-phase0]: https://github.com/BEKO2210/EVOLUTION/releases/tag/v0.0.1-phase0
