# 10 — Release Checklist (Master)

**Status:** Phase 0 v0.1 — Master-Checkliste, konsolidiert mehrere `docs/steam/*`-Checklisten.

Diese Datei wird kurz vor Release durchgegangen. Kein Punkt offen = release-fähig.

---

## Geschäftsmäßig

- [ ] Steam Direct Application Fee bezahlt (100 $)
- [ ] Tax-Form + Bank-Info verifiziert im Steam Partner-Backend
- [ ] 30-Tage-Wartezeit verstrichen
- [ ] Spieltitel Trademark-Check durchgeführt (USPTO, EUIPO, DPMA)
- [ ] Domain registriert (Press-Kit, Privacy Policy)
- [ ] Studio-Entity (falls relevant: Gewerbe / GbR / GmbH / Einzelunternehmen) klar

## Rechtlich

- [ ] Privacy Policy online + im Spiel verlinkt
- [ ] EULA online + im Spiel verlinkt
- [ ] DSGVO-konforme Telemetrie-Einwilligung im First-Run-Dialog
- [ ] Open-Source-Attribution-Screen im Spiel (Godot MIT, GodotSteam, etc.)
- [ ] Übersetzer-Verträge mit Buy-Out-Klausel dokumentiert
- [ ] Audio-Komponist-Vertrag mit Buy-Out-Klausel dokumentiert
- [ ] PEGI / ESRB Selbst-Einschätzung im Steam-Backend
- [ ] Refund Policy (Steam-Standard) verstanden

## Store-Page (siehe `docs/steam/store-page-checklist.md`)

- [ ] Alle Capsules hochgeladen (siehe `docs/steam/asset-checklist.md`)
- [ ] Mindestens 5 Screenshots in 1920×1080
- [ ] Trailer 60–90 s als MP4 H.264 hochgeladen
- [ ] Short + Long Description in allen Launch-Sprachen
- [ ] Tags gesetzt (mind. 5)
- [ ] Genre + Subgenre
- [ ] System Requirements (Min + Recommended) für Win + Linux + macOS
- [ ] Preis gesetzt (4.99 €)
- [ ] Launch-Discount konfiguriert falls geplant

## Build & Steamworks

- [ ] Steamworks SDK eingebunden (GodotSteam Spike erfolgreich)
- [ ] Build-Pipeline produziert Win + Linux + macOS Artefakte
- [ ] Builds auf `default`-Branch hochgeladen + Lock entfernt
- [ ] Build via Steam-Client gespielt (5+ min Smoke-Test pro Plattform)
- [ ] `beta`, `unstable`, `hotfix`-Branches angelegt
- [ ] Hotfix-Branch <2 h einsatzbereit
- [ ] Source + Assets in 2 unabhängigen Backups

## Steam Features

- [ ] Achievements im Backend angelegt + Icons hochgeladen + ingame triggert korrekt
- [ ] Cloud Save konfiguriert + Cross-Device-Test bestanden
- [ ] Steam Input konfiguriert (default Action Set für Controller)
- [ ] Steam Trading Cards: in Phase 7, nicht v1.0

## Plattformen

- [ ] Windows 10/11 getestet (Low/Mid/High GPU)
- [ ] Linux (Ubuntu 22.04) getestet
- [ ] macOS Sonoma getestet (Intel + Apple Silicon)
- [ ] **Steam Deck Compatibility Check** (siehe `docs/steam/steam-deck-checklist.md`)

## QA (siehe `qa/smoke-test.md`)

- [ ] QA-Matrix auf allen Ziel-Geräten bestanden
- [ ] Zero P0, Zero P1, <10 dokumentierte P2
- [ ] Save-Migration über alle Schema-Versionen getestet
- [ ] 1000-Cycle Save/Load Stress-Test bestanden
- [ ] Performance ≥60 fps auf Min-Spec
- [ ] Accessibility-Audit (Touch-Targets, Color-Blind, kein Flickering)
- [ ] Crash-Reporting (Sentry) live + Dashboard erreichbar

## Übersetzungen

- [ ] Übersetzungen für alle Launch-Sprachen integriert
- [ ] Native-Speaker-Review für EN, DE, JA, zh-Hans (kritische 4)
- [ ] Übersetzungen in `localization/strings.csv` versioniert in Repo
- [ ] CJK-Font-Fallback im Theme funktioniert

## Marketing

- [ ] Steam-Page seit ≥3 Monaten live
- [ ] **≥1000 Wishlists** (siehe `docs/08-steam-marketing-plan.md`)
- [ ] Press-Kit online
- [ ] ≥50 Streamer/Press kontaktiert
- [ ] Reviewer-Keys generiert + ausgegeben
- [ ] Demo (Next Fest oder permanent) verfügbar
- [ ] Discord-Server live, mind. 200 Members
- [ ] Devlog-Reihe (mind. 5 Posts) veröffentlicht
- [ ] Launch-Trailer auf YouTube als Premiere geplant

## Launch-Tag

- [ ] Public-Release-Button geklickt
- [ ] Launch-Trailer auf YouTube live
- [ ] News-Post „Wir sind live!" in Steam-Community
- [ ] Discord-Announcement
- [ ] Reddit-Post in r/incrementalgames + r/gamedev
- [ ] Twitter / Bluesky Cross-Post
- [ ] Solo-Dev erreichbar (Discord, Steam-Forum, Email)
- [ ] Tag freigeschaufelt, keine anderen Termine

## Tag +7 (Launch-Woche-Abschluss)

- [ ] Mindestens 1 Patch released (falls nötig)
- [ ] Reviews-Monitoring, P0-Bugs gefixed
- [ ] Launch-Retro-Post in Discord/Reddit
- [ ] Wishlist→Verkauf-Conversion-Rate gemessen
- [ ] KPI-Report für eigene Records erstellt

---

## Hard-Stop-Kriterien

**Release wird verschoben wenn:**

- [ ] <500 Wishlists vor Release (Algorithmus-Wand)
- [ ] P0/P1-Bug in Release-Candidate-Build
- [ ] Steam Deck Compatibility ist „Unsupported"
- [ ] Save-Migration für aktuellen Schema nicht getestet
- [ ] Build-Review von Steam abgelehnt
- [ ] Store-Page-Review von Steam abgelehnt und nicht innerhalb 1 Woche resubmitable

→ Verschieben statt mit Mängeln launchen. Reputation > Kalender.
