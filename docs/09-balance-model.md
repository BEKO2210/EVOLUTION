# 09 — Balance Model

**Status:** Phase 0 v0.1 — Begleitend zur Spreadsheet `docs/09-balance-model.xlsx` (in Phase 0 erstellen)

---

## 1. Konstanten (live in `data/balance_constants.json`)

| Konstante | Wert | Begründung |
|---|---|---|
| `COST_GROWTH` | 1.15 | Klassische Idle-Formel (Cookie Clicker), schaffte 12-Monate-Lebensdauer in Tests |
| `MILESTONES` | [10, 25, 50, 100] | Logarithmische Verteilung, jede Meilenstein-Doppelung ist Player-Reward |
| `MILESTONE_MULTIPLIER` | 2.0 | Konsistent verdoppeln, kumulativ ×16 bei Tier 100 |
| `PRESTIGE_THRESHOLD` | 1.000.000 | Lifetime-DNA, erreichbar in 8–12 h |
| `PRESTIGE_BASE` | 1.10 | Multiplikator pro Evolutionspunkt, kompoundierend |
| `AUTO_SYNERGY_PER_COUNT` | 0.005 | +0.5 % je Auto-Upgrade-Kauf für alle anderen |
| `CLICK_SYNERGY_PER_COUNT` | 0.003 | +0.3 % je Click-Upgrade-Kauf für alle anderen |
| `OFFLINE_EFF_DEFAULT` | 0.5 | 50 % DPS-Effizienz offline |
| `OFFLINE_EFF_WITH_RESEARCH` | 1.0 | 100 % mit `r12 Zeit-Komprimierung` |
| `OFFLINE_CAP_SECONDS` | 14400 | 4 Stunden Default |
| `OFFLINE_CAP_SECONDS_SKILL` | 43200 | 12 Stunden mit Skill-Tree-Knoten |
| `CRIT_CHANCE_BASE` | 0.05 | 5 % Default, durch Forschung steigerbar |
| `CRIT_MULT_BASE` | 5.0 | ×5 auf Crit |

## 2. Kosten-Formel

```
cost_at_count(u, n) = u.cost_base × 1.15^n
output_at_count(u, n) = u.dps × n × ownership_mult(n)

ownership_mult(n):
  m = 1
  for t in [10, 25, 50, 100]:
    if n >= t: m *= 2
  return m
```

Bei n=10: m=2
Bei n=25: m=4
Bei n=50: m=8
Bei n=100: m=16

## 3. Cost-/Output-Curves pro Auto-Tier (Beispiel a1 Mitochondrien)

| n (Anzahl) | Cost (DNA) | Output (DNA/s) |
|---|---|---|
| 1 | 60 | 0.4 |
| 5 | 121 | 2.0 |
| 10 | 243 (≈ Meilenstein x2!) | 4.0 × 2 = 8.0 |
| 25 | 2.000 (x4) | 10.0 × 4 = 40.0 |
| 50 | 65.000 (x8) | 20.0 × 8 = 160.0 |
| 100 | 7.6M (x16) | 40.0 × 16 = 640.0 |
| 200 | 880G (x16) | 80.0 × 16 = 1.28k |

## 4. Time-to-Stage-Tabelle (Simulation, ohne Prestige, ohne Skill-Tree)

Annahme: Spieler klickt 1× pro 2 Sekunden im Early-Game, kauft Auto-Upgrades sobald affordable.

| Stage | DNA-Threshold | Geschätzte Zeit zum Erreichen | Sessions à 30 min |
|---|---|---|---|
| 1 | 0 | sofort | 0 |
| 2 | 1.000 | 2–4 min | 1 |
| 3 | 25.000 | 15–25 min | 1 |
| 4 | 600.000 | 60–90 min | 2–3 |
| 5 | 15.000.000 | 3–5 h | 6–10 |
| 6 | 380.000.000 | 6–10 h | 12–20 |
| 10 | 150.000.000.000.000 | 30–50 h | 60–100 |
| 20 | 24·10²⁴ | 100–200 h | 200–400 |
| 30 | 1.5·10⁴² | 200–400 h | 400–800 |

**Diese Tabelle wird in Phase 0 mit echter Spreadsheet-Simulation präzisiert und in Beta-Telemetrie validiert.**

## 5. Prestige-Erträge

Erste Prestige nach 1M Lifetime-DNA:
- Evolutionspunkte: `floor(sqrt(1M / 1M)) = 1`
- Multiplikator: `1.10^1 = 1.10` (+10 %)

Bei 100M Lifetime:
- EP: `floor(sqrt(100)) = 10`
- Multiplikator: `1.10^10 = 2.59` (+159 %)

Bei 10B Lifetime:
- EP: `floor(sqrt(10.000)) = 100`
- Multiplikator: `1.10^100 ≈ 13.8k` (+13800 %)

→ Skaliert sub-linear, belohnt Langzeit-Spieler ohne in Power-Creep zu explodieren.

## 6. Sensitivitäts-Analyse

| Änderung | Effekt auf Time-to-Stage-30 | Beibehalten? |
|---|---|---|
| `COST_GROWTH` 1.15 → 1.18 | +30 % länger | nein, zu langsam |
| `COST_GROWTH` 1.15 → 1.12 | -25 % schneller | nein, zu schnell, Early-Game leidet |
| Meilensteine [10, 25, 50, 100] → [10, 30, 75, 150] | +20 % länger, weniger spürbare Spikes | nein |
| `PRESTIGE_BASE` 1.10 → 1.15 | -40 % nach 5 Prestiges (Power-Creep!) | nein |
| `OFFLINE_EFF` 0.5 → 0.75 | Idle-Sessions wertiger, Active-Play weniger relevant | erwägen für Phase 4 nach Beta-Feedback |

## 7. Failure-Mode-Tests

| Szenario | Erwartung |
|---|---|
| Spieler ignoriert alle Auto-Upgrades, klickt nur | Stage 5–6 erreichbar nach ~10h, dann harte Wall |
| Spieler ignoriert alle Click-Upgrades, nur Auto | Stage 30 erreichbar, ~200h, ohne Prestige Stage 15 max ohne Prestige in <50h |
| Spieler kauft NUR günstigstes Upgrade jedes Mal | Sub-optimal, Wall bei Stage 8–10. Skill-Tree-Knoten „Auto-Buyer" fixed das post-prestige |
| Spieler prestiged zu früh (1M Lifetime) | OK, kleine Boost, kann öfter prestigen |
| Spieler prestiged spät (1B Lifetime) | Großer Boost auf einmal, attraktiver Decision-Point |

## 8. Daily-Login-Bonus

Optionaler Anreiz, niemals spielentscheidend:

| Tag | Bonus |
|---|---|
| 1 | +10 min DPS als DNA |
| 2 | +15 min DPS |
| 3 | +25 min DPS |
| 4 | +40 min DPS |
| 5 | +1 h DPS |
| 6 | +1.5 h DPS |
| 7 | +2 h DPS + Goldene Zelle |
| Wiederholung | zurück zu Tag 1 |

Streak-Verlust kostet keine permanenten Inhalte. Nur den nächsten höheren Bonus.

## 9. Achievement-Reward-Balance

Aus dem bestehenden Prototyp übernommen, hier dokumentiert:

| Achievement-Klasse | Reward-Klasse |
|---|---|
| Click-Counts (10–100k) | clickMult 1.02–1.10 |
| DNA-Counts (1k–1t) | allMult 1.01–1.05 |
| Stage (3–30) | dpsMult 1.03–1.30 |
| Crits (10–100) | critChance +0.005–0.01 |
| Goldene (5–25) | goldenMult 1.3, goldenRate 1.15 |
| Division (5–10) | allMult 1.05–1.10 |
| Prestige (1–5) | allMult 1.03–1.08 |
| Komplettist (alle Auto/Click) | dpsMult 1.10 / clickMult 1.10 |

Gesamt-Reward-Stack maximal ~×2 von allen Achievements zusammen. Bewusst sanft, damit Achievements Belohnung statt Pflicht sind.

## 10. Spreadsheet-Pflicht

Die Excel/Google-Sheet-Datei `09-balance-model.xlsx` muss in Phase 0 enthalten:

- **Tab 1: Konstanten** — alle Konstanten aus Sektion 1, mit Notes
- **Tab 2: Auto-Upgrades** — alle 30, mit Spalten n=1, n=10, n=25, n=50, n=100 (Cost + Output)
- **Tab 3: Click-Upgrades** — selbes Schema
- **Tab 4: Stages** — alle 30 mit Threshold + kumulativer Bonus
- **Tab 5: Forschungen** — alle 12 mit Cost + Effekt
- **Tab 6: Time-to-Stage-Simulation** — geschätzt mit Auto-Update-Formel
- **Tab 7: Prestige-Curve** — Lifetime-DNA → Evolutionspunkte → Multiplikator
- **Tab 8: Sensitivität** — Was-wäre-wenn-Analysen
- **Tab 9: Achievements** — Reward-Übersicht

JSON-Export aus Spreadsheet via Script (Python/Sheets-Apps-Script) in `data/*.json`. Quelle-Wahrheit ist Spreadsheet, JSON ist Build-Output.
