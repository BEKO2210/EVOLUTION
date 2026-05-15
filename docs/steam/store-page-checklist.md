# Steam Store Page Checklist

**Status:** Phase 0 v0.1
**Owner:** Marketing-Lead

Konsolidierte Checkliste für die Steam-Store-Page. Trennt klar zwischen „muss vor Coming-Soon-Page-Live", „muss vor Build-Upload" und „muss vor Release-Date".

---

## A — Vor „Coming Soon"-Page-Live

Diese Felder sind Mindest-Set damit Steam-Page als Wishlist-Sammler funktioniert.

- [ ] Steam-Partner-Account aktiv (Tax + Bank-Info verifiziert)
- [ ] App-Erstellt im Partner-Backend, AppID zugeteilt
- [ ] **Steam Direct Application Fee bezahlt** (100 $)
- [ ] **30-Tage-Wartezeit hat begonnen** (ab Bezahlung der Fee)
- [ ] Spieltitel + Genre + Tags festgelegt
- [ ] Short Description (300 Zeichen) auf Englisch geschrieben
- [ ] Long Description (initial) auf Englisch geschrieben
- [ ] Mindestens Header Capsule (460×215) hochgeladen
- [ ] Mindestens 1 Screenshot hochgeladen (Platzhalter aus Vertical Slice OK)
- [ ] Coming-Soon-Datum gesetzt (kann fließend verschoben werden)
- [ ] Privacy Policy + EULA verlinkt (kann initial einfaches Template sein)
- [ ] Wishlist-Button aktiv
- [ ] Studio-Logo + Studio-Beschreibung hinterlegt

## B — Vor erstem Build-Upload

- [ ] Steamworks SDK in Spiel integriert
- [ ] AppID im Build hartcodiert (oder via Build-Flag setzbar)
- [ ] Build-Pipeline produziert Win + Linux + macOS Artefakte
- [ ] SteamCMD-Upload-Script funktional
- [ ] Build-Branches angelegt (`default`, `beta`, `unstable`)
- [ ] Erster Build via SteamCMD auf `unstable` hochgeladen
- [ ] Build startet lokal aus Steam-Client (Steam-Init-Call funktioniert)

## C — Vor Release-Date (alle B + folgende)

- [ ] **Long Description final** in allen Launch-Sprachen
- [ ] **Short Description final** in allen Launch-Sprachen
- [ ] **Alle Capsules final** (siehe `asset-checklist.md`)
  - [ ] Header Capsule 460×215
  - [ ] Small Capsule 231×87
  - [ ] Main Capsule 616×353
  - [ ] Vertical Capsule 374×448
  - [ ] Page Background 1438×810
  - [ ] Library Capsule 600×900
  - [ ] Library Hero 3840×1240
  - [ ] Library Logo PNG mit Alpha
- [ ] Mindestens 5 Screenshots in 1920×1080
- [ ] Trailer (60–90 s) hochgeladen und als „Featured Trailer" markiert
- [ ] System Requirements final (Min + Recommended für Win/Linux/macOS)
- [ ] Genre / Subgenre gesetzt
- [ ] Tags gesetzt (mind. 5, max. 20)
- [ ] Steam Achievements im Partner-Backend angelegt + Icons hochgeladen
- [ ] Steam Cloud konfiguriert
- [ ] Steam Input konfiguriert (default Action Set)
- [ ] Trading Cards: optional, nach Release falls Approval-Schwelle erreicht
- [ ] Preis gesetzt (4.99 € empfohlen)
- [ ] Launch-Discount konfiguriert falls geplant (max 10 %)
- [ ] **Builds auf `default`-Branch hochgeladen + verifiziert**
- [ ] **Build via Steam-Client tatsächlich gespielt** (5+ Minuten Smoke-Test)
- [ ] DLC-Vorbereitung: falls Post-Launch-DLC geplant, AppID-Struktur klar
- [ ] Refund Policy (Standard von Steam) verstanden und akzeptiert
- [ ] PEGI / ESRB Selbst-Einschätzung ausgefüllt (Idle-Spiele = ohne Altersbeschränkung)
- [ ] Privacy Policy + EULA final, mehrsprachig (mind. EN + DE)
- [ ] Open-Source-Attribution-Screen im Spiel
- [ ] Demo (falls Next Fest oder permanent) als separater AppID angelegt + hochgeladen
- [ ] Marketing-Page-Visibility-Datum gesetzt
- [ ] Reviewer-Keys gerneriert + verschickt (mind. 50 vor Release)
- [ ] **Mindestens 1000 Wishlists** (siehe Marketing-Plan-KPI)
- [ ] Discord-Server öffentlich verlinkt
- [ ] Press-Kit live auf eigener Domain

## D — Day-0 + Launch-Woche

- [ ] Public-Release-Button geklickt (nach 30-Tage-Wartezeit erreicht)
- [ ] Launch-Trailer auf Steam-Page als Featured + auf YouTube als Premiere
- [ ] News-Post „Wir sind live!" in Steam-Community veröffentlicht
- [ ] Discord-Announcement
- [ ] Reddit-Post in r/incrementalgames + r/gamedev (Launch-Post)
- [ ] Twitter / Bluesky / Mastodon Cross-Post
- [ ] Hotfix-Branch ready falls P0-Bug
- [ ] Solo-Dev erreichbar in Steam-Discussions + Discord für die ersten 72 h

---

## Post-Submission-Review-Prozesse

Steam hat 3 separate Review-Stufen, die parallel oder sequenziell laufen:

### 1. Store Page Review
- Steam-Mitarbeiter prüfen Store-Page-Inhalt auf Compliance
- Typisch 1–5 Werktage
- Trigger: jede Store-Page-Veränderung nach erstem Submit
- Kann Resubmission erfordern bei Problemen (z. B. Marketing-Sprache, falsche Genre-Klassifikation, Asset-Verstöße)

### 2. Build Review
- Steam prüft den Game-Build auf grundlegende Funktionalität, Crashes, EULA, etc.
- Typisch 1–3 Werktage pro Build-Submit
- Trigger: Build auf `default`-Branch released
- Kann Resubmission erfordern bei kritischen Issues

### 3. Steam Direct Wait
- **30 Tage zwischen Bezahlung der App Fee und frühestmöglichem Release**
- Läuft parallel zu allen anderen Reviews
- Kann nicht beschleunigt werden

→ Siehe `release-timeline.md` für integrierte Timeline.

---

## Wichtige Caveats

- **Build Review ist nicht „Inhalts-Review" wie bei App-Stores.** Steam ist relativ liberal mit Inhalt, aber prüft Funktionalität.
- **Region-Sperren / Inhalts-Anpassungen** sind weitestgehend Studio-Entscheidung (außer Glücksspiel, NSFW, etc.).
- **Steam Deck Compatibility Review** ist separat und passiert nach Release (Anmeldung im Partner-Backend möglich).
