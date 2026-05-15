# 06 — Risk Register

**Status:** Phase 0 v0.1, Living Document
**Review-Cadence:** monatlich + bei Phasen-Übergang

Skala: Wahrscheinlichkeit / Impact je L (low) / M (medium) / H (high).

---

| # | Risiko | Wahrsch. | Impact | Mitigation | Trigger für Re-Evaluation |
|---|---|---|---|---|---|
| 1 | **GodotSteam-Integration scheitert** (Spike findet Blocker) | M | H | Spike in Phase 1 vor Vertical-Slice-Commit. Plan B dokumentiert: Steamworks.NET via C#-Modul. Worst-Case: Engine-Wechsel zu Unity mit 3-Monats-Verzug. | Spike-Ergebnis Phase 1, Woche 4 |
| 2 | **Burnout (Solo-Dev)** | H | H | Feste Wochen-Stunden-Cap. Pflicht-Pause-Woche alle 8 Wochen. Scope-Cuts statt Crunch. Externe Auslagerung von Audio + Übersetzungen + ggf. Icon-Set. | Selbst-Check monatlich, Pulse-Test |
| 3 | **Spieltitel-Trademark-Konflikt** | L | H | Trademark-Check in Phase 0 (USPTO, EUIPO, DPMA). 2 Backup-Namen vorbereitet. Domain-Reservierung erst nach Check. | Phase 0 Woche 1 |
| 4 | **Performance bricht auf Low-End ein** (Steam Deck < 60 fps, Mid-Phone < 30 fps) | M | M | Frühes Profiling ab Phase 1. Quality-Preset-System (Low/Mid/High/Ultra). Adaptive Cell-Count. MultiMeshInstance3D statt vieler Nodes. | Profiler-Report pro Phase |
| 5 | **Wishlist-Ziel verfehlt** (<1000 vor Launch) | H | H | Steam-Page 3+ Monate vor Launch live. Devlog-Reihe ab Vertical-Slice-Ende. Streamer-Outreach gestaffelt. Next-Fest-Slot fest eingeplant. Release verschieben statt mit Sub-1000 launchen. | Wöchentliches Wishlist-Monitoring ab Page-Live |
| 6 | **Save-System-Bug zerstört Saves** | L | VH | Schema-Version + Auto-Backup vor Migration. 1000-Cycle Stress-Test in Phase 4. Save-Export als Disaster-Recovery. CLI-Restore-Tool. | Code-Review pro Save-Code-Change |
| 7 | **Übersetzungs-Verzögerung** (Lieferant liefert spät / schlechte Qualität) | M | M | Native-Speaker-Review für Top-4-Sprachen (EN, DE, JA, zh-Hans). Übrige Sprachen können Beta-Patch nachreichen. Frühe Beauftragung in Phase 0/3. | Übersetzung-Status alle 2 Wochen in Phase 3 |
| 8 | **Mobile-Build UX bricht** (Touch-Targets zu klein, Layout nicht responsiv) | M | M | Touch-First-Audit ab Phase 1. Separate Mobile-Scene-Variant. Long-Press-Tooltip-System. Min-Touch-Target 44×44 dp Pflicht. | QA-Pass auf 3 Geräten in Phase 4 |
| 9 | **Konkurrenz-Spiel released gleichzeitig** | L | M | Marktbeobachtung monatlich. Release-Datum flexibel halten bis Phase 5. Differenzierung über USP (Bio-Neon-Ästhetik, 3D-Hero-Cell) verteidigen. | Wettbewerber-Roadmap-Monitoring |
| 10 | **Steam Deck Verified verfehlt** | M | M | Steam-Deck-Checkliste (`docs/steam/steam-deck-checklist.md`) ab Phase 2 abarbeiten. Test auf realem Deck ab Phase 3. „Playable"-Status ist akzeptables Fallback, „Unsupported" nicht. | Deck-Test pro Phase |
| 11 | **Crash-Cascade am Launch durch un-getesteten Edge-Case** | M | H | Beta-Phase (50–200 Tester, 6+ Wochen). Sentry-Pipeline aktiv. Hotfix-Branch <2 h einsatzbereit. P0/P1-Backlog vor Release zero. | Launch-Week-Monitoring |
| 12 | **Stage-30-Erreichung dauert zu lange** (Balance-Fehler) | M | M | Balance-Sheet in Phase 0. Telemetrie-basiertes Balancing in Beta. Notfalls Multiplier-Adjustments via JSON-Patch (Phase 7). | Beta-Telemetrie alle 2 Wochen |
| 13 | **Steam-Direct-Submission abgelehnt** (Inhalt/Form) | L | H | Steam Onboarding-Guide vorher lesen. Inhalte sind sehr safe (kein NSFW, kein political content). 30-Tage-Puffer vor Wunsch-Release. | Bei Submission |
| 14 | **Cloud-Save-Konflikt zerstört Spielfortschritt** | M | H | Konflikt-UI mit Diff (siehe ADR-0003). Beide-Behalten-Option als Default. User-Test der Konflikt-UI in Phase 4. | QA in Phase 4 |
| 15 | **Übersetzungs-Lizenz / Übersetzer-Rights-Issue** | L | M | Vertrag mit Buy-Out-Klausel. Übersetzungen in `localization/strings.csv` als ediertes Werk dokumentiert. | Vertragsabschluss in Phase 3 |
| 16 | **DSGVO-Verstoß durch Telemetrie** | L | H | Opt-in (nicht Opt-out). Klarer First-Run-Dialog. Keine PII. Privacy Policy klar. Bei Zweifel: Anwaltskosten <500 € einplanen. | Phase 3 Telemetrie-Aktivierung |
| 17 | **Audio-Komponist liefert nicht** | M | M | Vertrag mit Meilenstein-Zahlungen. Backup-Plan: Eigenproduktion oder Royalty-Free-Music. Spätestens Phase 2 Lieferung erwartet. | Audio-Status alle 2 Wochen |
| 18 | **Engine-Breaking-Change in Godot 4.x** (Major-Update zerstört Code) | L | M | `.godot-version` pinned zu spezifischer Patch-Version. Update nur bewusst und mit Test-Pass. | Bei Godot-Major-Release |
| 19 | **Negative-Review-Cascade in Launch-Woche** | M | H | Day-0-Patch-Plan. Hotfix-Branch ready. Offene Kommunikation in Steam-Discussions + Discord. Auf Bugs reagieren, nicht auf einzelne Reviews. | Launch-Woche-Monitoring |
| 20 | **Selbst-blokierung durch Perfektionismus** | H | H | Phasen-Akzeptanz-Kriterien sind Schluss-Linien. „Good enough to ship" als Mantra in Phase 5–6. Externe Person als Sanity-Check vor Launch-Klick. | Selbst-Check vor jedem Phasen-Ende |

---

## Risiko-Verteilung-Übersicht

| Wahrscheinlichkeit | Anzahl Risiken |
|---|---|
| Hoch | 4 |
| Mittel | 11 |
| Niedrig | 5 |

| Impact | Anzahl Risiken |
|---|---|
| Sehr Hoch | 1 |
| Hoch | 9 |
| Mittel | 10 |

**Top-3-Risiken (Wahrscheinlichkeit × Impact):**
1. Burnout (H × H)
2. Wishlist-Ziel verfehlt (H × H)
3. Selbst-Blockierung Perfektionismus (H × H)

→ Diese drei brauchen aktive monatliche Überwachung.

## Review-Prozess

- **Monatlich:** Owner durchgeht Liste, markiert Status-Änderungen
- **Phasen-Übergang:** Liste wird ergänzt um neue Phasen-spezifische Risiken
- **Risiko-Eintritt:** Entry wird als „REALIZED" markiert, Lessons-Learned-Sektion ergänzt
