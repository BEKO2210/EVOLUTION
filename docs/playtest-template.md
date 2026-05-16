# Playtest-Session-Template (Phase 1 / P1-013)

Strukturierte Vorlage für Greybox-Playtest-Sessions mit ungeschulten Spielern. Ziel: validieren ob die Core-Loop trägt, bevor wir in Phase 2 (Vertical Slice) Audio + Visual-Polish-Budget reinwerfen.

**Pro Session-Dauer:** 30–45 min inklusive Briefing + Debrief.
**Zielanzahl:** ≥3 Personen, möglichst nicht aus dem Idle-Genre.

---

## Vor der Session — Setup

- [ ] Aktueller `main`-Branch ist gebaut (Windows / macOS / Linux / Steam Deck — was du verfügbar hast)
- [ ] Build startet ohne Errors (Bootstrap-Konsole zeigt "Autoload smoke-test ... OK")
- [ ] **Slot 1 oder 2 ist leer** (`user://save_slot_1.json` löschen, falls vorhanden)
- [ ] Screen-Recording aktiv (OBS, ShareX, macOS Screen Recording, etc.) — Audio nur falls der Tester einverstanden ist
- [ ] Stift + Papier neben dir (oder ein zweiter Bildschirm für Live-Notizen)
- [ ] Tester sitzt am Gerät; du sitzt **nicht direkt daneben** — sonst neigen sie dazu zu fragen statt zu entdecken

---

## Briefing (1 min, kurz halten)

> "Ich teste hier ein Spiel das ich entwickle. Ich kann dir leider nichts erklären — genau das ist der Punkt. Spiel einfach, sag laut was du siehst und denkst (`think aloud`). Es gibt kein 'falsch'. Wenn du nicht weiterweißt, ist das wertvolle Info für mich."

**Was NICHT sagen:**
- "Klick auf die Zelle" (lass sie selbst rausfinden)
- "Das ist ein Klicker, du musst..."
- "Sehr cool, oder?" (suggestive Fragen verfälschen)

---

## Session-Beobachtungen (während des Spielens)

Spalten: **Zeit** | **Aktion des Testers** | **Aussage / Frage** | **deine Notiz (Hypothese)**

| Zeit | Aktion | Aussage / Frage | Notiz |
|---|---|---|---|
| 0:00 | Startbildschirm | "...okay, was soll ich..." | UI-Hierarchie unklar? |
| 0:15 | klickt Tab "Auto" | "Mitochondrien — was kostet das?" | Cost-Label lesbar? |
| | | | |
| | | | |

→ Liste während des Spielens erweitern. Lass den Tester reden; du schreibst.

---

## Kritische Beobachtungspunkte (in deinen Notizen markieren)

### Erste 2 Minuten — Onboarding
- [ ] Was klickt der Tester **zuerst**? (Idealer Pfad: KLICK-ZELLE-Button)
- [ ] Wie lange dauert es, bis sie kapieren dass Klicken DNA gibt?
- [ ] Verstehen sie was "DNA" ist? (kein Tutorial → testet ob die Begriffe stehen)

### Minute 3–10 — Erste Upgrades
- [ ] Wann öffnen sie den Auto-Tab?
- [ ] Verstehen sie sofort "Cost vs Output"?
- [ ] Frust-Moment: gibt es einen Punkt wo sie 30+ Sek warten ohne dass etwas passiert?
- [ ] Welche Begriffe verwirren (Stage / DPS / Click-Power / Milestone)?

### Minute 10–25 — Mid-Game
- [ ] Probiert der Tester andere Tabs aus (Click, Forschung, Erfolge)?
- [ ] Werden Achievements wahrgenommen? (Aktuelle Greybox-UI zeigt sie nur im Tab — kein Toast)
- [ ] Was geschieht beim ersten Stage-Up — wird das gefühlt als "Belohnung"?
- [ ] Hat der Tester eine Strategie entwickelt (z. B. "ich kaufe immer das billigste")?

### Minute 25–30 — Endphase + Stop
- [ ] Sieht der Tester den Meta-Tab → Prestige?
- [ ] Wenn nicht: zeig ihn am Ende und frag was er erwartet hätte
- [ ] Welche Frage hat er ans Spiel, die nirgendwo beantwortet wird?

---

## Debrief-Fragen (nach dem Spielen, 5 min)

1. **Erster Eindruck — beschreib das Spiel in einem Satz, als würdest du es einem Freund erzählen.**  
   _(Wenn die Beschreibung nicht "Klicker / Idle / Wachstum" enthält, stimmt die Visual-Sprache nicht.)_

2. **Was war der spaßigste Moment?**

3. **Wann wolltest du aufhören? Was hätte dich zum Weiterspielen gebracht?**

4. **Gab es einen Moment, wo du dich verloren / verwirrt gefühlt hast?**

5. **Welches eine Feature würdest du dir wünschen?** _(Frag NICHT was sie ändern würden — das gibt Detail-Feedback; frag was sie hinzufügen wollen — das zeigt Mental-Model-Lücken.)_

6. **Auf einer Skala von 1–10: wie wahrscheinlich würdest du das nochmal spielen?**

---

## Nach der Session — Auswertung

Innerhalb von 24 h zusammenfassen in `docs/playtest-notes-phase-1.md`:

- **Pro Session ein Block** mit Datum, Tester-Pseudonym, Plattform, Spielzeit, Quote-Highlights
- **3–5 Action-Items** ableiten (priorisiert)
- **Pattern markieren** wenn ≥2 Tester dasselbe Problem hatten

---

## Roter Faden: was wir prüfen

Die Phase-1-Akzeptanz ist:

> Die Core-Loop **funktioniert** technisch. Phase 2 ist es wert, **darin Polish-Budget zu investieren**.

Wenn der Test ergibt:
- ✅ Tester verstehen den Loop in <2 min → **Phase 2 starten**
- ⚠️ Tester verstehen den Loop nicht, aber haben kleine Frust-Punkte → **Phase 2 mit Onboarding-Fokus starten**
- ❌ Tester langweilen sich oder verstehen das Spiel grundsätzlich nicht → **Core-Loop-Reform, Phase 2 verschoben**

Egal welches Ergebnis: das ist genau warum wir den Test machen, bevor wir 8–12 Wochen Vertical-Slice-Arbeit reinkippen.
