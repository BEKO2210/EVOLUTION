# 08 — Steam Marketing Plan

**Status:** Phase 0 v0.1
**Owner:** Marketing-Lead (= Solo-Dev)

---

## 1. Ziele

### Quantitativ

| Metrik | Ziel pre-Launch | Ziel Launch-Tag | Ziel 30 Tage post-Launch |
|---|---|---|---|
| Wishlists | ≥1000 (Mindest), ≥3000 (Stretch) | ≥3000 | ≥10000 |
| Steam-Page-Visits | n/a | ≥2× Wishlist-Count | ≥3× Wishlist-Count |
| Verkäufe | n/a | 200–500 (konservativ) | 1000–3000 |
| Reviews | n/a | ≥10 | ≥100, ≥85 % positiv |
| Discord-Members | ≥200 | ≥500 | ≥1500 |

### Qualitativ

- Bekanntheit in r/incrementalgames als „kommendes ernsthaftes Indie-Idle"
- Mindestens 3 Streamer/YouTuber haben Demo gezeigt
- Mindestens 1 Trade-Press-Mention (RockPaperShotgun, PC Gamer Indie, Indie DB)

---

## 2. Timeline

| Phase / Datum | Marketing-Aktivität |
|---|---|
| Pre-Production (Phase 0) | Discord-Skelett aufbauen, Domain reservieren, Press-Kit-Template vorbereiten |
| Engine-Prototyp (Phase 1) | Stille Phase, kein öffentliches Material — Spoiler-Schutz |
| Vertical Slice (Phase 2) | **Steam-Page öffnen** (Coming Soon), Trailer-Master fertig, erste Devlog-Posts |
| Alpha (Phase 3) | Wöchentliche Devlogs auf r/incrementalgames, Twitter/Bluesky-GIFs, Streamer-Outreach erste Welle |
| Beta (Phase 4) | Discord öffentlich, Beta-Recruiting, Next-Fest-Anmeldung, Press-Outreach |
| Release-Prep (Phase 5) | Demo öffentlich (Next Fest), Reviewer-Keys, Launch-Trailer-Premiere |
| Launch-Woche (Phase 6) | siehe Launch-Woche-Plan unten |

---

## 3. Wishlist-Aufbau-Strategie

### Hauptkanäle

| Kanal | Cadence | Inhalt |
|---|---|---|
| r/incrementalgames | alle 2 Wochen | Devlog (Build-Tagebuch, **nicht** als „Wishlist meinen Game" markiert) |
| Twitter / Bluesky | 2–3× pro Woche | GIFs (kurz, geloopt, kein Audio), Screenshots, Polls |
| Discord | täglich light | Devlog-Snippets, Community-Q&A |
| TIGSource | 1× | Devlog-Thread starten und gelegentlich Updates |
| Steam News | alle 2 Wochen ab Steam-Page-Live | Update-Posts |
| Mastodon (gamedev-Instanz) | 1× pro Woche | Cross-Posting |

### Devlog-Themen-Pipeline (Beispiele)

1. „Warum Godot statt Unity" (technisch)
2. „Die Mathematik hinter dem Idle-Loop" (theory-craft)
3. „Wie ich die Zelle in Three.js prototyped habe" (Postmortem)
4. „Stage-Up Sound-Design in 4 Layern" (Audio-Devlog mit Sound-Clip)
5. „Steam Deck Verified — die Checkliste" (technisch + Marketing)
6. „Localization für 11 Sprachen — Lessons" (technisch)
7. „Wie Cookie Clicker meine Wirtschaft beeinflusst hat" (Design)

---

## 4. Streamer / Press Outreach

### Liste (Phase 0 erweitern)

| Name | Plattform | Reichweite | Fokus | Wann kontaktieren |
|---|---|---|---|---|
| RetromationRanted | YouTube | mittel | Idle/Roguelike | Demo-Phase |
| Olexa | YouTube | groß | Idle/Casual | Demo + Launch |
| Northernlion | YouTube/Twitch | sehr groß | Indie-Variety | Launch (geringere Chance, aber lohnt sich) |
| SsethTzeentach | YouTube | groß | Idle/Skeptisch | Launch |
| GamingOnLinux | News | klein, aber Steam-Deck-Fokus | Steam Deck News | Demo + Launch |
| RockPaperShotgun | News | groß | Indie | Demo |
| PC Gamer Indie | News | sehr groß | Indie | Launch |
| IndieDB | News | klein, organisches Wachstum | Indie-Showcase | Vertical-Slice-Phase |
| TouchArcade | News | mittel | Mobile-fokussiert | Phase 7 (Mobile-Launch) |
| 78MillionMore | YouTube | mittel | German-Indie | Demo + Launch |
| Pietsmiet | YouTube/Twitch (DE) | sehr groß | Variety | Launch |
| HandyGamerHD | YouTube (DE) | mittel | Mobile/Casual | Phase 7 |
| Wholesomeverse | Twitter | klein, kuratiert | „Cozy Games" | Demo |

### Outreach-Vorlage

```
Hi <Name>,

ich entwickle ein Indie-Idle namens "Evolution" — premium, kein P2W, ein 3D-Hero-Visual statt Pixel-Listen,
Aesthetik wie Subnautica/FTL.

Eine Demo läuft ab <Datum>. Steam-Key gerne im Anhang.

Steam: <link>
Trailer: <link>
Press Kit: <link>

Schreib mir wenn was hilft.

<Name>
```

Personalisierung pro Empfänger (1 Satz). Mass-Mailing-Optik vermeiden.

---

## 5. Trailer-Konzept

### Hard-Constraints (Steam-Algorithmus)

- **Erste 5 Sekunden** = Hook (Auto-Play startet stumm — Visuals müssen sofort tragen)
- **Länge:** 60–90 s (Steam empfiehlt 60–90 s, lange Trailer haben niedrige Completion-Rate)
- **Aspect:** 16:9, 1920×1080 (4K-Master, 1080-Export)
- **Codec:** H.264 MP4
- **Loudness:** -16 LUFS

### Storyboard (Vertical Slice Trailer, Phase 2 Iteration)

| Sek | Bild | Audio |
|---|---|---|
| 0–2 | Schwarzer Bildschirm → Proto-Molekül erscheint | Drone fade-in |
| 2–5 | Cell klickt sich selbst, DNA-Counter steigt schnell hoch | Click-Layer + Pad |
| 5–10 | Mitose-Animation, Cell teilt sich | Mitose-SFX |
| 10–20 | Cluster wächst, Stage-Up-Sequenz | Stage-Up Fanfare |
| 20–35 | Cluster → Morphogenese-Übergang | Music-Layer komplett |
| 35–50 | Organismus schwimmt im Mikrokosmos | Music ruhig + Tension |
| 50–65 | Cosmic-Phase-Andeutung (Stage 25+) | Music-Crescendo |
| 65–75 | Titel: „EVOLUTION — Coming 202X to Steam" + Wishlist-CTA | Music-Hold |

### Launch-Trailer (Phase 5, separat)

Dieselbe Sprache + Tonalität, aber kürzer (45–60 s) und mit klarem CTA zum Kauf.

---

## 6. Demo-Strategie

### Next Fest

- Anmeldung **1–2 Monate vor Fest** im Steam-Partner-Backend
- Demo = Vertical Slice (Phase 2) + 2–3 zusätzliche Stages
- Bleibt nach Fest **permanent** auf Steam-Page verfügbar (verkaufsfördernd)
- Demo-Save kann beim Kauf des Vollspiels migriert werden (UX-Win)

### Demo-Scope

| Inhalt | In Demo |
|---|---|
| Stages 1–7 | ✓ |
| Auto-Upgrades a1–a10 | ✓ |
| Click-Upgrades c1–c10 | ✓ |
| Forschungen r1–r3 | ✓ |
| Abilities | nur Photo + Adrena |
| Prestige | nein (Soft-Lock mit „Im Vollspiel verfügbar") |
| Codex | erste 5 Einträge |

---

## 7. Press Kit

### Inhalt (presskit.html-Template, eigene Domain)

- Game-Logo + Studio-Logo (PNG, transparent)
- Fact-Sheet (Genre, Plattformen, Release-Datum, Preis, Studio)
- 8 Screenshots in 1920×1080
- Trailer-Embed + MP4-Download
- 4 GIFs (kurz, autoplay-fähig)
- Beschreibung (Short + Long)
- Features-Liste
- Awards/Mentions (wenn vorhanden)
- Team (Solo + Credits für Externe)
- Contact (Email, Twitter, Discord)
- Lizenz-Hinweis („Free for editorial use")

---

## 8. Discord-Strategie

- Server-Skelett in Phase 0 (privat)
- Öffentlich ab Phase 4 (Beta-Phase)
- Kanäle: `#general`, `#feedback`, `#bug-reports`, `#suggestions`, `#strategy-discussion`, `#announcements`, `#dev-blog`, `#fanart`
- Mod-Rolle: 1–3 Community-Mods aus Beta-Cohort

---

## 9. Budget-Plan

| Posten | Min | Max |
|---|---|---|
| Steam Direct Fee | 100 € | 100 € |
| Komponist (Buy-Out) | 1500 € | 4000 € |
| SFX-Pack | 100 € | 300 € |
| Übersetzungen (11 Sprachen × ~3000 Wörter) | 500 € | 2000 € |
| Domain + Hosting (Press-Kit) | 50 € | 150 € |
| Trailer-Editing (falls extern) | 0 € (Eigenproduktion) | 800 € |
| Marketing-Tools (Newsletter, Analytics) | 0 € | 200 € / Jahr |
| Anwalt (Trademark + EULA-Review) | 0 € | 800 € |
| Beta-Tester-Plattform (PlaytestCloud / Backup) | 0 € | 500 € |
| **Total Min** | **2250 €** | |
| **Total Max** | | **8850 €** |

---

## 10. Risiko-Mitigationen (Marketing-spezifisch)

- **Wishlist-Ziel verfehlt** → Release verschieben, nicht launchen mit Sub-1000 Wishlists
- **Streamer ignorieren Outreach** → niedrige Erwartung, Discord/Reddit-Community-Building als Primärkanal
- **Negative Reviews am Launch** → Hotfix-Plan + öffentliche Antworten in Steam-Discussions (sachlich, nicht emotional)

---

## 11. KPIs für laufende Überwachung

Wöchentlich ab Steam-Page-Live:

- Wishlist-Count + Delta zur Vorwoche
- Steam-Page-Visits (Steamworks Analytics)
- Discord-Member-Count
- r/incrementalgames-Post-Performance (Upvotes, Comments)
- Trailer-Views

Monatlich: Cohort-Analyse (woher kommen Wishlists?), Outreach-Hit-Rate.
