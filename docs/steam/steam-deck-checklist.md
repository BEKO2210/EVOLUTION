# Steam Deck Verified Checklist

**Status:** Phase 0 v0.1
**Ziel:** **Steam Deck Verified anstreben** (nicht garantieren). „Playable" ist akzeptables Fallback, „Unsupported" ist nicht akzeptabel.

---

## Was bedeutet „Verified"

Steam Deck Verification hat 4 Stufen:

| Stufe | Bedeutung |
|---|---|
| **Verified** ✓ | Spiel funktioniert vollständig out-of-the-box. Beste Kategorisierung. |
| **Playable** | Spiel funktioniert, aber mit kleinen Issues (z. B. Maus-Bindings, kleine Schriftgröße, externer Launcher) |
| **Unsupported** | Spiel funktioniert nicht oder hat schwerwiegende Issues |
| **Untested** | Steam hat es noch nicht reviewed |

---

## Kriterien für „Verified" (Stand Steam-Empfehlungen)

### A — Input & Controller

- [ ] **Controller-only Navigation funktioniert vollständig** — keine Maus-Required-Aktion
- [ ] Default Controller-Layout für Steam Deck (Steam Input API) funktioniert
- [ ] Alle Aktionen via Controller erreichbar: Tab-Wechsel, Cell-Tap, Upgrades kaufen, Settings, Ability-Activation
- [ ] Glyphs (Knopf-Symbole im UI) zeigen Steam Deck Variante (Steam Input überschreibt automatisch falls Action Set definiert)
- [ ] Touch-Screen funktioniert (Steam Deck ist Touch-fähig, idle-Spiele profitieren)
- [ ] On-Screen-Keyboard via Steam Input wird ausgelöst falls Text-Input nötig (z. B. Save-Slot-Naming, Player-Name)

### B — Display & Resolution

- [ ] **1280 × 800 als Default-Resolution unterstützt** (Steam Deck native)
- [ ] UI ist responsive auch bei 1280×800 — keine abgeschnittenen Elemente
- [ ] **Textgröße mindestens 9pt** bei 1280×800 (lesbar auf 7-Zoll-Bildschirm)
- [ ] Aspect 16:10 (Steam Deck) ohne UI-Probleme dargestellt
- [ ] Auf Steam Deck OLED (höhere Pixel-Dichte) keine Unschärfe

### C — Suspend / Resume

- [ ] **Game-State persistiert bei Suspend** (Schlafmodus des Geräts)
- [ ] Audio resumed sauber nach Wake
- [ ] Cloud-Save nicht korrupt nach Suspend mit ungesichertem State
- [ ] Time-since-suspend wird korrekt in Offline-Progress umgesetzt

### D — Performance

- [ ] **60 fps Median** bei mid-game (Stage 10–15, ~1000 Cells im Cluster)
- [ ] Frametime im 99. Perzentil < 16 ms
- [ ] Kein Throttling auf Steam Deck unter Last
- [ ] Battery-Drain im Idle-Mode < 5 %/h bei Min-Brightness
- [ ] Kein nennenswertes Lüfter-Hochfahren bei normalem Spiel

### E — Launcher / Externe Abhängigkeiten

- [ ] **Kein externer Launcher** (kein Epic Online, kein eigener Launcher vorgeschaltet)
- [ ] Kein Account-Login außerhalb Steam erforderlich
- [ ] Keine externen Konfigurationsdialoge beim Start
- [ ] Spiel startet direkt in Gameplay (oder Menü)

### F — Audio

- [ ] Audio funktioniert mit Steam Deck eingebauten Lautsprechern
- [ ] Audio funktioniert mit Bluetooth-Kopfhörern (Standard-Codec)
- [ ] Audio-Mix funktioniert bei niedriger Lautstärke (Steam Deck Default ist mittel)

### G — Save / Cloud

- [ ] Steam Cloud konfiguriert + funktional
- [ ] Saves persistieren über Suspend/Resume
- [ ] Cross-Device-Save zwischen Deck und Desktop funktioniert

### H — Visual

- [ ] Cursor sichtbar wenn Maus-Mode aktiv
- [ ] UI-Hover-States funktionieren via Trackpad / Sticks
- [ ] Keine Kantenflimmern in den ersten Stages (Test mit BioNexus auf Low-End-GPU-Profil)

---

## Verbotene Patterns (führen automatisch zu Playable/Unsupported)

- ❌ „Bitte klicken Sie hier"-Buttons ohne Controller-Pendant
- ❌ Mausrad-only Scrolling in scrollbaren Listen
- ❌ Drag-and-Drop ohne Controller-Alternative
- ❌ Pre-Game-Settings-Dialog der nicht Controller-navigierbar ist
- ❌ Splash-Video das nicht überspringbar ist
- ❌ Default-Auflösung > 1280×800 ohne automatische Anpassung
- ❌ Externe Login-Pflicht
- ❌ Pop-up-Notifications die das Spiel blocken (Modal-Dialoge)

---

## Test-Plan

### Phase 1 (Engine-Prototyp)

- [ ] Linux-Build läuft auf Steam Deck (Test im Desktop-Mode reicht erstmal)
- [ ] 60 fps im Greybox-Build mit 1000 Cells

### Phase 2 (Vertical Slice)

- [ ] Vollständiger Test auf Steam Deck (LCD), 30 min Session
- [ ] Controller-Navigation komplett geprüft (alle Tabs, alle Aktionen)
- [ ] Resolutions-Test bei 1280×800
- [ ] Text-Lesbarkeit-Test bei Standard-Sitz-Abstand (~50 cm)

### Phase 3 (Alpha)

- [ ] Vollständiger Steam Deck Test, 2+ h Session
- [ ] Suspend/Resume-Test (10× nacheinander)
- [ ] Battery-Drain-Messung (1h Idle, 1h Active)
- [ ] Test auf Steam Deck OLED falls verfügbar

### Phase 4 (Beta)

- [ ] **Self-Submit für Steam Deck Review** (im Partner-Backend)
- [ ] Test mit Beta-Spielern die Steam Deck haben (5+ Personen)
- [ ] Cloud-Save Cross-Device Steam Deck ↔ Desktop verifiziert

### Phase 5 (Release-Prep)

- [ ] Steam Deck Review-Status auf Verified hoffend
- [ ] Falls Playable: Steam-Review-Feedback umsetzen + Resubmit
- [ ] Falls Unsupported: Release verschieben + Issues fixen

---

## Verantwortlichkeiten

- **Dev:** Alle technischen Kriterien (Controller, Suspend, Performance, Auflösung)
- **Designer:** Alle UX-Kriterien (Touch-Targets, Glyph-Konsistenz, Text-Größe)
- **QA:** Test-Plan-Ausführung pro Phase, Issue-Tracking

---

## Disclaimer

Diese Checkliste basiert auf den öffentlich kommunizierten Steam-Empfehlungen. **Steam kann zusätzliche oder geänderte Kriterien anwenden** — vor Submission die offizielle Steamworks-Dokumentation prüfen (https://partner.steamgames.com/doc/steamdeck).

**„Verified" ist Steam-Discretion** — wir können alle Kriterien erfüllen und trotzdem auf „Playable" gestuft werden. Strategie: erfüllen, submitten, Feedback umsetzen, resubmiten.
