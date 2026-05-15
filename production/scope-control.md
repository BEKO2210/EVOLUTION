# Scope Control

**Status:** Phase 0 v0.1, Living Document
**Verantwortlich:** Game Director (= Solo-Dev)

Scope-Creep ist der häufigste Indie-Killer. Dieses Dokument ist die Bremse.

---

## Must-have für Steam v1.0

Diese Features sind NICHT optional. Ohne sie keine Release.

### Core-Gameplay
- 30 Stages mit Threshold-Progression
- 30 Auto-Upgrades + 30 Click-Upgrades
- 12 Forschungen
- 4 Abilities (Photo, Adrena, Mitose, Frenzy)
- Prestige mit Evolutionspunkten + Skill-Tree (6–10 Knoten)
- Milestone-Doppelung bei 10/25/50/100
- Synergien (Auto-Synergie 0.5 %, Click-Synergie 0.3 %)
- Crit-System (5 % Basis-Chance, ×5 Mult)

### Meta-Systeme
- 50 Achievements (Steam-integriert)
- Codex (≥75 Einträge, freischaltbar)
- Stats-Panel mit Sparkline-Charts
- Daily-Login-Bonus
- Goldene Zellen, DNA-Drops, Mutationen

### UI/UX
- 5 Tabs (Auto, Klick, Forschung, Erfolge, Meta)
- Settings-Menü (Volume × 3, Quality-Preset, Sprache, Reduce-Motion, Color-Blind, Haptic, Telemetrie-Opt-in)
- Onboarding (3-Schritt-FTUE)
- Tooltip-System (Hover Desktop, Long-Press Mobile)
- 3 lokale Save-Slots + 1 Cloud-Slot
- Save-Export / Save-Import
- Cloud-Conflict-UI

### Visuell
- BioNexus-3D-Cell mit Phase-Machine (Solo / Mitose / Cluster / Morphogenese / Lebewesen)
- Custom SVG-Iconset (Wave-1 + Wave-2 für alle 60 Upgrades)
- Stage-Transition-Animation
- Click-Feedback (Float-Text, Ripple, Burst)
- Milestone-Feedback (Card-Flash, Shockwave)

### Audio
- 4 adaptive Musik-Layer (Drone, Pad, Melody, Tension)
- Komplette SFX-Familie (Click, UI, Stage, Ability, Milestone, Ambient)
- Mastered ~-16 LUFS
- Ambient-Triggers (zufällige Bubbles, Drones)

### Plattformen & Integration
- Windows + Linux + macOS Builds
- **Steam Deck Verified angestrebt** (Playable als Fallback)
- Controller-Support (Steam Input API)
- Cloud Save (Steam Cloud)
- Steam Achievements
- 11 Sprachen (EN, DE, FR, ES, IT, PT-BR, RU, JA, zh-Hans, zh-Hant, KO)

### Stabilität
- Zero P0/P1 Bugs zum Launch
- Crash-Reporting (Sentry, opt-in)
- 1000-Cycle Save-Stress-Test bestanden
- Save-Migration-Framework

---

## Nice-to-have für v1.0 (cuttable falls Zeit knapp)

Cut-Reihenfolge: Top→Unten, also obere Items cutten zuerst.

1. **Rich Presence** („Spielt als Bakterium (Stage 5)") — UX-nice, kein Showstopper
2. **Animated Save-Slot-Previews** — Static reicht
3. **Stage-Transition-Cinematic** (10 s Animationen) — kann auf Standard-Transition reduziert werden
4. **Codex-Such-/Filter-Funktion** — Liste reicht
5. **Mehr als 50 Achievements** — 50 reicht für „Sehr Positiv"-Schwelle
6. **Confetti / Fireworks bei Stage-30** — Standard-Animation reicht
7. **Multi-Sprach-Trailer** (lokalisierte Trailer pro Sprache) — Untertitel reichen
8. **Cosmetic-Customization (Cell-Themes)** — Post-Launch
9. **Soundtrack als separater Steam-Download** — Post-Launch
10. **Steam Trading Cards** — Approval-Schwelle erst nach 5000+ Käufen erreichbar

---

## Post-Launch (v1.1 bis v1.3, Phase 7)

Diese Features sind explizit NICHT in v1.0. Sie sind aber im Roadmap-Bewusstsein.

### v1.1 (Monat 1 post-launch)
- Bug-Fix-Pass auf Basis Spieler-Feedback
- QoL-Features die im Beta-Feedback hochgekommen sind (1–3 Items)
- Balancing-Tuning basierend auf Telemetrie
- Translation-Korrekturen aus Community-Feedback

### v1.2 (Monat 3 post-launch)
- Saisonales Event (z. B. Halloween-Stage-Skin)
- 5–10 neue Achievements
- Skill-Tree-Erweiterung (2–3 neue Knoten)
- Mobile-Companion-Vorbereitung (Android-Build-Pipeline)

### v1.3 (Monat 6 post-launch)
- Mobile-Companion-Release (Google Play)
- Steam Trading Cards (falls Approval erreicht)
- Cross-Save zwischen Mobile + Steam
- Cosmetic-DLC (Cell-Themes, UI-Themes — NICHT Pay-to-Progress)

### DLC „Cosmic Depths" (Monat 9+ post-launch, optional)
- Stages 31–40
- Multiversum-Prestige-Layer
- 20+ neue Achievements
- Eigene Music-Layer
- Preis: 4.99–6.99 € als Standalone-DLC

---

## Bewusst NICHT in v1.0 (auch nicht in Post-Launch ohne explizite Entscheidung)

Diese Liste schützt gegen Scope-Creep durch „wäre cool wenn"-Vorschläge.

- ❌ **Online-Multiplayer** (PvP, Co-op, Leaderboards-Wettkampf)
- ❌ **Echtzeit-Asynchron-Multiplayer**
- ❌ **In-Game-Käufe / Microtransactions**
- ❌ **Werbung** (intern für Studio-Apps oder extern)
- ❌ **Loot Boxes**
- ❌ **Premium-Currency**
- ❌ **Combat-System** (Gegner, HP, Schaden)
- ❌ **Skill-/Reaktion-Spiel-Elemente** (QTE, Timing-basierte Mini-Games)
- ❌ **Roguelike-Permadeath**
- ❌ **Voice Acting**
- ❌ **Pre-Rendered Cutscenes**
- ❌ **3D-Charakter-Customization**
- ❌ **NFT / Blockchain / Crypto** in jeder Form
- ❌ **Account-System außerhalb Steam** (kein eigener Login-Server)
- ❌ **Pay-to-Skip-Cooldowns** (alle Cooldowns sind Design-Bestandteil, nicht Monetarisierungs-Hebel)
- ❌ **Streamer-Mode mit Censoring** (kein Bedarf, Spiel ist familien-freundlich)
- ❌ **VR-Modus**
- ❌ **AR-Modus**
- ❌ **AI-Generated-Content in Shipping-Assets** (Steam-Disclosure + Copyright-Risiko)

---

## Cut-Regeln gegen Scope Creep

### Regel 1: Phase-Backlog ist gelocked

Nach Phase-Start: nur P0/P1-Bug-Tickets dürfen hinzugefügt werden. Neue Features → `backlog/post_launch.md`, nicht aktueller Sprint.

### Regel 2: Pillars sind Vetorecht

Jedes neue Feature gegen Pillars (siehe `docs/01-game-pillars.md`) validieren. Verstoß = automatisch geblockt.

### Regel 3: „Wäre cool wenn"-Killer

Sobald die Phrase „wäre cool wenn" fällt, landet die Idee in `backlog/post_launch.md` mit Datum + 1-Satz-Beschreibung. NICHT im aktiven Sprint.

### Regel 4: Zeit-Budget pro Phase

Wenn 80 % des Phasen-Zeit-Budgets verbraucht sind und ≥1 Must-Have noch offen ist → **Scope schneiden statt Phase verlängern**.

### Regel 5: Vertical-Slice-Lock

Nach Phase 2 sind Visuals + Audio-Vokabular gefroren. Änderungen nur bei dokumentierten UX-Problemen (mit Beta-Feedback).

### Regel 6: Late-Stage-Lock (Phase 5)

Ab Phase 5 (Release-Prep): keine neuen Features. Nur Bug-Fixes + Polish. Hard-Stop.

### Regel 7: Day-0-Patch-Disziplin

Day-0-Patch enthält **nur Critical-Path-Fixes**. Keine „While-we-at-it"-Features.

---

## Decision-Log

Jede Cut-Entscheidung wird mit Datum + Grund hier dokumentiert.

| Datum | Feature | Status | Grund |
|---|---|---|---|
| Phase 0 | NFT / Blockchain | Ausgeschlossen v1.0+ | Verstößt gegen Pillar 4 + Reputations-Risiko |
| Phase 0 | Mobile-Companion in v1.0 | Verschoben Phase 7 | Doppel-Belastung, separater Store-Approval |
| Phase 0 | Voice Acting | Ausgeschlossen v1.0+ | Kein Budget, kein narrative Bedarf |
| Phase 0 | Steam Trading Cards | Verschoben Phase 7 | Approval-Schwelle erst nach 5000 Käufen |
| Phase 0 | Multiplayer in jeder Form | Ausgeschlossen v1.0+ | Verstößt gegen Pillar 4 (Singleplayer-Identität) |

Neue Cut-Entscheidungen werden hier eingetragen, sobald sie getroffen werden.
