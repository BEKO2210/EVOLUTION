# GodotSteam Setup

Schritt-für-Schritt-Anleitung um GodotSteam GDExtension in dieses Projekt zu integrieren. **Folge dieser Anleitung erst wenn du tatsächlich Steam-Features bauen / testen willst** — Phase 1 hat alle Hooks bereits no-op-safe vorbereitet, das Spiel läuft komplett ohne diese Schritte.

Architekturentscheidung dahinter: siehe `docs/decisions/ADR-0005-godotsteam-integration.md`.

---

## Voraussetzungen

- Godot 4.3-stable installiert (Standard-Binary von godotengine.org — **kein** Custom-Build nötig)
- Steamworks-Partner-Account angelegt (für eigene AppID — für reinen Test reicht Spacewar AppID 480, das ist Steams öffentliche Test-AppID)
- Steam-Client lokal installiert + eingeloggt
- ~5 Minuten Zeit pro Plattform die du unterstützen willst

---

## Schritt 1: GodotSteam GDExtension herunterladen

1. Gehe zu https://github.com/CoaguCo-Industries/GodotSteam/releases
2. Lade das aktuelle **GDExtension Release** für deine Plattform(en) (z.B. `godotsteam-gdextension-v4.13-godot4.3-stable.zip`)
3. Entpacke die ZIP — du bekommst einen `addons/godotsteam/` Ordner

**Wichtig:** wir brauchen die **GDExtension**-Variante, NICHT die Module-/Engine-Build-Variante.

## Schritt 2: Steamworks SDK herunterladen

1. Login bei https://partner.steamgames.com → Steamworks SDK Download
2. Die ZIP enthält `tools/`, `redistributable_bin/`, etc. — wir brauchen nur die **redistributable** Libraries:
   - **Windows 64-bit:** `redistributable_bin/win64/steam_api64.dll`
   - **Linux 64-bit:** `redistributable_bin/linux64/libsteam_api.so`
   - **macOS (Intel + ARM, universal):** `redistributable_bin/osx/libsteam_api.dylib`

## Schritt 3: Files in das Projekt-Repo legen

```
EVOLUTION/
└── addons/
    └── godotsteam/
        ├── godotsteam.gdextension          ← Manifest, definiert wo die Libraries liegen
        ├── godotsteam.gd                    ← GDScript bindings (vom Release)
        ├── win64/
        │   ├── godotsteam.windows.template_release.x86_64.dll
        │   └── steam_api64.dll              ← aus Steamworks SDK
        ├── linux64/
        │   ├── godotsteam.linuxbsd.template_release.x86_64.so
        │   └── libsteam_api.so              ← aus Steamworks SDK
        └── macos/
            ├── godotsteam.macos.template_release.framework/
            └── libsteam_api.dylib           ← aus Steamworks SDK
```

(Die genauen Filenamen können sich zwischen GodotSteam-Releases minimal ändern — folge dem README im heruntergeladenen Plugin.)

## Schritt 4: Editor neu öffnen

1. Schließe Godot wenn offen
2. Öffne das Projekt wieder
3. Im Output-Tab sollte folgende Zeile erscheinen:
   ```
   GodotSteam: Initialized as GDExtension (version X.YZ)
   ```
   
Wenn nicht: `addons/godotsteam/godotsteam.gdextension` öffnen und prüfen ob die Pfade zu den Libraries für deine Plattform stimmen.

## Schritt 5: AppID anlegen

1. Im Projekt-Root: `steam_appid.txt` mit einer einzigen Zeile:
   ```
   480
   ```
   (Das ist Spacewar — Steams offizielle Test-AppID. Für Production-Build ersetzt durch unsere echte AppID.)
2. Diese Datei ist **per `.gitignore` ausgeschlossen** (steht schon drin) damit nicht versehentlich unsere Production-AppID in einen Public-Branch landet.

## Schritt 6: Steam Client läuft

GodotSteam braucht den lokalen Steam-Client als Backend. Stelle sicher dass Steam offen und du eingeloggt bist, BEVOR du das Spiel startest.

## Schritt 7: Smoke Test

1. Öffne `scenes/dev/steam_smoke_test.tscn` im Godot Editor
2. F6 (Play scene)
3. Du solltest sehen:
   - "Steam Init: OK"
   - "User: <dein Steam-Display-Name>"
   - "AppID: 480"

Wenn nicht: Output-Tab inspizieren. Häufigste Probleme:
- "Steam not running" → Client starten
- "AppID missing" → `steam_appid.txt` fehlt im Projektroot
- "Library load failed" → falsche `.dll`/`.so`/`.dylib`-Architektur für deine Plattform

## Schritt 8: Achievement testen

In der Smoke-Test-Scene: **"Test Achievement triggern"** Button drücken. Du solltest:
- Steam-Overlay-Popup links unten "Spacewar — Achievement freigeschaltet"
- Im Steam-Profil → Spacewar → Achievements: das neue Achievement sichtbar

## Schritt 9: Cloud Save testen

1. **"Cloud Save schreiben"** Button drücken → schreibt Testdatei in Steam Cloud
2. **Auf zweitem Gerät:** Steam-Client → Spacewar → Spielen → Smoke-Scene öffnen → **"Cloud Save lesen"**
3. Der gleiche Inhalt sollte erscheinen (Sync-Zeit typisch 5–60 s)

---

## Phase-spezifisches

### Während Phase 1 (jetzt)

GodotSteam ist **nicht** installiert. `steam_api.gd` no-op't alle Calls (`SteamAPI.is_available == false`). Alle Tests laufen ohne Steam-Runtime.

### Während Phase 2 (Vertical Slice)

GodotSteam wird auf dem Dev-Rechner installiert für Real-Test der Marketing-Material-Aufnahmen. Test-AppID Spacewar 480 ausreichend.

### Während Phase 5 (Release-Prep)

GodotSteam läuft mit unserer echten AppID. Achievements sind im Steam-Partner-Backend definiert. Cloud-Save-Pfade konfiguriert. Steam Input Action Sets gepflegt. Test-Matrix:
- Win + Linux + macOS Builds
- Cloud-Save zwischen 2 echten Geräten
- Steam Deck Verified Self-Test (siehe `steam-deck-checklist.md`)

---

## Wartung

- Steam Cloud Datei-Quota: 1 GB pro App. Unsere Saves sind <50 KB → kein Limit-Risiko.
- GodotSteam Releases: alle 1–3 Monate. Update-Prozess: nur die `addons/godotsteam/`-Files austauschen, Library-Files nicht. Pin-Version in `docs/decisions/ADR-0005-godotsteam-integration.md` aktualisieren.
- Steamworks SDK Updates: rare (1× pro Jahr typisch). Sicherheitsrelevant — immer einspielen.
