# 07 — Competitive Analysis

**Status:** Phase 0 Draft v0.1 — vor Beauftragung in Phase 0 anhand Steam-Daten verifizieren

Methode: Steam-Page-Daten + SteamSpy / Gamalytic (Schätzungen) + eigene Bewertung. Konkrete Sales-Zahlen sind Schätzungen, in Phase 0 mit aktuellen Datenquellen aktualisieren.

---

## Analyse-Tabelle

| Titel | Release | Preis (€) | Reviews | % positiv | Geschätzte Sales | USP | Was sie gut machen | Was wir besser machen |
|---|---|---|---|---|---|---|---|---|
| **Cookie Clicker (Steam)** | 2021 | 4.99 | 80k+ | 96 % | 1M+ | Original-Idle, 600+ Items, langjährige Updates | Tiefer Content, Charme, Humor | Hochwertige 3D-Hauptfigur, ernstere Ästhetik |
| **Antimatter Dimensions** | 2022 | Free / Paid Cosmetics | 7k+ | 95 % | n/a | Mathematik-Tiefe, mehrere Prestige-Layer | Theorycraft-Tiefe | Bessere UX, weniger spröde UI |
| **Trimps** | 2024 (Steam) | 9.99 | 1k+ | 90 % | ~20k | Combat + Idle Hybrid | Tiefe Build-Variation | Reines Idle ohne Combat-Reibung |
| **Idle Slayer** | 2021 | 4.99 | 14k+ | 95 % | ~150k | Action + Idle Hybrid | Pixel-Art-Identität, Steam Deck Verified | Atmosphärische 3D statt Pixel |
| **NGU Idle** | 2018 | 0 (F2P + Premium DLC) | 22k+ | 97 % | n/a (kostenlos) | Extreme Tiefe, viele Layer | Content-Umfang | Professionelle UI/UX, Premium-Modell |
| **Crusaders of the Lost Idols** | 2017 | F2P + MTX | 7k+ | 85 % | n/a (F2P) | Formations-Build-Tiefe | Build-Variation | Kein P2W, Premium-Modell |
| **Melvor Idle** | 2021 | 9.99 + DLC | 17k+ | 96 % | ~200k | RuneScape-inspiriert, browser-fähig | Cross-Platform-Sync, Tiefe | Visuelle Hero-Cell statt Listen-Only-UI |
| **Cell to Singularity** | 2019 | F2P + MTX | 25k+ | 81 % | n/a (F2P) | **Direkter thematischer Vergleich**: Evolution + Skalierung | Wissenschafts-Thema, 3D-Visuals | Kein P2W, ruhigere Ästhetik, kein FOMO |
| **Dome Keeper** (Godot-Beispiel) | 2022 | 19.99 | 14k+ | 91 % | ~300k | Roguelike + Tower-Defense | Polish, Audio, Spannungsbogen | Anderes Genre, nur Engine-Beweis |
| **Brotato** (Godot-Beispiel) | 2023 | 4.99 | 70k+ | 98 % | ~1M+ | Bullet Heaven, kurze Runs | Polished Indie, Steam-Hit | Anderes Genre, nur Engine-Beweis |

---

## Direktester Wettbewerber: Cell to Singularity

**Warum kritisch:** Gleiches Thema (Evolution, Skalierung), gleicher Markt.

**Was sie machen:**
- F2P + aggressive MTX
- Wissenschaftliches Setting mit Lore-Tafeln
- 3D-Visuals
- Mobile-First, dann Steam-Port

**Was wir anders machen:**
- **Premium-Modell** statt F2P (zieht andere Käuferschaft an)
- **Keine MTX** (Reviews-Sentiment bei Cell to Singularity zeigt MTX-Frust)
- **Ruhigere Ästhetik** — wir sind meditativ, sie sind Reklame-Feedback-bunt
- **Tiefere Idle-Mechanik** (Mitose, Skill-Tree, Codex)
- **Steam-First** (besseres Tooling, kein Mobile-Port-Kompromiss in v1.0)

→ Differenzierung über Tonalität + Geschäftsmodell, nicht über Thema. Käuferschaft-Überlappung erwartet ~30 %.

---

## Lessons-Learned aus Wettbewerbern

### Was funktioniert (übernehmen)

- **Lange Halbwertzeit** durch Prestige + Meta-Progression (Cookie Clicker, NGU Idle, Trimps)
- **Steam-Deck-Verified** als Sichtbarkeits-Boost (Idle Slayer)
- **Wissenschaftliches Setting** mit Lore-Tafeln (Cell to Singularity, Universal Paperclips)
- **Achievement-Density** als Pull-Mechanik
- **Cross-Save** zwischen Geräten (Melvor Idle)
- **Indie-Polish-Standard** (Brotato, Dome Keeper) — UI/UX-Politur ist USP

### Was wir vermeiden

- **F2P + MTX** — wir sind Premium
- **Visual Noise / FOMO-Popups** (Cell to Singularity, viele F2P-Idles)
- **Pixel-Art als Default** (Idle Slayer)
- **Listen-Only-UI ohne Hero-Visual** (Antimatter Dimensions)
- **Combat-Loop** (Trimps, Idle Slayer)
- **Aggressive Sound-Design / Hooks** (Hyper-Casual-Idles)

---

## USP-Statement (für Marketing)

> Evolution ist das Cell-to-Singularity ohne Mikrotransaktionen — mit professioneller Indie-Polish, einem 3D-Hero-Visual statt Pixel-Items, und einer ruhigen, meditativen Ästhetik, die das Genre seit Cookie Clicker nicht mehr versucht hat.

---

## Preis-Positionierung

| Preis-Punkt | Wer ist da | Pro/Contra für uns |
|---|---|---|
| 2.99 € | Hyper-Casual Idles | Zu billig — signalisiert „Mobile-Port", drückt LTV |
| **4.99 €** ✓ | Cookie Clicker, Idle Slayer, Brotato | **Empfohlen für Launch** — Genre-Standard, niedrige Einstiegshürde |
| 6.99 € | Halbwegs ambitionierte Indies | Sweet-Spot nach Content-Update post-launch |
| 9.99 € | Trimps, Melvor Idle | Zu hoch für Launch ohne Track-Record, später möglich |
| 14.99 € | Dome Keeper, Hades | Außerhalb Idle-Genre-Standard, nicht empfohlen |

**Empfehlung:** Launch bei 4.99 €. Nach 3-Monats-Content-Update auf 6.99 € erhöhen. Discounts auf max. 30 % im ersten Jahr.

---

## Steam-Tag-Strategie (basierend auf Top-Performern)

Pflicht-Tags (alle Top-Performer haben sie): Idle, Clicker, Casual, Singleplayer
Identitäts-Tags: Atmospheric, Relaxing, Sci-fi, Cute
Sekundäre Tags: Strategy, Indie, 2D (Steam zählt unsere Card-UI als 2D auch wenn die Cell 3D ist)

---

## Update-Pflicht

Dieses Dokument wird in Phase 0 mit aktuellen Steam-Daten verifiziert (Reviews-Stand, Preise, ungefähre Sales aus SteamSpy/Gamalytic). Schätzungen klar als solche kennzeichnen.
