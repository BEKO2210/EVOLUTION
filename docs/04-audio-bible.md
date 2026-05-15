# 04 — Audio Bible

**Status:** Phase 0 Draft v0.1

---

## 1. Audio-Vision

Ambient. Wissenschaftlich. Niemals aggressiv. Audio ist atmosphärischer Hintergrund + funktionales Feedback, nicht Aufmerksamkeits-Magnet. Lautstärke-Profil: das Spiel kann mit halber Lautstärke gespielt werden, ohne dass Information verloren geht.

## 2. Genre-Referenzen

| Referenz | Was wir übernehmen | Was wir vermeiden |
|---|---|---|
| **FTL: Faster Than Light** (Ben Prunty) | Adaptive ambient Synth-Layer, leise Hooks | Combat-Tension nicht — wir haben keinen Combat |
| **Subnautica** (Simon Chylinski) | Mikrokosmos-Atmosphäre, organische Drone | Horror-Stings nicht — wir sind ruhig |
| **Mini Metro** (Disasterpeace) | Diegetisches Sound-Design, Generative Patterns | — |
| **Monument Valley** (Stafford Bawler) | Sanfte melodische Hooks, ruhige Übergänge | Cinematic Bombast nicht |
| **Hexcells Infinite** (Matthew Dear) | Meditative Loops, nicht-aufdringlich | — |
| **Stellaris Ambient** (Andreas Waldetoft) | Kosmische Weite, langsame Crescendi | Orchestraler Bombast nicht |

## 3. SFX-Vokabular

### Familie: Click

| ID | Beschreibung | Layer-Komponenten |
|---|---|---|
| `click_standard` | Standard-Klick auf Zelle | Soft Sub-Bass + UI-Click + leichter Reverb-Tail |
| `click_crit` | Crit-Klick | Standard + High-Pitch-Bell + Cyan-Glitter-Hi |
| `click_gold` | Gold-Cell-Klick | Standard + Chime-Cluster + Gold-Wash |

### Familie: UI

| ID | Beschreibung |
|---|---|
| `ui_tab_switch` | Tab-Wechsel — kurzer Wisch + Sub-Bass-Impuls |
| `ui_buy` | Upgrade gekauft — 2-Ton-Click-Cluster (523 Hz → 784 Hz, square wave gefiltert) |
| `ui_cancel` | Cancel/Back — Reverse-Wisch, dunkler |
| `ui_hover` | Hover (optional) — sehr leiser Soft-Click |
| `ui_popup_in` | Popup öffnet — Soft-Whoosh aufsteigend |
| `ui_popup_out` | Popup schließt — Reverse |

### Familie: Stage

| ID | Beschreibung |
|---|---|
| `stage_up` | Stage-Up Fanfare — 3-Ton-Akkord (523/659/784 Hz, sine, layered Reverb, 1.2s Tail) |
| `stage_transition` | Visuelle Transition-Begleitung — Drone-Swell + Sub-Bass-Hit |
| `stage_milestone` | Meilenstein erreicht — Soft-Bell-Cluster |

### Familie: Ability

| ID | Beschreibung |
|---|---|
| `ability_photo` | Photo-Activation — Solar-Wash + High-Pitch-Sustain |
| `ability_adrena` | Adrena — Sharp Synth-Surge, leichtes Glitch |
| `ability_mitose` | Mitose — Bass-Drop + Wet-Splash |
| `ability_frenzy` | Frenzy — Rolling-Drum-Cluster |
| `ability_ready` | Ready-Ping (subtil, optional) — kurzer Bell |

### Familie: Ambient (zufällig, alle 30–120 s ein Trigger)

| ID | Beschreibung |
|---|---|
| `ambient_bubble` | Sehr leiser Plopp |
| `ambient_drone_lo` | 4 s Sub-Drone-Pad |
| `ambient_resonance` | Distant-Bell-Schwingung |

## 4. Adaptive Musik-Layer

4 Layer pro Stage-Phase, alle geloopt, Crossfade über 4–6 s.

| Layer | Aktiv ab Stage | Charakter |
|---|---|---|
| Drone | 1 (immer) | Tiefe Sub-Bass-Pad, langsame Modulation |
| Pad | 5 | Mittlerer Synth-Pad, melodische Andeutung |
| Melody | 12 | Hohe Melodie-Linie, sparsam |
| Tension | 23 + während Stage-Up | Filter-Sweep, Atmospheric Build |

Implementierung:
```gdscript
AudioManager.set_layer_volume("drone", 1.0)
AudioManager.set_layer_volume("pad", clamp((stage - 5) / 5.0, 0.0, 1.0))
AudioManager.set_layer_volume("melody", clamp((stage - 12) / 6.0, 0.0, 1.0))
AudioManager.set_layer_volume("tension", clamp((stage - 23) / 7.0, 0.0, 1.0))
```

## 5. Komposition-Plan

| Phase | Material |
|---|---|
| Vertical Slice (Phase 2) | Drone + Pad-Layer für Stages 1–5, 1 Stage-Up Fanfare, Ability-SFX-Familie komplett |
| Alpha (Phase 3) | Alle 4 Layer komplett, 1 Stage-Up-Fanfare-Variante pro Stage-Phase (5 Varianten), volle SFX-Bibliothek |
| Beta (Phase 4) | Mastering-Pass, Lautstärke-Balance, finale Crossfade-Tuning |

## 6. Mastering-Targets

| Parameter | Wert |
|---|---|
| Integrierte Loudness | -16 LUFS (Stereo-Standard für Spiele) |
| True Peak | nicht über -1 dBTP |
| Loudness Range (LRA) | 6–10 LU (komprimiert genug für ruhige Atmosphäre) |
| Dynamic Range | dezent komprimiert, nicht gestaucht |
| Frequency Balance | leicht warm (300 Hz–3 kHz Schwerpunkt), High-End nicht aggressiv |

**SFX-Mix-Regel:** Lautester SFX-Trigger (Stage-Up) darf Music-Layer nicht übertönen. Music duckt automatisch um 3 dB für 1.5 s bei Stage-Up (Sidechain-Compression).

## 7. Lizenz-Plan

### Optionen für Music

| Option | Vor | Nach | Budget |
|---|---|---|---|
| Eigenproduktion | volle Kontrolle, keine Lizenzkosten | Zeitaufwand, Skill-Voraussetzung | 0 € |
| Komponist-Auftrag (Buy-Out) | maßgeschneidert, einmalige Lizenzkosten | Lieferzeit-Risiko | 1500–4000 € |
| Royalty-Free-Pool (z. B. Soundstripe, Artlist) | schnell, günstig | weniger Identität, Lizenzbedingungen prüfen | 100–400 € / Jahr |
| Public Domain / Creative Commons | gratis | begrenztes Material in dem spezifischen Genre | 0 € |

**Empfehlung:** Komponist-Auftrag mit Buy-Out für Identität. Alternative: Eigenproduktion mit DAW (Ableton/Reaper) falls Komponist-Budget nicht verfügbar.

### Optionen für SFX

| Option | Vor | Nach | Budget |
|---|---|---|---|
| SFX-Bibliothek (z. B. Soniss, BOOM Library) | breites Material, royalty-free | großes Sortieren, generisch | 50–200 € pro Pack |
| Eigenaufnahme + Synth | spezifisch, kostenlos | Skill + Zeit | 0 € |
| freesound.org (CC-Lizenz) | gratis, breit | Lizenz-Compliance pflegen | 0 € |

**Empfehlung:** Hybrid — Synth-SFX selbst produziert (Synth-Plugins, ggf. mit Web-Audio-API-Prototyp-SFX als Referenz), Foley-SFX aus SFX-Bibliothek.

## 8. Lokalisations-Implikationen

- **Voice-Over: keins.** Spiel ist VO-frei.
- **SFX sind sprach-neutral** — keine Lokalisations-Arbeit nötig
- **Music ist sprach-neutral** — kein Vocal in Music

## 9. Accessibility

- **Visuelles Audio-Feedback:** wichtige Events haben auch visuelles Pendant (Stage-Up = Visual + Audio, Achievement = Toast + Audio)
- **Audio-Sliders:** Master, Music, SFX separat
- **Mute-on-Background:** Audio pausiert wenn Tab/App im Hintergrund
- **Reduce-Audio-Modus** (optional, Phase 4): Stages-Up dezenter, Ambient aus

## 10. Akzeptanz-Checkliste pro Audio-Asset

- [ ] Format `.ogg` (für Music + SFX), mind. 192 kbps
- [ ] Mono falls keine Stereo-Information nötig
- [ ] Looping-Punkte gesetzt (für Music-Layer)
- [ ] Lautstärke ans Mix-Profil angepasst
- [ ] In `AudioManager.sounds` registriert mit ID + Bus-Zuordnung
- [ ] Lizenz dokumentiert in `ATTRIBUTIONS.md` (auch bei Eigenproduktion: „Eigenwerk, alle Rechte Studio")
