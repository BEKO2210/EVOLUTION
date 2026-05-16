# `data/` — Schema Notes

**Status:** Phase 0, extracted from HTML/Three.js prototype (rev `7318ce6`)
**Audience:** Godot-Implementation in Phase 1 (`DataLoader` autoload)
**Source of truth:** `index.html` JS-constants are the validated reference. After Phase-1-import, this folder takes over as the single source.

---

## Dateien — Zuständigkeit

| Datei | Zuständig für | Wird geladen von |
|---|---|---|
| `stages.json` | 30 Evolutionsstufen (Threshold, Stage-Bonus, Visual-Hinweise) | `StageSystem` (Stage-Progression + UI-Stage-Anzeige) |
| `upgrades_auto.json` | 30 passive DPS-Upgrades | `UpgradeSystem` (Buy-Logic, Stats-Recalc) |
| `upgrades_click.json` | 30 click-power Upgrades | `UpgradeSystem` |
| `research.json` | 12 einmalige permanente Forschungen | `ResearchSystem` (kauft + tracked als Owned) |
| `abilities.json` | 4 aktive Cooldown-Abilities | `AbilitySystem` (Cooldown-Tracking, Trigger) |
| `achievements.json` | 27 deklarative Achievement-Trigger | `AchievementSystem` (Predicate-Eval + Steam-Hook) |
| `balance_constants.json` | Alle globalen Konstanten & Formeln | `BalanceConfig` (load once, expose globally) |
| `schema-notes.md` | Dieses Dokument | — |

---

## Pflichtfelder pro Datei

### `stages.json`

Top-Level:
- `schema_version: int` (Pflicht, currently `1`)
- `items: array of Stage`

Stage-Objekt:
- `id: string` (Pflicht, eindeutig, Format `stage_NNN`, stabil)
- `tier: int` (Pflicht, 1..30, Sortier-Reihenfolge)
- `name_key: string` (Pflicht, Lokalisierungs-Key, Format `stage.<id>.name`)
- `threshold_dna: number` (Pflicht, Lifetime-DNA für Aufstieg)
- `bonus_multiplier: number` (Pflicht, Stage-Bonus auf alle DNA)
- `visual_radius: number` (optional, HTML-Prototyp-Hinweis — Godot kann reinterpretieren)
- `visual_wobble: number` (optional, HTML-Prototyp-Hinweis)
- `color_hex: string` (optional, Stage-Tönungs-Hinweis)
- `legacy_name_de: string` (informativ, deutscher Name aus Prototyp)

### `upgrades_auto.json` / `upgrades_click.json`

Top-Level wie oben.

Item-Objekt:
- `id: string` (Pflicht, `auto_NNN` / `click_NNN`)
- `tier: int` (Pflicht)
- `legacy_id: string` (Pflicht, mapping zum Prototyp `a1..a30` / `c1..c30`)
- `name_key: string` (Pflicht)
- `desc_key: string` (Pflicht)
- `dps_base: number` (Pflicht für auto_ — passives DNA/s pro Stück)
- `click_power_base: number` (Pflicht für click_ — additive click power pro Stück)
- `cost_base: number` (Pflicht — Basis-Kosten, Runtime-Cost = `cost_base * cost_growth^count`)
- `unlock_after_id: string|null` (Pflicht — UI hidden bis vorheriger Tier mit count >= 1)
- `legacy_emoji: string` (informativ, OS-Emoji aus Prototyp; Godot ersetzt durch eigenes Icon)

### `research.json`

Item-Objekt:
- `id`, `legacy_id`, `name_key`, `desc_key`, `cost_dna`: Pflicht
- `effect.kind: string` (Pflicht — Enum siehe unten)
- `effect.value: number` (Pflicht für alle kind != offline_full)

**Effect-Kind-Enum** (kontrolliert vom ResearchSystem):
- `dps_multiplier` — multiplikativer DPS-Boost
- `click_multiplier` — multiplikativer Click-Boost
- `crit_chance_add` — additive Crit-Wahrscheinlichkeit
- `crit_multiplier_set` — überschreibt Crit-Mult (research_004)
- `golden_spawn_rate` — multipliziert Spawn-Häufigkeit
- `golden_reward_mult` — multipliziert Golden-Reward
- `click_dps_share` — Klick bekommt N% des aktuellen DPS
- `combo_max_multiplier` — multipliziert max Combo
- `combo_time_multiplier` — multipliziert Combo-Zeitfenster
- `mutation_rate` — multipliziert Mutation-Spawn-Rate
- `stage_bonus_amplify` — verstärkt Stage-Bonus-Distanz von 1
- `offline_full` — setzt Offline-Effizienz auf 1.0 (Boolean-Effekt)

### `abilities.json`

Item-Objekt:
- `id`, `legacy_id`, `name_key`, `desc_key`, `kind`, `duration_ms`, `cooldown_ms`: Pflicht
- `svg_icon: string` (Pflicht, Icon-Registry-ID, z. B. `ico-sun`)
- `multiplier: number` (Pflicht falls kind in `[dps_multiplier, click_multiplier]`)
- `instant_dps_seconds: number` (Pflicht falls kind == `instant_dps_seconds`)
- `autoclick_count: int` (Pflicht falls kind == `autoclick_burst`)

**Ability-Kind-Enum:**
- `dps_multiplier` — temporärer DPS-Multiplier für `duration_ms`
- `click_multiplier` — temporärer Click-Multiplier
- `instant_dps_seconds` — sofortige Gabe von N Sekunden DPS als DNA
- `autoclick_burst` — N Auto-Klicks über `duration_ms`

### `achievements.json`

Item-Objekt:
- `id`, `legacy_id`, `name_key`, `condition`, `reward`: Pflicht
- `condition.kind: string` (Pflicht — Enum siehe unten)
- `condition.threshold: number` (Pflicht)

**Condition-Kind-Enum** (AchievementSystem-Predicates):
- `total_clicks_at_least` — `game.total_clicks >= threshold`
- `lifetime_dna_at_least` — `game.lifetime_dna >= threshold`
- `stage_at_least` — `game.stage >= threshold`
- `total_crits_at_least` — `game.total_crits >= threshold`
- `total_goldens_at_least` — `game.total_goldens >= threshold`
- `divisions_at_least` — `game.divisions >= threshold`
- `prestige_points_at_least` — `game.prestige_points >= threshold`
- `all_auto_upgrades_owned` — `all upgrades_auto[i].count >= 1`
- `all_click_upgrades_owned` — `all upgrades_click[i].count >= 1`

**Reward-Shape** (jedes Feld optional, ResearchSystem stackt sie):
- `click_multiplier: number`
- `dps_multiplier: number`
- `all_multiplier: number`
- `crit_chance_add: number`
- `golden_spawn_rate: number`
- `golden_reward_multiplier: number`

### `balance_constants.json`

Top-Level Sections (alle Pflicht):
- `economy` (cost_growth, milestones, synergies)
- `prestige` (threshold, multiplier, point-formula)
- `division` (Mitose-Kosten + Bonus)
- `crit` (Chance, Mult, Cap)
- `combo` (Max, Window, Ramp, Cap)
- `offline_progression` (Effizienz, Cap)
- `tick_rates` (Logic + Visual + Save)
- `golden_cells` (Spawn, Reward)
- `mutations` (Spawn)
- `dna_drops` (Spawn, Reward)
- `bionexus_visual_cap` (Hard-Cap für Instancing)

Werte sind alle numerisch oder array-of-numbers, keine Booleans/Strings (außer `comment`).

---

## Welche Werte aus dem Prototyp übernommen wurden

| Wert | Übernommen aus |
|---|---|
| Stage-Liste (30) inkl. Thresholds, Bonus, Color | `const stages` Z. 1751–1783 |
| Auto-Upgrades (30) inkl. dps + cost | `const autoUpgrades` Z. 1795–1826 |
| Click-Upgrades (30) inkl. power + cost | `const clickUpgrades` Z. 1827–1858 |
| Forschungen (12) inkl. cost + effect | `const researchTree` Z. 1876–1889 |
| Achievements (27) inkl. condition + reward | `const achievements` Z. 1892–1920 |
| Abilities (4) inkl. dur + cd + kind + mult | `const abilities` Z. 1932–1937 |
| COST_GROWTH = 1.15 | Z. 1793 |
| MILESTONES = [10, 25, 50, 100] | Z. 1794 |
| PRESTIGE_THRESHOLD = 1e6 | Z. 2623 |
| Prestige-Mult-Base = 1.10 | `Math.pow(1.10, prestigePoints)` Z. 2635 |
| Evolutionspunkt-Formel | `floor(sqrt(lifetimeDna / 1M))` Z. 2630 |
| Division-Basis-Kosten = 250000 | Z. 1994 |
| Division-Cost-Growth = 8 | `Math.pow(8, divisions)` Z. 1994 |
| Division-Bonus = 1.08 | `Math.pow(1.08, divisions)` Z. 1997 |
| Auto-Synergy = 0.005 | Z. 2021 |
| Click-Synergy = 0.003 | Z. 2025 |
| Crit-Chance-Base = 0.05 | Z. 2322 |
| Crit-Mult-Base = 5 | Z. 2333 |
| Crit-Chance-Cap = 0.95 | Z. 2330 |
| Combo-Base = 3 | Z. 2190 |
| Combo-Window = 1500ms | Z. 2187 |
| Combo-Cap = 60 | Z. 2399 |
| Combo-Ramp 3..30 | Z. 2195, 2198 |
| Offline-Eff default 0.5 / 1.0 mit r12 | Z. 2973 |
| Offline-Cap 4h (14400s) | Z. 2972 |
| Logic-Tick 250ms | Z. 3252 |
| Save-Interval 15000ms | Z. 3246 |
| Single-Tick-Cap 60s | gameTick `dtSec = Math.min(dtMs/1000, 60)` |
| Golden-Mean-Interval 120000ms | Z. 2224 |
| Golden-Despawn 10000ms | Z. 2247 |
| Golden-Reward 30s DPS / 15× Click | Z. 2251, 2255 |
| Mutation-Mean-Interval 420000ms | Z. 2277 |
| DNA-Drop min/max-Interval | Z. 2032 |
| DNA-Drop-Lifetime 8000ms | Z. 1776/3-Anti `setTimeout` 8000 |
| DNA-Drop-Reward 10s DPS / 5× Click | `Math.max(dps*10, click*5)` |
| MAX_INSTANCES = 4000 | Z. 1274 |

---

## Welche Werte noch validiert werden müssen

Diese Werte sind aus dem Prototyp, aber **noch nicht in Beta-Telemetrie validiert** — in Phase 4 (Beta) wahrscheinlich tuning-bedürftig:

1. **Stage-Thresholds** ab Stage 10 (Late-Game) — könnten in Beta zu langsam/zu schnell sein, je nach Time-to-Stage-Median
2. **Auto-Cost vs DPS-Verhältnis** ab Tier 15 — Prototyp ist „Designed for ~1 year of real play", aber unvalidiert
3. **Click-Power-vs-DPS-Balance** ab Tier 15 — Click-Path soll bei dauerhaftem Aktiv-Play konkurrenzfähig bleiben
4. **Prestige-Threshold-Curve** `1M * 10^prestigePoints` — Cookie-Clicker-Style, aber Reset-Frequenz noch nicht gemessen
5. **Division-Cost-Growth ×8** — könnte zu schnell explodieren, aktuell 250k → 2M → 16M → 128M → ...
6. **Crit-Chance-Cap 0.95** — defensiv gegen Mutation+Research-Stack
7. **Combo-Cap 60 Klicks** — UX-Schutz, in Beta auf Spaß-Faktor prüfen
8. **Mutation-Spawn-Rate 7-Min-Avg** — Frequency vs. „nervig"
9. **DNA-Drop-Lifetime 8s** — eventuell für Mobile-Touch-Player zu kurz
10. **MAX_INSTANCES 4000** — Performance auf Steam Deck OLED in Beta verifizieren

→ Beta-Telemetrie-Events in Phase 3 messen, dann data-driven adjustment in Beta (Phase 4).

---

## Was bewusst NICHT extrahiert wurde

- **`mutations`-Array** — die Mutations-Definitionen sind im Prototyp inline (`const mutations` Z. 1924–1929). Sie gehören gameplay-mäßig zu Achievements/Abilities, aber **konzeptuell zu Random-Events**. Eigene Datei `data/mutations.json` ist sinnvoll, kommt in Folge-PR (B). Aktuell bleiben sie im Prototyp und werden im Godot-Port direkt nachgebildet.
- **`autoClickerLevels`-Array** (Z. 1864–1873) — Meta-Feature („Auto-Clicker kaufen"), aktuell im Meta-Tab. Gehört zu Phase-3-Skill-Tree-Diskussion (siehe GDD), eventuell migration in Skill-Tree-Knoten. Bleibt bis dahin im Prototyp.
- **Skill-Tree** — noch nicht im Prototyp implementiert. Wird in Phase-3 designed (`data/skill_tree.json` neu).
- **Codex / Lore-Texte** — noch nicht im Prototyp. Werden in Phase-3 in `localization/strings.csv` als Lokalisierungs-Texte angelegt + `data/codex.json` als Trigger-Liste.
- **UI-Strings / Tooltips** — bewusst NICHT in `data/*.json`. Gehören in `localization/strings.csv` (Phase 3). Die `name_key`/`desc_key`-Felder hier sind nur Verweise.

---

## Validierungs-Strategie (für Godot DataLoader)

Phase 1, Ticket P1-003 implementiert in `scripts/autoload/data_loader.gd`:

```gdscript
func _load_table(path: String, validator: Callable) -> Array:
    var f := FileAccess.open(path, FileAccess.READ)
    var data := JSON.parse_string(f.get_as_text())
    assert(data.has("schema_version"))
    assert(data.has("items") or path.ends_with("balance_constants.json"))
    for item in data.get("items", []):
        validator.call(item)
    return data.get("items", [data])
```

Pro Datei eine spezifische `validator`-Funktion, die Pflichtfelder + Typen + Enums prüft. Schema-Verstoß = `push_error()` + Crash (Dev-Fehler).

Tests in `tests/test_data_loader.gd` (Phase 1):
- Lädt jede Datei
- Validiert keine duplizierten IDs
- Validiert `unlock_after_id`-Ketten korrekt verlinkt
- Validiert alle Enum-Werte gegen erlaubte Listen
- Validiert Lifetime-DNA-Curve monoton steigend

---

## Wartung / Updates

Wenn das Balance-Spreadsheet (`docs/09-balance-model.xlsx`, in Folge-PR B angelegt) als Single-Source-of-Truth übernimmt, wird ein **Export-Script** (`tools/export_data.py` oder Sheets-Apps-Script) generierte JSON-Files in `data/` schreiben. Bis dahin manuell pflegen.

Schema-Änderungen: `schema_version` inkrementieren, Migration-Code in `data_loader.gd`.

Verifikations-Pflicht vor jedem Major-Update:
1. `npm test` (falls JS-Tests hinzukommen) oder `gut` (Godot Unit Test) muss grün sein
2. Eigene Smoke-Run der ersten 3 Stages im Prototyp gegen die neuen Werte
