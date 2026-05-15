# 03 — Art Bible

**Status:** Phase 0 Draft v0.1

---

## 1. Visuelle Vision

Bio-Neon. Dunkler Mikroskop-Raum. Leuchtende Zelle als Hauptfigur. UI ist Hologramm-Overlay. Jedes visuelle Element trägt entweder Bio-Metapher oder Sci-Fi-HUD-Sprache. Niemals Cartoon, niemals Pixel-Art, niemals Realismus.

## 2. Color-Palette

### Primärfarben

| Name | Hex | RGB | Verwendung |
|---|---|---|---|
| Accent Green | `#00ffa3` | 0,255,163 | Hauptakzent, Zellmembran-Highlight, Active-States |
| Accent Cyan | `#4fd1ff` | 79,209,255 | Sekundäre Aktion, Click-Shockwave, Info-Tooltips |
| Accent Gold | `#ffd24a` | 255,210,74 | Belohnung, Goldene Zellen, Meilensteine, Affordable-Highlight |
| Crit Pink | `#ff5da2` | 255,93,162 | Crits, Danger-Buttons, Warnung |

### Hintergrund-Stack

| Name | Hex | Verwendung |
|---|---|---|
| BG 0 | `#05070d` | Tiefster Hintergrund, Mikroskop-Schwarz |
| BG 1 | `#0a0e1a` | Header/Footer, Container-Hintergrund |
| BG 2 | `#121829` | Card-Hintergrund, Tab-Hintergrund |
| Line | `rgba(255,255,255,0.07)` | Trenner, Borders |

### Text

| Name | Hex | Verwendung |
|---|---|---|
| Text | `#e6ecf3` | Primärer Text |
| Text Dim | `#7d8aa0` | Sekundärer Text, Labels, Captions |
| Text Accent | `#00ffa3` | Wichtige Zahlen (DNA-Wert, Stage) |

### Verwendungsregeln

- **Accent Green** ist die Identität — sparsam einsetzen, niemals als großflächige Hintergrundfarbe
- **Gold** nur bei tatsächlicher Belohnung oder erreichbarer Aktion (nicht dekorativ)
- **Crit Pink** nur bei Crits, Warnungen, Danger — keine Verwendung als Akzent ohne semantische Bedeutung
- **Pure White** außerhalb von Specular-Highlights vermeiden — wirkt zu hart auf dem dunklen Hintergrund

## 3. Typografie

**Primary Font:** System-UI-Stack (`-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`) im Web-Prototyp. **In Godot:** Inter (variable font, Open Source, gute Lesbarkeit klein + groß). CJK-Fallback: Noto Sans CJK (Open Source).

### Hierarchie

| Klasse | Größe | Weight | Verwendung |
|---|---|---|---|
| H1 | 1.1rem | 800 | Spielname, große Popups |
| H2 | 0.85rem | 700 | Panel-Titel, Section-Header |
| Body | 0.75rem | 400–600 | Beschreibungen, Tooltips |
| Caption | 0.6rem | 700 | Labels, Tabs, UPPERCASE |
| Mono | tabular-nums | 800 | Alle Zahlenwerte (DNA, Kosten) |

### Letter-Spacing

- UPPERCASE-Labels: `letter-spacing: 1.4px`
- Body-Text: normal
- Tabellen-Zahlen: `font-variant-numeric: tabular-nums` (gleiche Breite pro Ziffer)

## 4. Icon-Sprache

### Konventionen (aus Wave-1-Iconset etabliert)

- **viewBox:** 24×24
- **Stroke-Width:** 1.8 (line-Icons), 0 (solid)
- **Stroke-Linecap:** round
- **Stroke-Linejoin:** round
- **Geometrie:** Bio-/Sci-Fi-Sprache — Kreise, Linien, hexagonale Cluster
- **Fill:** `currentColor` oder Solid für Highlights
- **Glow:** `filter: drop-shadow(0 0 8px currentColor)` für aktive States

### Icon-Familien

| Familie | Visuelle Sprache | Beispiele |
|---|---|---|
| **Cell / Bio** | Kreise, Kerne, organische Formen | mitochondria, ribosomes, nucleus, flagella |
| **Energy** | Spitze Polygone, Blitze | bolt, lightning, adrena |
| **Science** | Geräte, Linsen, Mikroskop | microscope, flask, dna-helix |
| **Achievement** | Pokale, Sterne, Sparkles | trophy, sparkle, check |
| **Action** | Pfeile, Chevrons, Ripples | touch, frenzy, arrow |

### Verbotene Icon-Stile

- Emoji-Optik (cartoony, multi-color, OS-rendered)
- Pixel-Art
- Foto-realistisch
- Skeuomorphismus (3D-Buttons mit Glanz/Schatten)

## 5. UI-Spacing-System (8-px-Grid)

| Token | Wert | Verwendung |
|---|---|---|
| xs | 4px | Inner-Padding kleiner Elemente |
| sm | 8px | Standard Inner-Padding |
| md | 12px | Padding für Container |
| lg | 16px | Section-Spacing |
| xl | 24px | Major Section-Spacing |
| xxl | 32px | Hero-Section-Spacing |

Alle Container-Paddings, Margins, Gaps in diesen Werten. **Keine Magic-Numbers wie 7px oder 13px.**

## 6. Border-Radius

| Token | Wert | Verwendung |
|---|---|---|
| sm | 8px | Buttons, kleine Cards |
| md | 12px | Standard-Cards, Panels |
| lg | 16px | UI-Layer, Popups |
| pill | 99px | Buy-Btn-Pills, Tags, Bio-Hud-Pill |
| circle | 50% | Cell-Frame, Dot-Indicators |

## 7. Glow / Shadow

| Verwendung | CSS-Pattern |
|---|---|
| Aktives Icon | `filter: drop-shadow(0 0 8px var(--accent))` |
| Active Card | `box-shadow: 0 0 14px rgba(0,255,163,0.4)` |
| Hover Lift | `box-shadow: 0 6px 18px -8px rgba(0,255,163,0.4)` |
| Gold Highlight | `box-shadow: 0 0 14px -4px rgba(255,210,74,0.4)` |
| Crit Flash | `box-shadow: 0 0 14px -4px rgba(255,93,162,0.4)` |

**Verboten:** Drop-Shadow mit Pure-Black (`#000`) — immer Accent-Farbe für Sci-Fi-Look.

## 8. Animation-Curves

| Curve | CSS / Godot Tween | Verwendung |
|---|---|---|
| Standard | `cubic-bezier(0.4, 0, 0.2, 1)` / Tween.EASE_OUT + Tween.TRANS_QUAD | Allgemeine Transitions |
| Spring | `cubic-bezier(0.34, 1.56, 0.64, 1)` / Tween.EASE_OUT + Tween.TRANS_BACK | Tab-Switches, Popup-Entries |
| Snap | 80–120ms linear | Press-Squish, Tap-Feedback |
| Glide | 0.55s cubic-bezier(0.16, 1, 0.3, 1) | Ripple-Effekt |

**Animation-Dauer-Regeln:**
- Micro-Interactions (Tap, Hover): 80–150ms
- Tab/Panel-Switches: 250–350ms
- Popup-Entries: 300–500ms
- Stage-Transitions: 750–1500ms (zelebrieren)
- **Nichts länger als 1500ms außer Stage-Transitions**

## 9. Stage-Mood-Boards

Pro Stage-Phase:

### Phase „Subzellulär" (Stages 1–4)
- Cell: hell-grün, klein, einzeln
- Hintergrund: tiefes Schwarz, sparsame Plankton-Partikel
- Audio: nur Drone-Layer
- Tempo: ruhig

### Phase „Mikrobiell" (Stages 5–9)
- Cell: heller, beginnt Mitose-Cluster zu zeigen
- Hintergrund: mehr Plankton, leichte Bewegung
- Audio: Drone + leichter Pad
- Tempo: leicht ansteigend

### Phase „Zellulär" (Stages 10–12)
- Cell: voller Cluster (Fibonacci-Kugel)
- Hintergrund: Hintergrund-Tönung leicht ins Cyan
- Audio: Pad voll ausgebaut
- Tempo: rhythmisch

### Phase „Mehrzeller" (Stages 13–18)
- Cell: beginnt sich zu strecken (Morphogenese)
- Hintergrund: zarte Cyan-Akzente, Plankton intensiver
- Audio: Melody-Layer setzt ein
- Tempo: deutlich aktiver

### Phase „Wirbeltier" (Stages 19–22)
- Cell: voller Organismus, schwimmt
- Hintergrund: tiefere Farben, atmosphärisch
- Audio: alle Layer aktiv
- Tempo: ruhig-majestätisch

### Phase „Transzendenz" (Stages 23–30)
- Cell: kosmische Formen, mehr Gold/Cyan-Akzente
- Hintergrund: ganz leichte Sternenfeld-Andeutung
- Audio: Melody + zarte Tension-Schwellen
- Tempo: episch-ruhig

## 10. Asset-Produktion-Regeln

- **Bei externer Beauftragung:** dieses Dokument als Brief mitliefern
- **Source-Files behalten:** SVG für Icons, Figma/Penpot für UI-Mocks, FLAC für Audio-Master
- **Lizenzdokumentation:** jeder externe Asset in `ATTRIBUTIONS.md` mit Lizenz-Hinweis
- **AI-Generated-Content:** **nicht für Steam-veröffentlichbare Assets** (Steam-Disclosure-Pflicht + Copyright-Risiko). Erlaubt für interne Mockups/Konzept-Phase.

## 11. Akzeptanz-Checkliste pro Asset

- [ ] Folgt etablierter Color-Palette
- [ ] Folgt 24×24-Icon-Konvention (falls Icon)
- [ ] Folgt 8-px-Grid (falls UI-Komponente)
- [ ] Glow/Shadow nutzt Accent-Farbe, kein Pure-Black
- [ ] Source-File in Repo + Lizenz dokumentiert
- [ ] Bei Animation: Curve aus Tabelle 8, Dauer aus Regelwerk
- [ ] Bei Sprache: Stil-Konsistent (Bio/Sci-Fi)
