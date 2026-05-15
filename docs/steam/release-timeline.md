# Steam Release Timeline

**Status:** Phase 0 v0.1

Steam hat mehrere überlappende Prozesse mit unterschiedlicher Dauer. Wer sie nicht sauber trennt, plant zu knapp.

---

## Die 4 separaten Steam-Prozesse

### 1. Steam Direct Wartezeit (30 Tage)

| | |
|---|---|
| Was | Mindestzeit zwischen Bezahlung der $100 Application Fee und frühestmöglichem Release-Termin |
| Dauer | **Fix 30 Kalender-Tage** |
| Steuerbar | nein, läuft automatisch |
| Beginnt | mit Bezahlung der Fee (= App-Erstellung im Partner-Backend) |
| Endet | 30 Tage später, dann Release möglich |

### 2. Coming-Soon-Seite öffentlich (Wishlist-Phase)

| | |
|---|---|
| Was | Steam-Page ist öffentlich sichtbar, Wishlist-Button aktiv |
| Mindest-Dauer | **mindestens 2 Wochen vor Release** (Steam-Empfehlung), realistisch **mindestens 3 Monate** für Wishlist-Aufbau |
| Steuerbar | ja, du entscheidest wann „Coming Soon" geht |
| Beginnt | mit erstem Speichern + Veröffentlichen der Store-Page |
| Trigger für Spätestens | mindestens 14 Tage vor Wunsch-Release-Datum |

### 3. Store Page Review (durch Steam-Mitarbeiter)

| | |
|---|---|
| Was | Steam prüft Store-Page-Inhalt (Texte, Capsules, Tags, Pricing, Genre) auf Compliance |
| Dauer | typisch **1–5 Werktage** pro Submission, kann bei Iteration mehrfach |
| Steuerbar | nein |
| Beginnt | mit Submission der Page für Review |
| Trigger für Spätestens | 2–3 Wochen vor Release-Datum (für Puffer bei Resubmission) |

### 4. Build Review (durch Steam-Mitarbeiter)

| | |
|---|---|
| Was | Steam prüft den Game-Build auf grundlegende Funktionalität (Startet? Crasht beim Start? EULA korrekt?) |
| Dauer | typisch **1–3 Werktage** pro Build-Submit auf `default`-Branch |
| Steuerbar | nein |
| Beginnt | mit Build-Upload auf `default`-Branch in Steamworks |
| Trigger für Spätestens | 1 Woche vor Release-Datum |

---

## Konsolidierte Timeline (rückwärts geplant von Release-Datum)

Annahme: Release-Datum ist **T**.

```
T-180 (6 Monate vor Release):
├─ Steam-Partner-Account aktiv, $100 bezahlt
├─ 30-Tage-Wartezeit startet
├─ App im Backend angelegt, AppID erhalten
└─ Vertical Slice (Phase 2) abgeschlossen oder kurz vor Abschluss

T-150 (~5 Monate vor Release):
├─ 30-Tage-Wartezeit bereits abgelaufen → Release wäre jetzt rechtlich möglich
├─ Wir warten aber für Wishlist-Aufbau
└─ Coming-Soon-Seite vorbereitet (Capsules, Texte initial fertig)

T-120 (~4 Monate vor Release):
├─ Coming-Soon-Seite geht online
├─ Wishlist-Phase startet
├─ Devlog-Reihe startet (alle 2 Wochen)
└─ Discord-Server geht öffentlich

T-90 (~3 Monate vor Release):
├─ Alpha-Phase abgeschlossen (Feature Complete)
├─ Beta-Phase startet
├─ Übersetzungen in Arbeit
└─ Marketing-Push: Streamer-Outreach erste Welle

T-45:
├─ Beta abgeschlossen
├─ Release-Candidate-Build fertig
├─ Store-Page-Final-Pass (alle Capsules, Trailer, Texte komplett)
└─ Store-Page-Review submitten

T-30:
├─ Release-Datum fest verkündet (Discord, Reddit, Twitter)
├─ Demo-Build hochgeladen (für Next Fest oder permanent)
├─ Build-Review-Submission auf `default`-Branch (gelocked)
└─ Reviewer-Keys an erste Welle Streamer/Press

T-14:
├─ Build-Review sollte durch sein (puffer für Resubmission falls nötig)
├─ Store-Page-Review sollte durch sein
├─ Letzte Outreach-Welle
└─ Discord-Hype, Twitter-Countdown

T-7:
├─ Letzter Hot-Fix-Check auf Beta-Branch
├─ Launch-Trailer auf YouTube als Premiere
└─ Press-Embargo-Datum (falls Embargo gewählt)

T-3:
├─ Final-Build auf `default`-Branch, Lock entfernt
├─ Letzte Reviewer-Keys
└─ Social-Media-Countdown

T-1:
├─ Twitch-Stream wo du selbst spielst (eigener Channel, sammelt last-minute Wishlists)
└─ Discord-Hype

T-0 (RELEASE-TAG):
├─ Spiel öffentlich, Public-Release-Button geklickt
├─ Launch-Tweet, Reddit-Post, Discord-Announcement
├─ Solo-Dev online für 8+ h (Discord, Steam-Discussions)
└─ Hotfix-Branch ready

T+1 bis T+7:
├─ Tägliche Reviews-/Bug-Monitor
├─ Patches alle 1–3 Tage bei Bedarf
└─ T+7: Launch-Retro-Post auf Reddit + Discord
```

---

## Kritischer Pfad

Die 30-Tage-Wartezeit ist Boden, aber **nicht** der bindende Constraint — Marketing-Wishlist-Phase ist es. Daher:

1. **Steam-Partner-Account + Fee** in Phase 0 erledigen (Wartezeit läuft im Hintergrund)
2. **Coming-Soon-Seite live** Ende Phase 2 / Anfang Phase 3 (4–6 Monate vor Wunsch-Release)
3. **Build-Reviews und Store-Page-Reviews** in Phase 5 mit Puffer
4. **Release-Klick** in Phase 6

---

## Gefährliche Annahmen (gegen die wir designen)

| Annahme | Realität |
|---|---|
| „30 Tage ab Build-Upload" | Falsch. 30 Tage ab **App-Fee-Bezahlung**. |
| „Build-Review ist sofort" | Falsch. 1–3 Werktage, bei Resubmission mehrfach. |
| „Coming Soon → Wishlists kommen von selbst" | Falsch. Algorithmus belohnt Velocity. Marketing nötig. |
| „Ich kann am Release-Tag noch Capsules ändern" | Technisch ja, aber Store-Page-Review kann sie blocken bis korrigiert. Nicht empfohlen. |
| „Trading Cards beantrage ich am Release" | Falsch. Trading-Cards-Approval geht erst nach 5000+ Käufen (oder Steam-Discretion). Phase 7. |
| „Steam Deck Verified ist garantiert wenn Linux-Build funktioniert" | Falsch. Separate Review (siehe `steam-deck-checklist.md`). |

---

## Puffer-Regel

Plane **mindestens 2 Wochen Puffer** zwischen geplanten Phasen-Übergängen und harten Steam-Deadlines. Wenn die Store-Page-Review kritisch ablehnt 1 Woche vor Release, brauchst du Reaktionszeit.

Wenn der Puffer aufgebraucht ist, **Release verschieben statt Qualität opfern.**
