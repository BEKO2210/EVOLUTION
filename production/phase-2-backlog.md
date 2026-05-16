# Phase 2 — Vertical Slice Backlog

**Phase-Ziel:** Erste 5 Stages in **Shipping-Qualität** — Steam-Next-Fest-Demo-tauglich, Trailer-Material-tauglich, "wird das schon released?" als Default-Reaktion.

**Dauer:** 8–12 Wochen (15–20 h/Wo solo) bis 4–6 Wochen (Team 2–3 Personen). Quelle: `docs/02-gdd.md` Sektion 7.

**Phase-1-Vorbedingung:** ✅ erfüllt. Engine-Prototyp ist code-complete, alle Game-Systeme laufen, Tests grün. Siehe `docs/phase-1-completion-report.md`.

Jedes Ticket folgt demselben Schema wie Phase 1: Ziel · Aufgaben · Akzeptanzkriterium · Risiko · Aufwand.

---

## Block A — Visual Polish (P2-001 … P2-008)

### P2-001 — Final Theme + Brand-Konsistenz

**Ziel:** `theme/main_theme.tres` als zentrale Style-Quelle. Alle UI-Komponenten beziehen Farben/Fonts daraus statt aus per-Knoten-Overrides.

**Aufgaben:**
- `theme/main_theme.tres` mit Style-Boxes für PanelContainer, Button, Label, ScrollContainer
- Brand-Farben aus `docs/03-art-bible.md` zentralisieren (`#00ffa3` accent green, `#ffd24a` gold, `#4fd1ff` cyan, `#ff5da2` crit-pink, `#05070d` BG)
- Custom Font einbinden (Inter / Noto Sans als Eigenproduktions-Fallback, kostenlose Open-Source-Lizenz)
- Alle bestehenden `theme_override_colors` aus den UI-Scenes entfernen, nur Theme nutzen

**Akzeptanz:** Editor → main_theme.tres öffnen → alle Farben/Fonts dort ändern → wirkt sofort überall.
**Risiko:** Theme-Hierarchien können tricky sein bei nested Controls. Mitigation: nicht zu tief verschachteln.
**Aufwand:** 6 h

### P2-002 — Tab-Bar-Polish

**Ziel:** Tabs sehen aus wie im HTML-Prototyp Wave 1: SVG-Icons + animierte Underline + Hover-Lift.

**Aufgaben:**
- 5 SVG-Icons importieren (oder als TextureRect mit Custom SVG-Source)
- `tab_controller.gd` → TabContainer durch Custom-Tab-Bar ersetzen (HBoxContainer mit eigenen TabButton-Nodes)
- Animated Underline beim Tab-Wechsel (Tween, spring-easing)
- Hover-Lift via theme + AnimationPlayer

**Akzeptanz:** Tab-Wechsel sieht aus wie HTML-Wave-1, animierte Underline springt rüber.
**Risiko:** TabContainer ist Godot-Native, eigene Implementation muss Pre/Next-Tab-Navigation für Controller selbst lösen.
**Aufwand:** 8 h

### P2-003 — UpgradeCard-Polish

**Ziel:** Cards haben Glow bei Affordability, Press-Squish, Milestone-Burst, smoothe Count-Updates.

**Aufgaben:**
- Glow-Animation auf affordable Card (subtle, AnimationPlayer)
- Press-Squish (Tween scale 0.95 → 1.0 in 100ms)
- Milestone-Burst: bei 10/25/50/100 → Particle2D + Sound
- Cost-Label updates animiert (tween statt set_text)

**Akzeptanz:** Buying eines Upgrades fühlt sich "knackig" an, visuelles Feedback kommt zeitgleich mit dem Klick.
**Risiko:** Particle2D-Performance bei 30+ Cards. Mitigation: Particle nur bei Milestone, nicht jeder Buy.
**Aufwand:** 6 h

### P2-004 — HUD-Polish

**Ziel:** DNA/DPS/Click-Power-Werte animieren beim Update statt hart zu springen.

**Aufgaben:**
- Number-Tween-Komponente (`scripts/ui/animated_number.gd`)
- Bei Stage-Up: HUD-Stage-Label kurz pulsiert (glow + scale)
- Brand-Color-Coding konsistent (DNA grün, DPS dim, Click cyan, Stage gold)

**Akzeptanz:** Klicken sieht aus wie DNA-Werte "fließen" hoch, nicht springen.
**Risiko:** Bei sehr hohen Werten wird Tween-Animation zu schnell. Mitigation: Lerp-Speed proportional zur Differenz.
**Aufwand:** 4 h

### P2-005 — Stage-Up Cinematic

**Ziel:** Stage-Wechsel ist ein **Moment**, nicht nur eine Zahl die hochspringt.

**Aufgaben:**
- `scenes/ui/popups/stage_up_popup.tscn` — Modal-Popup mit großem Stage-Namen
- Fade-In 0.3s, Hold 1.5s, Fade-Out 0.5s
- Sound-Trigger (3-Ton-Akkord aus Audio-Bible)
- Subscribed `GameState.stage_changed`
- "Weiter spielen"-Button (oder Auto-Dismiss nach 2s)

**Akzeptanz:** Stage-Up von 4 → 5 löst Popup mit "Prokaryot" aus, Sound, dann verschwindet's.
**Risiko:** Modal-Popup über Game-State darf logic-tick nicht pausieren. Already covered: TickSystem Logic-Tick ist `PROCESS_MODE_ALWAYS`.
**Aufwand:** 5 h

### P2-006 — Click-FX-Layer

**Ziel:** Klicken erzeugt Visual-Feedback wie im HTML-Prototyp (Float-Text, Ripple, Burst).

**Aufgaben:**
- `scenes/fx/float_text.tscn` — Label das nach oben fade-out tweent
- `scenes/fx/ripple.tscn` — Circle scale-up + fade-out
- `scenes/fx/click_burst.tscn` — kleine CPUParticles2D
- FX-Manager subscribes `ClickSystem.click_landed` und spawnt FX an `screen_pos`
- Crit + Milestone-Variation (größer, anderer Color)

**Akzeptanz:** Jeder Klick triggert Float-Text "+1 DNA" der nach oben fade-out, Ripple, kleiner Burst.
**Risiko:** Object-Pool nötig bei vielen Klicks/Sek. Mitigation: max 10 FX gleichzeitig.
**Aufwand:** 8 h

### P2-007 — Stage-Visuals (BioNexus-Variation Stage 1–5)

**Ziel:** Jede der ersten 5 Stages hat einen visuell unterscheidbaren Look (Farbe, Cell-Form, Hintergrund-Tönung).

**Aufgaben:**
- Erweiterung `scripts/cell/bionexus.gd` `STAGE_TARGETS` mit Color-Membrane pro Stage
- Background-Color-Lerp pro Stage (Subtle Tönung)
- Pro Stage 1–5 ein eigener "Identitäts-Frame" für Marketing-Screenshots
- Cluster-Layout-Variation: Stage 1 = ein Cell, Stage 5 = Mitose-Cluster (~30 Cells)

**Akzeptanz:** Side-by-Side Screenshot Stage 1 vs Stage 5 zeigt sofort dass das andere Stages sind.
**Risiko:** Visuell Vielfalt vs Brand-Konsistenz. Mitigation: nur Membrane-Hue varieren, Organ-Farbe + Glow gleich.
**Aufwand:** 6 h

### P2-008 — Post-Processing (Bloom + Vignette)

**Ziel:** Cell-Visual hat das "Mikroskop"-Gefühl aus dem HTML-Prototyp.

**Aufgaben:**
- `scenes/cell/bionexus.tscn` SubViewport → Environment-Resource mit Bloom + Vignette
- Bloom-Intensity 0.4–0.8 (subtle, nicht overdone)
- Vignette dark edges für "Mikroskop-Tunneling"-Effekt
- WorldEnvironment-Node konfigurieren

**Akzeptanz:** Cell strahlt sanft, Bildrand ist dunkler getönt → das Bild hat Tiefe.
**Risiko:** Performance auf Steam Deck bei Bloom. Mitigation: Quality-Preset, Bloom off im Low-Preset.
**Aufwand:** 4 h

---

## Block B — Audio (P2-009 … P2-011)

### P2-009 — AudioManager echte Implementation + Bus-Layout

**Ziel:** Stub aus P1-002 ersetzen durch funktionierenden AudioManager mit Bus-Routing.

**Aufgaben:**
- `default_bus_layout.tres` mit Master → Music / SFX / Ambient
- `audio_manager.gd` mit AudioStreamPlayer-Pool (für Polyphonie)
- `play_sfx(id)` lädt aus `assets/audio/sfx/<id>.ogg`
- Volume-Slider aus Settings-Menü routet auf Bus-Volume
- Mute-on-Tab-Hidden via WindowEvent

**Akzeptanz:** `AudioManager.play_sfx("click_standard")` spielt ein WAV ab.
**Risiko:** OGG-Decoding-Performance auf Mobile. Mitigation: kurze SFX als WAV, Music als OGG.
**Aufwand:** 6 h

### P2-010 — SFX-Familie für Slice

**Ziel:** 8–12 SFX produziert + integriert: Click (3 Varianten), Buy, Stage-Up, Crit, Milestone, Ambient (zufällig).

**Aufgaben:**
- Eigenproduktion in Reaper/Audacity ODER kostenlose Lizenz aus freesound.org / soniss
- Mastering ~-16 LUFS (siehe Audio-Bible)
- Loops + One-Shots strukturiert in `assets/audio/sfx/`
- Wiring via ClickSystem-Signal-Subscriber + manuelle Trigger im UI

**Akzeptanz:** Jeder Klick, Kauf, Stage-Up hat Sound. Audio-Mix ist nicht laut/nervig.
**Risiko:** Lizenz-Compliance. Mitigation: Eigenproduktion oder klar CC0-lizenzierte Samples, alles in ATTRIBUTIONS.md.
**Aufwand:** 8 h (mit Eigenproduktion) bis 4 h (mit fertigen Samples)

### P2-011 — Adaptive Musik-Layer

**Ziel:** 4-Layer-Musik aus Audio-Bible (Drone, Pad, Melody, Tension), kreuz-faded bei Stage-Wechsel.

**Aufgaben:**
- 4 Music-Tracks gleicher Länge (Loop-fähig), eigenproduziert oder beauftragt
- `AudioManager.set_music_intensity(stage)` lerp-t Layer-Volumes
- Crossfade bei Stage-Up automatisch
- Volume-Slider in Settings

**Akzeptanz:** Stage 1 = nur Drone. Stage 3 = Drone + Pad. Stage 5 = +Melody. Kein hartes Audio-Cut beim Wechsel.
**Risiko:** Eigenproduktion 4 stundenlanger Tracks ist Skill-intensiv. Mitigation: bis Komponist beauftragt, Placeholder-Drones aus freesound.org.
**Aufwand:** 12 h (Eigenproduktion) bis 4 h (Integration nur, Tracks von Komponist)

---

## Block C — UX (P2-012 … P2-015)

### P2-012 — Onboarding-Sequenz (3-Step FTUE)

**Ziel:** First-Time-User-Experience führt neue Spieler an die Core-Loop ohne Wall-of-Text.

**Aufgaben:**
- Step 1 (boot): "Klicke die Zelle" Hint-Arrow auf KLICK-Button
- Step 2 (nach 5 Klicks): "Du hast DNA! Öffne den Auto-Tab" Hint
- Step 3 (nach erstem Kauf): "Mitochondrien produzieren DNA für dich. Erreiche Stufe 2." Hint
- `scripts/ui/onboarding.gd` als Autoload, Schritte gespeichert in GameState
- Persistent: einmal abgeschlossen, nie wieder

**Akzeptanz:** Frischer Save → 3 Hints führen Tester durch erste 30 Sekunden. Skip-Button.
**Risiko:** Hint-Arrows können tricky positioniert sein bei verschiedenen Auflösungen. Mitigation: relative Positionierung an Target-Node.
**Aufwand:** 6 h

### P2-013 — Tooltip-System

**Ziel:** Hover (Desktop) und Long-Press (Mobile) zeigen Tooltips für Upgrades/Buttons/HUD-Werte.

**Aufgaben:**
- `scripts/ui/tooltip.gd` Singleton
- `scenes/ui/tooltip.tscn` Floating-Label-Scene
- Per-Node `tooltip_text` Custom-Property
- Mouse-Hover-Detection + Long-Press-Timer (500ms)
- Mobile: Touch-Long-Press-Detection

**Akzeptanz:** Hover über UpgradeCard → Tooltip zeigt Detail-Beschreibung + Multiplier-Breakdown.
**Risiko:** Tooltip muss Bildschirm-Rand respektieren (Cliping). Mitigation: dynamic position mit Margin.
**Aufwand:** 5 h

### P2-014 — Settings-Menü v1

**Ziel:** Spieler kann Volume / Quality / Reduce-Motion / Sprache / Save-Export ändern.

**Aufgaben:**
- `scenes/ui/popups/settings.tscn` als Popup
- Sliders für Master / Music / SFX (drei separate Buses)
- Dropdown für Quality-Preset (Low / Medium / High / Ultra)
- Checkbox Reduce-Motion (deaktiviert nicht-essentielle Animationen)
- Sprach-Dropdown (Stub für Phase 3, nur DE+EN aktiv)
- Save-Export-Button → File-Picker → schreibt Save als .json
- Persistent via GameState.settings

**Akzeptanz:** Settings öffnen, Music-Volume auf 50% → Music wird leiser. Reload → Slider erinnert sich.
**Risiko:** File-Picker-API unterschiedlich Win/Linux/macOS. Mitigation: Godot FileDialog (cross-platform).
**Aufwand:** 8 h

### P2-015 — Confirm-Dialoge

**Ziel:** Prestige + Hard-Reset fragen vorher nach.

**Aufgaben:**
- `scenes/ui/popups/confirm_dialog.tscn` (wiederverwendbar)
- Prestige-Button öffnet Dialog: "Du verlierst X DNA, gewinnst Y EP. Sicher?"
- Hard-Reset-Button öffnet Dialog: "ALLES wird gelöscht. SICHER?"

**Akzeptanz:** Prestige ohne Dialog nicht mehr möglich. Cancel-Button funktioniert.
**Risiko:** -
**Aufwand:** 3 h

---

## Block D — Steam-Integration scharf (P2-016 … P2-018)

### P2-016 — GodotSteam-Plugin installieren

**Ziel:** P1-012-Spike scharf schalten. Plugin-Binaries ins Repo, gegen Spacewar testen.

**Aufgaben:**
- GodotSteam GDExtension Release herunterladen (kompatibel mit Godot 4.3-stable)
- Steamworks SDK Redistributables (Win/Linux/macOS) herunterladen
- `addons/godotsteam/` einrichten (siehe `docs/steam/godotsteam-setup.md`)
- `steam_appid.txt` (Spacewar 480, ist in `.gitignore`)
- Editor öffnen, GodotSteam-Init-Message bestätigen
- `scenes/dev/steam_smoke_test.tscn` ausführen, alle 5 Buttons testen

**Akzeptanz:** Smoke-Test "Steam Init OK" + Achievement im Steam-Profil sichtbar + Cloud-Save sync 2 Geräte <60s.
**Risiko:** Plattform-spezifische Library-Probleme. Mitigation: pro Plattform einmal lokal testen.
**Aufwand:** 4 h (Plugin-Setup) + 2 h (Real-Verifikation)

### P2-017 — 5 Achievements live + Cloud-Save aktiv

**Ziel:** Echte Achievement-Trigger im Steam-Backend für die ersten 5 Achievements.

**Aufgaben:**
- Steam Partner Backend → 5 Achievement-IDs definieren (passen zu data/achievements.json)
- Icons hochladen (64×64 + 256×256 PNG)
- `AchievementSystem._on_unlock` ruft `SteamAPI.set_achievement(id)`
- Cloud-Save-Schreiben in `SaveSystem.save(SLOT_CLOUD)` ruft `SteamAPI.cloud_save_text`
- Manueller Test: 10 Klicks → click10-Achievement triggert in Steam

**Akzeptanz:** Click10-Achievement-Toast erscheint im Steam-Overlay nach 10 Klicks. Cloud-Save synct.
**Risiko:** Steam-Achievement-Backend braucht Approval pro Achievement (langsam für Production-AppID). Mitigation: Spacewar reicht für Phase 2, Production-IDs in Phase 5.
**Aufwand:** 6 h

### P2-018 — Steam Input Action Sets (Controller-Support)

**Ziel:** Spiel komplett mit Xbox-Controller oder DualSense bedienbar.

**Aufgaben:**
- `project.godot` InputMap mit allen Actions (click, nav_*, confirm, cancel, prestige, pause, tab_next, tab_prev)
- Steam Input via GodotSteam.activateActionSet
- Glyphs für Controller im UI anzeigen (z.B. "Drücke (A) zum Klicken")
- Test mit Xbox-Controller + DualSense

**Akzeptanz:** Maus + Tastatur weg, nur Controller. Spiel komplett durchspielbar inklusive Settings.
**Risiko:** Tabs-Navigation via Controller ist tricky in Godot. Mitigation: Focus-Mode Explicit + TabContainer.focus_neighbor.
**Aufwand:** 6 h

---

## Block E — Mobile + Build (P2-019 … P2-021)

### P2-019 — Mobile Touch-Layout (Portrait + Landscape)

**Ziel:** Spiel funktioniert auf Phone (Portrait + Landscape).

**Aufgaben:**
- Responsive Layout: VBox vs HBox bei Portrait vs Landscape
- Touch-Target-Audit (Buttons min 44×44 dp)
- Long-Press statt Hover für Tooltips (P2-013 erledigt)
- Test auf Android Device (Pixel 6a oder besser)

**Akzeptanz:** Spiel läuft + ist bedienbar auf 6"-Phone in Portrait + Landscape.
**Risiko:** UI-Reorganisation komplex. Mitigation: Container-Anchors statt absolute Positionierung.
**Aufwand:** 8 h

### P2-020 — Build-Pipeline (GitHub Actions)

**Ziel:** CI baut alle Plattform-Builds bei jedem Push auf `main`.

**Aufgaben:**
- `.github/workflows/build.yml` mit Matrix (windows/linux/macos/android)
- Godot-CI-Container nutzen (z.B. `barichello/godot-ci`)
- Build-Artifacts hochladen
- Optional: Release-Action bei Tag

**Akzeptanz:** Push auf `main` → 5 Min später Artifacts in Actions-Tab.
**Risiko:** macOS-Builds brauchen macOS-Runner ($$). Mitigation: macOS-Build manuell auf lokalem Mac, CI nur Win+Linux+Android.
**Aufwand:** 6 h

### P2-021 — SteamCMD-Upload-Script

**Ziel:** Builds automatisch in den `prerelease`-Branch im Steam-Partner-Backend.

**Aufgaben:**
- `ci/upload_steamcmd.sh` Script mit SteamCMD-Auth (Token via GitHub Secrets)
- 3 Steam-Branches anlegen: `default`, `beta`, `prerelease`, `hotfix`
- VDF-Manifest-Files für jede Plattform
- Manual-Trigger via Workflow-Dispatch

**Akzeptanz:** Manueller GH-Actions-Trigger → Build erscheint auf `prerelease`-Branch in Steam.
**Risiko:** Steam-Guard-2FA blockiert Auto-Upload. Mitigation: Dedicated Build-Account ohne 2FA oder steam_guard_codes-File.
**Aufwand:** 6 h

---

## Block F — Marketing-Assets (P2-022 … P2-023)

### P2-022 — Marketing-Screenshots (8 Stück, 1920×1080)

**Ziel:** Steam-Store-Page-Screenshots aus dem polierten Slice.

**Aufgaben:**
- Build starten, manuell zu jedem Stage 1–5 spielen
- 8 Screenshots aufnehmen: Hero-Shot (Stage 1), Stage-2-Übergang, Mid-Game (Stage 3), Stage-Up-Cinematic, voller Tab "Auto" mit allen Cards, Meta-Tab mit Stats, Achievement-Unlock-Moment, Klick-FX in Aktion
- Post-Processing in GIMP/Photoshop wenn nötig (Crop, kleines Logo)
- In `assets/steam/screenshots/` ablegen

**Akzeptanz:** 8 PNGs in 1920×1080, alle echtes Gameplay, alle visuell konsistent.
**Risiko:** Screenshots "verfälschen" vs Real-Gameplay (Steam-Policy). Mitigation: nur Real-Frames nutzen.
**Aufwand:** 4 h

### P2-023 — Vertical-Slice-Trailer (60–90s)

**Ziel:** Trailer-Master für Steam-Page (kann später updated werden).

**Aufgaben:**
- Storyboard (siehe `docs/08-steam-marketing-plan.md` Sektion 5)
- Screen-Recording während gespieltem Slice (OBS)
- Music-Track im Hintergrund (aus P2-011 oder royalty-free)
- Cut in DaVinci Resolve / Shotcut (kostenlose Editors)
- Hook in den ersten 5s (Auto-Play startet stumm)
- 1080p H.264 MP4

**Akzeptanz:** 60–90s Trailer-Datei, exportable in Steam-Store-Page.
**Risiko:** Video-Editing-Aufwand. Mitigation: einfacher Schnitt, Visuals tragen sich selbst, keine Story-Sequenz nötig.
**Aufwand:** 12 h

---

## Phase-2-Aufwand-Summe

| Block | Tickets | Aufwand |
|---|---|---|
| A — Visual Polish | 8 | ~47 h |
| B — Audio | 3 | ~26 h |
| C — UX | 4 | ~22 h |
| D — Steam-Integration scharf | 3 | ~24 h |
| E — Mobile + Build | 3 | ~20 h |
| F — Marketing-Assets | 2 | ~16 h |
| **Σ** | **23** | **~155 h** |

Bei 15–20 h/Wo solo: **~10 Wochen** Phase 2.
Bei 30–40 h/Wo: **~5 Wochen**.
Team 2–3 Personen: **~3–4 Wochen** (Audio + Visual parallel).

---

## Phase-2-Akzeptanz

Aus `production/definition-of-done.md`:

- Eine Testperson spielt den Slice 20+ Minuten am Stück freiwillig durch
- Niemand fragt „ist das schon Beta?"
- Steam Deck: 60 fps, Battery-Drain in normalem Range
- Save funktioniert Cross-Device (Cloud)

**Plus:** Marketing-Material (Screenshots + Trailer) ist Steam-Store-tauglich produziert.

---

## Reihenfolge-Empfehlung

Nicht streng linear — manche Tickets sind parallel:

1. **P2-001** (Final Theme) → Grundlage für allen folgenden Visual-Polish
2. **P2-009** (AudioManager echt) → Grundlage für alle Audio-Tickets
3. **P2-002 + P2-003 + P2-004** (Tab/Card/HUD-Polish) → können parallel laufen
4. **P2-006** (Click-FX-Layer) → standalone, parallel
5. **P2-014** (Settings-Menü) → blockt nichts, früh angehen
6. **P2-007 + P2-008** (Stage-Visuals + Post-FX) → BioNexus-Polish
7. **P2-005** (Stage-Up Cinematic) → braucht Audio-Familie (P2-010) zumindest für Stage-Up-Fanfare
8. **P2-010 + P2-011** (SFX + Musik) → kann später kommen wenn Komponist liefert
9. **P2-012 + P2-013 + P2-015** (Onboarding + Tooltip + Confirm) → UX-Block, vor Marketing
10. **P2-016 + P2-017 + P2-018** (Steam scharf + Achievements + Controller) → Mid-Phase-2
11. **P2-019 + P2-020 + P2-021** (Mobile + Build + SteamCMD) → Vorbereitung für Phase 3/4
12. **P2-022 + P2-023** (Marketing-Assets) → letzte Phase-2-Wochen, brauchen alle visuellen Polish-Tickets

---

## Was Phase 2 absichtlich NICHT abdeckt

- Stages 6–30 (nur die ersten 5 sind in Vertical-Slice-Qualität — Rest bleibt Greybox bis Phase 3 / Alpha)
- Research-Effekt-Wiring (Multiplier-Chain-Refactor) → Phase 3 / Alpha
- Mutationen, Goldene Zellen, DNA-Drops als Random-Events → Phase 3
- Codex / Lore → Phase 3
- Localization (>2 Sprachen) → Phase 3
- Skill-Tree → Phase 3
- Save-Slot-Picker-UI (multiple Slots) → Phase 3
- Telemetrie-Backend → Phase 3
- Production-Steam-AppID → Phase 5

Phase 2 ist **eine vertikale Scheibe**, nicht "Phase 1 ÷ 5 schöner machen".
