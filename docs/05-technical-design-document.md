# 05 — Technical Design Document (TDD)

**Status:** Phase 0 Draft v0.1
**Engine:** Godot 4.x (aktuelle stabile Version zum Projektstart, konkrete Patch-Version wird in Phase 1 in `project.godot` und `.godot-version` fixiert)
**Sprachen:** GDScript primär, GDShader für Visuals, C# nur falls Hot-Path-Analyse es rechtfertigt

---

## 1. Zielarchitektur (Übersicht)

```
                    ┌─────────────────────────────┐
                    │       Player Input          │
                    │  (Mouse / Touch / Pad)      │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │   Godot InputMap (Actions)  │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │     UI Layer (Control)      │
                    │  Tabs, Panels, Cards,       │
                    │  Tooltips, Popups, Settings │
                    └──────────┬──────────────────┘
                               │
       ┌───────────────────────┼────────────────────────┐
       │                       │                        │
┌──────▼─────────┐    ┌────────▼─────────┐    ┌─────────▼──────────┐
│  Game Systems  │    │   BioNexus 3D    │    │    FX Layer        │
│  (GDScript)    │    │  (Shader+Mesh)   │    │  (Particles 2D)    │
└──────┬─────────┘    └────────┬─────────┘    └────────────────────┘
       │                       │
┌──────▼─────────┐    ┌────────▼─────────┐
│  GameState     │    │  AudioManager    │
│  Autoload      │    │  (Bus Routing)   │
└──────┬─────────┘    └──────────────────┘
       │
┌──────▼───────────────────────────────────┐
│  SaveSystem (JSON, Cloud-Sync)           │
│  DataLoader (JSON Balance-Tables)        │
│  SteamAPI (GodotSteam, optional)         │
│  Telemetry (Sentry + Event-Pipeline)     │
└──────────────────────────────────────────┘
```

## 2. Ordnerstruktur (verbindlich)

```
project_root/
├── project.godot
├── .godot-version                  # exakte Patch-Version
├── export_presets.cfg              # Windows / Linux / macOS / Android
├── icon.svg
├── .gitignore
├── .gitattributes                  # *.tscn/*.tres als text-mode
├── README.md
├── LICENSE                         # MIT für Game-Code, separat für Assets
├── ATTRIBUTIONS.md                 # Godot, GodotSteam, Drittsoftware
├── docs/                           # Phase-0-Dokumente
├── ci/                             # Build-Scripts für GitHub Actions
│   ├── build_windows.sh
│   ├── build_linux.sh
│   ├── build_macos.sh
│   ├── build_android.sh
│   └── upload_steamcmd.sh
├── data/                           # JSON-Balance-Tables (siehe ADR-0004)
├── localization/
│   ├── strings.csv
│   └── fonts/                      # CJK-Fallback-Fonts
├── scenes/
│   ├── main.tscn                   # Root-Scene
│   ├── cell/
│   │   └── bionexus.tscn
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── tabs.tscn
│   │   ├── panels/
│   │   ├── popups/
│   │   └── settings.tscn
│   └── fx/
│       ├── float_text.tscn
│       ├── ripple.tscn
│       └── burst.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd
│   │   ├── save_system.gd
│   │   ├── data_loader.gd
│   │   ├── audio_manager.gd
│   │   ├── steam_api.gd
│   │   └── telemetry.gd
│   ├── systems/
│   │   ├── tick_system.gd
│   │   ├── click_system.gd
│   │   ├── upgrade_system.gd
│   │   ├── stage_system.gd
│   │   ├── prestige_system.gd
│   │   ├── achievement_system.gd
│   │   └── milestone_system.gd
│   └── ui/
│       ├── upgrade_card.gd
│       ├── tab_controller.gd
│       └── tooltip.gd
├── shaders/
│   ├── bionexus_cell.gdshader
│   ├── bionexus_plankton.gdshader
│   └── ui_glow.gdshader
├── assets/
│   ├── icons/                      # SVG-Source + Atlas-PNGs
│   ├── audio/
│   │   ├── music/
│   │   ├── sfx/
│   │   └── ambient/
│   ├── fonts/
│   └── steam/                      # Capsules, Library-Assets, Trailer
├── theme/
│   └── main_theme.tres
├── tests/                          # GUT-Test-Files
│   ├── test_save_migration.gd
│   ├── test_economy_math.gd
│   ├── test_data_loader.gd
│   └── test_milestone_system.gd
├── qa/
│   ├── smoke-test.md
│   └── deck-verified-checklist.md
└── tools/
    └── restore.gd                  # CLI Save-Restore
```

## 3. Szenenstruktur

```
Main (Node, Autoload-Trigger)
├── BackgroundLayer (CanvasLayer, layer=0)
│   └── ParticleField (CPUParticles2D, plankton substitute)
├── CellViewport (SubViewportContainer, layer=1)
│   └── SubViewport (own_world_3d=true)
│       ├── Camera3D
│       └── BioNexusCell (MultiMeshInstance3D + ShaderMaterial)
├── FxLayer (CanvasLayer, layer=3)
├── HUDLayer (CanvasLayer, layer=4)
│   ├── Header
│   ├── StageBar
│   ├── BioHud (Phase-Pill)
│   ├── AbilitiesBar
│   ├── Tabs
│   └── ActivePanel (Container für aktuell sichtbares Panel)
└── PopupLayer (CanvasLayer, layer=5)
    ├── OfflinePopup
    ├── StageUpPopup
    ├── PrestigeConfirmPopup
    └── SettingsPopup
```

**Begründung SubViewport für Cell:**
- Erlaubt Post-Processing nur auf der Zelle (Bloom, Glow)
- Erlaubt unabhängige Auflösung (z. B. 80 % für Performance auf Low-End)
- Trennt 3D-Rendering vom 2D-UI sauber

## 4. Autoloads

| Autoload | Zweck | Hauptmethoden |
|---|---|---|
| `GameState` | Single Source of Truth für alle Spielwerte | `add_dna()`, `set_stage()`, `recalc_stats()` |
| `SaveSystem` | JSON-IO, Migration, Cloud-Sync | `save()`, `load(slot)`, `migrate()` |
| `DataLoader` | Lädt alle `data/*.json`, validiert Schema | `get_upgrade_auto(id)`, `get_stage(n)` |
| `AudioManager` | Bus-Routing, Music-Layering | `play_sfx(id)`, `set_music_intensity(n)` |
| `SteamAPI` | GodotSteam-Wrapper, no-op falls Steam nicht da | `set_achievement(id)`, `cloud_save()` |
| `Telemetry` | Opt-in Event-Pipeline | `track(event, props)` |

Konfiguriert in `project.godot` → AutoLoad-Sektion, alle als `Node` mit Singleton-Flag.

## 5. Save-System

Siehe `docs/decisions/ADR-0003-save-system.md` für vollständige Spezifikation.

**Kurzfassung:**
- Format: JSON, ein Slot = eine Datei in `user://`
- 3 lokale Slots + 1 Cloud-Slot (`main`)
- Schema-Version + Migrations
- Checksum (SHA256) gegen Corruption
- Auto-Backup vor jeder Migration
- Steam Cloud Mapping in Partner-Backend

## 6. Datenmodell

Siehe `docs/decisions/ADR-0004-data-driven-upgrades.md`.

**Pflicht-Regel:** Kein Wert hartcodiert in GDScript. Alles in `data/*.json`.

## 7. JSON-/Resource-Strategie

- `data/*.json` für **Balance-Daten** (extern, Designer-editierbar, mod-fähig)
- `.tres` (Godot Resources) für **Engine-Konfigurationen** (Theme, Material, AnimationLibrary)
- Kein `.tres` für Game-Werte → das wäre Vendor-Lock-in und Cheat-Hürde ohne Gewinn

## 8. Shader-Portierung aus Three.js

### BioNexus Cell Shader

**Three.js → GDShader Mapping:**

| Three.js (GLSL) | GDShader Äquivalent |
|---|---|
| `attribute vec3 targetPos` | Per-Instance `INSTANCE_CUSTOM` (Vec4) oder `MultiMeshInstance3D.set_instance_custom_data()` |
| `attribute float clusterOffset` | Channel von `INSTANCE_CUSTOM` |
| `attribute float cellType` | Channel von `INSTANCE_CUSTOM` |
| `instanceMatrix` | `MODEL_MATRIX` (von Godot bereitgestellt im `vertex()`) |
| `gl_Position = projectionMatrix * mvPosition` | direkt zu `POSITION` zuweisen |
| `uniform float morph` | `uniform float morph : hint_range(0.0, 1.0)` |
| `varying vec3 vNormal` | `varying vec3 v_normal` |
| Simplex-Noise-Funktion | 1:1 übernehmen in `shader_type spatial`-Block |
| Additive Blending + depthWrite=false | `render_mode blend_add, depth_draw_never` |

**Implementation:** `MultiMeshInstance3D` mit eigenem Material:
```gdscript
var mm := MultiMesh.new()
mm.transform_format = MultiMesh.TRANSFORM_3D
mm.use_custom_data = true
mm.instance_count = MAX_INSTANCES
mm.mesh = preload("res://assets/meshes/cell_icosahedron.tres")
multi_mesh_instance.multimesh = mm
multi_mesh_instance.material_override = preload("res://shaders/bionexus_cell.tres")
```

### Plankton Shader

Particle-Shader portiert nach Godot. Alternativ: `CPUParticles2D` mit Texture statt Shader (einfacher, performant genug für 220 Plankton-Partikel).

### Spike-Aufwand (Schätzung)

- Cell-Shader-Port: 4–8 h
- Plankton-Migration: 1–2 h
- Validierung auf Steam Deck: 2 h

## 9. UI-System

- **Godot Control-Nodes** für alle UI
- **Zentrales Theme** in `theme/main_theme.tres` mit allen Farben, Fonts, Borders
- **Custom Controls:**
  - `UpgradeCard` (für Auto/Click-Upgrades)
  - `Tooltip` (Hover Desktop, Long-Press Mobile)
  - `Ripple` (Click-Feedback)
  - `BioHud` (Phase-Pill mit Pulse)
- **Responsives Layout** via `MarginContainer` + `HBoxContainer`/`VBoxContainer` + Anchor-Mode
- **Mobile-Layout** via separate Scene-Variants (`hud_mobile.tscn`) und Auto-Switch basierend auf Screen-Size

## 10. Input-System

`project.godot` → InputMap definiert:

| Action | Default-Bindings |
|---|---|
| `click_cell` | Linke Maustaste / Touch / A-Button (Controller) |
| `confirm` | Enter / A-Button |
| `cancel` | Escape / B-Button |
| `tab_next` | RB / R1 / Tab |
| `tab_prev` | LB / L1 / Shift+Tab |
| `pause` | P / Start-Button |
| `quick_save` | F5 |
| `nav_up` / `down` / `left` / `right` | Pfeiltasten + D-Pad + Stick |

Steam Input API über GodotSteam → `Steam.activateActionSet()` für Big-Picture-Modus.

## 11. Localization-System

- **CSV-Tabelle** `localization/strings.csv` (Godot importiert nativ als Translation)
- **Schlüssel-Konvention:** `domain.subdomain.id` (z. B. `upg.a1.name`, `ach.click100.desc`)
- **`tr(key)`** überall in UI-Code statt Hardcode-Strings
- **Fallback:** Englisch, falls Schlüssel in gewählter Sprache fehlt
- **CJK-Fonts** als Fallback-Cascade im Theme

```csv
keys,en,de,fr,es,it,pt_BR,ru,ja,zh_Hans,zh_Hant,ko
upg.a1.name,"Mitochondria","Mitochondrien","Mitochondries","Mitocondrias","Mitocondri","Mitocôndrias","Митохондрии","ミトコンドリア","线粒体","粒線體","미토콘드리아"
```

## 12. Audio-System

### Bus-Struktur (`default_bus_layout.tres`)

```
Master
├── Music         (Slider: Music-Volume)
├── SFX           (Slider: SFX-Volume)
│   ├── Click
│   ├── UI
│   └── Stage
└── Ambient       (Slider: Ambient-Volume, optional separat von Music)
```

### Music-Layering

4 Layer pro Stage-Range, geloopt, Crossfade beim Stage-Wechsel:
- Drone (immer aktiv)
- Pad (ab Stage 5)
- Melody (ab Stage 12)
- Tension (ab Stage 23 und während Stage-Übergang)

Code:
```gdscript
AudioManager.set_layer_volume("pad", clamp((stage - 5) / 5.0, 0.0, 1.0))
```

### SFX-Familien

| Familie | Beispiele |
|---|---|
| Click | Standard, Crit, Goldene Zelle |
| UI | Tab-Wechsel, Buy, Cancel |
| Stage | Stage-Up Fanfare (3-Ton-Akkord, layered) |
| Ability | Photo-Activation, Adrena-Surge, Mitose-Burst, Frenzy-Sturm |
| Milestone | Doppel-Klick mit Bell |
| Ambient | Bubble, Distant-Resonance (selten, zufällig) |

Format: `.ogg` (besser komprimiert als `.wav`, in Godot nativ).

### Mastering-Target

Master-Loudness ~-16 LUFS (Standard für Spiele). True-Peak nicht über -1 dBTP. SFX gemischt damit der lauteste SFX-Trigger den Music-Layer nicht übertönt.

## 13. Steamworks / GodotSteam Spike

**Spike-Ticket** (zu erledigen vor Vertical Slice):

| Feld | Wert |
|---|---|
| Ziel | Validieren, dass GodotSteam (oder GDExtension-Alternative) mit AppID 480 (Spacewar) funktioniert |
| Aufgaben | (1) GodotSteam-Repo klonen, README folgen. (2) Prüfen ob Standard-Godot-Build genügt oder eigener Engine-Build nötig ist — **erst nach dieser Prüfung** Entscheidung treffen. (3) Steam-Init-Call ausführen, Username loggen. (4) Test-Achievement triggern (Spacewar hat eingebaute Test-Achievements). (5) Test-Datei in Steam Cloud schreiben + von zweitem Gerät lesen. |
| Akzeptanzkriterium | Spacewar-Test läuft auf Win + Linux. Achievement triggered und ist im Steam-Profil sichtbar. Cloud-Save-Datei erscheint auf zweitem Gerät innerhalb 60 s. |
| Risiko | GodotSteam erfordert eventuell selbst-gebauten Godot-Build (über GDExtension-Modus ist es heute typischerweise vermeidbar, aber **nicht garantiert** — Spike klärt das). Falls eigener Build nötig: 1-Tage-Setup-Aufwand. Falls GDExtension reicht: 2 Stunden. |
| Aufwand | 6–10 Stunden |

**Wichtig:** Wir formulieren GodotSteam-Integration NICHT als „eigener Engine-Build erforderlich" — das ist nicht bewiesen. Die GDExtension-Variante ist die bevorzugte Annahme; Spike validiert.

## 14. Build-Pipeline

### CI: GitHub Actions

`.github/workflows/build.yml`:

```yaml
name: Build
on:
  push:
    branches: [main, develop]
  workflow_dispatch:

jobs:
  build:
    strategy:
      matrix:
        target: [windows, linux, macos]
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true
      - name: Install Godot 4.x
        run: |
          curl -L https://github.com/godotengine/godot/releases/download/4.x.x-stable/Godot_v4.x.x-stable_linux.x86_64.zip -o godot.zip
          unzip godot.zip
      - name: Install Export Templates
        run: # ...
      - name: Export
        run: ./ci/build_${{ matrix.target }}.sh
      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: build-${{ matrix.target }}
          path: build/

  upload-steam:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-22.04
    steps:
      - name: Download all builds
        uses: actions/download-artifact@v4
      - name: Upload via SteamCMD
        env:
          STEAM_USERNAME: ${{ secrets.STEAM_USERNAME }}
          STEAM_PASSWORD: ${{ secrets.STEAM_PASSWORD }}
        run: ./ci/upload_steamcmd.sh unstable
```

### Steam-Branches

| Branch | Verwendung |
|---|---|
| `default` | Live für Spieler |
| `beta` | Public-Beta-Branch (Opt-In im Steam-Client) |
| `unstable` | CI-Builds, intern für QA |
| `hotfix` | Notfall-Branch für Day-0-Fixes |

### Lokal-Build

`./ci/build_<target>.sh` ist standalone, läuft auch lokal für Testing.

## 15. Crash-/Error-Reporting

- **Sentry SDK für Godot** (Community-Plugin oder GDExtension)
- Auto-Capture: alle `push_error()`-Calls, alle Script-Exceptions
- **Opt-in im First-Run-Dialog**, DSGVO-konform
- Sentry-DSN als Build-Time-Konstante (Env-Variable)
- Privacy: keine personenbezogenen Daten, nur Stack-Traces + Game-Version + OS

## 16. Testing-Strategie

| Test-Typ | Tool | Coverage-Ziel |
|---|---|---|
| Unit | GUT (Godot Unit Test Framework) | Economy-Math, Save-Migrations, Data-Loader, Milestone-Logic |
| Integration | GUT mit Headless-Scene-Loading | Save→Load→Verify-Cycles, Stage-Transition-Pipeline |
| Smoke | Manuell via `qa/smoke-test.md` | 15 min Vollspiel-Walkthrough, alle Tabs, Settings, Save/Load |
| Performance | Godot Profiler + In-Game-FPS-Counter | Min 60 fps auf Min-Spec (Steam Deck, Pixel 6a) |
| Save Stress | Eigenes Script `tools/stress_save.gd` | 1000× Save/Load/Modify ohne Datenverlust |
| QA-Matrix | Manuell | siehe Phase 4 QA-Matrix in `production/phase-1-backlog.md` (Phase-4-Sektion) |

CI führt Unit + Integration bei jedem Push aus. Smoke + Performance vor jedem Release.
