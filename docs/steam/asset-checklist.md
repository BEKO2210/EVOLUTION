# Steam Asset Checklist

**Status:** Phase 0 v0.1
**Wichtig:** Steam aktualisiert gelegentlich Asset-Anforderungen. **Vor finaler Produktion und vor Submission jede Größe gegen die aktuelle Steamworks-Dokumentation verifizieren** (https://partner.steamgames.com/doc/store/assets).

---

## Store-Capsules

| Asset | Größe (px) | Format | Pflicht | Verwendung |
|---|---|---|---|---|
| Header Capsule (klein) | 460 × 215 | PNG | ✓ | Tile auf Browse-/Store-Listen |
| Small Capsule | 231 × 87 | PNG | ✓ | Such-Ergebnisse, kleine Listen |
| Main Capsule | 616 × 353 | PNG | ✓ | Daily Deals, Featured-Listen |
| Vertical Capsule | 374 × 448 | PNG | ✓ | Frontpage Featured, Sales |
| Page Background | 1438 × 810 | JPG/PNG | ✓ | Hintergrund der Store-Page |

## Library Assets (für installiertes Spiel im Steam-Client)

| Asset | Größe (px) | Format | Pflicht | Verwendung |
|---|---|---|---|---|
| Library Capsule | 600 × 900 | PNG | ✓ | Library-Grid-Ansicht |
| Library Hero | 3840 × 1240 | PNG | ✓ | Hintergrund auf Library-Detail-Page |
| Library Logo | PNG mit Alpha | PNG | ✓ | Logo-Overlay auf Library Hero |
| Client Icon | 32 × 32 | ICO oder PNG | ✓ | Taskbar / Window-Icon |

## Community Items (optional, Phase 7)

| Asset | Größe (px) | Format | Pflicht |
|---|---|---|---|
| Profile Background | 1438 × 810 | JPG | nein |
| Trading Card | 184 × 256 | PNG | nein (Approval-Prozess) |
| Profile Frame | 760 × 376 | PNG (mit Alpha) | nein |
| Game Badge | 256 × 256 | PNG | nein |

## Screenshots

| Asset | Größe (px) | Format | Anzahl |
|---|---|---|---|
| Screenshots | mind. 1920 × 1080 | JPG / PNG | mind. 5, empfohlen 8–12 |
| Steam Deck Screenshots | 1280 × 800 | JPG / PNG | nice-to-have, separat hochladbar |

**Inhaltsregeln:**
- Echtes Gameplay, kein Concept-Art
- Erste 4–5 Screenshots zeigen Kern-Mechanik (Cell, Upgrades, Stage-Übergänge)
- Keine UI-Elemente, die nicht im Spiel vorkommen
- Konsistente Auflösung über alle Screenshots
- Keine Wasserzeichen / Text-Overlays

## Trailer

| Asset | Spec |
|---|---|
| Format | MP4 (H.264, AAC Audio) |
| Auflösung | 1920 × 1080 (1080p) Master, evtl. 2160p (4K) für Hero-Trailer |
| Länge | 60–90 Sekunden (Standard), max 90 s für Auto-Play |
| Audio | -16 LUFS, true-peak ≤ -1 dBTP |
| Aspect | 16:9 |
| Frame Rate | 30 oder 60 fps |
| Hook | erste 5 Sekunden tragen den Visual-Hook (Auto-Play startet stumm) |
| CTA | „Wishlist on Steam" am Ende, falls Pre-Launch |

## Text-Assets (Store-Page-Texte)

| Asset | Limit | Sprachen |
|---|---|---|
| Short Description | 300 Zeichen | alle Launch-Sprachen |
| Long Description | unbegrenzt (Empfehlung: 800–2000 Wörter mit Bullet-Listen + GIFs) | alle Launch-Sprachen |
| Tags | bis zu 20, von Genre-Tags ausgehen | EN (Tags sind sprach-neutral) |
| Genre (Steam-Kategorie) | 1 Primär + bis zu 2 Sekundäre | n/a |
| Pricing-Beschreibung | von Steam vorgegeben | n/a |

## Mehrsprachige Assets

Für jede unterstützte Sprache:
- Lokalisierter Store-Page-Text (Short + Long Description)
- **Optional:** lokalisierte Screenshots (mit übersetzten UI-Strings) — pro Sprache eigene Screenshot-Sets möglich
- **Optional:** lokalisierter Trailer mit Untertiteln oder Voice-Over (für VO-freies Spiel nur Untertitel falls Text im Trailer)

## Prüf-Checkliste vor Submission

- [ ] Alle Capsule-Größen verifiziert gegen aktuelle Steamworks-Dokumentation
- [ ] Header / Small / Main / Vertical Capsule produziert + uploaded
- [ ] Page Background uploaded
- [ ] Library Capsule + Hero + Logo uploaded
- [ ] Mindestens 5 Screenshots in 1920×1080 uploaded
- [ ] Trailer als MP4 H.264 < 90 s uploaded
- [ ] Short Description in allen Launch-Sprachen
- [ ] Long Description in allen Launch-Sprachen
- [ ] Tags gesetzt (mind. 5, empfohlen 10)
- [ ] System Requirements gesetzt (Min + Recommended)
- [ ] Genre + Subgenre gesetzt
- [ ] Preis gesetzt + Preis-Geschichte konfiguriert (Launch-Discount falls geplant)
- [ ] „Coming Soon"-Datum gesetzt
- [ ] Logo-Files für Press-Kit kopiert (PNG mit Alpha)
- [ ] Alle Assets in `assets/steam/` Versionierungs-tagged

## Production-Empfehlungen

- **Source-Files behalten:** AI / Vector / PSD für alle Capsules, damit Updates möglich
- **Naming-Convention:** `evolution_capsule_header_460x215_v2.png` mit Version
- **Color-Profil:** sRGB (Steam zeigt im Browser → kein wide-gamut)
- **PNG-Optimierung:** vor Upload via `oxipng` oder ähnlich (reduziert Größe um 30–50 %)
- **Trailer-Hoster:** primär Steam-CDN. YouTube-Mirror für externe Marketing-Verlinkung

## Disclaimer

Steam ändert gelegentlich Asset-Anforderungen (z. B. Einführung neuer Capsule-Typen, geänderte Größen). Diese Checkliste ist Stand zum Zeitpunkt von Phase 0. Vor jedem Asset-Production-Sprint:

1. https://partner.steamgames.com/doc/store/assets aufrufen
2. Aktuelle Größen + Pflicht-Status prüfen
3. Diese Datei updaten + ADR oder Changelog-Eintrag schreiben
