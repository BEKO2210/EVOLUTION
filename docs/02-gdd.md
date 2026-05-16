# 02 — Game Design Document

**Status:** Living document, Version 0.1, Phase 0
**Owner:** Game Director
**Letzte Änderung:** Phase 0

---

## 1. Vision

Evolution erzählt die Geschichte des Lebens als spielbare Skalierungs-Metapher. Aus einem Proto-Molekül wird über 30 Stufen ein kosmisches Bewusstsein. Der Spieler ist nicht „die Zelle" — er ist die treibende Kraft hinter der Evolution, der zusieht, kuratiert, beschleunigt.

Die Ästhetik ist wissenschaftlich-meditativ: Bio-Neon-Farbpalette, lebendiges 3D-Cell-Visual als Hauptfigur, ruhige adaptive Musik. Die Mechanik ist klassisches Incremental mit moderner UX-Politur.

## 2. Genre & Vergleichstitel

**Genre-Kombination:** Incremental / Idle / Atmospheric Clicker / Singleplayer

**Steam-Tags (priorisiert):**
1. Idle
2. Clicker
3. Atmospheric
4. Sci-fi
5. Casual
6. Singleplayer
7. Relaxing
8. Cute
9. Strategy (sekundär)
10. Indie

**Vergleichstitel:**

| Titel | Lehrt uns | Vermeiden wir |
|---|---|---|
| **Cookie Clicker** | Tiefer Content-Stack, lange Halbwertzeit | Visuelle Überfrachtung, Humor-Lastigkeit, kein 3D-Hero |
| **Antimatter Dimensions** | Theory-Craft-Tiefe, mehrere Prestige-Layer | Spröde UI, abstrakte Visuals |
| **Mini Metro** | Meditative Atmosphäre, ruhiges Sound-Design | Mini Metro hat keine Idle-Komponente |
| **Subnautica** (Audio-Referenz) | Adaptive ambient Musik, Mikrokosmos-Erzählung | Kein direkter Mechanik-Vergleich |
| **NGU Idle** | Tiefe Mechanik, lange Spielzeit | Hässliche UI, überladene Screens |
| **Hexcells** (Pillar-Referenz) | Ruhe, Eleganz, jede Animation gewollt | Kein direkter Mechanik-Vergleich |
| **Crusaders of the Lost Idols** | Formations-Build-Tiefe in Idle | Aggressive Monetarisierung |
| **Trimps** | Lange Halbwertzeit, viele Layer | Combat-Loop nicht übernehmen |
| **Halls of Torment** (Godot-Beispiel) | Polished Indie auf Godot, Steam-Erfolg | Anderes Genre, aber Engine-Validierung |
| **Brotato** (Godot-Beispiel) | Mobile + Desktop aus einem Code | Anderes Genre, aber Build-Pipeline-Validierung |

## 3. Core Loop

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   ┌─────────────────────────────────────────┐       │
│   │  Klicke die Zelle  →  +DNA              │       │
│   └─────────────────────────────────────────┘       │
│                       ↓                             │
│   ┌─────────────────────────────────────────┐       │
│   │  Kaufe Upgrades (Auto + Klick)          │       │
│   │  → DNA/s steigt + Klick-Power steigt    │       │
│   └─────────────────────────────────────────┘       │
│                       ↓                             │
│   ┌─────────────────────────────────────────┐       │
│   │  Stage-Threshold erreicht               │       │
│   │  → Visual evolviert, Stage-Bonus aktiv  │       │
│   └─────────────────────────────────────────┘       │
│                       ↓                             │
│   ┌─────────────────────────────────────────┐       │
│   │  Milestone-Doppelung bei 10/25/50/100   │       │
│   │  upgrades → spürbarer Power-Spike       │       │
│   └─────────────────────────────────────────┘       │
│                       ↓                             │
└─────────────────────────────────────────────────────┘
        (zurück zu Klick + Idle, mit neuer Power)
```

**Cycle-Dauer pro Iteration:** ~30 s im Early Game, ~5 min im Mid-Game, ~30 min im Late Game.

## 4. Meta Loop

```
┌────────────────────────────────────────────────────────┐
│                                                        │
│   Stage 30 erreicht  oder  Lifetime-DNA-Threshold      │
│                       ↓                                │
│   Prestige (Soft-Reset)                                │
│   → Verlust: DNA, Upgrades, Stage                      │
│   → Gewinn: permanente Evolutionspunkte                │
│                       ↓                                │
│   Evolutionspunkte in Skill-Tree investieren           │
│   (6–10 Knoten, Trade-offs)                            │
│                       ↓                                │
│   Neuer Run, schneller dank Skill-Tree-Boni            │
│                       ↓                                │
│   Goldene Zellen / DNA-Drops / Mutationen / Achievements│
│   sammeln                                              │
│                       ↓                                │
│   Codex-Einträge freischalten (Lore pro Stage)         │
│                       ↓                                │
│   Daily Login Bonus (kleiner, optionaler Anreiz)       │
│                                                        │
└────────────────────────────────────────────────────────┘
```

## 5. Stages (30, aus Prototyp übernommen)

Vollständige Liste in `data/stages.json`. Hier strukturiert:

### Phase „Subzellulär" (Stages 1–4)
1. **Proto-Molekül** — Schwellwert 0
2. **RNA-Strang** — 1k DNA
3. **DNA-Helix** — 25k
4. **Virus** — 600k

### Phase „Mikrobiell" (Stages 5–9)
5. **Prokaryot** — 15M
6. **Bakterium** — 380M
7. **Archaea** — 9.5G
8. **Amöbe** — 240G
9. **Paramecium** — 6T

### Phase „Zellulär" (Stages 10–12)
10. **Pflanzenzelle** — 150T
11. **Schwamm** — 3.8Q
12. **Hydra** — 95Q

### Phase „Mehrzeller" (Stages 13–18)
13. **Plattwurm** — 2.4 Quintilliarden
14. **Insekt**
15. **Fisch**
16. **Amphibie**
17. **Reptil**
18. **Vogel**

### Phase „Wirbeltier" (Stages 19–22)
19. **Säugetier**
20. **Primat**
21. **Hominid**
22. **Mensch**

### Phase „Transzendenz" (Stages 23–30)
23. **Übermensch**
24. **Schwarm-Intelligenz**
25. **KI-Singularität**
26. **Stern-Bewusstsein**
27. **Galaktischer Geist**
28. **Universum-Knoten**
29. **Multiversum**
30. **Transzendenz**

**Visueller Match (BioNexus-Phase):**
- Stages 1–4 → SOLO (eine pulsierende Hero-Zelle)
- Stages 5–7 → MITOSE (Zellteilungs-Sequenzen)
- Stages 8–15 → CLUSTER (Fibonacci-Kugel wächst)
- Stages 16–22 → MORPHOGENESE (Cluster wird zu Organismus)
- Stages 23–30 → LEBEWESEN (Organismus schwimmt + Kosmos-Effekte)

## 6. Upgrades

### Auto-Upgrades (30 Tiers)

Liefern passive DNA/Sekunde. Vollständige Liste in `data/upgrades_auto.json`. Beispiele:

| ID | Name | Basis-DPS | Basis-Kosten |
|---|---|---|---|
| a1 | Mitochondrien | 0.4 | 60 |
| a2 | Ribosomen | 1.8 | 850 |
| a3 | Zellkern | 7 | 9.5k |
| ... | ... | ... | ... |
| a30 | Kosmische Struktur | 310 Quadrilliarden | 6.3 Decilliarden |

**Kostenformel:** `cost = base × 1.15^count`
**Meilensteine:** ×2 Output bei Tier 10, 25, 50, 100 (kombiniert ×16 bei 100)

### Click-Upgrades (30 Tiers)

Erhöhen DNA-Gewinn pro Klick. Gleiches Schema (`upgrades_click.json`).

### Synergien
- Auto-Synergie: jeder Auto-Upgrade-Kauf gibt +0.5 % zu allen anderen Auto
- Click-Synergie: jeder Click-Upgrade-Kauf gibt +0.3 % zu allen anderen Click

## 7. Forschungen (12 einmalig)

Permanente passive Boni, kosten einmalig DNA. Vollständig in `data/research.json`. Beispiele:
- **Energiestoffwechsel** — Auto-DNA +25 %
- **Schnelle Reflexe** — Klick ×1.5
- **Glücksgen** — Crit-Chance +5 %
- **Synaptische Resonanz** — Klick gibt 2 % deines DPS
- **Zeit-Komprimierung** — Offline-Effizienz auf 100 %

## 8. Abilities (4 aktive, Cooldown-basiert)

| Name | Effekt | Cooldown |
|---|---|---|
| Photo | DPS ×8 für 15 s | 75 s |
| Adrena | Klick ×20 für 10 s | 50 s |
| Mitose | sofortige Gabe von 2 min DPS | 240 s |
| Frenzy | 30 Auto-Klicks in 3 s | 120 s |

## 9. Prestige (Soft-Reset)

**Trigger:** Lifetime-DNA ≥ 1 Million (erster Prestige)
**Was passiert:** DNA, Upgrades, Stage werden zurückgesetzt. Evolutionspunkte bleiben permanent.
**Evolutionspunkte gewonnen:** `floor(sqrt(lifetimeDNA / 1M)) - bisherigePunkte`
**Effekt:** Permanenter PPS-Multiplikator `1.10^evolutionsPunkte` (kompoundierend)

### Skill-Tree (Phase 3, noch zu finalisieren)
Vorläufige 8 Knoten, je 1–5 Evolutionspunkte:
1. **Schnellstart** — Anfangs-DNA 100 → 1000
2. **Auto-Buyer** — Cheapest-Upgrade-Auto-Buy alle 10 s
3. **Crit-Hunter** — Crit-Chance Basis +5 %
4. **Geißel-Träger** — Stages 5+ haben +50 % visuelle Geißeln (visuell + 5 % Click)
5. **Mitose-Meister** — Mitose-Cooldown ×0.8
6. **Goldene-Hand** — Goldene-Zellen-Spawn-Rate ×1.5
7. **Tiefe-Wahrnehmung** — Codex-Einträge zeigen Formeln statt nur Beschreibung
8. **Endloser-Idle** — Offline-Cap 4 h → 12 h

## 10. Codex / Lore

Freischaltbare Texte pro Stage + jedem Upgrade-Tier. Erste Prestige schaltet Codex-Tab frei. Schreibstil: wissenschaftlich, aber poetisch (Carl-Sagan-Anmutung).

**Beispiel-Eintrag „Mitochondrien":**
> Vor 1.5 Milliarden Jahren verschluckte eine Zelle ein Bakterium und vergaß, es zu verdauen. Aus dem Versehen wurde Symbiose. Heute trägst du diesen Fehler in jeder Zelle deines Körpers — er heißt jetzt Energie.

Codex erfüllt:
- Belohnung für Sammler
- Erzählerischer Anker für die Skalierungs-Metapher
- Achievement-Hook („Codex-Komplettist")

## 11. Achievements (27+ aus Prototyp, Ziel 50 für Steam-Launch)

Kategorien:
- **Klick** (10/100/1k/10k/100k Klicks)
- **DNA** (1k/100k/10m/1g/1t Lifetime)
- **Stage** (3/6/9/12/20/25/30)
- **Crit** (10/100)
- **Gold** (5/25)
- **Division** (5/10)
- **Prestige** (1/5)
- **Komplettist** (alle Auto / alle Click)

Phase 3 ergänzt:
- **Speed-Run** (Stage 10 in <1h)
- **Pazifist** (Stage 5 ohne Ability-Nutzung)
- **Codex-Komplettist**
- **Crit-Streak** (10 Crits in Folge)
- **Marathon** (24h Idle ohne Klick)

## 12. Onboarding (FTUE)

3-Schritte, harte Wand danach:

| Schritt | Trigger | UI |
|---|---|---|
| 1 | First-Run | „Klicke die Zelle" — pulsierender Hinweis-Ring um die Zelle |
| 2 | Nach 5 Klicks | „Kaufe deinen ersten Helfer" — Hinweis-Pfeil auf erstes Auto-Upgrade |
| 3 | Stage 2 erreicht | „Du wächst. Probier eine Ability." — Hinweis auf Abilities-Bar |

Danach: kein erzwungener Tutorial-Content. Tooltip-System (Hover/Long-Press) reicht.

## 13. Endgame

**Stage 30 erreicht** ist Win-Condition v1.0:
- Endgame-Animation (BioNexus-Final-Form, 10 s)
- Spezial-Achievement: „Transzendenz"
- Game läuft weiter; Prestige + Skill-Tree für Replay-Wert
- Codex 100 % komplett → Bonus-Achievement
- Stage 30 ist erreichbar in ~200–400 h Vollspielzeit (mit Prestige-Boost)

**Post-Stage-30 (Post-Launch-Content):**
- Stages 31–40 als DLC (Kosmische Tiefe)
- Multiversum-Prestige (Layer 2)

## 14. Failure- / Frustpunkte (bewusst designed gegen)

| Frustpunkt | Mitigation |
|---|---|
| „Ich klicke und passiert nichts Sichtbares" | Jeder Klick triggert Float-Text + Ripple + Cell-Shockwave |
| „Ich verstehe nicht warum X teurer wurde" | Tooltip zeigt Kosten-Berechnung im Detail |
| „Ich habe versehentlich Prestige gemacht" | Confirm-Dialog mit konkretem Verlust |
| „Mein Save ist weg" | Save-Export + automatisches Backup vor Migration |
| „Offline gibt zu wenig" | Default 50 %, mit Forschung 100 %, Cap 4–12 h je nach Skill-Tree |
| „Daily verpasst, FOMO" | Daily-Bonus ist nie spielentscheidend, kein Streak-Verlust kostet permanente Inhalte |
| „Endlose Zahlen ohne Bedeutung" | Stage-Namen + Codex geben jeder Zahl Kontext |
| „Lärm auf dem Bildschirm" | Reduced-Motion + Quality-Presets + Audio-Sliders |
| „Pay-Wall versteckt" | Es gibt keine — Premium-Modell garantiert |
| „Crash zerstört Stunden Fortschritt" | Auto-Save alle 15 s, Crash-Recovery beim Start |

## 15. Lokalisations-Strategie

Launch-Sprachen v1.0:
EN, DE, FR, ES, IT, PT-BR, RU, JA, zh-Hans, zh-Hant, KO

Alle UI-Strings, Codex-Einträge, Tooltips, Achievement-Namen + -Beschreibungen.
Stage-Namen bleiben in `data/stages.json` lokalisiert.

## 16. Inhalt-Umfang v1.0

| Element | Anzahl |
|---|---|
| Stages | 30 |
| Auto-Upgrades | 30 |
| Click-Upgrades | 30 |
| Forschungen | 12 |
| Abilities | 4 |
| Skill-Tree-Knoten | 6–10 |
| Achievements | 50 |
| Codex-Einträge | ≥75 (30 Stages + 30 Auto + 12 Forschungen + 3 special) |
| Sprachen | 11 |

**Geschätzte Spielzeit:**
- Stage 10 erreichen: 6–10 h
- Erster Prestige: 8–12 h
- Stage 20: 30–50 h
- Stage 30: 200–400 h
- 100 % Achievements: 250–500 h
